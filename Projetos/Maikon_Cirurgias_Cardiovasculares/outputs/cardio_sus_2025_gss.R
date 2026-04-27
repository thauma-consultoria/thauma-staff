# ============================================================
# F2 PIPELINE — Cirurgias Cardiovasculares SUS 2025
# Cliente: Dr. Maikon Almeida (GSS Saude) — projeto GSS-CARDIO-2025
# Owner técnico: Heráclito (Engenheiro de Dados — THAUMA)
# Execução: 2026-04-26
# Saída: outputs/cardio_sus_2025_gss.xlsx
# ============================================================

t0 <- Sys.time()
cat("=== F2 PIPELINE CARDIO SUS 2025 ===\n")
cat("Início:", format(t0), "\n\n")

suppressWarnings(suppressMessages({
  library(data.table)
  library(arrow)
  library(openxlsx)
}))

# -----------------------------------------------------------
# PARÂMETROS
# -----------------------------------------------------------
DIR_BASE   <- "C:/Users/pedro/Desktop/Thauma/Projetos/Maikon_Cirurgias_Cardiovasculares"
DIR_SIH    <- file.path(DIR_BASE, "dados/sih_rd_2025")
DIR_CNES   <- file.path(DIR_BASE, "dados/cnes_st")
DIR_DIM    <- "C:/Users/pedro/Desktop/Thauma/Gerência de Dados/data/enrichment"
CNES_FANTASIA_RDS <- "C:/Users/pedro/Desktop/Thauma/Gerência de Dados/docs/cnes.rds"
DIR_OUT    <- file.path(DIR_BASE, "outputs")
LOGO       <- "C:/Users/pedro/Desktop/Thauma/Design/logo-branca-mini.PNG"
XLSX_OUT   <- file.path(DIR_OUT, "cardio_sus_2025_gss.xlsx")
SCRIPT_OUT <- file.path(DIR_OUT, "cardio_sus_2025_gss.R")

dir.create(DIR_OUT, showWarnings = FALSE, recursive = TRUE)

# Cores THAUMA
COR_AZUL   <- "#001070"
COR_BRANCO <- "#FFFFFF"
COR_CIANO  <- "#40D7FF"

# -----------------------------------------------------------
# ESCOPO — 23 procedimentos em 3 grupos
# -----------------------------------------------------------
# Grupo A — puro PROC_REA
GRUPO_A <- c("0406010935","0406010943","0406011206","0406010820","0406010846","0406010692")
# Grupo C — puro PROC_REA
GRUPO_C <- c("0406010137","0406040176","0415020034")
# Marcapassos (sem CID — tratamos como puro PROC_REA)
GRUPO_MP <- c("0406010650","0406010676","0406010684")

# Grupo B — SIGTAP + CID (lista de pares; cada par expande para uma "linha de escopo")
# Formato: list(sigtap = "...", cid_regex = "^...$" ou NULL p/ qualquer CID)
GRUPO_B <- list(
  list(sigtap="0406010536", cid="^Q211$"),                                   # CIA + Q21.1
  list(sigtap="0412040158", cid="^M869$"),
  list(sigtap="0412040212", cid="^M869$"),
  list(sigtap="0412040115", cid="^M869$"),
  list(sigtap="0412040174", cid="^J942$"),
  list(sigtap="0406010102", cid="^J942$"),                                   # cardiorrafia hemotórax
  list(sigtap="0406010765", cid="^(I312|I313|J90)$"),
  list(sigtap="0412020033", cid="^(I312|I313|J90)$"),
  list(sigtap="0412040166", cid="^(I312|I313|J90)$"),
  list(sigtap="0406010757", cid="^I311$"),
  list(sigtap="0406010102", cid="^I311$"),                                   # cardiorrafia pericardite (gera 2ª linha p/ mesmo SIGTAP)
  list(sigtap="0406020302", cid="^I702$")
)

# Lista única de SIGTAPs em escopo (para filtro inicial)
SIGTAPS_TODOS <- unique(c(GRUPO_A, GRUPO_C, GRUPO_MP, sapply(GRUPO_B, function(x) x$sigtap)))
cat("SIGTAPs em escopo:", length(SIGTAPS_TODOS), "\n")
cat(paste(SIGTAPS_TODOS, collapse=","), "\n\n")

# -----------------------------------------------------------
# 1. LOAD SIH-RD 2025 — 324 RDS
# -----------------------------------------------------------
cat("[1/9] Carregando SIH-RD 2025...\n")
arq_sih <- list.files(DIR_SIH, pattern="\\.rds$", full.names=TRUE)
cat("Arquivos RDS encontrados:", length(arq_sih), "\n")

# Colunas mínimas necessárias (reduz uso de memória)
COLS_SIH <- c("UF_ZI","ANO_CMPT","MES_CMPT","CNES","CGC_HOSP","N_AIH",
              "MUNIC_RES","DIAG_PRINC","PROC_REA","MORTE")

sih_list <- lapply(seq_along(arq_sih), function(i) {
  f <- arq_sih[i]
  if (i %% 50 == 1) cat("  Lendo arquivo", i, "/", length(arq_sih), basename(f), "\n")
  dt <- as.data.table(readRDS(f))
  cols_ok <- intersect(COLS_SIH, names(dt))
  dt <- dt[, ..cols_ok]
  # Filtra escopo cedo para reduzir memória
  dt <- dt[PROC_REA %in% SIGTAPS_TODOS]
  dt
})
sih <- rbindlist(sih_list, use.names=TRUE, fill=TRUE)
rm(sih_list); gc(verbose=FALSE)
cat("SIH consolidado:", nrow(sih), "linhas após filtro PROC_REA em escopo\n\n")

