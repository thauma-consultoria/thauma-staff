# Cronograma — Cirurgias Cardiovasculares GSS

**Janela total:** 2026-04-26 21h00 -> 2026-04-27 10h00 (13h)
**Entrega final:** 27/04 10h00 (Pedro -> Maikon via WhatsApp)

---

## Fase 0 — Setup paralelo (21h00–21h30, 30min)

| Hora | Owner | Acao | Output |
|------|-------|------|--------|
| 21h00 | Arquimedes | Criar pasta + briefing + cronograma + atualizar CRM | Esta pasta |
| 21h00 | Pitagoras | Receber briefing tecnico de Socrates, mapear 23 SIGTAP em grupos A/B/C | Plano tecnico |
| 21h30 | Arquimedes + Pitagoras | **Checkpoint 1:** sincronizar briefing x plano tecnico | Alinhamento |

**Quality gate:** Pitagoras confirma que a lista de 23 SIGTAP ta correta e os filtros CID estao mapeados.

## Fase 1 — Download microdatasus (21h30–00h30, 3h)

| Hora | Owner | Acao |
|------|-------|------|
| 21h30 | Heraclito (via Pitagoras) | Disparar `fetch_datasus` para SIH-RD nacional 2025-01 a 2025-12 |
| 21h30 | Heraclito | Em paralelo: baixar CADGER atualizado para enriquecimento CNES |
| 00h00 | Pitagoras | **Checkpoint 2:** downloads completos? Cache em `dados/` |

**Janela de risco principal.** DATASUS pode estar lento de madrugada. Downloads SIH-RD mensais nacionais sao pesados (~200-500MB/mes).

### Plano B se download travar > 1h sem progresso

1. **Plano B1 (preferido):** Trocar `microdatasus` pelo FTP direto DATASUS via `download.file()` em loop com retry. Mais bruto mas mais resiliente.
2. **Plano B2:** Reduzir escopo para **trimestre Q4/2025** (out-nov-dez) com nota explicita na metodologia. Maikon aceita parcial documentado vs entrega atrasada.
3. **Plano B3 (ultimo recurso):** Usar dados ate ultimo mes disponivel (provavelmente nov/2025), documentar como "ano corrente fechado ate mes X".

**Trigger de escalonamento:** se ate 23h00 nenhum mes baixou, Pitagoras escala para Socrates -> Pedro decide se aciona Plano B.

## Fase 2 — Processamento (00h30–04h00, 3h30)

| Hora | Owner | Acao |
|------|-------|------|
| 00h30 | Heraclito | Filtrar SIH-RD pelos 23 SIGTAP (com filtros CID compostos onde aplicavel) |
| 01h30 | Hipaso | Enriquecer com CADGER (CNES -> nome fantasia, UF, municipio, esfera) |
| 02h30 | Hipaso | Calcular agregacoes: por hospital, por UF, por procedimento |
| 03h30 | Pitagoras | **Checkpoint 3:** datasets prontos, sanity-check totais |

**Quality gate:** numero total de cirurgias e taxa de mortalidade nacional dentro de ordem de grandeza esperada (ref: estudos publicos de cardio SUS).

## Fase 3 — Diagramacao Excel (04h00–07h00, 3h)

| Hora | Owner | Acao |
|------|-------|------|
| 04h00 | Pitagoras (via Heraclito ou Hipaso, gera xlsx em R com `openxlsx`) | Montar 6 abas com dados, formatacao, capa |
| 06h00 | Pitagoras | Aplicar identidade visual THAUMA (cores, tipografia, logo) |
| 07h00 | Arquimedes | **Checkpoint 4:** abrir o .xlsx, conferir abas, formatos, totais |

## Fase 4 — Quality gate humano + entrega (07h00–10h00, 3h de folga)

| Hora | Owner | Acao |
|------|-------|------|
| 07h00 | Arquimedes | Conferir Definicao de Pronto (todas as caixas) |
| 07h30 | Pedro | Acordar, abrir .xlsx, validar a olho de cliente |
| 08h00 | Pedro + Pitagoras | Ajustes finais (se houver) |
| 09h30 | Pedro | Empacotar entrega: .xlsx + script R + breve email/WhatsApp explicativo |
| 10h00 | Pedro | **ENTREGA Maikon via WhatsApp** |

**Buffer de 3h** entre fim do pipeline tecnico e entrega para absorver imprevistos.

---

## Marcos criticos (resumo)

| Marco | Hora | Quem decide se atrasa |
|-------|------|----------------------|
| M1: Plano tecnico Pitagoras alinhado com briefing | 21h30 | Arquimedes |
| M2: Downloads completos | 00h30 | Pitagoras (escala se travado as 23h00) |
| M3: Datasets enriquecidos prontos | 03h30 | Pitagoras |
| M4: Excel diagramado | 07h00 | Arquimedes |
| M5: Pedro validou | 09h30 | Pedro |
| M6: Entregue ao cliente | 10h00 | Pedro |

## Janelas de risco

- **22h00–00h30:** Downloads DATASUS (maior risco do projeto)
- **04h00–07h00:** Diagramacao Excel (R gera xlsx complexo — formatacao pode dar trabalho)

## Buffers

- 3h de buffer entre fim do pipeline e entrega (07h00 -> 10h00)
- Plano B com escopo reduzido (trimestre) caso downloads travem
