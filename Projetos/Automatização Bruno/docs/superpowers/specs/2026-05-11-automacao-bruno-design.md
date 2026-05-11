---
title: Design — Automação de Identificação de Peças e Faturamento FIFO (POC Bruno)
date: 2026-05-11
status: aprovado-design (writing-plans pendente)
owner_estrategico: Sócrates (CEO THAUMA)
owners_tecnicos: Prometeu, Pitágoras, Hefesto
cliente: Bruno (externo, pintura industrial)
classificacao: operação paralela (fora da tese THAUMA)
janela: 2026-05-11 → 2026-06-01 (entrega POC)
fonte_brainstorm: sessão Sócrates × Pedro 2026-05-11
---

# Automação de Identificação de Peças e Faturamento FIFO — POC

## Resumo executivo

Sistema autônomo que recebe foto de peça industrial via Telegram, identifica o código correto comparando com acervo de PDFs CAD usando RAG vetorial multimodal sobre Claude Sonnet, valida com human-in-the-loop, e executa baixa FIFO em planilha de saldos. POC executado em duas fases (local + VPS) com adapters que isolam dependências de provider para garantir resiliência via fallback duplo (LLM e embedding).

---

## 1. Contexto e escopo

### Problema de negócio do Bruno
Identificação manual de peças (ex: cód. MEC 06332) feita por comparação visual entre fotos de celular e desenhos CAD em PDF. Gera erros de faturamento e quebra do controle FIFO de NFs.

### Escopo POC
- **Subset:** 30-50 PDFs das peças mais frequentes (de um universo de 1.270)
- **Single-user:** apenas Bruno autorizado no Telegram
- **Validação:** Bruno usa autônomo por 2-3 dias, depois demo ao vivo com 20 fotos
- **Critério de aceite comercial:** ≥18/20 acertos na demo final (90%+)

### Fora do escopo POC (mas nomeado para roadmap pós-fechamento)
- Multi-usuário (operadores além do Bruno)
- WhatsApp Business
- Aprendizado contínuo a partir de correções (cache simples sim, fine-tuning não)
- Dashboard web de auditoria
- Integração com ERP do Bruno
- Carga dos 1.270 PDFs (Fase pago)

---

## 2. Decisões consolidadas

| # | Decisão | Razão |
|---|---------|-------|
| D1 | Abordagem **A** (RAG vetorial), não B (vision-only) | Pedro priorizou stack que escala pra 1.270 PDFs sem refator se Bruno fechar |
| D2 | Embedding primário **Google `gemini-embedding-2-preview`** | Escolha explícita de Pedro |
| D3 | Embedding fallback **OpenAI `text-embedding-3-small`** dim 768 | Pedro autorizou; coleção ChromaDB paralela já indexada para resolver vector space mismatch |
| D4 | LLM primário **Anthropic `claude-sonnet-4-6`** direto | Modelo de visão capaz, custo controlado |
| D5 | LLM fallback **OpenRouter** roteando mesmo modelo | Resolve outage Anthropic; mantém prompt e resultado consistentes |
| D6 | Faseamento **POC-A local** + **POC-B VPS** | Pedro valida internamente antes de Bruno usar autônomo |
| D7 | VPS **Hostinger KVM 6 EUA** (compartilhada com Higia) | Custo marginal zero |
| D8 | Storage Fase A **Excel local (openpyxl)**, Fase B **Google Sheets (gspread)** | Quick & dirty na A; integrado e visível ao Bruno na B |
| D9 | Telegram **polling** Fase A, **webhook FastAPI** Fase B | Polling simplifica setup local; webhook é robusto em produção |
| D10 | **Cinco adapters** (MessageChannel, Storage, VectorStore, LLMProvider, EmbeddingProvider) | Migração A→B vira troca de DI no main; fallbacks plugáveis |
| D11 | **Sem CI de testes Anthropic/Google** | Custo + flakiness; testes integração rodam manual antes de cada gate |
| D12 | **Single-user (Bruno)** no POC, allowlist de Telegram user_id | Evita complexidade de auth multi-operador |

---

## 3. Arquitetura

### 3.1. Visão geral (4 camadas)