# Padroniza tipos
sih[, MORTE := as.integer(MORTE)]
sih[, CNES := as.character(CNES)]
sih[, CGC_HOSP := as.character(CGC_HOSP)]
sih[, MUNIC_RES := as.character(MUNIC_RES)]
sih[, UF_ZI := as.character(UF_ZI)]
sih[, DIAG_PRINC := as.character(DIAG_PRINC)]
sih[, PROC_REA := as.character(PROC_REA)]

# -----------------------------------------------------------
# 2. LOAD CNES-ST — 27 RDS, mantém linha mais recente por CNES
# -----------------------------------------------------------
cat("[2/9] Carregando CNES-ST...\n")
arq_cnes <- list.files(DIR_CNES, pattern="\\.rds$", full.names=TRUE)
cat("Arquivos CNES:", length(arq_cnes), "\n")

COLS_CNES <- c("CNES","CODUFMUN","NAT_JUR","TP_UNID","CPF_CNPJ","CNPJ_MAN","COMPETEN")

cnes_list <- lapply(arq_cnes, function(f) {
  dt <- as.data.table(readRDS(f))
  cols_ok <- intersect(COLS_CNES, names(dt))
  dt[, ..cols_ok]
})
cnes <- rbindlist(cnes_list, use.names=TRUE, fill=TRUE)
rm(cnes_list); gc(verbose=FALSE)

# Padroniza
cnes[, CNES := as.character(CNES)]
cnes[, CODUFMUN := as.character(CODUFMUN)]
cnes[, NAT_JUR := as.character(NAT_JUR)]
cnes[, TP_UNID := as.character(TP_UNID)]
if ("COMPETEN" %in% names(cnes)) cnes[, COMPETEN := as.character(COMPETEN)]

# Linha mais recente por CNES (todas são 2025_12, então um dedup simples basta)
setorder(cnes, CNES, -COMPETEN)
cnes <- unique(cnes, by="CNES")
cat("CNES-ST únicos:", nrow(cnes), "\n\n")

# -----------------------------------------------------------
# 3. APLICAR FILTROS DE ESCOPO — gera linhas de "evento"
# -----------------------------------------------------------
cat("[3/9] Aplicando filtros de escopo...\n")

# Limpa CID (remove pontos/espaços) — formato microdatasus geralmente já vem sem ponto (ex: Q211)
sih[, DIAG_PRINC_CLEAN := toupper(gsub("[^A-Z0-9]","", DIAG_PRINC))]

# Função utilitária: cria coluna escopo_id e cid_filtro_aplicado
eventos_lista <- list()

# Grupo A
ev_A <- sih[PROC_REA %in% GRUPO_A]
if (nrow(ev_A)>0) {
  ev_A[, escopo_codigo := PROC_REA]
  ev_A[, escopo_cid_filtro := "(qualquer)"]
  ev_A[, escopo_grupo := "A"]
  eventos_lista[["A"]] <- ev_A
}

# Grupo C
ev_C <- sih[PROC_REA %in% GRUPO_C]
if (nrow(ev_C)>0) {
  ev_C[, escopo_codigo := PROC_REA]
  ev_C[, escopo_cid_filtro := "(qualquer)"]
  ev_C[, escopo_grupo := "C"]
  eventos_lista[["C"]] <- ev_C
}

# Grupo MP (marcapassos sem CID)
ev_MP <- sih[PROC_REA %in% GRUPO_MP]
if (nrow(ev_MP)>0) {
  ev_MP[, escopo_codigo := PROC_REA]
  ev_MP[, escopo_cid_filtro := "(qualquer)"]
  ev_MP[, escopo_grupo := "B-MP"]
  eventos_lista[["MP"]] <- ev_MP
}

# Grupo B — par a par (com regex de CID)
for (i in seq_along(GRUPO_B)) {
  par <- GRUPO_B[[i]]
  ev <- sih[PROC_REA == par$sigtap & grepl(par$cid, DIAG_PRINC_CLEAN)]
  if (nrow(ev)>0) {
    ev[, escopo_codigo := par$sigtap]
    ev[, escopo_cid_filtro := par$cid]
    ev[, escopo_grupo := "B"]
    eventos_lista[[paste0("B_", i)]] <- ev
  }
}

eventos <- rbindlist(eventos_lista, use.names=TRUE, fill=TRUE)
rm(eventos_lista); gc(verbose=FALSE)
cat("Eventos após filtros:", nrow(eventos), "\n\n")

# -----------------------------------------------------------
# 4. AGREGAÇÃO POR CNES × CÓDIGO × CID
# -----------------------------------------------------------
cat("[4/9] Agregando por hospital × procedimento × CID...\n")

# Agregação detalhe (com CID quando aplicável)
agg_detalhe <- eventos[, .(
  cirurgias = .N,
  obitos    = sum(MORTE, na.rm=TRUE)
), by = .(CNES, CGC_HOSP, escopo_codigo, escopo_cid_filtro, escopo_grupo)]

agg_detalhe[, taxa_mortalidade_pct := round(100 * obitos / cirurgias, 2)]
cat("Linhas de detalhe (CNES × código × CID):", nrow(agg_detalhe), "\n\n")

# -----------------------------------------------------------
# 5. JOIN COM CNES-ST
# -----------------------------------------------------------
cat("[5/9] Enriquecendo com CNES-ST...\n")

agg_detalhe <- merge(agg_detalhe, cnes, by="CNES", all.x=TRUE)

# Mapear NAT_JUR para 3 categorias
# Códigos NAT_JUR (Receita Federal):
# 1xxx = Adm pública (federal/estadual/municipal)
# 2xxx = Entidades empresariais
# 3xxx = Entidades sem fins lucrativos (filantrópicas)
# 4xxx = Pessoas físicas
# 5xxx = Organizações internacionais e estrangeiras
agg_detalhe[, esfera := fifelse(
  is.na(NAT_JUR) | NAT_JUR == "", "Não informado",
  fifelse(substr(NAT_JUR,1,1)=="1", "Público",
  fifelse(substr(NAT_JUR,1,1)=="3", "Filantrópico",
  fifelse(substr(NAT_JUR,1,1)=="2", "Privado contratado",
  fifelse(substr(NAT_JUR,1,1)=="4", "Pessoa física",
  "Outros"))))
)]

