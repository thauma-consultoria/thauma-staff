# Coordenacao Arquimedes <-> Pitagoras

**Projeto:** GSS-CARDIO-2025
**Janela:** 2026-04-26 21h -> 2026-04-27 10h

## Divisao de responsabilidades

| Frente | Owner | Apoio |
|--------|-------|-------|
| Briefing, prazo, escopo, comunicacao com Pedro | Arquimedes | — |
| Pipeline tecnico (R, microdatasus, BigQuery se preciso) | Pitagoras | Heraclito (extracao), Hipaso (enriquecimento) |
| Diagramacao .xlsx final | Pitagoras (Heraclito ou Hipaso via openxlsx) | Arquimedes valida visual |
| Identidade visual THAUMA | Arquimedes especifica, Pitagoras aplica | — |
| Quality gate antes da entrega | Arquimedes (tecnico) + Pedro (cliente) | — |

## Pontos de checkpoint (4 sincronos + 1 final)

1. **21h30** — Plano tecnico Pitagoras x briefing Arquimedes alinhados [CONFIRMADO 26/04 22h]
2. **00h30** — Downloads microdatasus completos (ou acionar Plano B)
3. **03h30** — Datasets agregados prontos, totais sanity-check OK
4. **07h00** — .xlsx montado e diagramado
5. **09h30** — Pedro validou, pronto para envio

## Registro de checkpoints

### CP1 — 26/04/2026, 22h (alinhamento inicial)

**Status:** CONFIRMADO. Heraclito disparado para download SIH-RD 2025 nacional + CADGER em paralelo.

**Paths confirmados:**
- Cache SIH: `dados/sih_rd_2025/` (Heraclito popula)
- Cache CADGER: `dados/cadger_2025/` (Heraclito popula)
- Datasets agregados (F2-F3): `dados/agregados/` (Hipaso popula)
- Script R final: `outputs/cardio_sus_2025_gss.R`
- Excel final: `outputs/cardio_sus_2025_gss.xlsx`
- Logo capa Excel: `C:\Users\pedro\Desktop\Thauma\Design\logo-branca-mini.PNG`

**Estrutura de pastas confirmada:**
- `briefing.md` — OK
- `cronograma.md` — OK
- `cliente/registro_acordo.md` — OK
- `cliente/nota_metodologica_cliente.md` — CRIADO 26/04 22h (peca para o cliente)
- `docs/coordenacao_pitagoras.md` — OK
- `docs/duvidas_residuais.md` — OK (vivo, atualizar conforme aparecerem)
- `dados/` — vazio, aguardando F1
- `outputs/` — vazio, aguardando F4

**Comunicacao acordada para os 4 checkpoints seguintes:**
- 00h30 — status downloads (gargalo conhecido microdatasus)
- 03h30 — datasets agregados prontos, sanity-check
- 07h00 — .xlsx montado
- 09h30 — validacao Pedro pre-entrega

Em cada checkpoint, Pitagoras devolve mensagem 5-10 linhas no formato: status (OK/atrasado/bloqueado), arquivo+caminho pronto, proxima atividade, risco visivel.

**Trigger de escalonamento confirmado:** travado >30min Pitagoras chama Arquimedes; >1h Arquimedes chama Socrates; Plano B exige autorizacao explicita de Pedro.

**Ajustes apos CP1:** nenhum. Plano tecnico aprovado em plan mode segue intacto.

## Formato de handoff

A cada checkpoint, Pitagoras devolve mensagem curta (5-10 linhas) com:

- **Status:** OK / atrasado / bloqueado
- **O que ficou pronto:** arquivo + caminho
- **O que falta:** proxima atividade
- **Risco visivel:** algo a observar?

Arquimedes responde com: aprovado / ajuste X / escalar a Pedro.

## Escalonamento

- Travado > 30min em uma fase: Pitagoras chama Arquimedes
- Travado > 1h sem solucao: Arquimedes chama Socrates
- Decisao de Plano B (escopo reduzido): so Pedro autoriza

## Onde ficam os arquivos

- Cache microdatasus: `dados/sih_rd_2025/` (Heraclito)
- Cache CADGER: `dados/cadger_2025/` (Heraclito)
- Datasets agregados: `dados/agregados/` (Hipaso)
- Script R final: `outputs/script_cardio_2025.R` (Pitagoras)
- Excel final: `outputs/cardio_sus_2025_gss.xlsx` (Pitagoras)
- Logs/duvidas: `docs/duvidas_residuais.md` (todos)

## Identidade visual a aplicar no .xlsx

- Cores: header `#001070` (azul profundo), texto branco; destaque `#40D7FF` (ciano); fundo branco
- Tipografia: Helvetica/Arial (titulos), Calibri/Hahmlet (corpo) — Excel pode nao ter Hahmlet, fallback Calibri
- Capa com logo THAUMA (puxar de `Design/` se houver SVG/PNG)
- Cabecalho de cada aba com cor azul profundo + nome da aba em branco