```
┌─────────────────────────────────────────────────────────────────┐
│  CAMADA 1 — INGESTÃO (offline, 1x)                              │
│  PDF → PNG → Descrição (Sonnet) → Embedding dual (Google+OpenAI)│
│  → ChromaDB (2 coleções paralelas)                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAMADA 2 — AGENTE (runtime)                                    │
│  Telegram → foto → embed → ChromaDB top-5 → Sonnet classifica   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAMADA 3 — HITL                                                │
│  Card Telegram com confirmar/corrigir/ver-alternativas/cancelar │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  CAMADA 4 — FIFO                                                │
│  Lê saldos, abate da NF mais antiga, escreve movimentação       │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2. Estado da máquina por foto

1. `RECEBIDO` — bot recebe imagem
2. `IDENTIFICADO` — agente retornou código + confiança
3. `AGUARDANDO_CONFIRMACAO` — Bruno deve interagir
4. `CONFIRMADO` — código validado + qty informada
5. `LANCADO` — FIFO executado, storage atualizado
6. `ARQUIVADO` — foto + log persistido

Timeout de `AGUARDANDO_CONFIRMACAO`: lembrete em 30 min, cancelamento auto em 24h.

### 3.3. Os 5 adapters (Protocols)

```python
class MessageChannel(Protocol):
    async def receive_image(self) -> Image: ...
    async def send_card(self, content: Card) -> CardResponse: ...
    async def send_text(self, text: str) -> None: ...
# Implementações: TelegramPollingChannel (A), TelegramWebhookChannel (B)

class Storage(Protocol):
    def read_saldos(self, codigo: str) -> list[SaldoLote]: ...
    def append_movimentacao(self, mov: Movimentacao) -> None: ...
    def update_saldo(self, lote_id: str, qty_nova: float) -> None: ...
# Implementações: ExcelStorage (A), SheetsStorage (B)

class VectorStore(Protocol):
    def query(self, embedding: list[float], top_k: int, provider_tag: str) -> list[PartCandidate]: ...
    def add(self, id: str, embedding: list[float], metadata: dict, provider_tag: str) -> None: ...
# Implementação: ChromaDBStore (única, manipula 2 coleções nomeadas)

class LLMProvider(Protocol):
    async def vision_classify(self, foto: bytes, candidates: list[Image]) -> ClassificationResult: ...
    async def describe_geometry(self, image: bytes) -> str: ...
# Implementações: AnthropicProvider (primário), OpenRouterProvider (fallback)

class EmbeddingProvider(Protocol):
    name: str  # "google" ou "openai"
    async def embed(self, text: str) -> list[float]: ...
# Implementações: GoogleProvider (primário), OpenAIProvider (fallback)
```

Compositor `ResilientLLM` e `ResilientEmbedding` envolvem primário+fallback com retry exponencial e circuit breaker simples (3 falhas seguidas → desliga primário por 5 min).

---

## 4. Componentes detalhados

### 4.1. Camada 1 — Ingestão

**Script:** `scripts/ingest.py` (execução manual, 1x antes do POC começar).

**Pipeline:**
1. Para cada PDF em `data/pdfs/`:
   - PyMuPDF renderiza página 1 em PNG 300dpi escala de cinza → `data/pdfs_png/{codigo}.png`
   - Sonnet vê PNG + system prompt geométrico → descrição estruturada → `data/descriptions/{codigo}.txt`
   - **Google embedding** da descrição → vector(768d)
   - **OpenAI embedding** da descrição → vector(768d, dim explícito)
   - ChromaDB.add em **duas coleções**: `parts_google` e `parts_openai`
2. Persiste em `data/chroma_db/`

**Tempo estimado:** 30-50 PDFs × ~20s (com embedding dual) = ~10-17 min.

**System prompt geométrico** (a ser refinado com skill `voltagent-data-ai:prompt-engineer`):
> "Atue como Engenheiro de Qualidade Industrial. Descreva a peça nesta imagem com foco em: (1) contagem e disposição de furos com diâmetro relativo; (2) formato do perímetro (regular, irregular, simétrico); (3) recortes internos (padrão em 'X', concavidades, abas); (4) proporção largura/altura aproximada; (5) particularidades visuais marcantes. Use linguagem objetiva, 200-400 palavras. Não cite dimensões absolutas; descreva geometria comparável."

### 4.2. Camada 2 — Agente de identificação

**Módulo:** `src/agent/identify.py`

**Pipeline por foto:**
1. Salva foto: `data/uploads/YYYY-MM-DD/{user_id}_{ts}.jpg`
2. `LLMProvider.describe_geometry(foto)` → descrição
3. `EmbeddingProvider.embed(descrição)` → vector
4. `VectorStore.query(vector, top_k=5, provider_tag=embedding.name)` → 5 candidatos
5. `LLMProvider.vision_classify(foto, [pngs dos 5 candidatos])` → JSON estruturado:
```json
{
  "transaction_id": "BRUNO-2026-XXXX",
  "identified_part": {
    "code": "06332",
    "description": "Base Montagem Coluna Digimamo TM",
    "confidence_score": 0.98
  },
  "alternatives": [
    {"code": "06351", "confidence": 0.45},
    {"code": "06329", "confidence": 0.21}
  ],
  "reasoning": "Geometria com 4 furos simétricos no perímetro + recorte central em X correspondem ao 06332.",
  "production_data": {
    "quantity": null,  // preenchido após HITL
    "unit": "PC",
    "timestamp": "2026-05-12T14:23:00Z"
  },
  "source_image_url": "data/uploads/2026-05-12/123_1715520180.jpg"
}
```

**Otimização de custo via prompt caching** (skill `claude-api`):
- Sistema-prompt + 5 PNGs candidatos viram bloco cacheável
- Hit rate alto se Bruno tirar várias fotos da mesma peça
- Economia esperada: 70%+ no custo Sonnet

### 4.3. Camada 3 — HITL via Telegram

**Módulo:** `src/hitl/confirm.py`

**Card enviado:**
```
🔍 Identifiquei como:
*Cód. 06332* — Base Montagem Coluna Digimamo TM
Confiança: 98%