# -----------------------------------------------------------
# 5b. JOIN COM CNES FANTASIA (nome do estabelecimento)
# Fonte: Gerência de Dados/docs/cnes.rds (637.413 CNES × FANTASIA)
# -----------------------------------------------------------
cat("[5b] Enriquecendo com FANTASIA (cnes.rds)...\n")
cnes_fantasia <- as.data.table(readRDS(CNES_FANTASIA_RDS))
cnes_fantasia[, CNES := as.character(CNES)]
cnes_fantasia[, FANTASIA := as.character(FANTASIA)]
# Dedup defensivo (devem ser únicos, mas garantimos)
cnes_fantasia <- unique(cnes_fantasia, by="CNES")
cat("CNES com FANTASIA disponíveis:", nrow(cnes_fantasia), "\n")

agg_detalhe <- merge(agg_detalhe, cnes_fantasia, by="CNES", all.x=TRUE)

cnes_unicos_escopo <- uniqueN(agg_detalhe$CNES)
cnes_com_nome     <- uniqueN(agg_detalhe[!is.na(FANTASIA) & FANTASIA != ""]$CNES)
pct_match_fantasia <- round(100 * cnes_com_nome / cnes_unicos_escopo, 2)
cat("CNES no escopo:", cnes_unicos_escopo, "\n")
cat("CNES com FANTASIA preenchida:", cnes_com_nome,
    " (", pct_match_fantasia, "%)\n\n", sep="")

# -----------------------------------------------------------
# 6. JOIN COM DIMENSÕES (procedimento, CID, município)
# -----------------------------------------------------------
cat("[6/9] Enriquecendo com dimensões...\n")

dim_proc <- as.data.table(read_parquet(file.path(DIR_DIM, "dim_procedimentos.parquet")))
dim_proc <- dim_proc[, .(escopo_codigo = co_procedimento, descricao_proc = no_procedimento)]
agg_detalhe <- merge(agg_detalhe, dim_proc, by="escopo_codigo", all.x=TRUE)

dim_mun <- as.data.table(read_parquet(file.path(DIR_DIM, "dim_municipios.parquet")))
# CODUFMUN do CNES é IBGE 6 dígitos; dim_municipios traz IBGE (6 dígitos)
dim_mun_join <- dim_mun[, .(CODUFMUN = as.character(IBGE), municipio = `Município`, uf = UF, regiao = `Região`)]
agg_detalhe <- merge(agg_detalhe, dim_mun_join, by="CODUFMUN", all.x=TRUE)

# Fallback: se uf veio NA do município (CNES sem CODUFMUN ou inválido), usar UF_ZI do SIH? Não temos aqui.
# Para hospitais sem CNES no CNES-ST, ficam NA.

# Nome do hospital: prioriza FANTASIA do cnes.rds.
# Fallback: CNES + CNPJ (para os poucos casos sem match na base de FANTASIA).
agg_detalhe[, nome_hospital := fifelse(
  !is.na(FANTASIA) & FANTASIA != "",
  FANTASIA,
  paste0("CNES ", CNES,
         ifelse(!is.na(CGC_HOSP) & CGC_HOSP != "", paste0(" (CNPJ ", CGC_HOSP, ")"), ""))
)]

# Descrição CID — para Grupo B, o cid_filtro pode ser regex; tentamos casar com o primeiro CID literal
dim_cid <- as.data.table(read_parquet(file.path(DIR_DIM, "dim_cid10.parquet")))
# Construir mapa CID literal -> descrição (4 chars, ex Q211)
dim_cid_join <- dim_cid[, .(cid = co_cid, descricao_cid = no_cid)]

# Mapear CID em escopo para descrição "humana" (caso a caso)
cid_descricao_map <- data.table(
  escopo_cid_filtro = c("(qualquer)","^Q211$","^M869$","^J942$","^(I312|I313|J90)$","^I311$","^I702$"),
  descricao_cid = c("(qualquer CID)",
                    "Q21.1 — Comunicação interatrial",
                    "M86.9 — Osteomielite não especificada",
                    "J94.2 — Hemotórax",
                    "I31.2/I31.3/J90 — Hemopericárdio/derrame pericárdico/pleural",
                    "I31.1 — Pericardite constritiva crônica",
                    "I70.2 — Aterosclerose das artérias das extremidades")
)
agg_detalhe <- merge(agg_detalhe, cid_descricao_map, by="escopo_cid_filtro", all.x=TRUE)

cat("Detalhe enriquecido:", nrow(agg_detalhe), "linhas\n\n")

# -----------------------------------------------------------
# 7. AGREGAÇÕES PARA AS DEMAIS ABAS
# -----------------------------------------------------------
cat("[7/9] Calculando agregações para abas...\n")

# Consolidado por procedimento (× CID)
consol_proc <- agg_detalhe[, .(
  hospitais     = uniqueN(CNES),
  cirurgias     = sum(cirurgias, na.rm=TRUE),
  obitos        = sum(obitos, na.rm=TRUE)
), by = .(escopo_grupo, escopo_codigo, descricao_proc, escopo_cid_filtro, descricao_cid)]
consol_proc[, taxa_mortalidade_pct := round(100*obitos/cirurgias, 2)]
setorder(consol_proc, -cirurgias)

# Ranking por UF
ranking_uf <- agg_detalhe[!is.na(uf), .(
  hospitais = uniqueN(CNES),
  cirurgias = sum(cirurgias, na.rm=TRUE),
  obitos    = sum(obitos, na.rm=TRUE)
), by = .(uf, regiao)]
ranking_uf[, taxa_mortalidade_pct := round(100*obitos/cirurgias, 2)]
setorder(ranking_uf, -cirurgias)

