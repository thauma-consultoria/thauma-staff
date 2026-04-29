# =============================================================================
# THAUMA Data Lake — Higia F0: Setup Compartilhado
# =============================================================================
# Define parametros, bibliotecas, autenticacao BQ, logging e checkpoint.
# Carregado via source() no orquestrador e em cada script de carga.
#
# Agente: Heraclito (Engenheiro de Dados) | Gerente: Pitagoras
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PARAMETROS DA INGESTAO (alterar aqui para reaproveitar em outras UFs/anos)
# -----------------------------------------------------------------------------
UF              <- "MG"            # UF alvo (SIH/SIA/CNES filtram por essa UF)
ANOS_SIH_SIA    <- 2024:2025       # Anos completos a carregar (SIH-RD e SIA-PA)
MESES           <- 1:12            # Meses dentro de cada ano
COMP_CNES       <- list(ano = NULL, mes = NULL)  # NULL = competencia mais recente disponivel

PROJECT_ID      <- "datalake-thauma"
DATASET_RAW     <- "raw_saude"

# -----------------------------------------------------------------------------
# 2. CAMINHOS (absolutos para ser robusto entre maquinas)
# -----------------------------------------------------------------------------
# A raiz e' a pasta "Gerencia de Dados/" (dois niveis acima deste arquivo)
SCRIPT_DIR <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile, mustWork = FALSE)),
  error = function(e) getwd()
)
if (is.null(SCRIPT_DIR) || !nzchar(SCRIPT_DIR) || SCRIPT_DIR == ".") {
  # Fallback: assume cwd e' higia_ingestao/
  SCRIPT_DIR <- getwd()
}

GERENCIA_DIR  <- normalizePath(file.path(SCRIPT_DIR, "..", ".."), mustWork = FALSE)
DATA_DIR      <- file.path(GERENCIA_DIR, "data")
LOG_DIR       <- file.path(GERENCIA_DIR, "logs")
PROCESSED_DIR <- file.path(DATA_DIR, "processed")
MANIFEST_PATH <- file.path(PROCESSED_DIR, "manifest.csv")

dir.create(DATA_DIR,      recursive = TRUE, showWarnings = FALSE)
dir.create(LOG_DIR,       recursive = TRUE, showWarnings = FALSE)
dir.create(PROCESSED_DIR, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 3. BIBLIOTECAS
# -----------------------------------------------------------------------------
required_pkgs <- c("microdatasus", "arrow", "dplyr", "bigrquery", "readr")
missing <- required_pkgs[!vapply(required_pkgs, requireNamespace,
                                 logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  stop(sprintf(
    "[higia/setup] Pacotes ausentes: %s\nInstalar antes de rodar a carga.",
    paste(missing, collapse = ", ")
  ))
}
suppressPackageStartupMessages({
  library(microdatasus)
  library(arrow)
  library(dplyr)
  library(bigrquery)
  library(readr)
})

# -----------------------------------------------------------------------------
# 4. LOGGING ESTRUTURADO
# -----------------------------------------------------------------------------
.higia_log_file <- NULL

higia_log_init <- function(tag = "ingestao") {
  ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
  .higia_log_file <<- file.path(LOG_DIR, sprintf("%s_%s.log", tag, ts))
  cat(sprintf("[higia] log: %s\n", .higia_log_file))
  invisible(.higia_log_file)
}

higia_log <- function(msg, level = "INFO") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- sprintf("[%s] %s | %s", ts, level, msg)
  cat(line, "\n", sep = "")
  flush.console()
  if (!is.null(.higia_log_file)) {
    cat(line, "\n", sep = "", file = .higia_log_file, append = TRUE)
  }
}

# -----------------------------------------------------------------------------
# 5. CHECKPOINT / IDEMPOTENCIA (manifest.csv)
# -----------------------------------------------------------------------------
# manifest.csv guarda (base, uf, ano, mes, status, registros, tabela, ts)
# Re-execucao consulta este arquivo e pula competencias ja em status=ok.
# Para FORCAR recarga, deletar a linha do manifest correspondente OU rodar
# higia_manifest_reset(base, uf, ano, mes).

higia_manifest_load <- function() {
  if (!file.exists(MANIFEST_PATH)) {
    return(tibble::tibble(
      base = character(), uf = character(),
      ano = integer(), mes = integer(),
      status = character(), registros = integer(),
      tabela = character(), ts = character()
    ))
  }
  readr::read_csv(MANIFEST_PATH, col_types = readr::cols(
    base = "c", uf = "c", ano = "i", mes = "i",
    status = "c", registros = "i", tabela = "c", ts = "c"
  ))
}

higia_manifest_check <- function(base, uf, ano, mes) {
  m <- higia_manifest_load()
  any(m$base == base & m$uf == uf & m$ano == ano &
      m$mes == mes & m$status == "ok")
}

higia_manifest_record <- function(base, uf, ano, mes,
                                  status, registros = NA_integer_,
                                  tabela = NA_character_) {
  m <- higia_manifest_load()
  m <- dplyr::filter(m, !(base == !!base & uf == !!uf &
                          ano == !!ano & mes == !!mes))
  novo <- tibble::tibble(
    base = base, uf = uf, ano = as.integer(ano), mes = as.integer(mes),
    status = status, registros = as.integer(registros %||% NA),
    tabela = tabela %||% NA_character_,
    ts = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
  m <- dplyr::bind_rows(m, novo)
  readr::write_csv(m, MANIFEST_PATH)
  invisible(m)
}

`%||%` <- function(a, b) if (is.null(a) || is.na(a)) b else a

# -----------------------------------------------------------------------------
# 6. AUTENTICACAO BIGQUERY
# -----------------------------------------------------------------------------
# Espera-se que `gcloud auth application-default login` ja tenha sido executado
# na maquina antes da primeira carga. bigrquery usa as ADC automaticamente.
higia_bq_check <- function() {
  higia_log(sprintf("Validando acesso a BigQuery: %s", PROJECT_ID))
  out <- tryCatch({
    bq_project_datasets(PROJECT_ID)
    TRUE
  }, error = function(e) {
    higia_log(sprintf("FALHA autenticando BQ: %s", conditionMessage(e)),
              "ERROR")
    higia_log(
      "Rodar: gcloud auth application-default login (e instalar gcloud SDK)",
      "ERROR"
    )
    FALSE
  })
  out
}

# -----------------------------------------------------------------------------
# 7. UPLOAD HELPER (idempotente por competencia)
# -----------------------------------------------------------------------------
# Estrategia: WRITE_TRUNCATE por (UF, ano, mes) usando tabela particionada
# logica via SUFIXO de competencia. Ex.: sih_rd_mg_2024_01.
# Re-rodar a mesma competencia substitui apenas aquela tabela.
higia_bq_upload <- function(df, table_short, write_disposition = "WRITE_TRUNCATE") {
  tab <- bq_table(PROJECT_ID, DATASET_RAW, table_short)
  if (bq_table_exists(tab) && write_disposition == "WRITE_TRUNCATE") {
    higia_log(sprintf("BQ: substituindo tabela existente %s.%s",
                      DATASET_RAW, table_short))
  }
  bq_table_upload(tab, df, write_disposition = write_disposition,
                  create_disposition = "CREATE_IF_NEEDED")
  higia_log(sprintf("BQ: upload concluido -> %s.%s.%s (%s linhas)",
                    PROJECT_ID, DATASET_RAW, table_short,
                    format(nrow(df), big.mark = ".")))
}

higia_log("setup carregado.", "INFO")