Confirma?
[✅ Confirmar] [✏️ Corrigir]
[👀 Ver alternativas] [❌ Cancelar]
```

**Fluxo de callback:**
- ✅ → bot pergunta "Quantidade?" (input numérico)
- ✏️ → bot pede "Digite o código correto:" → grava em `data/correcoes.jsonl`
- 👀 → mostra os outros 4 candidatos com PNG miniatura e %
- ❌ → encerra transação, log marcado como `CANCELADO`

**Estado em `data/sessions.sqlite`** (Fase A) ou `sessions/` em Redis-like (Fase B se vier necessidade).

### 4.4. Camada 4 — Motor FIFO

**Módulo:** `src/fifo/motor.py`

**Estrutura mínima da planilha (3 abas):**

| Aba `saldos` | tipo | exemplo |
|---|---|---|
| `lote_id` | str | "LOT-2026-001" |
| `codigo_peca` | str | "06332" |
| `nf_origem` | str | "NF-12345" |
| `qty_original` | float | 200.0 |
| `qty_disponivel` | float | 156.0 |
| `data_entrada` | date | 2026-04-15 |

| Aba `movimentacoes` | tipo | exemplo |
|---|---|---|
| `timestamp` | datetime | 2026-05-12T14:25:30Z |
| `codigo_peca` | str | "06332" |
| `qty_baixada` | float | 34.0 |
| `lote_baixado` | str | "LOT-2026-001" |
| `nf_baixada` | str | "NF-12345" |
| `foto_url` | str | "data/uploads/..." |
| `confirmado_por` | str | "bruno" |
| `confidence_inicial` | float | 0.98 |

| Aba `auditoria` | tipo | exemplo |
|---|---|---|
| `timestamp` | datetime | ... |
| `evento` | str | "identificacao" |
| `payload` | json | {...} |

**Lógica FIFO:**
1. Lê todos os lotes do código solicitado, ordenados por `data_entrada` ASC
2. Itera abatendo da NF mais antiga até zerar quantidade
3. Se quantidade > soma dos saldos: alerta "Saldo total: X PC. Confirmar baixa parcial ou cancelar?"
4. Persiste 1 linha em `movimentacoes` por lote afetado (pode ser N>1 se cruzar lotes)
5. Atualiza `qty_disponivel` em cada lote afetado

**Lock/concorrência:** lock de arquivo (Excel) ou range lock (Sheets) durante leitura+escrita. Retry 3x com backoff em caso de conflito.

---

## 5. Fluxo de dados completo (runtime)

```
Bruno → Telegram → MessageChannel.receive_image()
      → agent.identify(image)
            → LLMProvider.describe_geometry(image)        [primário Anthropic; fallback OpenRouter]
            → EmbeddingProvider.embed(descricao)          [primário Google; fallback OpenAI]
            → VectorStore.query(emb, k=5, tag=provider)
            → LLMProvider.vision_classify(image, top5)
            → ClassificationResult (JSON)
      → hitl.confirm(result) via MessageChannel.send_card
            → callback Bruno: ✅/✏️/👀/❌
            → input: "Quantidade?"
      → fifo.lancar(code, qty, photo_ref)
            → Storage.read_saldos(code)
            → algoritmo FIFO
            → Storage.append_movimentacao + Storage.update_saldo
      → MessageChannel.send_text("✅ Lançado: 34 PC do código 06332. Saldo: 156 PC.")