# Detalhe por hospital — agregado para 1 linha por (CNES × código × CID)
detalhe_hosp <- agg_detalhe[, .(
  uf,
  municipio,
  regiao,
  esfera,
  cnes = CNES,
  cnpj = CGC_HOSP,
  nome_hospital,
  procedimento_codigo = escopo_codigo,
  procedimento_descricao = descricao_proc,
  cid_filtro = escopo_cid_filtro,
  cid_descricao = descricao_cid,
  cirurgias,
  obitos,
  taxa_mortalidade_pct
)]
setorder(detalhe_hosp, -cirurgias)

# Resumo executivo
total_cirurgias <- sum(agg_detalhe$cirurgias, na.rm=TRUE)
total_obitos    <- sum(agg_detalhe$obitos, na.rm=TRUE)
total_hospitais <- uniqueN(agg_detalhe$CNES)
total_ufs       <- uniqueN(agg_detalhe$uf[!is.na(agg_detalhe$uf)])
taxa_nacional   <- round(100*total_obitos/total_cirurgias, 2)

# Top-10 hospitais por volume
top10_volume <- agg_detalhe[, .(
  uf = uf[1],
  municipio = municipio[1],
  esfera = esfera[1],
  cirurgias = sum(cirurgias),
  obitos    = sum(obitos)
), by = .(CNES, nome_hospital)]
top10_volume[, taxa_mortalidade_pct := round(100*obitos/cirurgias, 2)]
setorder(top10_volume, -cirurgias)
top10_volume <- head(top10_volume, 10)

# Top-10 hospitais por mortalidade (N>=12)
top10_mort <- agg_detalhe[, .(
  uf = uf[1],
  municipio = municipio[1],
  esfera = esfera[1],
  cirurgias = sum(cirurgias),
  obitos    = sum(obitos)
), by = .(CNES, nome_hospital)]
top10_mort[, taxa_mortalidade_pct := round(100*obitos/cirurgias, 2)]
top10_mort <- top10_mort[cirurgias >= 12]
setorder(top10_mort, -taxa_mortalidade_pct)
top10_mort <- head(top10_mort, 10)

cat("Total cirurgias:", total_cirurgias, "\n")
cat("Total óbitos:", total_obitos, "\n")
cat("Hospitais únicos:", total_hospitais, "\n")
cat("UFs cobertas:", total_ufs, "\n\n")

# -----------------------------------------------------------
# 8. GERA XLSX COM IDENTIDADE THAUMA
# -----------------------------------------------------------
cat("[8/9] Gerando XLSX...\n")

wb <- createWorkbook()

# Estilos THAUMA
estilo_titulo <- createStyle(
  fontName="Helvetica", fontSize=22, fontColour=COR_AZUL,
  textDecoration="bold", halign="center", valign="center"
)
estilo_subtitulo <- createStyle(
  fontName="Helvetica", fontSize=14, fontColour=COR_AZUL,
  halign="center"
)
estilo_header <- createStyle(
  fontName="Helvetica", fontSize=11, fontColour=COR_BRANCO,
  fgFill=COR_AZUL, halign="center", valign="center",
  textDecoration="bold", border="TopBottomLeftRight", borderColour=COR_AZUL
)
estilo_celula <- createStyle(
  fontName="Hahmlet", fontSize=10, fontColour="#1A1A1A",
  halign="left", valign="center",
  border="TopBottomLeftRight", borderColour="#D0D0D0"
)
estilo_celula_num <- createStyle(
  fontName="Hahmlet", fontSize=10, fontColour="#1A1A1A",
  halign="right", valign="center",
  border="TopBottomLeftRight", borderColour="#D0D0D0",
  numFmt="#,##0"
)
estilo_celula_pct <- createStyle(
  fontName="Hahmlet", fontSize=10, fontColour="#1A1A1A",
  halign="right", valign="center",
  border="TopBottomLeftRight", borderColour="#D0D0D0",
  numFmt="0.00"
)
estilo_destaque <- createStyle(
  fontName="Hahmlet", fontSize=10, fontColour=COR_AZUL,
  fgFill=COR_CIANO, textDecoration="bold",
  halign="center", valign="center",
  border="TopBottomLeftRight"
)

# ---- Aba 1: CAPA ----
addWorksheet(wb, "Capa", gridLines=FALSE, tabColour=COR_AZUL)
showGridLines(wb, "Capa", showGridLines=FALSE)
setColWidths(wb, "Capa", cols=1:8, widths=18)

# Inserir logo se existir
if (file.exists(LOGO)) {
  tryCatch({
    insertImage(wb, "Capa", LOGO, startRow=3, startCol=4, width=4, height=2, units="in")
  }, error = function(e) cat("WARN: falha ao inserir logo:", conditionMessage(e), "\n"))
}

writeData(wb, "Capa", "Cirurgias Cardiovasculares no SUS — 2025", startRow=14, startCol=1)
mergeCells(wb, "Capa", cols=1:8, rows=14)
addStyle(wb, "Capa", estilo_titulo, rows=14, cols=1:8, gridExpand=TRUE)
setRowHeights(wb, "Capa", rows=14, heights=40)

writeData(wb, "Capa", "Levantamento Nacional de Hospitais Prestadores", startRow=16, startCol=1)
mergeCells(wb, "Capa", cols=1:8, rows=16)
addStyle(wb, "Capa", estilo_subtitulo, rows=16, cols=1:8, gridExpand=TRUE)

