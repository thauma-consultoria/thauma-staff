# =============================================================================
# THAUMA Data Lake — Higia F0: Orquestrador Mestre
# =============================================================================
# Executa, em sequencia: SIH-RD -> SIA-PA -> CNES-ST.
# Idempotente: re-execucao consulta manifest.csv e pula competencias ja "ok".
#
# Pre-requisitos na maquina:
#   1) R 4.x com pacotes: microdatasus, arrow, dplyr, bigrquery, readr
#   2) gcloud SDK instalado e autenticado:
#        gcloud auth application-default login
#      (projeto alvo: datalake-thauma)
#
# Execucao:
#   Rscript "Gerencia de Dados/scripts/higia_ingestao/executar_higia_ingestao.R"
#
# Acompanhamento (em outro terminal):
#   tail -f "Gerencia de Dados/logs/<arquivo_mais_recente>.log"
#
# Para retomar apos queda: basta rodar o mesmo comando — o manifest cuida.
# Para forcar recarga: editar/apagar linhas em data/processed/manifest.csv.
# =============================================================================

# 1. Localizar e carregar setup
this_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile, mustWork = FALSE)),
  error = function(e) {
    args <- commandArgs(trailingOnly = FALSE)
    f <- sub("--file=", "", args[grep("--file=", args)])
    if (length(f) > 0) dirname(normalizePath(f, mustWork = FALSE)) else getwd()
  }
)
setwd(this_dir)

source(file.path(this_dir, "00_setup.R"))
source(file.path(this_dir, "01_carga_sih.R"))
source(file.path(this_dir, "02_carga_sia.R"))
source(file.path(this_dir, "03_carga_cnes.R"))

higia_log_init(tag = "higia_f0")
higia_log("============================================================")
higia_log(sprintf("HIGIA F0 — INICIO | UF=%s | anos=%s",
                  UF, paste(range(ANOS_SIH_SIA), collapse = "-")))
higia_log(sprintf("Projeto BQ: %s | dataset: %s",
                  PROJECT_ID, DATASET_RAW))
higia_log("============================================================")

if (!higia_bq_check()) {
  higia_log("Abortando: autenticacao BQ falhou.", "ERROR")
  quit(status = 1)
}

t0 <- Sys.time()

# Etapa 1: SIH-RD
tryCatch(
  carga_sih(uf = UF, anos = ANOS_SIH_SIA, meses = MESES),
  error = function(e) higia_log(sprintf("Erro fatal SIH: %s",
                                         conditionMessage(e)), "ERROR")
)

# Etapa 2: SIA-PA
tryCatch(
  carga_sia(uf = UF, anos = ANOS_SIH_SIA, meses = MESES),
  error = function(e) higia_log(sprintf("Erro fatal SIA: %s",
                                         conditionMessage(e)), "ERROR")
)

# Etapa 3: CNES-ST
tryCatch(
  carga_cnes(uf = UF),
  error = function(e) higia_log(sprintf("Erro fatal CNES: %s",
                                         conditionMessage(e)), "ERROR")
)

# Resumo final
m <- higia_manifest_load()
ok <- sum(m$status == "ok")
fail <- sum(m$status == "fail")
total_reg <- sum(m$registros[m$status == "ok"], na.rm = TRUE)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))

higia_log("============================================================")
higia_log(sprintf("HIGIA F0 — FIM | %.1f min | %d competencias OK | %d falhas",
                  elapsed, ok, fail))
higia_log(sprintf("Registros totais carregados: %s",
                  format(total_reg, big.mark = ".")))
higia_log("============================================================")

# Saida com codigo apropriado
if (fail > 0) {
  higia_log(sprintf("Atencao: %d competencias falharam — ver manifest.csv",
                    fail), "WARN")
  quit(status = 2)
}
quit(status = 0)