```

---

## 6. Estrutura de pastas

```
Projetos/Automatização Bruno/
├── CLAUDE.md                                    # governança
├── docs/
│   ├── referencias/
│   │   ├── master-blueprint-automacao-thauma-v3.html
│   │   └── infografico-conceitual.png
│   └── superpowers/specs/
│       └── 2026-05-11-automacao-bruno-design.md  # este doc
├── data/                                        # gitignore inteiro
│   ├── pdfs/
│   ├── pdfs_png/
│   ├── descriptions/
│   ├── chroma_db/
│   ├── uploads/
│   ├── saldos.xlsx                             # Fase A
│   ├── correcoes.jsonl
│   └── sessions.sqlite
├── scripts/
│   ├── ingest.py                               # execução offline 1x
│   └── metrics.py                              # relatório de performance
├── src/
│   ├── main.py                                 # entrypoint
│   ├── config.py                               # carrega .env, decide A/B
│   ├── channels/
│   │   ├── base.py
│   │   ├── telegram_polling.py                 # Fase A
│   │   └── telegram_webhook.py                 # Fase B
│   ├── storage/
│   │   ├── base.py
│   │   ├── excel.py                            # Fase A
│   │   └── sheets.py                           # Fase B
│   ├── vectorstore/
│   │   └── chroma.py
│   ├── providers/
│   │   ├── llm/
│   │   │   ├── base.py
│   │   │   ├── anthropic.py
│   │   │   ├── openrouter.py
│   │   │   └── resilient.py                    # composer com fallback
│   │   └── embedding/
│   │       ├── base.py
│   │       ├── google.py
│   │       ├── openai.py
│   │       └── resilient.py
│   ├── agent/
│   │   └── identify.py
│   ├── hitl/
│   │   └── confirm.py
│   └── fifo/
│       └── motor.py
├── tests/
│   ├── test_pdf_to_png.py
│   ├── test_chroma_query.py
│   ├── test_fifo_motor.py
│   ├── test_hitl_state.py
│   ├── test_resilient_llm.py
│   ├── test_resilient_embedding.py
│   └── fixtures/
├── logs/
│   └── app.log                                 # gitignore
├── .env.example
├── .gitignore
├── pyproject.toml
└── README.md
```

---

## 7. Error handling

### Falhas previsíveis

| Falha | Camada | Tratamento |
|-------|--------|-----------|
| Foto borrada / muito escura | Agent | Sonnet retorna `confidence < 0.5` → bot pede nova foto |
| Top-1 confiança 50-80% | HITL | Card mostra **3 alternativas** com % e PNG miniatura |
| Bruno corrige código | HITL | Persiste em `data/correcoes.jsonl` |
| Quantidade > saldo total | FIFO | Bot pergunta baixa parcial ou cancela |
| Código sem lote | FIFO | Bot pergunta se é entrada de NF nova |
| API Anthropic offline | LLMProvider | Retry exp 2x → fallback OpenRouter |
| API OpenRouter offline também | LLMProvider | Bot avisa Bruno + alerta Pedro |
| API Google offline | EmbeddingProvider | Retry exp 2x → fallback OpenAI (coleção paralela já indexada) |
| API OpenAI offline também | EmbeddingProvider | Bot avisa Bruno + alerta Pedro |
| Telegram offline | Channel | Retry nativo do SDK |
| Excel/Sheets travado | Storage | Lock + retry 3x; se falhar persiste em `data/pending_movs.jsonl` |
| Bruno não confirma em 30 min | HITL | Lembrete; cancelamento auto em 24h |

### Logging estruturado

Todo evento crítico emite JSON em `logs/app.log` rotacionado. Exemplo:
```json
{"ts": "2026-05-12T14:23:11Z", "event": "identificacao", "foto": "uploads/...", "code": "06332", "confidence": 0.98, "candidates": [...], "duration_ms": 4521, "llm_provider_used": "anthropic", "embedding_provider_used": "google"}
```

### Métricas para demo (script `scripts/metrics.py`)
- Acerto top-1 (% confirmações sem correção)
- Acerto top-3 (% código correto entre os 3 mais prováveis)
- Confiança média top-1
- Latência média por foto
- Taxa de uso de fallback (LLM e embedding)

---

## 8. Testes

**Filosofia POC:** testes mínimos como defesa contra regressão, não cobertura de produção.

```
tests/
├── test_pdf_to_png.py            # PyMuPDF gera PNG legível
├── test_chroma_query.py          # ChromaDB.query top-k esperado em coleções google e openai
├── test_fifo_motor.py            # FIFO abate da NF mais antiga primeiro; cruzamento de lotes
├── test_hitl_state.py            # AGUARDANDO_CONFIRMACAO → timeout 30min/24h
├── test_resilient_llm.py         # primário falha 3x → fallback chamado; circuit breaker abre
├── test_resilient_embedding.py   # idem para embedding
└── fixtures/
    ├── pdf_sample.pdf
    ├── photo_sample.jpg
    └── saldos_sample.xlsx