writeData(wb, "Capa", paste0("Cliente: GSS Saúde — Dr. Maikon Almeida"), startRow=20, startCol=1)
writeData(wb, "Capa", paste0("Período de referência: Janeiro a Dezembro de 2025"), startRow=21, startCol=1)
writeData(wb, "Capa", paste0("Fonte: DATASUS — SIH-SUS (AIH) e CNES, via microdatasus"), startRow=22, startCol=1)
writeData(wb, "Capa", paste0("Data de emissão: ", format(Sys.Date(), "%d/%m/%Y")), startRow=23, startCol=1)
writeData(wb, "Capa", "Autoria: THAUMA — Inteligência & Narrativa em Saúde", startRow=25, startCol=1)
writeData(wb, "Capa", "Equipe técnica: Heráclito (Engenharia de Dados) | Hipaso (Enriquecimento) | Pitágoras (Coordenação)", startRow=26, startCol=1)

estilo_meta <- createStyle(fontName="Hahmlet", fontSize=11, fontColour="#1A1A1A", halign="center")
addStyle(wb, "Capa", estilo_meta, rows=20:26, cols=1, gridExpand=FALSE)
mergeCells(wb, "Capa", cols=1:8, rows=20)
mergeCells(wb, "Capa", cols=1:8, rows=21)
mergeCells(wb, "Capa", cols=1:8, rows=22)
mergeCells(wb, "Capa", cols=1:8, rows=23)
mergeCells(wb, "Capa", cols=1:8, rows=25)
mergeCells(wb, "Capa", cols=1:8, rows=26)
addStyle(wb, "Capa", estilo_meta, rows=20:26, cols=1:8, gridExpand=TRUE)

# Tagline
writeData(wb, "Capa", "\"O espanto da descoberta. A ciência do resultado.\"", startRow=29, startCol=1)
mergeCells(wb, "Capa", cols=1:8, rows=29)
estilo_tagline <- createStyle(fontName="Helvetica", fontSize=11,
                               fontColour=COR_AZUL, textDecoration="italic", halign="center")
addStyle(wb, "Capa", estilo_tagline, rows=29, cols=1:8, gridExpand=TRUE)

# ---- Aba 2: RESUMO EXECUTIVO ----
addWorksheet(wb, "Resumo Executivo", gridLines=FALSE, tabColour=COR_AZUL)
showGridLines(wb, "Resumo Executivo", showGridLines=FALSE)

writeData(wb, "Resumo Executivo", "RESUMO EXECUTIVO", startRow=1, startCol=1)
mergeCells(wb, "Resumo Executivo", cols=1:8, rows=1)
addStyle(wb, "Resumo Executivo", estilo_titulo, rows=1, cols=1:8, gridExpand=TRUE)
setRowHeights(wb, "Resumo Executivo", rows=1, heights=30)

# KPIs
kpis <- data.table(
  Indicador = c("Total de cirurgias cardiovasculares (escopo)","Total de óbitos hospitalares",
                "Taxa de mortalidade nacional (%)","Hospitais prestadores (CNES únicos)",
                "Unidades da Federação cobertas","Procedimentos SIGTAP no escopo"),
  Valor = c(format(total_cirurgias, big.mark="."),
            format(total_obitos, big.mark="."),
            format(taxa_nacional, decimal.mark=","),
            format(total_hospitais, big.mark="."),
            total_ufs,
            length(SIGTAPS_TODOS))
)

writeData(wb, "Resumo Executivo", kpis, startRow=3, startCol=1, headerStyle=estilo_header)
addStyle(wb, "Resumo Executivo", estilo_celula, rows=4:(3+nrow(kpis)), cols=1, gridExpand=TRUE)
addStyle(wb, "Resumo Executivo", estilo_destaque, rows=4:(3+nrow(kpis)), cols=2, gridExpand=TRUE)
setColWidths(wb, "Resumo Executivo", cols=1:2, widths=c(48, 22))

# Top-10 volume
linha_top <- 3 + nrow(kpis) + 3
writeData(wb, "Resumo Executivo", "TOP-10 HOSPITAIS POR VOLUME", startRow=linha_top, startCol=1)
mergeCells(wb, "Resumo Executivo", cols=1:8, rows=linha_top)
estilo_h2 <- createStyle(fontName="Helvetica", fontSize=14, fontColour=COR_AZUL,
                          textDecoration="bold", halign="left")
addStyle(wb, "Resumo Executivo", estilo_h2, rows=linha_top, cols=1:8, gridExpand=TRUE)

writeData(wb, "Resumo Executivo", top10_volume, startRow=linha_top+2, startCol=1, headerStyle=estilo_header)
n_top1 <- nrow(top10_volume)
addStyle(wb, "Resumo Executivo", estilo_celula,
         rows=(linha_top+3):(linha_top+2+n_top1), cols=1:5, gridExpand=TRUE)
addStyle(wb, "Resumo Executivo", estilo_celula_num,
         rows=(linha_top+3):(linha_top+2+n_top1), cols=6:7, gridExpand=TRUE)
addStyle(wb, "Resumo Executivo", estilo_celula_pct,
         rows=(linha_top+3):(linha_top+2+n_top1), cols=8, gridExpand=TRUE)

# Top-10 mortalidade
linha_top2 <- linha_top + 2 + n_top1 + 3
writeData(wb, "Resumo Executivo", "TOP-10 HOSPITAIS POR MORTALIDADE (N≥12)", startRow=linha_top2, startCol=1)
mergeCells(wb, "Resumo Executivo", cols=1:8, rows=linha_top2)
addStyle(wb, "Resumo Executivo", estilo_h2, rows=linha_top2, cols=1:8, gridExpand=TRUE)

writeData(wb, "Resumo Executivo", top10_mort, startRow=linha_top2+2, startCol=1, headerStyle=estilo_header)
n_top2 <- nrow(top10_mort)
if (n_top2 > 0) {
  addStyle(wb, "Resumo Executivo", estilo_celula,
           rows=(linha_top2+3):(linha_top2+2+n_top2), cols=1:5, gridExpand=TRUE)
  addStyle(wb, "Resumo Executivo", estilo_celula_num,
           rows=(linha_top2+3):(linha_top2+2+n_top2), cols=6:7, gridExpand=TRUE)
  addStyle(wb, "Resumo Executivo", estilo_celula_pct,
           rows=(linha_top2+3):(linha_top2+2+n_top2), cols=8, gridExpand=TRUE)
}

