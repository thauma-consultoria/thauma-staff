# Higia F0 — Pipeline de Ingestão DATASUS para o Data Lake THAUMA

Carga inicial de **SIH-RD + SIA-PA + CNES-ST** para `datalake-thauma` (BigQuery).
Escopo desta execução: **MG, 2024-2025** (parametrizável em `00_setup.R`).

> Agente: **Heráclito** (Engenheiro de Dados) | Gerente: **Pitágoras**
> Decisão arquitetural Higia D1 (23/04/2026): Data Lake DATASUS público completo.

---

## Pré-requisitos (instalar antes de rodar)

1. **R 4.x** com os pacotes:
   ```r
   install.packages(c("arrow", "dplyr", "bigrquery", "readr"))
   # microdatasus vem do CRAN OU do GitHub:
   install.packages("microdatasus")  # se disponível no CRAN
   # ou:
   remotes::install_github("rfsaldanha/microdatasus")
   ```

2. **Google Cloud SDK** (`gcloud`/`bq`) instalado e autenticado:
   ```bash
   gcloud auth application-default login
   gcloud config set project datalake-thauma
   ```
   `bigrquery` usa as Application Default Credentials automaticamente.

3. **Permissão BigQuery** no projeto `datalake-thauma` para o e-mail
   autenticado (mínimo: BigQuery Data Editor + BigQuery Job User).

4. **`cnes.rds` proprietário** (637.413 estabelecimentos × FANTASIA) **não
   é input desta carga** — é dimensão de enriquecimento usada em fases
   posteriores. Se for rodar pipelines downstream nesta máquina, copiar
   manualmente de `Gerência de Dados/docs/cnes.rds`.

---

## Execução

Comando único (PowerShell ou bash, na raiz do repositório):

```bash
Rscript "Gerência de Dados/scripts/higia_ingestao/executar_higia_ingestao.R"
```

O orquestrador roda, em sequência:
1. **SIH-RD** MG, 24 competências (2024-01 → 2025-12)
2. **SIA-PA** MG, 24 competências (2024-01 → 2025-12)
3. **CNES-ST** MG, competência mais recente (auto-detectada)

---

## O que esperar

| Etapa | Volume aproximado | Tempo estimado |
|-------|-------------------|----------------|
| SIH-RD MG 2024-2025 | ~3,2 milhões de AIH (1,6M/ano × 2) | 60-120 min |
| SIA-PA MG 2024-2025 | ~150-300 milhões de linhas (BPA enorme) | 6-12 horas |
| CNES-ST MG (1 mês) | ~16-18 mil estabelecimentos | 2-5 min |

**Tempo total estimado:** 8-15 horas em conexão decente. SIA-PA é o gargalo
(volume e parsing). Memória recomendada: ≥16 GB. Disco livre: ≥50 GB para
parquets locais durante a carga.

---

## Acompanhamento em tempo real

Em outro terminal, na raiz do repo:

```bash
# Linux/Mac/Git Bash:
tail -f "Gerência de Dados/logs/higia_f0_"*.log

# Windows PowerShell:
Get-Content "Gerência de Dados/logs/higia_f0_*.log" -Wait -Tail 50
```

Cada operação imprime timestamp + nível (`INFO`/`WARN`/`ERROR`) +
contagem de registros. Logs ficam em `Gerência de Dados/logs/`
(gitignorados).

---

## Idempotência — o que acontece se cair no meio?

**Basta rodar o mesmo comando de novo.** O orquestrador consulta
`data/processed/manifest.csv` antes de cada competência e pula tudo que
já está em status `ok`.

- `manifest.csv` registra: `base, uf, ano, mes, status, registros, tabela, ts`
- Tabelas no BigQuery são uma por competência: `sih_rd_mg_2024_03`,
  `sia_pa_mg_2025_07`, etc. — `WRITE_TRUNCATE` por competência.
- Para **forçar recarga** de uma competência específica, deletar a linha
  correspondente em `manifest.csv` (ou apagar o arquivo inteiro para
  recomeçar do zero).

---

## Layout das tabelas no BigQuery

Projeto: `datalake-thauma` | Dataset: `raw_saude`

| Tabela | Conteúdo | Granularidade |
|--------|----------|---------------|
| `sih_rd_mg_<AAAA>_<MM>` | AIH Reduzida MG, mês | 1 linha = 1 AIH |
| `sia_pa_mg_<AAAA>_<MM>` | Produção Ambulatorial MG, mês | 1 linha = 1 procedimento |
| `cnes_st_mg_<AAAA>_<MM>` | Estabelecimentos MG, snapshot | 1 linha = 1 CNES |

---

## Reaproveitar para outra UF / período

Editar topo de `00_setup.R`:

```r
UF              <- "SP"          # ou outra UF
ANOS_SIH_SIA    <- 2023:2025     # 3 anos
COMP_CNES       <- list(ano = 2025, mes = 12)  # ou NULL para auto
```

Rodar de novo. O `manifest.csv` é compartilhado, então cargas anteriores
de outras UFs não são afetadas.

---

## Troubleshooting

| Sintoma | Diagnóstico |
|---------|-------------|
| `gcloud auth ... required` | Rodar `gcloud auth application-default login` |
| `package microdatasus not available` | `remotes::install_github("rfsaldanha/microdatasus")` |
| Carga trava em uma competência | Ctrl-C, rodar de novo — manifest pula o que já passou |
| BQ "Permission denied" | Conferir IAM no projeto `datalake-thauma` |
| `out of memory` em SIA | Reduzir `MESES <- 1:6` em `00_setup.R`, rodar 2x |
| FTP DATASUS instável (504/timeout) | Tentar fora de horário comercial; FTP fica saturado dia 15-20 do mês |

---

## Estrutura desta pasta

```
higia_ingestao/
├── 00_setup.R                       <- parâmetros, libs, log, manifest, BQ helpers
├── 01_carga_sih.R                   <- carga SIH-RD por competência
├── 02_carga_sia.R                   <- carga SIA-PA por competência
├── 03_carga_cnes.R                  <- carga CNES-ST snapshot
├── executar_higia_ingestao.R        <- orquestrador único (rodar este)
└── README.md                        <- este arquivo
```

Saídas (gitignoradas):
- `Gerência de Dados/data/processed/*.parquet` — staging local
- `Gerência de Dados/data/processed/manifest.csv` — checkpoint idempotência
- `Gerência de Dados/logs/higia_f0_*.log` — log estruturado por execução