```

**Não testados em CI:** chamadas reais Anthropic/Google/OpenAI (custo + flakiness). Smoke tests de integração rodam manual antes de cada gate via `scripts/smoke_test.py`.

---

## 9. Critério de aceite por gate

### Gate POC-A (interno, ~21/05)
- 10 fotos de teste → ≥7 acertos (70%, relaxado pra Fase A)
- Latência média < 15s por foto
- FIFO escreve em Excel sem corromper saldos
- Zero crash do bot durante teste

### Gate POC-B (Bruno autônomo, ~28/05)
- ≥30 fotos processadas em 2-3 dias de uso
- Taxa de confirmação sem correção ≥80%
- Zero erro de saldo
- Bruno consegue usar sem Pedro intervir

### Gate comercial (fechamento, 25/05 - 01/06)
- Demo ao vivo: ≥18/20 fotos corretas (90%+)
- Bruno verbaliza intenção de fechar
- Pricing alinhado: setup R$ 4-6k + MRR R$ 1k

---

## 10. Riscos rastreados

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Pedro estoura janela 2-3h/dia | Média | Alto | Gate semanal interno; pausa após 2 semanas |
| Subset 30-50 PDFs não cobre demo | Média | Alto | Pedir lista priorizada por volume + 5-10 "difíceis" |
| Bruno não testa por 2-3 dias | Alta | Médio | Cláusula explícita: 3 dias de janela combinada antes |
| Custo Sonnet maior que esperado | Baixa | Baixo | Prompt caching dos 5 PNGs candidatos |
| Bruno fecha mas escala 1.270 e RAG textual falha | Média | Médio | Migrar pra embedding multimodal CLIP no contrato pago |
| Bruno não fecha após POC | Média | Aceitável | POC é hipótese; aprendizado registrado em qualquer cenário |

---

## 11. Pendências antes de iniciar implementação

### Pedro alinhar com Bruno
1. Lista das 30-50 peças mais frequentes + os PDFs correspondentes
2. 20 fotos com gabarito para a demo final
3. Janela combinada de 2-3 dias para uso autônomo (Fase B)
4. Autorização explícita para enviar PDFs/fotos à API Anthropic e Google

### Pedro provisionar credenciais
- Conta Anthropic — já tem
- Conta OpenRouter — criar se não tiver
- Conta Google AI Studio — criar se não tiver
- Conta OpenAI — provavelmente já tem
- Bot Telegram via @BotFather — criar
- Service Account Google para Sheets (só Fase B)

### Sócrates → Hefesto
- Confirmar capacidade da VPS Hostinger pra rodar este bot em paralelo à Higia (recursos: ~512MB RAM extra, espaço disco ~200MB)

---

## 12. Próximo passo

Após aprovação deste design por Pedro, **invocar `superpowers:writing-plans`** para criar plano de implementação detalhado: cronograma, sprints, owners por sprint, dependências, gates internos, scripts de smoke test, deploy plan.

---

## Apêndice A — Variáveis de ambiente

```bash
# LLM
ANTHROPIC_API_KEY=sk-ant-...
OPENROUTER_API_KEY=sk-or-...

# Embedding
GOOGLE_AI_KEY=...
OPENAI_API_KEY=sk-...

# Telegram
TELEGRAM_BOT_TOKEN=123456:ABC-...
TELEGRAM_ALLOWED_USER_IDS=123456789  # ID do Bruno

# Storage Fase B
GOOGLE_SHEETS_CREDS_PATH=./secrets/sheets-sa.json
GOOGLE_SHEET_ID=...

# Config geral
APP_PHASE=A  # ou B
LOG_LEVEL=INFO
CHROMA_PATH=./data/chroma_db
EXCEL_PATH=./data/saldos.xlsx
```

---

## Apêndice B — Comparação descartada (por que não Abordagem B)

A Abordagem B (vision-only, sem RAG) foi tecnicamente mais simples para POC mas **descartada por Pedro** por dois motivos arquiteturais:
1. Não escala para os 1.270 PDFs caso Bruno feche — precisaria de refator completo da Camada 2
2. Vai contra a tese de respeitar o blueprint v3 que Bruno já viu como proposta

Mantém-se como **plano B de emergência** se o RAG textual falhar nos testes da Fase A: nesse caso, com 30-50 PDFs ainda cabe no contexto Sonnet sem RAG.