setColWidths(wb, "Resumo Executivo", cols=1:8, widths=c(10, 50, 6, 18, 18, 12, 12, 14))

# ---- Aba 3: CONSOLIDADO POR PROCEDIMENTO ----
addWorksheet(wb, "Consolidado Procedimento", gridLines=FALSE, tabColour=COR_AZUL)
showGridLines(wb, "Consolidado Procedimento", showGridLines=FALSE)
writeData(wb, "Consolidado Procedimento", "CONSOLIDADO POR PROCEDIMENTO", startRow=1, startCol=1)
mergeCells(wb, "Consolidado Procedimento", cols=1:8, rows=1)
addStyle(wb, "Consolidado Procedimento", estilo_titulo, rows=1, cols=1:8, gridExpand=TRUE)
setRowHeights(wb, "Consolidado Procedimento", rows=1, heights=30)

writeData(wb, "Consolidado Procedimento", consol_proc, startRow=3, startCol=1, headerStyle=estilo_header)
n_cp <- nrow(consol_proc)
addStyle(wb, "Consolidado Procedimento", estilo_celula,
         rows=4:(3+n_cp), cols=1:5, gridExpand=TRUE)
addStyle(wb, "Consolidado Procedimento", estilo_celula_num,
         rows=4:(3+n_cp), cols=6:8, gridExpand=TRUE)
addStyle(wb, "Consolidado Procedimento", estilo_celula_pct,
         rows=4:(3+n_cp), cols=9, gridExpand=TRUE)
setColWidths(wb, "Consolidado Procedimento", cols=1:9,
             widths=c(8, 14, 50, 22, 50, 12, 14, 12, 14))
freezePane(wb, "Consolidado Procedimento", firstActiveRow=4, firstActiveCol=1)

# ---- Aba 4: RANKING POR UF ----
addWorksheet(wb, "Ranking UF", gridLines=FALSE, tabColour=COR_AZUL)
showGridLines(wb, "Ranking UF", showGridLines=FALSE)
writeData(wb, "Ranking UF", "RANKING POR UF", startRow=1, startCol=1)
mergeCells(wb, "Ranking UF", cols=1:6, rows=1)
addStyle(wb, "Ranking UF", estilo_titulo, rows=1, cols=1:6, gridExpand=TRUE)
setRowHeights(wb, "Ranking UF", rows=1, heights=30)

writeData(wb, "Ranking UF", ranking_uf, startRow=3, startCol=1, headerStyle=estilo_header)
n_ru <- nrow(ranking_uf)
addStyle(wb, "Ranking UF", estilo_celula, rows=4:(3+n_ru), cols=1:2, gridExpand=TRUE)
addStyle(wb, "Ranking UF", estilo_celula_num, rows=4:(3+n_ru), cols=3:5, gridExpand=TRUE)
addStyle(wb, "Ranking UF", estilo_celula_pct, rows=4:(3+n_ru), cols=6, gridExpand=TRUE)
setColWidths(wb, "Ranking UF", cols=1:6, widths=c(8, 18, 14, 14, 14, 16))
freezePane(wb, "Ranking UF", firstActiveRow=4, firstActiveCol=1)

# ---- Aba 5: DETALHE POR HOSPITAL ----
# Usa Excel Table (addTable) para sort/filter nativo, banded rows e AutoFilter automático.
# Cabeçalho real fica na linha 3 (linha 1 é título visual; linha 2 vazia).
addWorksheet(wb, "Detalhe Hospital", gridLines=FALSE, tabColour=COR_AZUL)
showGridLines(wb, "Detalhe Hospital", showGridLines=FALSE)
writeData(wb, "Detalhe Hospital", "DETALHE POR HOSPITAL — use os filtros nos cabeçalhos para buscar por hospital, UF, procedimento ou CID", startRow=1, startCol=1)
mergeCells(wb, "Detalhe Hospital", cols=1:14, rows=1)
addStyle(wb, "Detalhe Hospital", estilo_titulo, rows=1, cols=1:14, gridExpand=TRUE)
setRowHeights(wb, "Detalhe Hospital", rows=1, heights=30)

# addTable cria uma Excel Table real com filtros, sort e formatação alternada
n_dh <- nrow(detalhe_hosp)
writeDataTable(
  wb, "Detalhe Hospital", detalhe_hosp,
  startRow=3, startCol=1,
  tableStyle="TableStyleMedium2",   # base; cabeçalho azul/branco já vem no estilo
  tableName="tbl_detalhe_hospital",
  withFilter=TRUE,
  bandedRows=TRUE,
  headerStyle=estilo_header
)

# Estilos numéricos (sobrepõem células de dados; não interferem com a Table)
addStyle(wb, "Detalhe Hospital", estilo_celula_num, rows=4:(3+n_dh), cols=12:13, gridExpand=TRUE, stack=TRUE)
addStyle(wb, "Detalhe Hospital", estilo_celula_pct, rows=4:(3+n_dh), cols=14, gridExpand=TRUE, stack=TRUE)
setColWidths(wb, "Detalhe Hospital", cols=1:14,
             widths=c(6, 22, 14, 18, 10, 16, 50, 14, 50, 22, 40, 12, 12, 14))
freezePane(wb, "Detalhe Hospital", firstActiveRow=4, firstActiveCol=1)

# ---- Aba 6: METODOLOGIA ----
addWorksheet(wb, "Metodologia", gridLines=FALSE, tabColour=COR_AZUL)
showGridLines(wb, "Metodologia", showGridLines=FALSE)
writeData(wb, "Metodologia", "METODOLOGIA", startRow=1, startCol=1)
mergeCells(wb, "Metodologia", cols=1:2, rows=1)
addStyle(wb, "Metodologia", estilo_titulo, rows=1, cols=1:2, gridExpand=TRUE)
setRowHeights(wb, "Metodologia", rows=1, heights=30)

