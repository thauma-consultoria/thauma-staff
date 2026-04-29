# =============================================================================
# THAUMA Data Lake — Higia F0: Carga SIA-PA
# =============================================================================
# Baixa, processa e carrega SIA-PA (Producao Ambulatorial) para BigQuery.
# Idempotente por competencia (ano-mes) via manifest.csv.
#
# NOTA: SIA-PA tem volume significativamente maior que SIH-RD. Em maquinas
# com pouca memoria, considerar reduzir 'meses' por execucao ou usar swap.
# microdatasus.process_sia() ja faz limpeza/decodificacao.
# =============================================================================

if (!exists("higia_log")) {
  source(file.path(dirname(sys.frame(1)$ofile), "00_setup.R"))
}

carga_sia_competencia <- function(uf, ano, mes) {
  base    <- "SIA-PA"
  mes_2d  <- sprintf("%02d", mes)
  tabela  <- sprintf("sia_pa_%s_%s_%s", tolower(uf), ano, mes_2d)

  if (higia_manifest_check(base, uf, ano, mes)) {
    higia_log(sprintf("[SIA] %s/%s-%s ja em manifest (ok) — pulando.",
                      uf, ano, mes_2d))
    return(invisible(NULL))
  }

  higia_log(sprintf("[SIA] %s/%s-%s -> baixando via microdatasus...",
                    uf, ano, mes_2d))

  df <- tryCatch(
    fetch_datasus(
      year_start = ano, year_end = ano,
      month_start = mes, month_end = mes,
      uf = uf,
      information_system = "SIA-PA"
    ),
    error = function(e) {
      higia_log(sprintf("[SIA] FALHA download %s/%s-%s: %s",
                        uf, ano, mes_2d, conditionMessage(e)), "ERROR")
      NULL
    }
  )
  if (is.null(df) || nrow(df) == 0) {
    higia_manifest_record(base, uf, ano, mes, status = "fail")
    return(invisible(NULL))
  }
  higia_log(sprintf("[SIA] %s/%s-%s bruto: %s linhas, %d colunas",
                    uf, ano, mes_2d,
                    format(nrow(df), big.mark = "."), ncol(df)))

  higia_log(sprintf("[SIA] %s/%s-%s processando (process_sia)...",
                    uf, ano, mes_2d))
  df_proc <- tryCatch(
    process_sia(df, information_system = "SIA-PA"),
    error = function(e) {
      higia_log(sprintf("[SIA] erro process_sia: %s — uso bruto",
                        conditionMessage(e)), "WARN")
      df
    }
  )

  pq <- file.path(PROCESSED_DIR, sprintf("%s.parquet", tabela))
  write_parquet(df_proc, pq)
  higia_log(sprintf("[SIA] parquet local: %s (%.1f MB)",
                    basename(pq), file.size(pq) / 1024 / 1024))

  higia_bq_upload(df_proc, tabela, write_disposition = "WRITE_TRUNCATE")

  higia_manifest_record(base, uf, ano, mes,
                        status = "ok",
                        registros = nrow(df_proc),
                        tabela = tabela)

  # Liberar memoria — SIA cresce rapido
  rm(df, df_proc); gc(verbose = FALSE)

  invisible(tabela)
}

carga_sia <- function(uf = UF, anos = ANOS_SIH_SIA, meses = MESES) {
  higia_log(sprintf("=== INICIO carga SIA-PA %s | anos: %s | %d meses cada ===",
                    uf, paste(range(anos), collapse = "-"), length(meses)))
  for (ano in anos) {
    for (mes in meses) {
      carga_sia_competencia(uf, ano, mes)
    }
  }
  higia_log(sprintf("=== FIM carga SIA-PA %s ===", uf))
}
