# CLAUDE.md — Projeto Automatização Bruno

> Este arquivo é ativado quando você abre Claude Code dentro de `Projetos/Automatização Bruno/`. Ele complementa (não substitui) o CLAUDE.md raiz da THAUMA, que define você como Sócrates.

---

## O que é este projeto

**Sistema autônomo de identificação de peças industriais e faturamento FIFO** para o cliente externo **Bruno** (pintura industrial). Substitui o processo atual de comparar fotos de celular com PDFs CAD à mão — fonte de erros de faturamento e quebra de FIFO.

**Solução técnica:** bot Telegram que recebe foto da peça → identifica via Claude Sonnet + RAG vetorial sobre os PDFs CAD → confirma com Bruno (HITL) → executa baixa FIFO em planilha de saldos.

**Documento conceitual de origem:** `docs/referencias/master-blueprint-automacao-thauma-v3.html` (proposta v3 que o Bruno provavelmente já viu).

---

## Enquadramento estratégico

**Classificação:** **operação paralela** — fora da tese THAUMA (saúde). Equivale ao TECH Estrutural classificado em 12/04/2026 como "operação paralela mantida por caixa tático e laboratório de automações".

**Por que existe:**
1. Cliente externo pagante (potencial MRR R$ 1k + setup R$ 4-6k)
2. Hipótese estratégica capturada em 27/04: levantamento/automação pontual como **terceiro arquétipo de monetização** complementar a Prisma (longo prazo) e BIaaS (recorrente)
3. Validação técnica de pipeline RAG vetorial multimodal — capacidade reaproveitável em futuros produtos THAUMA

**Inviolável — não contamina:**
- Não é vertical THAUMA. Não entra em pitch comercial THAUMA. Não em portfolio público de Pedro.
- Métricas deste projeto não entram nos KPIs de THAUMA.
- Pipeline THAUMA (Higia, Prisma, BIaaS) tem prioridade absoluta sobre este projeto em caso de conflito de tempo.

---

## Status comercial

| Campo | Valor |
|-------|-------|
| Cliente | Bruno (externo, pintura industrial) |
| Estágio | POC antes de pricing — gate comercial = demo aprovada |
| Modelo pretendido | MRR R$ 1.000/mês + setup R$ 4.000-6.000 |
| Critério de fechamento | Demo ao vivo: ≥18 acertos em 20 fotos pré-acordadas (90%+) |
| Risco | Trabalho de graça se Bruno não fechar pós-POC |
| Mitigação | Janela cravada (2-3 semanas), fora dela encerra |

---

## Janela de execução

| Marco | Data |
|-------|------|
| Kick-off (este documento) | **2026-05-11** |
| Gate POC-A interno (Pedro valida local) | ~21/05 |
| Gate POC-B (Bruno usa autônomo 2-3 dias) | ~28/05 |
| **Entrega demo + decisão Bruno** | **25/05 - 01/06** |

**Cadência Pedro:** lateral, 2-3h/dia. Não atrapalha Higia (gate F0 15/05), Trilha A (gates 13/05, 20/05, 26/05), Newsletter Aletheia (estreia 31/05).

**Gate semanal interno:** toda segunda à noite Sócrates checa se ultrapassou as 2-3h/dia. Se ultrapassou em 2 semanas seguidas, pausa o projeto e renegocia escopo com Bruno.

---

## Arquitetura (resumo)

Quatro camadas conforme blueprint v3, com adapters para fallback de provider:

1. **Ingestão** — PDFs → PNGs (PyMuPDF) → descrições geométricas (Claude Sonnet) → embeddings duais (Google + OpenAI fallback) → ChromaDB
2. **Agente** — foto Telegram → embed → busca top-5 → Sonnet classifica
3. **HITL** — card Telegram com botões confirmar/corrigir/alternativas
4. **Motor FIFO** — abate da NF mais antiga; persiste em Excel (Fase A) ou Sheets (Fase B)

**Detalhe técnico completo:** `docs/superpowers/specs/2026-05-11-automacao-bruno-design.md`

### Faseamento POC-A → POC-B

| | POC-A (local) | POC-B (VPS) |
|---|---|---|
| Onde roda | PC do Pedro | VPS Hostinger (compartilhada com Higia) |
| Telegram | polling | webhook FastAPI |
| Storage | Excel local | Google Sheets |
| Quando ligado | Pedro decide janelas | 24/7 |

Migração A→B troca 3 linhas de DI no `main.py` (interfaces isolam o resto).

---

## Stack técnica

| Camada | Tecnologia |
|--------|------------|
| Linguagem | Python 3.12+ |
| LLM primário | Anthropic SDK (`claude-sonnet-4-6`) |
| LLM fallback | OpenRouter (mesma família Claude) |
| Embedding primário | Google AI (`gemini-embedding-2-preview`) |
| Embedding fallback | OpenAI (`text-embedding-3-small`, dim 768) |
| Vector store | ChromaDB persistente (duas coleções paralelas) |
| Bot | `python-telegram-bot` v21+ |
| Storage Fase A | `openpyxl` (Excel local) |
| Storage Fase B | `gspread` (Google Sheets) |
| HTTP server (Fase B) | FastAPI |
| Logging | `structlog` (JSON) |
| Deploy | VPS Hostinger KVM 6 EUA (mesma da Higia) |