metodologia <- data.table(
  Tópico = c(
    "Fontes primárias",
    "Universo temporal",
    "Granularidade",
    "Procedimentos em escopo (Grupo A — puro PROC_REA)",
    "Procedimentos em escopo (Grupo C — puro PROC_REA)",
    "Marcapassos (filtro PROC_REA puro)",
    "Procedimentos em escopo (Grupo B — PROC_REA + DIAG_PRINC)",
    "Definição de óbito",
    "Definição de cirurgia",
    "Esfera administrativa",
    "Identificação do hospital",
    "Enriquecimento — Nome fantasia",
    "Limitação 1 — Cobertura geográfica",
    "Limitação 2 — Reinternação / múltiplos procedimentos",
    "Limitação 3 — Diagnóstico secundário",
    "Quality Gates aplicados"
  ),
  Descrição = c(
    "DATASUS / SIH-SUS (AIH-RD reduzida) e DATASUS / CNES (Estabelecimentos — ST), extraídos via pacote R 'microdatasus'. Dimensões SIGTAP, CID-10 e municípios IBGE do Data Lake THAUMA.",
    "Janeiro a Dezembro de 2025 (12 competências × 27 UFs = 324 arquivos SIH-RD; 27 arquivos CNES-ST 2025/12).",
    "Linha = 1 hospital (CNES) × 1 procedimento SIGTAP × 1 filtro de CID (quando aplicável). Cada AIH é contada uma única vez via PROC_REA (procedimento realizado).",
    paste(GRUPO_A, collapse=", "),
    paste(GRUPO_C, collapse=", "),
    paste(GRUPO_MP, collapse=", "),
    paste(sapply(GRUPO_B, function(x) paste0(x$sigtap, " + ", x$cid)), collapse=" | "),
    "Variável MORTE = 1 na AIH-RD (saída por óbito durante a internação).",
    "Cada AIH corresponde a uma cirurgia (procedimento principal realizado = PROC_REA).",
    "Mapeada a partir do código NAT_JUR do CNES-ST: prefixo 1xxx = Público; 3xxx = Filantrópico; 2xxx = Privado contratado; 4xxx = Pessoa física; demais = Outros.",
    "CNES (7 dígitos) + CNPJ (CGC_HOSP do SIH). Município e UF do estabelecimento via CODUFMUN do CNES-ST com join em dim_municipios IBGE.",
    paste0("Cada CNES é nomeado pelo seu Nome Fantasia, obtido via base proprietária THAUMA de FANTASIA por CNES (637.413 estabelecimentos). Cobertura nesta entrega: ", pct_match_fantasia, "% dos CNES no escopo. Para os poucos sem match, usa-se 'CNES <código> (CNPJ <cnpj>)' como identificador."),
    "Inclui apenas estabelecimentos com pelo menos 1 AIH no escopo durante 2025. Hospitais sem CNES no CNES-ST 2025/12 ficam com município/UF/esfera não informados (raro).",
    "AIH com múltiplos procedimentos do escopo é contada 1x via PROC_REA. Reinternação do mesmo paciente conta como nova AIH (regra DATASUS).",
    "Filtro de CID aplicado apenas sobre DIAG_PRINC (diagnóstico principal). Diagnósticos secundários (DIAG_SEC) não foram considerados no Grupo B.",
    "Validação 1: Universo SIH 2025 carregado (324 arquivos × 27 UFs × 12 meses). Validação 2: Match SIGTAP no dim_procedimentos. Validação 3: Soma nacional de cirurgias e óbitos > 0 e coerente com ordem de grandeza esperada (~70-90 mil cirurgias/ano)."
  )
)

writeData(wb, "Metodologia", metodologia, startRow=3, startCol=1, headerStyle=estilo_header)
estilo_meto_topico <- createStyle(fontName="Helvetica", fontSize=10, fontColour=COR_AZUL,
                                   textDecoration="bold", halign="left", valign="top",
                                   border="TopBottomLeftRight", borderColour="#D0D0D0",
                                   wrapText=TRUE)
estilo_meto_desc <- createStyle(fontName="Hahmlet", fontSize=10, fontColour="#1A1A1A",
                                 halign="left", valign="top",
                                 border="TopBottomLeftRight", borderColour="#D0D0D0",
                                 wrapText=TRUE)
n_m <- nrow(metodologia)
addStyle(wb, "Metodologia", estilo_meto_topico, rows=4:(3+n_m), cols=1, gridExpand=TRUE)
addStyle(wb, "Metodologia", estilo_meto_desc, rows=4:(3+n_m), cols=2, gridExpand=TRUE)
setColWidths(wb, "Metodologia", cols=1:2, widths=c(40, 110))
setRowHeights(wb, "Metodologia", rows=4:(3+n_m), heights=60)

# ---- Aba 7: BUSCA RÁPIDA (instruções de uso) ----
addWorksheet(wb, "Busca Rápida", gridLines=FALSE, tabColour=COR_CIANO)
showGridLines(wb, "Busca Rápida", showGridLines=FALSE)
writeData(wb, "Busca Rápida", "BUSCA RÁPIDA", startRow=1, startCol=1)
mergeCells(wb, "Busca Rápida", cols=1:2, rows=1)
addStyle(wb, "Busca Rápida", estilo_titulo, rows=1, cols=1:2, gridExpand=TRUE)
setRowHeights(wb, "Busca Rápida", rows=1, heights=30)

