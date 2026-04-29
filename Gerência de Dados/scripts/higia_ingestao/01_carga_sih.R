# =============================================================================
# THAUMA Data Lake — Higia F0: Carga SIH-RD
# =============================================================================
# Baixa, processa e carrega SIH-RD (AIH Reduzida) para BigQuery.
# Idempotente por competencia (ano-mes) via manifest.csv.
#
# Uso (chamado pelo orquestrador):
#   source("00_setup.R"); source("01_carga_sih.R"); carga_sih()
#
# Para forcar recarga de uma competencia: editar manifest.csv ou apagar.
# =============================================================================

if (!exists("higia_log")) {
  source(file.path(dirname(sys.frame(1)$ofile), "00_setup.R"))
}

carga_sih_competencia <- function(uf, ano, mes) {
  base    <- "SIH-RD"
  ano_2d  <- sprintf("%02d", ano %% 100)
  mes_2d  <- sprintf("%02d", mes)
  tabela  <- sprintf("sih_rd_%s_%s_%s", tolower(uf), ano, mes_2d)

  if (higia_manifest_check(base, uf, ano, mes)) {
    higia_log(sprintf("[SIH] %s/%s-%s ja em manifest (ok) — pulando.",
                      uf, ano, mes_2d))
    return(invisible(NULL))
  }

  higia_log(sprintf("[SIH] %s/%s-%s -> baixando via microdatasus...",
                    uf, ano, mes_2d))

  df <- tryCatch(
    fetch_datasus(
      year_start = ano, year_end = ano,
      month_start = mes, month_end = mes,
      uf = uf,
      information_system = "SIH-RD"
    ),
    error = function(e) {
      higia_log(sprintf("[SIH] FALHA download %s/%s-%s: %s",
                        uf, ano, mes_2d, conditionMessage(e)), "ERROR")
      NULL
    }
  )
  if (is.null(df) || nrow(df) == 0) {
    higia_manifest_record(base, uf, ano, mes, status = "fail")
    return(invisible(NULL))
  }
  higia_log(sprintf("[SIH] %s/%s-%s bruto: %s linhas, %d colunas",
                    uf, ano, mes_2d,
                    format(nrow(df), big.mark = "."), ncol(df)))

  higia_log(sprintf("[SIH] %s/%s-%s processando (process_sih)...",
                    uf, ano, mes_2d))
  df_proc <- tryCatch(
    process_sih(df, information_system = "SIH-RD"),
    error = function(e) {
      higia_log(sprintf("[SIH] erro process_sih: %s — uso bruto",
                        conditionMessage(e)), "WARN")
      df
    }
  )

  pq <- file.path(PROCESSED_DIR, sprintf("%s.parquet", tabela))
  write_parquet(df_proc, pq)
  higia_log(sprintf("[SIH] parquet local: %s (%.1f MB)",
                    basename(pq), file.size(pq) / 1024 / 1024))

  higia_bq_upload(df_proc, tabela, write_disposition = "WRITE_TRUNCATE")

  higia_manifest_record(base, uf, ano, mes,
                        status = "ok",
                        registros = nrow(df_proc),
                        tabela = tabela)

  invisible(tabela)
}

carga_sih <- function(uf = UF, anos = ANOS_SIH_SIA, meses = MESES) {
  higia_log(sprintf("=== INICIO carga SIH-RD %s | anos: %s | %d meses cada ===",
                    uf, paste(range(anos), collapse = "-"), length(meses)))
  for (ano in anos) {
    for (mes in meses) {
      carga_sih_competencia(uf, ano, mes)
    }
  }
  higia_log(sprintf("=== FIM carga SIH-RD %s ===", uf))
}