**Variáveis de ambiente esperadas em `.env`** (não commitar):
```
ANTHROPIC_API_KEY=
OPENROUTER_API_KEY=
GOOGLE_AI_KEY=
OPENAI_API_KEY=
TELEGRAM_BOT_TOKEN=
TELEGRAM_ALLOWED_USER_IDS=
GOOGLE_SHEETS_CREDS_PATH=   # só Fase B
```

---

## Owners e delegação (protocolo Sócrates aplicado)

**Sócrates (CEO) faz:** governança deste arquivo, validação de gates, briefing das pendências comerciais com Pedro, decisões de escopo, ajustes ao spec.

**Sócrates NÃO escreve código aqui.** Toda implementação vai por delegação:

| Domínio | Owner principal | Especialistas |
|---------|----------------|---------------|
| Arquitetura full-stack + deploy | **Prometeu** | (Engenharia de Produto, Operações) |
| Pipeline ETL + ChromaDB + embeddings | **Pitágoras** → Heráclito/Hipaso | (Dados) |
| Engenharia de prompt geométrico | **Pitágoras** → Hipaso | usar skill `voltagent-data-ai:prompt-engineer` |
| VPS + secrets + observabilidade | **Hefesto** → Atlas | (Operações) |
| Conversa comercial com Bruno | **Pedro direto** | Sócrates dá briefing, Pedro fala |
| Pricing + contrato | **Tales** + **Sólon** | quando Bruno sinalizar fechamento |

---

## Skills úteis identificadas

**Pipeline brainstorm → spec → plan → implementação:**
- `superpowers:brainstorming` — definir escopo (usado nesta sessão de 11/05)
- `superpowers:writing-plans` — próximo passo após este spec aprovado
- `superpowers:test-driven-development` — durante implementação
- `superpowers:subagent-driven-development` — delegação paralela
- `superpowers:systematic-debugging` — bugs em runtime
- `superpowers:verification-before-completion` — antes de cada gate

**Domínio técnico:**
- `voltagent-data-ai:prompt-engineer` — system prompt geométrico (crítico)
- `voltagent-data-ai:ai-engineer` — design pipeline IA end-to-end
- `voltagent-lang:python-pro` — Python moderno
- `claude-api` — prompt caching dos PNGs candidatos (economia 70%+)

**Não aplicáveis no POC** (mas úteis se evoluir): `impeccable` + `tailwind-design-system` (se virar painel web), `humanizer` (se gerar copy comercial).

---

## Critério de aceite por gate

### Gate POC-A (interno)
- 10 fotos de teste → ≥7 acertos (70% — relaxado pra Fase A)
- Latência média < 15s por foto
- FIFO escreve em Excel sem corromper saldos
- Zero crash do bot durante teste

### Gate POC-B (Bruno autônomo)
- ≥30 fotos processadas em 2-3 dias
- Taxa de confirmação sem correção ≥80%
- Zero erro de saldo
- Bruno consegue usar sem Pedro intervir

### Gate comercial (fechamento)
- Demo ao vivo: ≥18/20 fotos corretas (90%+)
- Bruno verbaliza intenção de fechar
- Pricing alinhado: setup + MRR

---

## Riscos rastreados

| Risco | Mitigação |
|-------|-----------|
| Pedro estoura janela 2-3h/dia | Gate semanal interno; pausa após 2 semanas |
| Bruno não testa por 2-3 dias | Cláusula explícita: 3 dias de janela combinada antes |
| Subset 30-50 PDFs não cobre demo | Pedir lista priorizada por volume + 5-10 "difíceis" |
| API LLM cair | Fallback OpenRouter (mesmo modelo) |
| API embedding cair | Fallback OpenAI (coleção paralela já indexada) |
| Bruno não fecha após POC | Aceitar — POC é hipótese, não promessa |

---

## Pendências antes de iniciar implementação

1. **Pedro alinhar com Bruno** (próxima conversa):
   - Lista das 30-50 peças mais frequentes + os PDFs correspondentes
   - 20 fotos com gabarito para a demo final
   - Janela combinada de 2-3 dias para uso autônomo
   - Autorização explícita para enviar PDFs/fotos à API Anthropic e Google

2. **Pedro provisionar credenciais:**
   - Conta Anthropic — já tem
   - Conta OpenRouter — criar se não tiver
   - Conta Google AI Studio — criar se não tiver
   - Conta OpenAI — provavelmente já tem
   - Bot Telegram via @BotFather — criar
   - Service Account Google para Sheets (só Fase B)

3. **Sócrates → Hefesto:** confirmar capacidade da VPS Hostinger pra rodar este bot em paralelo à Higia (recursos: ~512MB RAM extra, espaço disco ~200MB).

---

## Conexão com pipeline THAUMA

Este projeto **não cruza fronteira FHEMIG/THAUMA** (cliente externo, peça industrial — fora do domínio saúde).

Hipóteses estratégicas que este POC pode validar (registrar em `Operando/03-thauma/Aprendizados.md` ao final):
- **Pipeline RAG multimodal funciona** com 30-50 itens em ChromaDB → reusável para Higia v2 (relatórios CONITEC, portarias, etc.)
- **Adapter pattern com fallback duplo** (LLM + embedding) → padrão arquitetural a adotar em todos os agentes THAUMA críticos
- **Telegram polling → webhook → handoff WhatsApp** → trilha técnica direta para a migração D11/D13 da Higia

---

## Atualizações deste documento

- **2026-05-11** — Sessão Sócrates × Pedro: kick-off, brainstorming completo, design aprovado, este CLAUDE.md criado.

*Próxima atualização esperada quando: gate POC-A fechar, ou pivot de escopo, ou Bruno responder ao alinhamento.*