busca <- data.table(
  `Como buscar` = c(
    "Pesquisar por nome de hospital",
    "Pesquisar por código de procedimento (SIGTAP)",
    "Pesquisar por descrição do procedimento",
    "Filtrar por UF",
    "Filtrar por município",
    "Filtrar por esfera (Público/Filantrópico/Privado)",
    "Filtrar por CID",
    "Ordenar por volume de cirurgias",
    "Ordenar por taxa de mortalidade",
    "Top-10 nacional por volume e mortalidade",
    "Ranking por UF e região",
    "Volume e mortalidade por procedimento (consolidado nacional)"
  ),
  `Onde / Como` = c(
    "Aba 'Detalhe Hospital' — clique no filtro do cabeçalho 'nome_hospital' e digite parte do nome (ex: 'INCOR', 'SANTA CASA'). Atalho universal: Ctrl+F.",
    "Aba 'Detalhe Hospital' — filtro do cabeçalho 'procedimento_codigo' (SIGTAP de 10 dígitos, ex: 0406010935).",
    "Aba 'Detalhe Hospital' — filtro do cabeçalho 'procedimento_descricao' (ex: digite 'PONTE' para revascularização miocárdica).",
    "Aba 'Detalhe Hospital' — filtro do cabeçalho 'uf' (selecione uma ou várias UFs).",
    "Aba 'Detalhe Hospital' — filtro do cabeçalho 'municipio'.",
    "Aba 'Detalhe Hospital' — filtro do cabeçalho 'esfera'.",
    "Aba 'Detalhe Hospital' — filtros 'cid_filtro' (regex original do escopo) ou 'cid_descricao' (rótulo humano).",
    "Aba 'Detalhe Hospital' — clique na seta do cabeçalho 'cirurgias' → Classificar do maior para o menor.",
    "Aba 'Detalhe Hospital' — clique na seta do cabeçalho 'taxa_mortalidade_pct' → Classificar do maior para o menor. Atenção: filtre antes 'cirurgias >= 12' para evitar viés de baixo volume.",
    "Aba 'Resumo Executivo'.",
    "Aba 'Ranking UF'.",
    "Aba 'Consolidado Procedimento'."
  )
)

writeData(wb, "Busca Rápida", busca, startRow=3, startCol=1, headerStyle=estilo_header)
n_b <- nrow(busca)
estilo_busca_topico <- createStyle(fontName="Helvetica", fontSize=10, fontColour=COR_AZUL,
                                    textDecoration="bold", halign="left", valign="top",
                                    border="TopBottomLeftRight", borderColour="#D0D0D0",
                                    wrapText=TRUE)
estilo_busca_desc <- createStyle(fontName="Hahmlet", fontSize=10, fontColour="#1A1A1A",
                                  halign="left", valign="top",
                                  border="TopBottomLeftRight", borderColour="#D0D0D0",
                                  wrapText=TRUE)
addStyle(wb, "Busca Rápida", estilo_busca_topico, rows=4:(3+n_b), cols=1, gridExpand=TRUE)
addStyle(wb, "Busca Rápida", estilo_busca_desc, rows=4:(3+n_b), cols=2, gridExpand=TRUE)
setColWidths(wb, "Busca Rápida", cols=1:2, widths=c(50, 95))
setRowHeights(wb, "Busca Rápida", rows=4:(3+n_b), heights=42)

# Nota de rodapé
linha_nota <- 3 + n_b + 2
writeData(wb, "Busca Rápida",
          "Dica: para análises ad-hoc fora do Excel, todo o detalhe está em formato tabular contínuo na Aba 'Detalhe Hospital' (Excel Table chamada 'tbl_detalhe_hospital') — copie e cole em outra ferramenta sem perder estrutura.",
          startRow=linha_nota, startCol=1)
mergeCells(wb, "Busca Rápida", cols=1:2, rows=linha_nota)
estilo_nota <- createStyle(fontName="Hahmlet", fontSize=10, fontColour="#1A1A1A",
                            textDecoration="italic", halign="left", valign="top", wrapText=TRUE)
addStyle(wb, "Busca Rápida", estilo_nota, rows=linha_nota, cols=1:2, gridExpand=TRUE)
setRowHeights(wb, "Busca Rápida", rows=linha_nota, heights=42)

# Salva workbook
saveWorkbook(wb, XLSX_OUT, overwrite=TRUE)
cat("XLSX salvo:", XLSX_OUT, "\n")
cat("Tamanho:", round(file.info(XLSX_OUT)$size / 1024, 1), "KB\n\n")

# -----------------------------------------------------------
# 9. SALVA SCRIPT REPRODUTÍVEL (cópia do próprio)
# -----------------------------------------------------------
cat("[9/9] Copiando script reproduzível...\n")
file.copy(
  from = "C:/Users/pedro/Desktop/Thauma/Projetos/Maikon_Cirurgias_Cardiovasculares/dados/f2_pipeline.R",
  to   = SCRIPT_OUT,
  overwrite = TRUE
)
cat("Script salvo:", SCRIPT_OUT, "\n\n")

# -----------------------------------------------------------
# SANITY CHECKS
# -----------------------------------------------------------
cat("\n=== SANITY CHECKS ===\n")
cat("Total cirurgias nacional:", format(total_cirurgias, big.mark="."), "\n")
cat("Total óbitos nacional:", format(total_obitos, big.mark="."), "\n")
cat("Taxa mortalidade nacional:", taxa_nacional, "%\n")
cat("Hospitais únicos:", total_hospitais, "\n")
cat("UFs cobertas:", total_ufs, "/27\n")
cat("\nTop-3 hospitais por volume:\n")
print(head(top10_volume[, .(CNES, nome_hospital, uf, municipio, cirurgias)], 3))

t1 <- Sys.time()
dur <- as.numeric(difftime(t1, t0, units="mins"))
cat("\n=== FIM ===\n")
cat("Duração total:", round(dur, 2), "min\n")
cat("Arquivo final:", XLSX_OUT, "\n")
cat("DONE_F2_PIPELINE\n")
