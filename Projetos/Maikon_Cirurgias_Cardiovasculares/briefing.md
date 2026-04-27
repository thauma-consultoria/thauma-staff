# Briefing — Cirurgias Cardiovasculares SUS 2025

**Projeto:** Levantamento Nacional de Cirurgias Cardiovasculares SUS 2025
**Codigo interno:** GSS-CARDIO-2025
**Aberto em:** 2026-04-26 21h
**Owner do projeto (gerencia):** Arquimedes
**Owner tecnico:** Pitagoras (coordena Heraclito + Hipaso)
**Aprovador final / cliente-facing:** Pedro

---

## Cliente

| Campo | Valor |
|-------|-------|
| Nome | Dr. Maikon Almeida (registrado no CRM como "Madeira" — corrigir) |
| Instituicao | GSS Saude |
| Canal | WhatsApp |
| Status anterior | Lead morno reaberto em 22/04/2026 |
| Status novo | Cliente — primeiro projeto pago |

## Escopo

Levantamento nacional de **cirurgias cardiovasculares no SUS** para **ano-calendario 2025**, por **hospital prestador**, contendo:

- Numero de cirurgias realizadas
- Taxa de mortalidade (obitos / cirurgias)
- Identificacao do hospital: **CNES + nome fantasia (via CADGER)**, nao apenas razao social do CNES bruto
- Recorte por UF / municipio / esfera administrativa

**Universo de procedimentos:** 23 codigos SIGTAP, alguns com filtro composto SIGTAP + CID. Pitagoras detalha grupos A, B, C no plano tecnico.

## Prazo

- **Inicio:** 2026-04-26 21h00
- **Entrega Pedro -> Maikon:** 2026-04-27 ate 10h00 (manha de segunda)
- **Janela operacional:** ~13 horas, com 8h dedicadas a sono/contingencia

## Valor

R$ 1.200,00 — pagamento ja acordado via WhatsApp. Sem contrato formal (recibo informal arquivado em `cliente/`).

## Entregavel final

**Planilha Excel (.xlsx)** profissionalmente diagramada com identidade visual THAUMA, contendo no minimo:

1. **Capa** — logo THAUMA, titulo, cliente, periodo, autor, data
2. **Resumo executivo** — totais nacionais, top 10 hospitais, principais achados
3. **Detalhe por hospital** — uma linha por CNES com todos os procedimentos
4. **Ranking por UF** — agregacao estadual
5. **Consolidado por procedimento** — uma linha por SIGTAP com totais
6. **Metodologia** — fontes, filtros, limitacoes, duvidas residuais

Acompanhamento:
- **Script R reproduzivel** em `outputs/script_cardio_2025.R`
- **Cache de dados brutos** em `dados/` (microdatasus + CADGER)

## Definicao de pronto

- [ ] .xlsx abre sem erro em Excel/LibreOffice
- [ ] 23 codigos SIGTAP processados com filtros corretos (Pitagoras valida)
- [ ] Hospitais identificados por CNES **+ nome fantasia** (via CADGER, nao apenas nome CNES)
- [ ] Minimo 5 abas (capa + resumo + detalhe + ranking UF + procedimento + metodologia = 6)
- [ ] Identidade visual THAUMA aplicada (#001070 azul, #FFFFFF branco, #40D7FF ciano; Helvetica/Hahmlet)
- [ ] Aba metodologia preenchida (fontes, filtros, limitacoes, duvidas residuais)
- [ ] Script R em `outputs/` executavel ponta-a-ponta
- [ ] Pedro validou antes do envio (quality gate humano)

## Exclusoes (o que NAO entra neste projeto)

- Analise interpretativa / dossie narrativo (apenas dados estruturados)
- Recorte por parlamentar / SAT (nao e Prisma)
- Visualizacoes em HTML / dashboard (apenas Excel)
- Dados pre-2025 ou pos-2025
- Procedimentos fora dos 23 codigos SIGTAP definidos

## Riscos identificados

1. **Download microdatasus** pode falhar/travar em horario noturno (DATASUS instavel) — Plano B definido em `cronograma.md`
2. **CADGER (CNES)** pode estar desatualizado ou faltar nome fantasia para alguns hospitais — fallback: razao social
3. **Filtros compostos SIGTAP+CID** sao complexos — Pitagoras valida com Heraclito antes de processar tudo
4. **Janela curta (13h)** sem margem para refazer pipeline — quality gate cedo, nao apenas no fim

## Comunicacao

- Pedro -> Maikon: WhatsApp (canal ja em uso)
- Sao Arquimedes <-> Pitagoras: checkpoints horarios documentados em `cronograma.md`
- Escalonamento: se algo travar > 30min sem solucao, escalar a Pedro/Socrates

---
*Documento vivo — atualizar conforme decisoes do projeto.*
