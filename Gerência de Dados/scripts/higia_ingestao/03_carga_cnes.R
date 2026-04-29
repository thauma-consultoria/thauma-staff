# =============================================================================
# THAUMA Data Lake — Higia F0: Carga CNES-ST
# =============================================================================
# Baixa, processa e carrega CNES-ST (Estabelecimentos) para BigQuery.
# Single snapshot: a tabela e' substituida integralmente (WRITE_TRUNCATE).
# Por padrao busca a competencia mais recente disponivel para a UF.
#
# Auto-deteccao: tenta o mes corrente e retrocede ate achar dados (max 6 meses).
# =============================================================================

if (!exists("higia_log")) {
  source(file.path(dirname(sys.frame(1)$ofile), "00_setup.R"))
}

cnes_descobrir_competencia <- function(uf) {
  hoje <- Sys.Date()
  for (k in 0:6) {
    ano <- as.integer(format(seq(hoje, by = sprintf("-%d months", k),
                                  length.out = 2)[2], "%Y"))
    mes <- as.integer(format(seq(hoje, by = sprintf("-%d months", k),
                                  length.out = 2)[2], "%m"))
    higia_log(sprintf("[CNES] tentando competencia %s-%02d...", ano, mes))
    df <- tryCatch(
      fetch_datasus(
        year_start = ano, year_end = ano,
        month_start = mes, month_end = mes,
        uf = uf,
        information_system = "CNES-ST"
      ),
      error = function(e) NULL
    )
    if (!is.null(df) && nrow(df) > 0) {
      higia_log(sprintf("[CNES] competencia disponivel: %s-%02d (%s linhas)",
                        ano, mes, format(nrow(df), big.mark = ".")))
      return(list(ano = ano, mes = mes, df = df))
    }
  }
  higia_log("[CNES] nenhuma competencia recente disponivel (testou 7 meses).",
            "ERROR")
  NULL
}

carga_cnes <- function(uf = UF,
                       ano = COMP_CNES$ano,
                       mes = COMP_CNES$mes) {
  higia_log(sprintf("=== INICIO carga CNES-ST %s ===", uf))

  if (is.null(ano) || is.null(mes)) {
    res <- cnes_descobrir_competencia(uf)
    if (is.null(res)) {
      higia_manifest_record("CNES-ST", uf, NA, NA, status = "fail")
      return(invisible(NULL))
    }
    ano <- res$ano; mes <- res$mes; df <- res$df
  } else {
    higia_log(sprintf("[CNES] competencia fixada: %s-%02d", ano, mes))
    df <- tryCatch(
      fetch_datasus(
        year_start = ano, year_end = ano,
        month_start = mes, month_end = mes,
        uf = uf,
        information_system = "CNES-ST"
      ),
      error = function(e) {
        higia_log(sprintf("[CNES] FALHA download: %s",
                          conditionMessage(e)), "ERROR")
        NULL
      }
    )
    if (is.null(df) || nrow(df) == 0) {
      higia_manifest_record("CNES-ST", uf, ano, mes, status = "fail")
      return(invisible(NULL))
    }
  }

  if (higia_manifest_check("CNES-ST", uf, ano, mes)) {
    higia_log(sprintf("[CNES] %s-%02d ja em manifest (ok) — pulando.",
                      ano, mes))
    return(invisible(NULL))
  }

  higia_log(sprintf("[CNES] %s-%02d processando (process_cnes ST)...",
                    ano, mes))
  df_proc <- tryCatch(
    process_cnes(df, information_system = "CNES-ST"),
    error = function(e) {
      higia_log(sprintf("[CNES] erro process_cnes: %s — uso bruto",
                        conditionMessage(e)), "WARN")
      df
    }
  )

  mes_2d <- sprintf("%02d", mes)
  tabela <- sprintf("cnes_st_%s_%s_%s", tolower(uf), ano, mes_2d)

  pq <- file.path(PROCESSED_DIR, sprintf("%s.parquet", tabela))
  write_parquet(df_proc, pq)
  higia_log(sprintf("[CNES] parquet local: %s (%.1f MB)",
                    basename(pq), file.size(pq) / 1024 / 1024))

  higia_bq_upload(df_proc, tabela, write_disposition = "WRITE_TRUNCATE")

  higia_manifest_record("CNES-ST", uf, ano, mes,
                        status = "ok",
                        registros = nrow(df_proc),
                        tabela = tabela)

  higia_log(sprintf("=== FIM carga CNES-ST %s (competencia %s-%02d) ===",
                    uf, ano, mes_2d))
}
