# Automação Bruno — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar POC fim-a-fim de identificação de peças industriais via Telegram + RAG vetorial multimodal sobre Claude Sonnet, com 5 adapters isolando dependências (LLM, embedding, channel, storage, vector store) e fallback duplo (Anthropic→OpenRouter, Google→OpenAI), entregue em 2 fases (POC-A local Excel + polling, POC-B VPS Sheets + webhook).

**Architecture:** 4 camadas (Ingestão / Agente / HITL / FIFO) sobre Python 3.12+ assíncrono. Camada 1 indexa PDFs no ChromaDB com embeddings duais (Google `gemini-embedding-2-preview` + OpenAI `text-embedding-3-small` dim=768) em duas coleções paralelas. Camada 2 usa Sonnet 4.6 com prompt caching para classificar foto contra top-5 candidatos. Camada 3 é card Telegram com confirmar/corrigir/alternativas. Camada 4 abate FIFO em Excel local (Fase A) ou Google Sheets (Fase B).

**Tech Stack:** Python 3.12+ (uv), `python-telegram-bot` v21+, `chromadb`, `pymupdf`, `openpyxl`/`gspread`, `anthropic`, `openai`, `google-genai`, FastAPI (Fase B), `structlog`, `pytest`+`pytest-asyncio`, deploy VPS Hostinger.

**Spec de origem:** `docs/superpowers/specs/2026-05-11-automacao-bruno-design.md`

**Janela:** 2026-05-11 → 2026-06-01. Pedro a 2-3h/dia, lateral a Higia/Trilha A.

---

## Mapa de arquivos

### Criados nesta implementação

```
Projetos/Automatização Bruno/
├── pyproject.toml                        # T1
├── .env.example                          # T1
├── README.md                             # T1
├── src/
│   ├── __init__.py                       # T1
│   ├── config.py                         # T2  — carrega .env, decide A/B
│   ├── logging_setup.py                  # T2  — structlog JSON
│   ├── models.py                         # T3  — dataclasses (Image, Card, ClassificationResult, SaldoLote, Movimentacao)
│   ├── providers/
│   │   ├── __init__.py
│   │   ├── embedding/
│   │   │   ├── base.py                   # T4  — Protocol
│   │   │   ├── google.py                 # T4
│   │   │   ├── openai.py                 # T5
│   │   │   └── resilient.py              # T6  — composer com fallback + circuit breaker
│   │   └── llm/
│   │       ├── base.py                   # T7  — Protocol
│   │       ├── anthropic.py              # T7
│   │       ├── openrouter.py             # T8
│   │       └── resilient.py              # T9
│   ├── vectorstore/
│   │   ├── base.py                       # T10 — Protocol
│   │   └── chroma.py                     # T10 — duas coleções
│   ├── ingestion/
│   │   ├── pdf_to_png.py                 # T11
│   │   └── geometry_describer.py         # T12
│   ├── agent/
│   │   └── identify.py                   # T14
│   ├── hitl/
│   │   ├── card.py                       # T15 — render do card
│   │   └── session.py                    # T16 — estado AGUARDANDO_CONFIRMACAO + timeout
│   ├── storage/
│   │   ├── base.py                       # T17 — Protocol
│   │   └── excel.py                      # T17
│   ├── fifo/
│   │   └── motor.py                      # T18
│   ├── channels/
│   │   ├── base.py                       # T19 — Protocol
│   │   └── telegram_polling.py           # T19
│   └── main.py                           # T20 — wiring DI Fase A
├── scripts/
│   ├── ingest.py                         # T13 — execução offline
│   ├── smoke_apis.py                     # T3
│   └── metrics.py                        # T26
├── tests/
│   ├── conftest.py                       # T1
│   ├── unit/
│   │   ├── test_config.py                # T2
│   │   ├── test_models.py                # T3
│   │   ├── test_resilient_embedding.py   # T6
│   │   ├── test_resilient_llm.py         # T9
│   │   ├── test_chroma_store.py          # T10
│   │   ├── test_pdf_to_png.py            # T11
│   │   ├── test_geometry_describer.py    # T12 (mocked)
│   │   ├── test_agent_identify.py        # T14 (mocked)
│   │   ├── test_hitl_session.py          # T16
│   │   ├── test_excel_storage.py         # T17
│   │   └── test_fifo_motor.py            # T18
│   └── fixtures/
│       ├── pdf_sample.pdf                # T11 (Pedro fornece)
│       ├── photo_sample.jpg              # T11 (Pedro fornece)
│       └── saldos_sample.xlsx            # T17 (gerado por fixture)
├── deploy/                               # Sprint 6 (Fase B)
│   ├── Dockerfile                        # T22
│   ├── docker-compose.yml                # T22
│   ├── nginx.conf                        # T23
│   └── systemd/
│       └── automacao-bruno.service       # T23
└── src/
    ├── channels/telegram_webhook.py      # T21 — Fase B
    ├── storage/sheets.py                 # T24 — Fase B
    └── server.py                         # T22 — FastAPI Fase B
```

### Já existentes (não modificar)
- `CLAUDE.md` — governança
- `docs/superpowers/specs/2026-05-11-automacao-bruno-design.md` — design
- `docs/referencias/master-blueprint-automacao-thauma-v3.html` — proposta v3

---

## Convenções

- **Manager Python:** `uv` (moderno, rápido). Comandos: `uv add`, `uv sync`, `uv run`.
- **Linguagem:** Python 3.12+, type hints obrigatórios, `async`/`await` no IO.
- **Estilo:** `ruff` + `mypy` (modo strict).
- **Testes:** `pytest` + `pytest-asyncio`. Unit com mocks. Smoke separado, manual.
- **Logging:** `structlog` JSON em `logs/app.log`.
- **Commits:** Conventional Commits. Frequência: 1 por task no mínimo.
- **Owner padrão de execução:** subagentes técnicos (Prometeu para infra/full-stack, Pitágoras para dados/embeddings/RAG, Hefesto para deploy VPS). Sócrates valida gates entre sprints, não escreve código.

---

## Pré-requisitos por sprint (checklist Pedro)

> **Como ler:** cada sprint só destrava quando todos os itens marcados como ⚠️ estiverem prontos. Itens 🟢 são desejáveis mas não bloqueiam.

### Sprint 0 — Bootstrap + smoke APIs
- ⚠️ **`ANTHROPIC_API_KEY`** — Pedro já tem (Higia)
- ⚠️ **`OPENROUTER_API_KEY`** — criar em https://openrouter.ai/keys + saldo U$5-10
- ⚠️ **`GOOGLE_AI_KEY`** — criar em https://aistudio.google.com/apikey (free tier basta)
- ⚠️ **`OPENAI_API_KEY`** — Pedro provavelmente já tem; senão https://platform.openai.com/api-keys + U$5 saldo
- ⚠️ **`TELEGRAM_BOT_TOKEN`** — falar com `@BotFather` (`/newbot`)
- ⚠️ **`TELEGRAM_ALLOWED_USER_IDS`** — pegar via `@userinfobot` (Pedro + Bruno)
- 🟢 Confirmação Hefesto: VPS Hostinger tem ~512MB RAM extra livre

### Sprint 1 — Adapters (LLM, Embedding, VectorStore)
- ⚠️ Tudo do Sprint 0 fechado (smoke das 4 APIs verde)
- _Sem novos requisitos externos_

### Sprint 2 — Ingestão de PDFs
- ⚠️ Tudo do Sprint 1 fechado
- ⚠️ **30-50 PDFs do Bruno** em `data/pdfs/` com nomes no formato `<codigo>.pdf` (ex: `06332.pdf`)
- ⚠️ Bruno autorizou explicitamente envio dos PDFs à API Anthropic e Google
- 🟢 Lista priorizada das peças mais frequentes (sem isso, Pedro escolhe critério: random ou top-N por volume vendido)

### Sprint 3 — Agente identificador
- ⚠️ Tudo do Sprint 2 fechado (ChromaDB indexado, smoke query funciona)
- _Sem novos requisitos externos_

### Sprint 4 — HITL + Storage Excel + FIFO
- ⚠️ Tudo do Sprint 3 fechado
- 🟢 Estrutura inicial de `saldos.xlsx` com lotes do Bruno (se não, sistema cria vazio e Pedro injeta dados de teste fictícios)

### Sprint 5 — Telegram polling + Gate POC-A
- ⚠️ Tudo do Sprint 4 fechado
- ⚠️ **10 fotos de teste com gabarito** (Pedro tira ou Bruno manda) — para validar 70%+ acerto
- 🟢 Bruno disponível para 1 call rápida de demo informal (opcional na Fase A)

### Sprint 6 — Migração VPS (Webhook + FastAPI + Sheets + Docker)
- ⚠️ Gate POC-A passou (≥7/10 acertos)
- ⚠️ **Acesso SSH à VPS Hostinger** (mesma do Higia) com Docker + Compose instalados
- ⚠️ **Subdomínio apontado para o IP da VPS** (sugestão: `bruno.thauma.consulting`)
- ⚠️ **Service Account Google + Sheet ID** — Hefesto guia Pedro em https://console.cloud.google.com → IAM → Service Accounts → criar key JSON → compartilhar Google Sheet com o email do SA
- ⚠️ **`GOOGLE_SHEETS_CREDS_PATH`** + **`GOOGLE_SHEET_ID`** preenchidos em `.env.production`
- 🟢 Certificado SSL do subdomínio via certbot (Hefesto faz)

### Sprint 7 — Handoff Bruno + Gate POC-B + Gate comercial
- ⚠️ Sprint 6 deployado e smoke pessoal de Pedro passou
- ⚠️ **Janela de 2-3 dias combinada com Bruno** (datas explícitas, ex: 28-30/05)
- ⚠️ **20 fotos com gabarito** entregues por Bruno para a demo final do Gate Comercial
- ⚠️ Bruno tem o handle do bot (`@nome_do_bot`) e instruções enviadas
- 🟢 Pricing pré-acordado verbalmente com Bruno (R$ 1k MRR + R$ 4-6k setup) para evitar surpresa no fechamento

### Síntese — o que destrava começar HOJE
**Sprint 0 só precisa dos 6 itens ⚠️ acima** (4 API keys + bot Telegram + 2 user_ids). Tudo o mais (PDFs, VPS, fotos gabarito) tem janela de várias sessões para resolver em paralelo aos sprints anteriores.

---

# SPRINT 0 — Setup base (T1-T3) — Estimado 4-6h

Objetivo: projeto Python operacional, dependências instaladas, credenciais validadas via smoke test antes de qualquer código de domínio.

---

### Task 1: Setup do projeto Python

**Files:**
- Create: `Projetos/Automatização Bruno/pyproject.toml`
- Create: `Projetos/Automatização Bruno/.env.example`
- Create: `Projetos/Automatização Bruno/README.md`
- Create: `Projetos/Automatização Bruno/src/__init__.py`
- Create: `Projetos/Automatização Bruno/tests/__init__.py`
- Create: `Projetos/Automatização Bruno/tests/conftest.py`

- [ ] **Step 1: Criar `pyproject.toml`**

```toml
[project]
name = "automacao-bruno"
version = "0.1.0"
description = "POC identificacao de pecas industriais via Telegram + RAG vetorial"
requires-python = ">=3.12"
dependencies = [
    "anthropic>=0.40.0",
    "openai>=1.50.0",
    "google-genai>=0.3.0",
    "chromadb>=0.5.0",
    "pymupdf>=1.24.0",
    "python-telegram-bot[ext]>=21.0",
    "openpyxl>=3.1.0",
    "structlog>=24.0",
    "pydantic>=2.7",
    "pydantic-settings>=2.4",
    "tenacity>=9.0",
    "httpx>=0.27",
]

[project.optional-dependencies]
fase-b = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
    "gspread>=6.0",
    "google-auth>=2.30",
]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "pytest-mock>=3.14",
    "ruff>=0.6",
    "mypy>=1.11",
]

[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM"]

[tool.mypy]
python_version = "3.12"
strict = true
ignore_missing_imports = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

- [ ] **Step 2: Criar `.env.example`**

```bash
# LLM
ANTHROPIC_API_KEY=sk-ant-...
OPENROUTER_API_KEY=sk-or-...

# Embedding
GOOGLE_AI_KEY=...
OPENAI_API_KEY=sk-...

# Telegram
TELEGRAM_BOT_TOKEN=123456:ABC-...
TELEGRAM_ALLOWED_USER_IDS=123456789

# Storage Fase B (deixar vazio na Fase A)
GOOGLE_SHEETS_CREDS_PATH=
GOOGLE_SHEET_ID=

# Config geral
APP_PHASE=A
LOG_LEVEL=INFO
CHROMA_PATH=./data/chroma_db
EXCEL_PATH=./data/saldos.xlsx
UPLOADS_PATH=./data/uploads
LOGS_PATH=./logs
```

- [ ] **Step 3: Criar `README.md` mínimo**

````markdown
# Automação Bruno — POC

POC de identificação de peças industriais via Telegram + RAG vetorial.

## Setup local (Fase A)

```bash
uv sync --extra dev
cp .env.example .env
# preencher .env com as credenciais
mkdir -p data/{pdfs,pdfs_png,descriptions,chroma_db,uploads} logs
```

## Comandos

| Comando | Descrição |
|---------|-----------|
| `uv run scripts/smoke_apis.py` | Valida todas as 4 APIs |
| `uv run scripts/ingest.py` | Indexa PDFs no ChromaDB |
| `uv run python -m src.main` | Inicia o bot (Fase A) |
| `uv run pytest` | Roda testes unitários |
| `uv run scripts/metrics.py` | Relatório de performance |

## Documentação
- `CLAUDE.md` — governança do projeto
- `docs/superpowers/specs/2026-05-11-automacao-bruno-design.md` — design técnico
- `docs/superpowers/plans/2026-05-11-automacao-bruno-implementacao.md` — este plano
````

- [ ] **Step 4: Criar `src/__init__.py` e `tests/__init__.py` (vazios)**

```bash
touch src/__init__.py tests/__init__.py
```

- [ ] **Step 5: Criar `tests/conftest.py`**

```python
"""Configuração compartilhada para testes pytest."""
from pathlib import Path

import pytest


@pytest.fixture
def fixtures_dir() -> Path:
    """Diretório de fixtures de teste."""
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def tmp_data_dir(tmp_path: Path) -> Path:
    """Diretório temporário emulando data/ do projeto."""
    for sub in ["pdfs", "pdfs_png", "descriptions", "chroma_db", "uploads"]:
        (tmp_path / sub).mkdir(parents=True, exist_ok=True)
    return tmp_path
```

- [ ] **Step 6: Sincronizar dependências**

```bash
cd "Projetos/Automatização Bruno"
uv sync --extra dev
```

Expected: `Resolved N packages` + `Installed N packages` sem erro. Cria `.venv/` e `uv.lock`.

- [ ] **Step 7: Verificar smoke ruff + mypy + pytest**

```bash
uv run ruff check src tests
uv run mypy src
uv run pytest
```

Expected: ruff "All checks passed", mypy "Success: no issues", pytest "no tests ran" (esperado, sem testes ainda).

- [ ] **Step 8: Commit**

```bash
git add "Projetos/Automatização Bruno/pyproject.toml" \
        "Projetos/Automatização Bruno/.env.example" \
        "Projetos/Automatização Bruno/README.md" \
        "Projetos/Automatização Bruno/src/__init__.py" \
        "Projetos/Automatização Bruno/tests/__init__.py" \
        "Projetos/Automatização Bruno/tests/conftest.py" \
        "Projetos/Automatização Bruno/uv.lock"
git commit -m "chore(bruno): bootstrap projeto Python (uv, deps, conftest)"
```

---

### Task 2: Config + logging estruturado

**Files:**
- Create: `Projetos/Automatização Bruno/src/config.py`
- Create: `Projetos/Automatização Bruno/src/logging_setup.py`
- Create: `Projetos/Automatização Bruno/tests/unit/__init__.py`
- Create: `Projetos/Automatização Bruno/tests/unit/test_config.py`

- [ ] **Step 1: Escrever teste failing para config**

`tests/unit/test_config.py`:
```python
"""Testa carregamento de configuração via env."""
import os

import pytest

from src.config import AppConfig, AppPhase


def test_config_loads_phase_a_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_PHASE", "A")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-ant-test")
    monkeypatch.setenv("OPENROUTER_API_KEY", "sk-or-test")
    monkeypatch.setenv("GOOGLE_AI_KEY", "g-test")
    monkeypatch.setenv("OPENAI_API_KEY", "sk-test")
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "123:abc")
    monkeypatch.setenv("TELEGRAM_ALLOWED_USER_IDS", "123,456")

    cfg = AppConfig()

    assert cfg.app_phase == AppPhase.A
    assert cfg.anthropic_api_key == "sk-ant-test"
    assert cfg.telegram_allowed_user_ids == [123, 456]


def test_config_phase_b_requires_sheets_creds(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_PHASE", "B")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "x")
    monkeypatch.setenv("OPENROUTER_API_KEY", "x")
    monkeypatch.setenv("GOOGLE_AI_KEY", "x")
    monkeypatch.setenv("OPENAI_API_KEY", "x")
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "x")
    monkeypatch.setenv("TELEGRAM_ALLOWED_USER_IDS", "1")
    monkeypatch.delenv("GOOGLE_SHEETS_CREDS_PATH", raising=False)

    with pytest.raises(ValueError, match="GOOGLE_SHEETS_CREDS_PATH"):
        AppConfig()
```

- [ ] **Step 2: Rodar teste, ver falhar**

```bash
uv run pytest tests/unit/test_config.py -v
```

Expected: FAIL — `ModuleNotFoundError: No module named 'src.config'`

- [ ] **Step 3: Implementar `src/config.py`**

```python
"""Configuração da aplicação carregada de variáveis de ambiente."""
from enum import Enum
from pathlib import Path

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppPhase(str, Enum):
    A = "A"
    B = "B"


class AppConfig(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # LLM
    anthropic_api_key: str
    openrouter_api_key: str

    # Embedding
    google_ai_key: str
    openai_api_key: str

    # Telegram
    telegram_bot_token: str
    telegram_allowed_user_ids: list[int] = Field(default_factory=list)

    # Phase
    app_phase: AppPhase = AppPhase.A

    # Storage Fase B
    google_sheets_creds_path: Path | None = None
    google_sheet_id: str | None = None

    # Paths
    chroma_path: Path = Path("./data/chroma_db")
    excel_path: Path = Path("./data/saldos.xlsx")
    uploads_path: Path = Path("./data/uploads")
    logs_path: Path = Path("./logs")
    log_level: str = "INFO"

    @field_validator("telegram_allowed_user_ids", mode="before")
    @classmethod
    def _split_ids(cls, v: str | list[int]) -> list[int]:
        if isinstance(v, str):
            return [int(x.strip()) for x in v.split(",") if x.strip()]
        return v

    @model_validator(mode="after")
    def _validate_phase_b_creds(self) -> "AppConfig":
        if self.app_phase == AppPhase.B and not self.google_sheets_creds_path:
            raise ValueError("GOOGLE_SHEETS_CREDS_PATH é obrigatório em APP_PHASE=B")
        return self
```

- [ ] **Step 4: Rodar teste, ver passar**

```bash
uv run pytest tests/unit/test_config.py -v
```

Expected: 2 passed.

- [ ] **Step 5: Implementar `src/logging_setup.py`**

```python
"""Configuração centralizada de logging estruturado (structlog JSON)."""
import logging
import sys
from pathlib import Path

import structlog


def setup_logging(level: str = "INFO", logs_path: Path = Path("./logs")) -> None:
    logs_path.mkdir(parents=True, exist_ok=True)
    log_file = logs_path / "app.log"

    handlers: list[logging.Handler] = [
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(log_file, encoding="utf-8"),
    ]

    logging.basicConfig(
        format="%(message)s",
        level=getattr(logging, level.upper()),
        handlers=handlers,
    )

    structlog.configure(
        processors=[
            structlog.stdlib.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )


def get_logger(name: str) -> structlog.stdlib.BoundLogger:
    return structlog.get_logger(name)
```

- [ ] **Step 6: Smoke logger manual**

```bash
uv run python -c "from src.logging_setup import setup_logging, get_logger; setup_logging(); get_logger('smoke').info('hello', test=True)"
```

Expected: linha JSON em stdout com `"event": "hello"`, `"test": true`, `"timestamp"`, `"level": "info"`.

- [ ] **Step 7: Commit**

```bash
git add "Projetos/Automatização Bruno/src/config.py" \
        "Projetos/Automatização Bruno/src/logging_setup.py" \
        "Projetos/Automatização Bruno/tests/unit/__init__.py" \
        "Projetos/Automatização Bruno/tests/unit/test_config.py"
git commit -m "feat(bruno): config validada (pydantic) + logging structlog JSON"
```

---

### Task 3: Smoke test das 4 APIs externas

**Files:**
- Create: `Projetos/Automatização Bruno/scripts/smoke_apis.py`
- Create: `Projetos/Automatização Bruno/src/models.py`
- Create: `Projetos/Automatização Bruno/tests/unit/test_models.py`

- [ ] **Step 1: Escrever teste failing para models**

`tests/unit/test_models.py`:
```python
"""Testa dataclasses de domínio."""
from datetime import datetime, timezone

from src.models import (
    ClassificationResult,
    IdentifiedPart,
    Movimentacao,
    SaldoLote,
)


def test_identified_part_serializes_to_dict() -> None:
    part = IdentifiedPart(code="06332", description="Base Coluna", confidence_score=0.98)
    assert part.code == "06332"
    assert part.confidence_score == 0.98


def test_classification_result_with_alternatives() -> None:
    result = ClassificationResult(
        transaction_id="BRUNO-2026-0001",
        identified_part=IdentifiedPart(code="06332", description="Base", confidence_score=0.98),
        alternatives=[IdentifiedPart(code="06351", description="X", confidence_score=0.45)],
        reasoning="4 furos + recorte X",
        source_image_url="data/uploads/1.jpg",
    )
    assert result.identified_part.code == "06332"
    assert len(result.alternatives) == 1


def test_saldo_lote_immutable_fields() -> None:
    lote = SaldoLote(
        lote_id="LOT-2026-001",
        codigo_peca="06332",
        nf_origem="NF-12345",
        qty_original=200.0,
        qty_disponivel=156.0,
        data_entrada=datetime(2026, 4, 15, tzinfo=timezone.utc),
    )
    assert lote.qty_disponivel < lote.qty_original


def test_movimentacao_creation() -> None:
    mov = Movimentacao(
        timestamp=datetime.now(tz=timezone.utc),
        codigo_peca="06332",
        qty_baixada=34.0,
        lote_baixado="LOT-2026-001",
        nf_baixada="NF-12345",
        foto_url="data/uploads/1.jpg",
        confirmado_por="bruno",
        confidence_inicial=0.98,
    )
    assert mov.qty_baixada == 34.0
```

- [ ] **Step 2: Rodar teste, ver falhar**

```bash
uv run pytest tests/unit/test_models.py -v
```

Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 3: Implementar `src/models.py`**

```python
"""Modelos de domínio (dataclasses Pydantic v2)."""
from datetime import datetime
from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field


class TransactionState(str, Enum):
    RECEBIDO = "RECEBIDO"
    IDENTIFICADO = "IDENTIFICADO"
    AGUARDANDO_CONFIRMACAO = "AGUARDANDO_CONFIRMACAO"
    CONFIRMADO = "CONFIRMADO"
    LANCADO = "LANCADO"
    ARQUIVADO = "ARQUIVADO"
    CANCELADO = "CANCELADO"


class IdentifiedPart(BaseModel):
    code: str
    description: str
    confidence_score: float = Field(ge=0.0, le=1.0)


class ProductionData(BaseModel):
    quantity: float | None = None
    unit: str = "PC"
    timestamp: datetime


class ClassificationResult(BaseModel):
    transaction_id: str
    identified_part: IdentifiedPart
    alternatives: list[IdentifiedPart] = Field(default_factory=list)
    reasoning: str
    source_image_url: str
    production_data: ProductionData | None = None
    llm_provider_used: Literal["anthropic", "openrouter"] | None = None
    embedding_provider_used: Literal["google", "openai"] | None = None


class SaldoLote(BaseModel):
    lote_id: str
    codigo_peca: str
    nf_origem: str
    qty_original: float
    qty_disponivel: float
    data_entrada: datetime


class Movimentacao(BaseModel):
    timestamp: datetime
    codigo_peca: str
    qty_baixada: float
    lote_baixado: str
    nf_baixada: str
    foto_url: str
    confirmado_por: str
    confidence_inicial: float


class PartCandidate(BaseModel):
    code: str
    distance: float
    metadata: dict[str, str]


class Card(BaseModel):
    text: str
    inline_buttons: list[tuple[str, str]]  # (label, callback_data)
    photo_url: str | None = None


class CardResponse(BaseModel):
    callback_data: str
    user_id: int
```

- [ ] **Step 4: Rodar teste, ver passar**

```bash
uv run pytest tests/unit/test_models.py -v
```

Expected: 4 passed.

- [ ] **Step 5: Implementar `scripts/smoke_apis.py`**

```python
"""Smoke test das 4 APIs externas. Roda manual com credenciais reais.

Uso:
    uv run scripts/smoke_apis.py
"""
import asyncio
import sys

import httpx
from anthropic import AsyncAnthropic
from google import genai
from openai import AsyncOpenAI

from src.config import AppConfig
from src.logging_setup import get_logger, setup_logging


async def test_anthropic(cfg: AppConfig) -> bool:
    client = AsyncAnthropic(api_key=cfg.anthropic_api_key)
    try:
        msg = await client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=10,
            messages=[{"role": "user", "content": "Diga 'pong'"}],
        )
        return "pong" in (msg.content[0].text if msg.content else "").lower()
    except Exception as e:
        get_logger("smoke").error("anthropic_failed", error=str(e))
        return False


async def test_openrouter(cfg: AppConfig) -> bool:
    async with httpx.AsyncClient(timeout=30) as http:
        try:
            r = await http.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={"Authorization": f"Bearer {cfg.openrouter_api_key}"},
                json={
                    "model": "anthropic/claude-sonnet-4-6",
                    "messages": [{"role": "user", "content": "Diga 'pong'"}],
                    "max_tokens": 10,
                },
            )
            r.raise_for_status()
            content = r.json()["choices"][0]["message"]["content"]
            return "pong" in content.lower()
        except Exception as e:
            get_logger("smoke").error("openrouter_failed", error=str(e))
            return False


async def test_google_embedding(cfg: AppConfig) -> bool:
    client = genai.Client(api_key=cfg.google_ai_key)
    try:
        result = client.models.embed_content(
            model="gemini-embedding-2-preview",
            contents="ping",
        )
        return len(result.embeddings[0].values) > 0
    except Exception as e:
        get_logger("smoke").error("google_failed", error=str(e))
        return False


async def test_openai_embedding(cfg: AppConfig) -> bool:
    client = AsyncOpenAI(api_key=cfg.openai_api_key)
    try:
        r = await client.embeddings.create(
            model="text-embedding-3-small",
            input="ping",
            dimensions=768,
        )
        return len(r.data[0].embedding) == 768
    except Exception as e:
        get_logger("smoke").error("openai_failed", error=str(e))
        return False


async def main() -> int:
    setup_logging()
    log = get_logger("smoke")
    cfg = AppConfig()

    results = {
        "anthropic": await test_anthropic(cfg),
        "openrouter": await test_openrouter(cfg),
        "google_embedding": await test_google_embedding(cfg),
        "openai_embedding": await test_openai_embedding(cfg),
    }

    for api, ok in results.items():
        log.info("smoke_result", api=api, ok=ok)

    return 0 if all(results.values()) else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
```

- [ ] **Step 6: Rodar smoke test (precisa `.env` real)**

```bash
uv run scripts/smoke_apis.py
```

Expected: 4 linhas JSON com `"ok": true` e exit 0. Se algum falhar, **STOP** e investigar credencial/quota antes de prosseguir.

- [ ] **Step 7: Commit**

```bash
git add "Projetos/Automatização Bruno/src/models.py" \
        "Projetos/Automatização Bruno/scripts/smoke_apis.py" \
        "Projetos/Automatização Bruno/tests/unit/test_models.py"
git commit -m "feat(bruno): modelos pydantic + smoke test das 4 APIs"
```

**🚦 GATE INTERNO POC-A-0:** Sprint 0 fechado quando smoke test passa para todas as 4 APIs.

---

# SPRINT 1 — Adapters de provider e vector store (T4-T10) — Estimado 8-10h

Objetivo: as 5 abstrações principais (LLM, Embedding, VectorStore) implementadas e testadas com mocks. Fallback comprovado.

---

### Task 4: EmbeddingProvider base + GoogleProvider

**Files:**
- Create: `src/providers/__init__.py`
- Create: `src/providers/embedding/__init__.py`
- Create: `src/providers/embedding/base.py`
- Create: `src/providers/embedding/google.py`

- [ ] **Step 1: Criar pacotes vazios**

```bash
touch src/providers/__init__.py src/providers/embedding/__init__.py
```

- [ ] **Step 2: Implementar `src/providers/embedding/base.py`**

```python
"""Protocol para providers de embedding."""
from typing import Protocol


class EmbeddingProvider(Protocol):
    name: str

    async def embed(self, text: str) -> list[float]: ...
```

- [ ] **Step 3: Implementar `src/providers/embedding/google.py`**

```python
"""GoogleProvider — embedding via gemini-embedding-2-preview."""
import asyncio

from google import genai

from src.logging_setup import get_logger

_log = get_logger(__name__)


class GoogleProvider:
    name = "google"

    def __init__(self, api_key: str, model: str = "gemini-embedding-2-preview") -> None:
        self._client = genai.Client(api_key=api_key)
        self._model = model

    async def embed(self, text: str) -> list[float]:
        # google-genai SDK é síncrono; envolver em to_thread para não bloquear loop.
        result = await asyncio.to_thread(
            self._client.models.embed_content,
            model=self._model,
            contents=text,
        )
        embedding = result.embeddings[0].values
        _log.debug("google_embed", dim=len(embedding))
        return list(embedding)
```

- [ ] **Step 4: Smoke manual rápido**

```bash
uv run python -c "
import asyncio
from src.config import AppConfig
from src.providers.embedding.google import GoogleProvider

async def main():
    cfg = AppConfig()
    p = GoogleProvider(api_key=cfg.google_ai_key)
    v = await p.embed('peça base com 4 furos')
    print(f'OK: dim={len(v)}, first={v[0]:.4f}')

asyncio.run(main())
"
```

Expected: `OK: dim=768, first=...` (o número exato pode variar).

- [ ] **Step 5: Commit**

```bash
git add "Projetos/Automatização Bruno/src/providers/"
git commit -m "feat(bruno): EmbeddingProvider Protocol + GoogleProvider (gemini-embedding-2-preview)"
```

---

### Task 5: OpenAIProvider para embedding

**Files:**
- Create: `src/providers/embedding/openai.py`

- [ ] **Step 1: Implementar `src/providers/embedding/openai.py`**

```python
"""OpenAIProvider — embedding fallback via text-embedding-3-small dim=768."""
from openai import AsyncOpenAI

from src.logging_setup import get_logger

_log = get_logger(__name__)


class OpenAIProvider:
    name = "openai"

    def __init__(
        self,
        api_key: str,
        model: str = "text-embedding-3-small",
        dimensions: int = 768,
    ) -> None:
        self._client = AsyncOpenAI(api_key=api_key)
        self._model = model
        self._dimensions = dimensions

    async def embed(self, text: str) -> list[float]:
        r = await self._client.embeddings.create(
            model=self._model,
            input=text,
            dimensions=self._dimensions,
        )
        embedding = r.data[0].embedding
        _log.debug("openai_embed", dim=len(embedding))
        return embedding
```

- [ ] **Step 2: Smoke manual**

```bash
uv run python -c "
import asyncio
from src.config import AppConfig
from src.providers.embedding.openai import OpenAIProvider

async def main():
    cfg = AppConfig()
    p = OpenAIProvider(api_key=cfg.openai_api_key)
    v = await p.embed('peça base com 4 furos')
    print(f'OK: dim={len(v)}, first={v[0]:.4f}')

asyncio.run(main())
"
```

Expected: `OK: dim=768, first=...`.

- [ ] **Step 3: Commit**

```bash
git add "Projetos/Automatização Bruno/src/providers/embedding/openai.py"
git commit -m "feat(bruno): OpenAIProvider para embedding (text-embedding-3-small dim=768)"
```

---

### Task 6: ResilientEmbedding (composer com fallback + circuit breaker)

**Files:**
- Create: `src/providers/embedding/resilient.py`
- Create: `tests/unit/test_resilient_embedding.py`

- [ ] **Step 1: Escrever testes failing**

`tests/unit/test_resilient_embedding.py`:
```python
"""Testa fallback + circuit breaker do ResilientEmbedding."""
import asyncio

import pytest

from src.providers.embedding.resilient import ResilientEmbedding


class FakeProvider:
    def __init__(self, name: str, fail_n_times: int = 0, vector: list[float] | None = None) -> None:
        self.name = name
        self._fail_remaining = fail_n_times
        self._vector = vector or [0.1] * 768
        self.call_count = 0

    async def embed(self, text: str) -> list[float]:
        self.call_count += 1
        if self._fail_remaining > 0:
            self._fail_remaining -= 1
            raise RuntimeError(f"{self.name} simulated failure")
        return self._vector


async def test_primary_success_no_fallback() -> None:
    primary = FakeProvider("p", vector=[1.0] * 768)
    fallback = FakeProvider("f", vector=[2.0] * 768)
    r = ResilientEmbedding(primary=primary, fallback=fallback)

    vec, used = await r.embed_with_provider("texto")

    assert vec == [1.0] * 768
    assert used == "p"
    assert primary.call_count == 1
    assert fallback.call_count == 0


async def test_primary_fails_then_fallback_used() -> None:
    primary = FakeProvider("p", fail_n_times=10)
    fallback = FakeProvider("f", vector=[2.0] * 768)
    r = ResilientEmbedding(primary=primary, fallback=fallback, primary_retry=2)

    vec, used = await r.embed_with_provider("texto")

    assert vec == [2.0] * 768
    assert used == "f"
    assert primary.call_count == 3  # 1 inicial + 2 retries
    assert fallback.call_count == 1


async def test_circuit_breaker_skips_primary_after_threshold() -> None:
    primary = FakeProvider("p", fail_n_times=100)
    fallback = FakeProvider("f", vector=[2.0] * 768)
    r = ResilientEmbedding(
        primary=primary,
        fallback=fallback,
        primary_retry=0,
        breaker_threshold=2,
        breaker_cooldown_s=60,
    )

    # 1ª chamada: primary falha 1x → fallback
    await r.embed_with_provider("a")
    # 2ª chamada: primary falha 2x → breaker abre
    await r.embed_with_provider("b")
    # 3ª chamada: breaker aberto → vai direto pro fallback, primary não chamado
    primary_calls_before = primary.call_count
    await r.embed_with_provider("c")
    assert primary.call_count == primary_calls_before  # primary não foi chamado


async def test_both_fail_raises() -> None:
    primary = FakeProvider("p", fail_n_times=10)
    fallback = FakeProvider("f", fail_n_times=10)
    r = ResilientEmbedding(primary=primary, fallback=fallback, primary_retry=1)

    with pytest.raises(RuntimeError, match="all providers failed"):
        await r.embed_with_provider("texto")
```

- [ ] **Step 2: Rodar testes, ver falhar**

```bash
uv run pytest tests/unit/test_resilient_embedding.py -v
```

Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 3: Implementar `src/providers/embedding/resilient.py`**

```python
"""ResilientEmbedding — composer com primário + fallback + circuit breaker simples."""
import asyncio
import time
from dataclasses import dataclass

from src.logging_setup import get_logger
from src.providers.embedding.base import EmbeddingProvider

_log = get_logger(__name__)


@dataclass
class _BreakerState:
    consecutive_failures: int = 0
    open_until: float = 0.0


class ResilientEmbedding:
    def __init__(
        self,
        primary: EmbeddingProvider,
        fallback: EmbeddingProvider,
        primary_retry: int = 2,
        retry_backoff_s: float = 2.0,
        breaker_threshold: int = 3,
        breaker_cooldown_s: float = 300.0,
    ) -> None:
        self._primary = primary
        self._fallback = fallback
        self._retry = primary_retry
        self._backoff = retry_backoff_s
        self._breaker_threshold = breaker_threshold
        self._breaker_cooldown = breaker_cooldown_s
        self._breaker = _BreakerState()

    async def embed_with_provider(self, text: str) -> tuple[list[float], str]:
        """Retorna (embedding, nome_do_provider_usado)."""
        if self._breaker_open():
            _log.info("breaker_open_skipping_primary", primary=self._primary.name)
            vec = await self._fallback.embed(text)
            return vec, self._fallback.name

        last_exc: Exception | None = None
        for attempt in range(self._retry + 1):
            try:
                vec = await self._primary.embed(text)
                self._record_success()
                return vec, self._primary.name
            except Exception as e:
                last_exc = e
                _log.warning(
                    "primary_embed_failed",
                    provider=self._primary.name,
                    attempt=attempt,
                    error=str(e),
                )
                if attempt < self._retry:
                    await asyncio.sleep(self._backoff * (2**attempt))

        self._record_failure()

        try:
            vec = await self._fallback.embed(text)
            return vec, self._fallback.name
        except Exception as e:
            raise RuntimeError(
                f"all providers failed: primary={last_exc!r} fallback={e!r}"
            ) from e

    async def embed(self, text: str) -> list[float]:
        vec, _ = await self.embed_with_provider(text)
        return vec

    @property
    def name(self) -> str:
        return f"resilient({self._primary.name}+{self._fallback.name})"

    def _breaker_open(self) -> bool:
        return time.monotonic() < self._breaker.open_until

    def _record_success(self) -> None:
        self._breaker.consecutive_failures = 0

    def _record_failure(self) -> None:
        self._breaker.consecutive_failures += 1
        if self._breaker.consecutive_failures >= self._breaker_threshold:
            self._breaker.open_until = time.monotonic() + self._breaker_cooldown
            _log.error(
                "breaker_opened",
                provider=self._primary.name,
                cooldown_s=self._breaker_cooldown,
            )
```

- [ ] **Step 4: Rodar testes, ver passar**

```bash
uv run pytest tests/unit/test_resilient_embedding.py -v
```

Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add "Projetos/Automatização Bruno/src/providers/embedding/resilient.py" \
        "Projetos/Automatização Bruno/tests/unit/test_resilient_embedding.py"
git commit -m "feat(bruno): ResilientEmbedding com retry, fallback e circuit breaker"
```

---

### Task 7: LLMProvider base + AnthropicProvider

**Files:**
- Create: `src/providers/llm/__init__.py`
- Create: `src/providers/llm/base.py`
- Create: `src/providers/llm/anthropic.py`

- [ ] **Step 1: Criar pacote**

```bash
touch src/providers/llm/__init__.py
```

- [ ] **Step 2: Implementar `src/providers/llm/base.py`**

```python
"""Protocol para LLMProvider."""
from typing import Protocol

from src.models import ClassificationResult


class CandidateImage:
    """Candidato exibido ao Sonnet para classificar."""

    def __init__(self, code: str, png_bytes: bytes, description: str) -> None:
        self.code = code
        self.png_bytes = png_bytes
        self.description = description


class LLMProvider(Protocol):
    name: str

    async def describe_geometry(self, image_bytes: bytes) -> str: ...

    async def vision_classify(
        self,
        photo_bytes: bytes,
        candidates: list[CandidateImage],
        transaction_id: str,
    ) -> ClassificationResult: ...
```

- [ ] **Step 3: Implementar `src/providers/llm/anthropic.py`**

```python
"""AnthropicProvider — Claude Sonnet via Anthropic SDK direto."""
import base64
import json

from anthropic import AsyncAnthropic

from src.logging_setup import get_logger
from src.models import ClassificationResult, IdentifiedPart, ProductionData
from src.providers.llm.base import CandidateImage

_log = get_logger(__name__)


GEOMETRY_PROMPT = """Atue como um Engenheiro de Qualidade Industrial. \
Descreva a peça nesta imagem com foco em:
1. Contagem e disposição de furos com diâmetro relativo
2. Formato do perímetro (regular, irregular, simétrico)
3. Recortes internos (padrão em 'X', concavidades, abas)
4. Proporção largura/altura aproximada
5. Particularidades visuais marcantes

Use linguagem objetiva, 200-400 palavras. Não cite dimensões absolutas; descreva geometria comparável.
Retorne apenas a descrição, sem preâmbulo."""


CLASSIFICATION_SYSTEM = """Você é um Engenheiro de Qualidade Industrial classificando uma peça \
em comparação com candidatas conhecidas. Analise a foto da peça desconhecida e compare \
visualmente com cada PNG de referência fornecida (que vêm dos PDFs CAD oficiais).

CRITÉRIOS DE ANÁLISE:
1. Contagem de furos e diâmetro aproximado
2. Formato do perímetro (irregular, simétrico, retangular)
3. Recortes internos (padrão em 'X' centralizado, concavidades)
4. Proporções relativas

RESTRIÇÃO: Retorne APENAS um objeto JSON válido com a estrutura abaixo.
Não adicione comentários, markdown, ou prefixos.

```json
{
  "code": "<código do PDF mais provável>",
  "confidence_score": <0.0 a 1.0>,
  "alternatives": [
    {"code": "<2º mais provável>", "confidence_score": <0.0 a 1.0>},
    {"code": "<3º mais provável>", "confidence_score": <0.0 a 1.0>}
  ],
  "reasoning": "<1-2 frases justificando a escolha geométrica>"
}
```"""


class AnthropicProvider:
    name = "anthropic"

    def __init__(self, api_key: str, model: str = "claude-sonnet-4-6") -> None:
        self._client = AsyncAnthropic(api_key=api_key)
        self._model = model

    async def describe_geometry(self, image_bytes: bytes) -> str:
        b64 = base64.standard_b64encode(image_bytes).decode("ascii")
        msg = await self._client.messages.create(
            model=self._model,
            max_tokens=1000,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/png",
                                "data": b64,
                            },
                        },
                        {"type": "text", "text": GEOMETRY_PROMPT},
                    ],
                }
            ],
        )
        text = "".join(b.text for b in msg.content if b.type == "text")
        _log.info("describe_geometry_ok", chars=len(text), provider=self.name)
        return text

    async def vision_classify(
        self,
        photo_bytes: bytes,
        candidates: list[CandidateImage],
        transaction_id: str,
    ) -> ClassificationResult:
        # Sonnet vê: foto desconhecida + N candidatos com seus códigos
        from datetime import datetime, timezone

        photo_b64 = base64.standard_b64encode(photo_bytes).decode("ascii")
        content: list[dict] = [
            {
                "type": "text",
                "text": "FOTO DA PEÇA DESCONHECIDA (a classificar):",
            },
            {
                "type": "image",
                "source": {"type": "base64", "media_type": "image/jpeg", "data": photo_b64},
            },
        ]
        # Bloco cacheável: candidatos repetidos entre chamadas terão hit
        for idx, cand in enumerate(candidates, start=1):
            cand_b64 = base64.standard_b64encode(cand.png_bytes).decode("ascii")
            content.append(
                {
                    "type": "text",
                    "text": f"CANDIDATO {idx} — código `{cand.code}`. Descrição: {cand.description}",
                }
            )
            content.append(
                {
                    "type": "image",
                    "source": {"type": "base64", "media_type": "image/png", "data": cand_b64},
                    "cache_control": {"type": "ephemeral"},
                }
            )
        content.append({"type": "text", "text": "Retorne o JSON conforme instruído."})

        msg = await self._client.messages.create(
            model=self._model,
            max_tokens=1500,
            system=CLASSIFICATION_SYSTEM,
            messages=[{"role": "user", "content": content}],
        )
        raw = "".join(b.text for b in msg.content if b.type == "text").strip()
        # Tolerar fences markdown se vierem
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
            raw = raw.strip()

        parsed = json.loads(raw)
        code = parsed["code"]
        candidate_by_code = {c.code: c for c in candidates}
        chosen_desc = candidate_by_code[code].description if code in candidate_by_code else ""

        return ClassificationResult(
            transaction_id=transaction_id,
            identified_part=IdentifiedPart(
                code=code,
                description=chosen_desc[:200],
                confidence_score=float(parsed["confidence_score"]),
            ),
            alternatives=[
                IdentifiedPart(
                    code=alt["code"],
                    description=candidate_by_code[alt["code"]].description[:200]
                    if alt["code"] in candidate_by_code
                    else "",
                    confidence_score=float(alt["confidence_score"]),
                )
                for alt in parsed.get("alternatives", [])
            ],
            reasoning=parsed.get("reasoning", ""),
            source_image_url="",  # preenchido pelo agent
            production_data=ProductionData(timestamp=datetime.now(tz=timezone.utc)),
            llm_provider_used="anthropic",
        )
```

- [ ] **Step 4: Smoke manual de describe_geometry**

```bash
uv run python -c "
import asyncio
from pathlib import Path
from src.config import AppConfig
from src.providers.llm.anthropic import AnthropicProvider

async def main():
    cfg = AppConfig()
    p = AnthropicProvider(api_key=cfg.anthropic_api_key)
    # use qualquer png pequeno como smoke
    img = Path('docs/referencias/infografico-conceitual.png').read_bytes()
    desc = await p.describe_geometry(img)
    print(f'OK: {len(desc)} chars\n{desc[:200]}...')

asyncio.run(main())
"
```

Expected: `OK: ~300 chars` + descrição da imagem.

- [ ] **Step 5: Commit**

```bash
git add "Projetos/Automatização Bruno/src/providers/llm/"
git commit -m "feat(bruno): LLMProvider Protocol + AnthropicProvider (sonnet-4-6, prompt geometric v0)"
```

---

### Task 8: OpenRouterProvider para LLM

**Files:**
- Create: `src/providers/llm/openrouter.py`

- [ ] **Step 1: Implementar `src/providers/llm/openrouter.py`**

```python
"""OpenRouterProvider — fallback que roteia mesmo modelo via OpenRouter."""
import base64
import json
from datetime import datetime, timezone

import httpx

from src.logging_setup import get_logger
from src.models import ClassificationResult, IdentifiedPart, ProductionData
from src.providers.llm.anthropic import CLASSIFICATION_SYSTEM, GEOMETRY_PROMPT
from src.providers.llm.base import CandidateImage

_log = get_logger(__name__)


class OpenRouterProvider:
    name = "openrouter"

    def __init__(
        self,
        api_key: str,
        model: str = "anthropic/claude-sonnet-4-6",
        base_url: str = "https://openrouter.ai/api/v1",
        timeout_s: float = 60.0,
    ) -> None:
        self._api_key = api_key
        self._model = model
        self._base_url = base_url
        self._timeout = timeout_s

    async def _post(self, payload: dict) -> dict:
        async with httpx.AsyncClient(timeout=self._timeout) as http:
            r = await http.post(
                f"{self._base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self._api_key}",
                    "HTTP-Referer": "https://thauma.consulting/automacao-bruno",
                    "X-Title": "Automacao Bruno POC",
                },
                json=payload,
            )
            r.raise_for_status()
            return r.json()

    async def describe_geometry(self, image_bytes: bytes) -> str:
        b64 = base64.standard_b64encode(image_bytes).decode("ascii")
        payload = {
            "model": self._model,
            "max_tokens": 1000,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": GEOMETRY_PROMPT},
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/png;base64,{b64}"},
                        },
                    ],
                }
            ],
        }
        r = await self._post(payload)
        text = r["choices"][0]["message"]["content"]
        _log.info("describe_geometry_ok", chars=len(text), provider=self.name)
        return text

    async def vision_classify(
        self,
        photo_bytes: bytes,
        candidates: list[CandidateImage],
        transaction_id: str,
    ) -> ClassificationResult:
        photo_b64 = base64.standard_b64encode(photo_bytes).decode("ascii")
        content: list[dict] = [
            {"type": "text", "text": "FOTO DA PEÇA DESCONHECIDA (a classificar):"},
            {
                "type": "image_url",
                "image_url": {"url": f"data:image/jpeg;base64,{photo_b64}"},
            },
        ]
        for idx, cand in enumerate(candidates, start=1):
            cand_b64 = base64.standard_b64encode(cand.png_bytes).decode("ascii")
            content.append(
                {
                    "type": "text",
                    "text": f"CANDIDATO {idx} — código `{cand.code}`. Descrição: {cand.description}",
                }
            )
            content.append(
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/png;base64,{cand_b64}"},
                }
            )
        content.append({"type": "text", "text": "Retorne o JSON conforme instruído."})

        payload = {
            "model": self._model,
            "max_tokens": 1500,
            "messages": [
                {"role": "system", "content": CLASSIFICATION_SYSTEM},
                {"role": "user", "content": content},
            ],
        }
        r = await self._post(payload)
        raw = r["choices"][0]["message"]["content"].strip()
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
            raw = raw.strip()

        parsed = json.loads(raw)
        code = parsed["code"]
        candidate_by_code = {c.code: c for c in candidates}
        chosen_desc = candidate_by_code[code].description if code in candidate_by_code else ""

        return ClassificationResult(
            transaction_id=transaction_id,
            identified_part=IdentifiedPart(
                code=code,
                description=chosen_desc[:200],
                confidence_score=float(parsed["confidence_score"]),
            ),
            alternatives=[
                IdentifiedPart(
                    code=alt["code"],
                    description=candidate_by_code[alt["code"]].description[:200]
                    if alt["code"] in candidate_by_code
                    else "",
                    confidence_score=float(alt["confidence_score"]),
                )
                for alt in parsed.get("alternatives", [])
            ],
            reasoning=parsed.get("reasoning", ""),
            source_image_url="",
            production_data=ProductionData(timestamp=datetime.now(tz=timezone.utc)),
            llm_provider_used="openrouter",
        )
```

- [ ] **Step 2: Smoke manual**

```bash
uv run python -c "
import asyncio
from pathlib import Path
from src.config import AppConfig
from src.providers.llm.openrouter import OpenRouterProvider

async def main():
    cfg = AppConfig()
    p = OpenRouterProvider(api_key=cfg.openrouter_api_key)
    img = Path('docs/referencias/infografico-conceitual.png').read_bytes()
    desc = await p.describe_geometry(img)
    print(f'OK via OpenRouter: {len(desc)} chars\n{desc[:200]}...')

asyncio.run(main())
"
```

Expected: descrição válida via rota OpenRouter.

- [ ] **Step 3: Commit**

```bash
git add "Projetos/Automatização Bruno/src/providers/llm/openrouter.py"
git commit -m "feat(bruno): OpenRouterProvider (rota anthropic/claude-sonnet-4-6)"
```

---

### Task 9: ResilientLLM (composer)

**Files:**
- Create: `src/providers/llm/resilient.py`
- Create: `tests/unit/test_resilient_llm.py`

- [ ] **Step 1: Escrever testes failing**

`tests/unit/test_resilient_llm.py`:
```python
"""Testa fallback do ResilientLLM."""
import pytest

from src.models import ClassificationResult, IdentifiedPart, ProductionData
from src.providers.llm.base import CandidateImage
from src.providers.llm.resilient import ResilientLLM
from datetime import datetime, timezone


class FakeLLM:
    def __init__(self, name: str, fail_n: int = 0) -> None:
        self.name = name
        self._fail = fail_n
        self.classify_calls = 0
        self.describe_calls = 0

    async def describe_geometry(self, image_bytes: bytes) -> str:
        self.describe_calls += 1
        if self._fail > 0:
            self._fail -= 1
            raise RuntimeError(f"{self.name} simulated failure")
        return f"desc by {self.name}"

    async def vision_classify(
        self, photo_bytes: bytes, candidates: list[CandidateImage], transaction_id: str
    ) -> ClassificationResult:
        self.classify_calls += 1
        if self._fail > 0:
            self._fail -= 1
            raise RuntimeError(f"{self.name} simulated failure")
        return ClassificationResult(
            transaction_id=transaction_id,
            identified_part=IdentifiedPart(code="X", description="d", confidence_score=0.9),
            reasoning=f"by {self.name}",
            source_image_url="",
            production_data=ProductionData(timestamp=datetime.now(tz=timezone.utc)),
            llm_provider_used=self.name,  # type: ignore
        )


async def test_describe_primary_ok() -> None:
    p = FakeLLM("anthropic")
    f = FakeLLM("openrouter")
    r = ResilientLLM(primary=p, fallback=f)

    desc = await r.describe_geometry(b"x")
    assert desc == "desc by anthropic"
    assert f.describe_calls == 0


async def test_describe_falls_back_when_primary_fails() -> None:
    p = FakeLLM("anthropic", fail_n=10)
    f = FakeLLM("openrouter")
    r = ResilientLLM(primary=p, fallback=f, primary_retry=1)

    desc = await r.describe_geometry(b"x")
    assert desc == "desc by openrouter"
    assert p.describe_calls == 2
    assert f.describe_calls == 1


async def test_classify_falls_back_when_primary_fails() -> None:
    p = FakeLLM("anthropic", fail_n=10)
    f = FakeLLM("openrouter")
    r = ResilientLLM(primary=p, fallback=f, primary_retry=1)

    result = await r.vision_classify(b"x", [], "T-1")
    assert result.identified_part.code == "X"
    assert p.classify_calls == 2
    assert f.classify_calls == 1


async def test_both_fail_raises() -> None:
    p = FakeLLM("anthropic", fail_n=10)
    f = FakeLLM("openrouter", fail_n=10)
    r = ResilientLLM(primary=p, fallback=f, primary_retry=1)

    with pytest.raises(RuntimeError, match="all LLM providers failed"):
        await r.describe_geometry(b"x")
```

- [ ] **Step 2: Rodar teste, ver falhar**

```bash
uv run pytest tests/unit/test_resilient_llm.py -v
```

Expected: FAIL.

- [ ] **Step 3: Implementar `src/providers/llm/resilient.py`**

```python
"""ResilientLLM — composer com primário + fallback + circuit breaker."""
import asyncio
import time
from dataclasses import dataclass

from src.logging_setup import get_logger
from src.models import ClassificationResult
from src.providers.llm.base import CandidateImage, LLMProvider

_log = get_logger(__name__)


@dataclass
class _BreakerState:
    consecutive_failures: int = 0
    open_until: float = 0.0


class ResilientLLM:
    def __init__(
        self,
        primary: LLMProvider,
        fallback: LLMProvider,
        primary_retry: int = 2,
        retry_backoff_s: float = 2.0,
        breaker_threshold: int = 3,
        breaker_cooldown_s: float = 300.0,
    ) -> None:
        self._primary = primary
        self._fallback = fallback
        self._retry = primary_retry
        self._backoff = retry_backoff_s
        self._breaker_threshold = breaker_threshold
        self._breaker_cooldown = breaker_cooldown_s
        self._breaker = _BreakerState()

    @property
    def name(self) -> str:
        return f"resilient({self._primary.name}+{self._fallback.name})"

    async def describe_geometry(self, image_bytes: bytes) -> str:
        return await self._call_with_fallback(
            lambda p: p.describe_geometry(image_bytes), op_name="describe_geometry"
        )

    async def vision_classify(
        self,
        photo_bytes: bytes,
        candidates: list[CandidateImage],
        transaction_id: str,
    ) -> ClassificationResult:
        return await self._call_with_fallback(
            lambda p: p.vision_classify(photo_bytes, candidates, transaction_id),
            op_name="vision_classify",
        )

    async def _call_with_fallback(self, op, op_name: str):
        if self._breaker_open():
            _log.info("breaker_open_skipping_primary", primary=self._primary.name, op=op_name)
            return await op(self._fallback)

        last_exc: Exception | None = None
        for attempt in range(self._retry + 1):
            try:
                result = await op(self._primary)
                self._record_success()
                return result
            except Exception as e:
                last_exc = e
                _log.warning(
                    "primary_llm_failed",
                    provider=self._primary.name,
                    op=op_name,
                    attempt=attempt,
                    error=str(e),
                )
                if attempt < self._retry:
                    await asyncio.sleep(self._backoff * (2**attempt))

        self._record_failure()

        try:
            return await op(self._fallback)
        except Exception as e:
            raise RuntimeError(
                f"all LLM providers failed: primary={last_exc!r} fallback={e!r}"
            ) from e

    def _breaker_open(self) -> bool:
        return time.monotonic() < self._breaker.open_until

    def _record_success(self) -> None:
        self._breaker.consecutive_failures = 0

    def _record_failure(self) -> None:
        self._breaker.consecutive_failures += 1
        if self._breaker.consecutive_failures >= self._breaker_threshold:
            self._breaker.open_until = time.monotonic() + self._breaker_cooldown
            _log.error("llm_breaker_opened", primary=self._primary.name)
```

- [ ] **Step 4: Rodar testes, ver passar**

```bash
uv run pytest tests/unit/test_resilient_llm.py -v
```

Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add "Projetos/Automatização Bruno/src/providers/llm/resilient.py" \
        "Projetos/Automatização Bruno/tests/unit/test_resilient_llm.py"
git commit -m "feat(bruno): ResilientLLM (retry + fallback OpenRouter + circuit breaker)"
```

---

### Task 10: VectorStore ChromaDB com 2 coleções

**Files:**
- Create: `src/vectorstore/__init__.py`
- Create: `src/vectorstore/base.py`
- Create: `src/vectorstore/chroma.py`
- Create: `tests/unit/test_chroma_store.py`

- [ ] **Step 1: Criar pacote**

```bash
touch src/vectorstore/__init__.py
```

- [ ] **Step 2: Implementar `src/vectorstore/base.py`**

```python
"""Protocol para VectorStore."""
from typing import Protocol

from src.models import PartCandidate


class VectorStore(Protocol):
    def add(
        self,
        id: str,
        embedding: list[float],
        metadata: dict[str, str],
        provider_tag: str,
    ) -> None: ...

    def query(
        self, embedding: list[float], top_k: int, provider_tag: str
    ) -> list[PartCandidate]: ...
```

- [ ] **Step 3: Escrever teste failing**

`tests/unit/test_chroma_store.py`:
```python
"""Testa ChromaDBStore com duas coleções paralelas."""
from pathlib import Path

from src.vectorstore.chroma import ChromaDBStore


def test_add_and_query_in_google_collection(tmp_path: Path) -> None:
    store = ChromaDBStore(persist_path=tmp_path / "chroma")

    store.add(
        id="06332",
        embedding=[0.1] * 768,
        metadata={"description": "base com 4 furos"},
        provider_tag="google",
    )
    store.add(
        id="06351",
        embedding=[0.9] * 768,
        metadata={"description": "outra peça"},
        provider_tag="google",
    )

    results = store.query(embedding=[0.1] * 768, top_k=2, provider_tag="google")
    assert len(results) == 2
    assert results[0].code == "06332"  # mais próximo


def test_collections_isolated_by_tag(tmp_path: Path) -> None:
    store = ChromaDBStore(persist_path=tmp_path / "chroma")

    store.add(
        id="A", embedding=[0.1] * 768, metadata={"d": "x"}, provider_tag="google"
    )
    store.add(
        id="B", embedding=[0.1] * 768, metadata={"d": "y"}, provider_tag="openai"
    )

    google_results = store.query([0.1] * 768, top_k=10, provider_tag="google")
    openai_results = store.query([0.1] * 768, top_k=10, provider_tag="openai")

    assert {r.code for r in google_results} == {"A"}
    assert {r.code for r in openai_results} == {"B"}
```

- [ ] **Step 4: Rodar teste, ver falhar**

```bash
uv run pytest tests/unit/test_chroma_store.py -v
```

Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 5: Implementar `src/vectorstore/chroma.py`**

```python
"""ChromaDBStore — persiste embeddings em duas coleções paralelas (google e openai)."""
from pathlib import Path

import chromadb
from chromadb.config import Settings

from src.logging_setup import get_logger
from src.models import PartCandidate

_log = get_logger(__name__)


_COLLECTIONS = {"google": "parts_google", "openai": "parts_openai"}


class ChromaDBStore:
    def __init__(self, persist_path: Path) -> None:
        persist_path.mkdir(parents=True, exist_ok=True)
        self._client = chromadb.PersistentClient(
            path=str(persist_path),
            settings=Settings(anonymized_telemetry=False),
        )
        # Garantir que as duas coleções existam
        for tag, name in _COLLECTIONS.items():
            self._client.get_or_create_collection(name=name, metadata={"provider": tag})

    def _coll(self, provider_tag: str):
        if provider_tag not in _COLLECTIONS:
            raise ValueError(f"provider_tag inválido: {provider_tag}")
        return self._client.get_or_create_collection(name=_COLLECTIONS[provider_tag])

    def add(
        self,
        id: str,
        embedding: list[float],
        metadata: dict[str, str],
        provider_tag: str,
    ) -> None:
        coll = self._coll(provider_tag)
        coll.upsert(ids=[id], embeddings=[embedding], metadatas=[metadata])
        _log.debug("chroma_add", id=id, provider=provider_tag, dim=len(embedding))

    def query(
        self, embedding: list[float], top_k: int, provider_tag: str
    ) -> list[PartCandidate]:
        coll = self._coll(provider_tag)
        result = coll.query(query_embeddings=[embedding], n_results=top_k)

        ids = result["ids"][0] if result["ids"] else []
        distances = result["distances"][0] if result["distances"] else []
        metadatas = result["metadatas"][0] if result["metadatas"] else []

        return [
            PartCandidate(code=id_, distance=float(dist), metadata=dict(meta or {}))
            for id_, dist, meta in zip(ids, distances, metadatas)
        ]
```

- [ ] **Step 6: Rodar testes, ver passar**

```bash
uv run pytest tests/unit/test_chroma_store.py -v
```

Expected: 2 passed.

- [ ] **Step 7: Commit**

```bash
git add "Projetos/Automatização Bruno/src/vectorstore/" \
        "Projetos/Automatização Bruno/tests/unit/test_chroma_store.py"
git commit -m "feat(bruno): ChromaDBStore com 2 coleções (google/openai) isoladas por tag"
```

**🚦 GATE INTERNO POC-A-1:** Sprint 1 fechado. Adapters principais funcionam isolados.

---

# SPRINT 2 — Pipeline de ingestão (T11-T13) — Estimado 4-6h

Objetivo: PDFs → ChromaDB indexado. Script `ingest.py` executável manualmente.

---

### Task 11: PDF → PNG (PyMuPDF)

**Files:**
- Create: `src/ingestion/__init__.py`
- Create: `src/ingestion/pdf_to_png.py`
- Create: `tests/unit/test_pdf_to_png.py`
- Create: `tests/fixtures/.gitkeep`

- [ ] **Step 1: Criar pacote e fixtures dir**

```bash
touch src/ingestion/__init__.py tests/fixtures/.gitkeep
```

- [ ] **Step 2: Pedro fornecer 1 PDF de teste**

> **AÇÃO MANUAL:** Pedro coloca um PDF de exemplo em `tests/fixtures/pdf_sample.pdf` (qualquer PDF, idealmente um dos que o Bruno enviou).

- [ ] **Step 3: Escrever teste failing**

`tests/unit/test_pdf_to_png.py`:
```python
"""Testa conversão PDF → PNG via PyMuPDF."""
from pathlib import Path

import pytest

from src.ingestion.pdf_to_png import convert_pdf_to_png


def test_pdf_renders_png(fixtures_dir: Path, tmp_path: Path) -> None:
    pdf = fixtures_dir / "pdf_sample.pdf"
    if not pdf.exists():
        pytest.skip("fixture pdf_sample.pdf ausente — Pedro precisa fornecer")

    png = tmp_path / "out.png"
    convert_pdf_to_png(pdf, png, dpi=300)

    assert png.exists()
    assert png.stat().st_size > 1000  # pelo menos 1KB


def test_pdf_first_page_only(fixtures_dir: Path, tmp_path: Path) -> None:
    pdf = fixtures_dir / "pdf_sample.pdf"
    if not pdf.exists():
        pytest.skip("fixture pdf_sample.pdf ausente")

    png = tmp_path / "out.png"
    # Não deve falhar mesmo se PDF tem múltiplas páginas
    convert_pdf_to_png(pdf, png)
    assert png.exists()
```

- [ ] **Step 4: Rodar teste, ver falhar**

```bash
uv run pytest tests/unit/test_pdf_to_png.py -v
```

Expected: FAIL — `ModuleNotFoundError`.

- [ ] **Step 5: Implementar `src/ingestion/pdf_to_png.py`**

```python
"""Converte PDF (página 1) em PNG de alta fidelidade."""
from pathlib import Path

import pymupdf  # type: ignore[import-not-found]

from src.logging_setup import get_logger

_log = get_logger(__name__)


def convert_pdf_to_png(pdf_path: Path, output_path: Path, dpi: int = 300) -> None:
    """Renderiza a página 1 do PDF em PNG escala de cinza com fundo branco."""
    doc = pymupdf.open(pdf_path)
    try:
        if doc.page_count == 0:
            raise ValueError(f"PDF vazio: {pdf_path}")
        page = doc[0]
        zoom = dpi / 72.0  # PyMuPDF default é 72 DPI
        matrix = pymupdf.Matrix(zoom, zoom)
        # colorspace=GRAY para reduzir tamanho; alpha=False para fundo branco
        pix = page.get_pixmap(matrix=matrix, colorspace=pymupdf.csGRAY, alpha=False)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        pix.save(str(output_path))
        _log.info(
            "pdf_to_png",
            pdf=str(pdf_path),
            png=str(output_path),
            dpi=dpi,
            size_kb=output_path.stat().st_size // 1024,
        )
    finally:
        doc.close()
```

- [ ] **Step 6: Rodar testes**

```bash
uv run pytest tests/unit/test_pdf_to_png.py -v
```

Expected: 2 passed (ou 2 skipped se Pedro ainda não forneceu PDF).

- [ ] **Step 7: Commit**

```bash
git add "Projetos/Automatização Bruno/src/ingestion/" \
        "Projetos/Automatização Bruno/tests/unit/test_pdf_to_png.py" \
        "Projetos/Automatização Bruno/tests/fixtures/.gitkeep"
git commit -m "feat(bruno): conversor PDF→PNG via PyMuPDF (300dpi grayscale)"
```

---

### Task 12: Geometry describer (Sonnet com prompt v0)

**Files:**
- Create: `src/ingestion/geometry_describer.py`
- Create: `tests/unit/test_geometry_describer.py`

- [ ] **Step 1: Escrever teste failing (com mock)**

`tests/unit/test_geometry_describer.py`:
```python
"""Testa wrapper geometry_describer (chamada delegada ao LLMProvider)."""
from unittest.mock import AsyncMock

from src.ingestion.geometry_describer import describe_pdf_png


async def test_describe_calls_llm_provider() -> None:
    fake_llm = AsyncMock()
    fake_llm.describe_geometry.return_value = "desc longa..."

    desc = await describe_pdf_png(b"png_bytes", fake_llm)

    fake_llm.describe_geometry.assert_awaited_once_with(b"png_bytes")
    assert desc == "desc longa..."
```

- [ ] **Step 2: Rodar, ver falhar**

```bash
uv run pytest tests/unit/test_geometry_describer.py -v
```

Expected: FAIL.

- [ ] **Step 3: Implementar `src/ingestion/geometry_describer.py`**

```python
"""Wrapper fino para geração de descrição geométrica via LLMProvider."""
from src.providers.llm.base import LLMProvider


async def describe_pdf_png(png_bytes: bytes, llm: LLMProvider) -> str:
    return await llm.describe_geometry(png_bytes)
```

- [ ] **Step 4: Rodar, ver passar**

```bash
uv run pytest tests/unit/test_geometry_describer.py -v
```

Expected: 1 passed.

- [ ] **Step 5: Commit**

```bash
git add "Projetos/Automatização Bruno/src/ingestion/geometry_describer.py" \
        "Projetos/Automatização Bruno/tests/unit/test_geometry_describer.py"
git commit -m "feat(bruno): wrapper describe_pdf_png delegando ao LLMProvider"
```

---

### Task 13: Script `ingest.py` end-to-end

**Files:**
- Create: `Projetos/Automatização Bruno/scripts/ingest.py`

- [ ] **Step 1: Implementar `scripts/ingest.py`**

```python
"""Script de ingestão offline: PDFs → PNGs → descrições → embeddings duais → ChromaDB.

Uso:
    uv run scripts/ingest.py [--pdf-dir PATH] [--limit N]

Lê PDFs de data/pdfs/ por padrão. Cada PDF deve ter nome no formato `<codigo>.pdf`
(o nome do arquivo vira o ID da peça).
"""
import argparse
import asyncio
import sys
from pathlib import Path

from src.config import AppConfig
from src.ingestion.geometry_describer import describe_pdf_png
from src.ingestion.pdf_to_png import convert_pdf_to_png
from src.logging_setup import get_logger, setup_logging
from src.providers.embedding.google import GoogleProvider
from src.providers.embedding.openai import OpenAIProvider
from src.providers.embedding.resilient import ResilientEmbedding
from src.providers.llm.anthropic import AnthropicProvider
from src.providers.llm.openrouter import OpenRouterProvider
from src.providers.llm.resilient import ResilientLLM
from src.vectorstore.chroma import ChromaDBStore


async def ingest_one(
    pdf: Path,
    png_dir: Path,
    desc_dir: Path,
    llm: ResilientLLM,
    google: GoogleProvider,
    openai: OpenAIProvider,
    store: ChromaDBStore,
    log,
) -> bool:
    codigo = pdf.stem
    png = png_dir / f"{codigo}.png"
    desc_file = desc_dir / f"{codigo}.txt"

    try:
        # 1. PDF → PNG (idempotente)
        if not png.exists():
            convert_pdf_to_png(pdf, png, dpi=300)

        # 2. Descrição via Sonnet (com fallback OpenRouter)
        if desc_file.exists():
            description = desc_file.read_text(encoding="utf-8")
            log.info("desc_cached", codigo=codigo)
        else:
            png_bytes = png.read_bytes()
            description = await describe_pdf_png(png_bytes, llm)
            desc_file.write_text(description, encoding="utf-8")

        # 3. Embedding dual
        emb_google = await google.embed(description)
        emb_openai = await openai.embed(description)

        meta = {"description": description[:500], "png_path": str(png)}
        store.add(id=codigo, embedding=emb_google, metadata=meta, provider_tag="google")
        store.add(id=codigo, embedding=emb_openai, metadata=meta, provider_tag="openai")

        log.info("ingest_ok", codigo=codigo)
        return True
    except Exception as e:
        log.error("ingest_failed", codigo=codigo, error=str(e))
        return False


async def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf-dir", type=Path, default=Path("data/pdfs"))
    parser.add_argument("--limit", type=int, default=None, help="Limita N PDFs (debug)")
    args = parser.parse_args()

    setup_logging()
    log = get_logger("ingest")
    cfg = AppConfig()

    pdf_dir: Path = args.pdf_dir
    if not pdf_dir.exists():
        log.error("pdf_dir_missing", path=str(pdf_dir))
        return 1

    pdfs = sorted(pdf_dir.glob("*.pdf"))
    if args.limit:
        pdfs = pdfs[: args.limit]
    log.info("ingest_start", total=len(pdfs))

    if not pdfs:
        log.error("no_pdfs_found")
        return 1

    png_dir = Path("data/pdfs_png")
    desc_dir = Path("data/descriptions")
    png_dir.mkdir(parents=True, exist_ok=True)
    desc_dir.mkdir(parents=True, exist_ok=True)

    llm = ResilientLLM(
        primary=AnthropicProvider(api_key=cfg.anthropic_api_key),
        fallback=OpenRouterProvider(api_key=cfg.openrouter_api_key),
    )
    google = GoogleProvider(api_key=cfg.google_ai_key)
    openai = OpenAIProvider(api_key=cfg.openai_api_key)
    store = ChromaDBStore(persist_path=cfg.chroma_path)

    ok_count = 0
    for pdf in pdfs:
        ok = await ingest_one(pdf, png_dir, desc_dir, llm, google, openai, store, log)
        if ok:
            ok_count += 1

    log.info("ingest_done", ok=ok_count, total=len(pdfs))
    return 0 if ok_count == len(pdfs) else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
```

- [ ] **Step 2: Pedro coloca subset de 30-50 PDFs em `data/pdfs/`**

> **AÇÃO MANUAL:** Cada PDF deve ter nome no formato `<codigo>.pdf` (ex: `06332.pdf`).
> Se Bruno enviou pasta com nomes não-padrão, Pedro renomeia ou ajusta script.

- [ ] **Step 3: Rodar ingest com `--limit 3` primeiro (sanity)**

```bash
uv run scripts/ingest.py --limit 3
```

Expected: 3 linhas `ingest_ok` + `ingest_done ok=3 total=3`. Tempo: ~1 min.

- [ ] **Step 4: Rodar ingest completo**

```bash
uv run scripts/ingest.py
```

Expected: ~30-50 PDFs em ~10-17 min (com embedding dual).
Verificar em `data/chroma_db/` que os arquivos foram criados.

- [ ] **Step 5: Smoke query manual**

```bash
uv run python -c "
from src.vectorstore.chroma import ChromaDBStore
from pathlib import Path
store = ChromaDBStore(Path('data/chroma_db'))
results = store.query(embedding=[0.0]*768, top_k=3, provider_tag='google')
print('Google collection:', [r.code for r in results])
results = store.query(embedding=[0.0]*768, top_k=3, provider_tag='openai')
print('OpenAI collection:', [r.code for r in results])
"
```

Expected: 3 códigos por coleção (mesmos códigos).

- [ ] **Step 6: Commit**

```bash
git add "Projetos/Automatização Bruno/scripts/ingest.py"
git commit -m "feat(bruno): script ingest.py end-to-end (PDFs → ChromaDB dual)"
```

**🚦 GATE INTERNO POC-A-2:** Sprint 2 fechado. ChromaDB indexado com 30-50 PDFs em ambas coleções.

---

# SPRINT 3 — Agente identificador (T14) — Estimado 3-4h

---

### Task 14: agent.identify (orquestração da Camada 2)

**Files:**
- Create: `src/agent/__init__.py`
- Create: `src/agent/identify.py`
- Create: `tests/unit/test_agent_identify.py`

- [ ] **Step 1: Criar pacote**

```bash
touch src/agent/__init__.py
```

- [ ] **Step 2: Escrever teste failing**

`tests/unit/test_agent_identify.py`:
```python
"""Testa orquestração do agente de identificação (com mocks)."""
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.agent.identify import IdentifierAgent
from src.models import (
    ClassificationResult,
    IdentifiedPart,
    PartCandidate,
    ProductionData,
)
from datetime import datetime, timezone


@pytest.fixture
def mock_llm() -> AsyncMock:
    llm = AsyncMock()
    llm.describe_geometry.return_value = "descrição da foto desconhecida"
    llm.vision_classify.return_value = ClassificationResult(
        transaction_id="T-1",
        identified_part=IdentifiedPart(code="06332", description="x", confidence_score=0.95),
        reasoning="ok",
        source_image_url="",
        production_data=ProductionData(timestamp=datetime.now(tz=timezone.utc)),
        llm_provider_used="anthropic",
    )
    return llm


@pytest.fixture
def mock_embedding() -> AsyncMock:
    emb = AsyncMock()
    emb.embed_with_provider.return_value = ([0.5] * 768, "google")
    return emb


@pytest.fixture
def mock_store() -> MagicMock:
    store = MagicMock()
    store.query.return_value = [
        PartCandidate(code="06332", distance=0.1, metadata={"description": "d1", "png_path": "p1"}),
        PartCandidate(code="06351", distance=0.5, metadata={"description": "d2", "png_path": "p2"}),
    ]
    return store


async def test_identify_pipeline_calls_all_layers(
    mock_llm: AsyncMock, mock_embedding: AsyncMock, mock_store: MagicMock, tmp_path: Path
) -> None:
    # criar pngs fake
    (tmp_path / "p1").write_bytes(b"fake_png_1")
    (tmp_path / "p2").write_bytes(b"fake_png_2")
    mock_store.query.return_value[0].metadata["png_path"] = str(tmp_path / "p1")
    mock_store.query.return_value[1].metadata["png_path"] = str(tmp_path / "p2")

    agent = IdentifierAgent(llm=mock_llm, embedding=mock_embedding, vector_store=mock_store)
    result = await agent.identify(
        photo_bytes=b"foto",
        uploads_dir=tmp_path,
        user_id=123,
    )

    mock_llm.describe_geometry.assert_awaited_once_with(b"foto")
    mock_embedding.embed_with_provider.assert_awaited_once()
    mock_store.query.assert_called_once_with(
        embedding=[0.5] * 768, top_k=5, provider_tag="google"
    )
    mock_llm.vision_classify.assert_awaited_once()

    assert result.identified_part.code == "06332"
    assert result.embedding_provider_used == "google"
    assert result.source_image_url.startswith(str(tmp_path))
```

- [ ] **Step 3: Rodar, ver falhar**

```bash
uv run pytest tests/unit/test_agent_identify.py -v
```

Expected: FAIL.

- [ ] **Step 4: Implementar `src/agent/identify.py`**

```python
"""IdentifierAgent — orquestra Camada 2 (descrição → embed → query → classify)."""
import uuid
from datetime import datetime, timezone
from pathlib import Path

from src.logging_setup import get_logger
from src.models import ClassificationResult
from src.providers.embedding.resilient import ResilientEmbedding
from src.providers.llm.base import CandidateImage, LLMProvider
from src.vectorstore.base import VectorStore

_log = get_logger(__name__)


class IdentifierAgent:
    def __init__(
        self,
        llm: LLMProvider,
        embedding: ResilientEmbedding,
        vector_store: VectorStore,
        top_k: int = 5,
    ) -> None:
        self._llm = llm
        self._embedding = embedding
        self._store = vector_store
        self._top_k = top_k

    async def identify(
        self,
        photo_bytes: bytes,
        uploads_dir: Path,
        user_id: int,
    ) -> ClassificationResult:
        ts = datetime.now(tz=timezone.utc)
        date_dir = uploads_dir / ts.strftime("%Y-%m-%d")
        date_dir.mkdir(parents=True, exist_ok=True)
        photo_path = date_dir / f"{user_id}_{int(ts.timestamp())}.jpg"
        photo_path.write_bytes(photo_bytes)

        transaction_id = f"BRUNO-{ts.strftime('%Y%m%d')}-{uuid.uuid4().hex[:8]}"
        _log.info("identify_start", transaction_id=transaction_id, photo=str(photo_path))

        # Descrição da foto
        description = await self._llm.describe_geometry(photo_bytes)
        _log.info("identify_described", transaction_id=transaction_id, chars=len(description))

        # Embedding (com info de qual provider foi usado)
        embedding, embedding_provider = await self._embedding.embed_with_provider(description)

        # Query no ChromaDB na coleção do mesmo provider
        candidates_meta = self._store.query(
            embedding=embedding, top_k=self._top_k, provider_tag=embedding_provider
        )
        _log.info(
            "identify_candidates",
            transaction_id=transaction_id,
            candidates=[c.code for c in candidates_meta],
            embedding_provider=embedding_provider,
        )

        # Carregar PNGs dos candidatos
        candidates: list[CandidateImage] = []
        for cm in candidates_meta:
            png_path = Path(cm.metadata.get("png_path", ""))
            if png_path.exists():
                candidates.append(
                    CandidateImage(
                        code=cm.code,
                        png_bytes=png_path.read_bytes(),
                        description=cm.metadata.get("description", ""),
                    )
                )

        # Classificação final
        result = await self._llm.vision_classify(
            photo_bytes=photo_bytes,
            candidates=candidates,
            transaction_id=transaction_id,
        )
        # Anotar metadados de proveniência
        result.source_image_url = str(photo_path)
        result.embedding_provider_used = embedding_provider  # type: ignore

        _log.info(
            "identify_done",
            transaction_id=transaction_id,
            code=result.identified_part.code,
            confidence=result.identified_part.confidence_score,
        )
        return result
```

- [ ] **Step 5: Rodar, ver passar**

```bash
uv run pytest tests/unit/test_agent_identify.py -v
```

Expected: 1 passed.

- [ ] **Step 6: Commit**

```bash
git add "Projetos/Automatização Bruno/src/agent/" \
        "Projetos/Automatização Bruno/tests/unit/test_agent_identify.py"
git commit -m "feat(bruno): IdentifierAgent (orquestra Camada 2 fim-a-fim)"
```

**🚦 GATE INTERNO POC-A-3:** Sprint 3 fechado. Agente identifica via mocks.

---

# SPRINT 4 — HITL + Storage + FIFO (T15-T18) — Estimado 6-8h

---

### Task 15: HITL card render

**Files:**
- Create: `src/hitl/__init__.py`
- Create: `src/hitl/card.py`

- [ ] **Step 1: Criar pacote**

```bash
touch src/hitl/__init__.py
```

- [ ] **Step 2: Implementar `src/hitl/card.py`**

```python
"""Renderiza Card a partir de ClassificationResult."""
from src.models import Card, ClassificationResult


def render_classification_card(result: ClassificationResult) -> Card:
    part = result.identified_part
    text = (
        f"🔍 *Identifiquei como:*\n"
        f"`{part.code}` — {part.description}\n"
        f"*Confiança:* {int(part.confidence_score * 100)}%\n\n"
        f"_{result.reasoning}_\n\n"
        f"Confirma?"
    )
    buttons = [
        ("✅ Confirmar", f"confirm:{result.transaction_id}"),
        ("✏️ Corrigir", f"correct:{result.transaction_id}"),
        ("👀 Alternativas", f"alts:{result.transaction_id}"),
        ("❌ Cancelar", f"cancel:{result.transaction_id}"),
    ]
    return Card(text=text, inline_buttons=buttons, photo_url=result.source_image_url)


def render_alternatives_card(result: ClassificationResult) -> Card:
    lines = [f"*Alternativas para `{result.identified_part.code}`:*\n"]
    for idx, alt in enumerate(result.alternatives, start=1):
        lines.append(f"{idx}. `{alt.code}` ({int(alt.confidence_score * 100)}%) — {alt.description}")
    text = "\n".join(lines) or "Sem alternativas adicionais."
    buttons = [
        (f"Escolher {alt.code}", f"choose:{result.transaction_id}:{alt.code}")
        for alt in result.alternatives[:3]
    ]
    buttons.append(("⬅️ Voltar", f"back:{result.transaction_id}"))
    return Card(text=text, inline_buttons=buttons)
```

- [ ] **Step 3: Commit**

```bash
git add "Projetos/Automatização Bruno/src/hitl/__init__.py" \
        "Projetos/Automatização Bruno/src/hitl/card.py"
git commit -m "feat(bruno): hitl cards (confirmacao + alternativas)"
```

---

### Task 16: HITL session (estado AGUARDANDO_CONFIRMACAO + timeout)

**Files:**
- Create: `src/hitl/session.py`
- Create: `tests/unit/test_hitl_session.py`

- [ ] **Step 1: Escrever teste failing**

`tests/unit/test_hitl_session.py`:
```python
"""Testa SessionStore: persiste estado de transações pendentes com timeout."""
from datetime import datetime, timedelta, timezone

from src.hitl.session import PendingTransaction, SessionStore
from src.models import ClassificationResult, IdentifiedPart, ProductionData, TransactionState


def _result(tid: str = "T-1") -> ClassificationResult:
    return ClassificationResult(
        transaction_id=tid,
        identified_part=IdentifiedPart(code="X", description="d", confidence_score=0.9),
        reasoning="r",
        source_image_url="u",
        production_data=ProductionData(timestamp=datetime.now(tz=timezone.utc)),
    )


def test_create_and_get_pending(tmp_path) -> None:
    store = SessionStore(db_path=tmp_path / "sessions.sqlite")
    store.create(_result("T-1"), user_id=42)

    pending = store.get("T-1")
    assert pending is not None
    assert pending.user_id == 42
    assert pending.state == TransactionState.AGUARDANDO_CONFIRMACAO


def test_update_state(tmp_path) -> None:
    store = SessionStore(db_path=tmp_path / "sessions.sqlite")
    store.create(_result("T-2"), user_id=1)
    store.update_state("T-2", TransactionState.CONFIRMADO)

    pending = store.get("T-2")
    assert pending is not None
    assert pending.state == TransactionState.CONFIRMADO


def test_expired_after_24h(tmp_path) -> None:
    store = SessionStore(db_path=tmp_path / "sessions.sqlite")
    store.create(_result("T-3"), user_id=1)

    fake_now = datetime.now(tz=timezone.utc) + timedelta(hours=25)
    expired = store.list_expired(now=fake_now, ttl_hours=24)

    assert "T-3" in [p.transaction_id for p in expired]


def test_needs_reminder_after_30min(tmp_path) -> None:
    store = SessionStore(db_path=tmp_path / "sessions.sqlite")
    store.create(_result("T-4"), user_id=1)

    fake_now = datetime.now(tz=timezone.utc) + timedelta(minutes=31)
    pending = store.list_needs_reminder(now=fake_now, reminder_minutes=30)

    assert "T-4" in [p.transaction_id for p in pending]
```

- [ ] **Step 2: Rodar, ver falhar**

```bash
uv run pytest tests/unit/test_hitl_session.py -v
```

Expected: FAIL.

- [ ] **Step 3: Implementar `src/hitl/session.py`**

```python
"""SessionStore SQLite — estado AGUARDANDO_CONFIRMACAO com timeout/reminder."""
import json
import sqlite3
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

from src.models import ClassificationResult, TransactionState


@dataclass
class PendingTransaction:
    transaction_id: str
    user_id: int
    state: TransactionState
    classification_json: str
    created_at: datetime
    last_reminder_at: datetime | None


class SessionStore:
    def __init__(self, db_path: Path) -> None:
        db_path.parent.mkdir(parents=True, exist_ok=True)
        self._db_path = db_path
        with self._conn() as conn:
            conn.executescript(
                """
                CREATE TABLE IF NOT EXISTS pending_tx (
                    transaction_id TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    state TEXT NOT NULL,
                    classification_json TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    last_reminder_at TEXT
                );
                CREATE INDEX IF NOT EXISTS idx_state ON pending_tx(state);
                """
            )

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self._db_path, detect_types=sqlite3.PARSE_DECLTYPES)
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    def create(self, result: ClassificationResult, user_id: int) -> None:
        with self._conn() as conn:
            conn.execute(
                "INSERT OR REPLACE INTO pending_tx VALUES (?, ?, ?, ?, ?, ?)",
                (
                    result.transaction_id,
                    user_id,
                    TransactionState.AGUARDANDO_CONFIRMACAO.value,
                    result.model_dump_json(),
                    datetime.now(tz=timezone.utc).isoformat(),
                    None,
                ),
            )

    def get(self, transaction_id: str) -> PendingTransaction | None:
        with self._conn() as conn:
            row = conn.execute(
                "SELECT transaction_id, user_id, state, classification_json, created_at, last_reminder_at "
                "FROM pending_tx WHERE transaction_id = ?",
                (transaction_id,),
            ).fetchone()
        if not row:
            return None
        return PendingTransaction(
            transaction_id=row[0],
            user_id=row[1],
            state=TransactionState(row[2]),
            classification_json=row[3],
            created_at=datetime.fromisoformat(row[4]),
            last_reminder_at=datetime.fromisoformat(row[5]) if row[5] else None,
        )

    def update_state(self, transaction_id: str, state: TransactionState) -> None:
        with self._conn() as conn:
            conn.execute(
                "UPDATE pending_tx SET state = ? WHERE transaction_id = ?",
                (state.value, transaction_id),
            )

    def mark_reminder_sent(self, transaction_id: str) -> None:
        with self._conn() as conn:
            conn.execute(
                "UPDATE pending_tx SET last_reminder_at = ? WHERE transaction_id = ?",
                (datetime.now(tz=timezone.utc).isoformat(), transaction_id),
            )

    def list_needs_reminder(
        self, now: datetime | None = None, reminder_minutes: int = 30
    ) -> list[PendingTransaction]:
        now = now or datetime.now(tz=timezone.utc)
        cutoff = now - timedelta(minutes=reminder_minutes)
        with self._conn() as conn:
            rows = conn.execute(
                "SELECT transaction_id, user_id, state, classification_json, created_at, last_reminder_at "
                "FROM pending_tx WHERE state = ? AND created_at < ? AND last_reminder_at IS NULL",
                (TransactionState.AGUARDANDO_CONFIRMACAO.value, cutoff.isoformat()),
            ).fetchall()
        return [
            PendingTransaction(
                transaction_id=r[0],
                user_id=r[1],
                state=TransactionState(r[2]),
                classification_json=r[3],
                created_at=datetime.fromisoformat(r[4]),
                last_reminder_at=datetime.fromisoformat(r[5]) if r[5] else None,
            )
            for r in rows
        ]

    def list_expired(
        self, now: datetime | None = None, ttl_hours: int = 24
    ) -> list[PendingTransaction]:
        now = now or datetime.now(tz=timezone.utc)
        cutoff = now - timedelta(hours=ttl_hours)
        with self._conn() as conn:
            rows = conn.execute(
                "SELECT transaction_id, user_id, state, classification_json, created_at, last_reminder_at "
                "FROM pending_tx WHERE state = ? AND created_at < ?",
                (TransactionState.AGUARDANDO_CONFIRMACAO.value, cutoff.isoformat()),
            ).fetchall()
        return [
            PendingTransaction(
                transaction_id=r[0],
                user_id=r[1],
                state=TransactionState(r[2]),
                classification_json=r[3],
                created_at=datetime.fromisoformat(r[4]),
                last_reminder_at=datetime.fromisoformat(r[5]) if r[5] else None,
            )
            for r in rows
        ]
```

- [ ] **Step 4: Rodar, ver passar**

```bash
uv run pytest tests/unit/test_hitl_session.py -v
```

Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add "Projetos/Automatização Bruno/src/hitl/session.py" \
        "Projetos/Automatização Bruno/tests/unit/test_hitl_session.py"
git commit -m "feat(bruno): SessionStore SQLite com timeout/reminder"
```

---

### Task 17: Storage Protocol + ExcelStorage

**Files:**
- Create: `src/storage/__init__.py`
- Create: `src/storage/base.py`
- Create: `src/storage/excel.py`
- Create: `tests/unit/test_excel_storage.py`

- [ ] **Step 1: Criar pacote**

```bash
touch src/storage/__init__.py
```

- [ ] **Step 2: Implementar `src/storage/base.py`**

```python
"""Protocol para Storage de saldos e movimentações."""
from typing import Protocol

from src.models import Movimentacao, SaldoLote


class Storage(Protocol):
    def read_saldos(self, codigo_peca: str) -> list[SaldoLote]: ...
    def append_movimentacao(self, mov: Movimentacao) -> None: ...
    def update_saldo(self, lote_id: str, qty_nova: float) -> None: ...
    def insert_lote(self, lote: SaldoLote) -> None: ...
```

- [ ] **Step 3: Escrever teste failing**

`tests/unit/test_excel_storage.py`:
```python
"""Testa ExcelStorage — leitura, atualização e append."""
from datetime import datetime, timezone
from pathlib import Path

import openpyxl

from src.models import Movimentacao, SaldoLote
from src.storage.excel import ExcelStorage


def _bootstrap(path: Path) -> None:
    wb = openpyxl.Workbook()
    saldos = wb.active
    saldos.title = "saldos"
    saldos.append(
        ["lote_id", "codigo_peca", "nf_origem", "qty_original", "qty_disponivel", "data_entrada"]
    )
    saldos.append(
        ["LOT-001", "06332", "NF-1", 200.0, 200.0, datetime(2026, 4, 1, tzinfo=timezone.utc).isoformat()]
    )
    saldos.append(
        ["LOT-002", "06332", "NF-2", 100.0, 100.0, datetime(2026, 4, 10, tzinfo=timezone.utc).isoformat()]
    )

    movs = wb.create_sheet("movimentacoes")
    movs.append(
        [
            "timestamp",
            "codigo_peca",
            "qty_baixada",
            "lote_baixado",
            "nf_baixada",
            "foto_url",
            "confirmado_por",
            "confidence_inicial",
        ]
    )

    aud = wb.create_sheet("auditoria")
    aud.append(["timestamp", "evento", "payload"])

    wb.save(path)


def test_read_saldos_ordered_by_data(tmp_path: Path) -> None:
    path = tmp_path / "saldos.xlsx"
    _bootstrap(path)
    s = ExcelStorage(path)

    saldos = s.read_saldos("06332")
    assert [l.lote_id for l in saldos] == ["LOT-001", "LOT-002"]


def test_update_saldo(tmp_path: Path) -> None:
    path = tmp_path / "saldos.xlsx"
    _bootstrap(path)
    s = ExcelStorage(path)

    s.update_saldo("LOT-001", qty_nova=150.0)

    saldos = s.read_saldos("06332")
    lot1 = next(l for l in saldos if l.lote_id == "LOT-001")
    assert lot1.qty_disponivel == 150.0


def test_append_movimentacao(tmp_path: Path) -> None:
    path = tmp_path / "saldos.xlsx"
    _bootstrap(path)
    s = ExcelStorage(path)

    mov = Movimentacao(
        timestamp=datetime.now(tz=timezone.utc),
        codigo_peca="06332",
        qty_baixada=50,
        lote_baixado="LOT-001",
        nf_baixada="NF-1",
        foto_url="u",
        confirmado_por="bruno",
        confidence_inicial=0.95,
    )
    s.append_movimentacao(mov)

    wb = openpyxl.load_workbook(path)
    movs = wb["movimentacoes"]
    assert movs.max_row == 2  # header + 1
```

- [ ] **Step 4: Rodar, ver falhar**

```bash
uv run pytest tests/unit/test_excel_storage.py -v
```

Expected: FAIL.

- [ ] **Step 5: Implementar `src/storage/excel.py`**

```python
"""ExcelStorage — Fase A. Persiste em arquivo .xlsx via openpyxl."""
import json
import threading
from datetime import datetime, timezone
from pathlib import Path

import openpyxl

from src.logging_setup import get_logger
from src.models import Movimentacao, SaldoLote

_log = get_logger(__name__)


class ExcelStorage:
    """Implementação Fase A — single-process com lock interno."""

    def __init__(self, path: Path) -> None:
        self._path = path
        self._lock = threading.RLock()
        if not path.exists():
            self._bootstrap_workbook()

    def _bootstrap_workbook(self) -> None:
        wb = openpyxl.Workbook()
        saldos = wb.active
        saldos.title = "saldos"
        saldos.append(
            [
                "lote_id",
                "codigo_peca",
                "nf_origem",
                "qty_original",
                "qty_disponivel",
                "data_entrada",
            ]
        )
        movs = wb.create_sheet("movimentacoes")
        movs.append(
            [
                "timestamp",
                "codigo_peca",
                "qty_baixada",
                "lote_baixado",
                "nf_baixada",
                "foto_url",
                "confirmado_por",
                "confidence_inicial",
            ]
        )
        aud = wb.create_sheet("auditoria")
        aud.append(["timestamp", "evento", "payload"])
        self._path.parent.mkdir(parents=True, exist_ok=True)
        wb.save(self._path)

    def read_saldos(self, codigo_peca: str) -> list[SaldoLote]:
        with self._lock:
            wb = openpyxl.load_workbook(self._path, data_only=True)
            sheet = wb["saldos"]
            saldos: list[SaldoLote] = []
            for row in sheet.iter_rows(min_row=2, values_only=True):
                if not row or row[0] is None:
                    continue
                if row[1] != codigo_peca:
                    continue
                saldos.append(
                    SaldoLote(
                        lote_id=str(row[0]),
                        codigo_peca=str(row[1]),
                        nf_origem=str(row[2]),
                        qty_original=float(row[3]),
                        qty_disponivel=float(row[4]),
                        data_entrada=datetime.fromisoformat(str(row[5])),
                    )
                )
            saldos.sort(key=lambda s: s.data_entrada)
            return saldos

    def update_saldo(self, lote_id: str, qty_nova: float) -> None:
        with self._lock:
            wb = openpyxl.load_workbook(self._path)
            sheet = wb["saldos"]
            for row in sheet.iter_rows(min_row=2):
                if row[0].value == lote_id:
                    row[4].value = qty_nova
                    break
            wb.save(self._path)
        _log.info("saldo_updated", lote_id=lote_id, qty_nova=qty_nova)

    def insert_lote(self, lote: SaldoLote) -> None:
        with self._lock:
            wb = openpyxl.load_workbook(self._path)
            sheet = wb["saldos"]
            sheet.append(
                [
                    lote.lote_id,
                    lote.codigo_peca,
                    lote.nf_origem,
                    lote.qty_original,
                    lote.qty_disponivel,
                    lote.data_entrada.isoformat(),
                ]
            )
            wb.save(self._path)
        _log.info("lote_inserted", lote_id=lote.lote_id)

    def append_movimentacao(self, mov: Movimentacao) -> None:
        with self._lock:
            wb = openpyxl.load_workbook(self._path)
            sheet = wb["movimentacoes"]
            sheet.append(
                [
                    mov.timestamp.isoformat(),
                    mov.codigo_peca,
                    mov.qty_baixada,
                    mov.lote_baixado,
                    mov.nf_baixada,
                    mov.foto_url,
                    mov.confirmado_por,
                    mov.confidence_inicial,
                ]
            )
            wb.save(self._path)
        _log.info("mov_appended", lote=mov.lote_baixado, qty=mov.qty_baixada)

    def append_auditoria(self, evento: str, payload: dict) -> None:
        with self._lock:
            wb = openpyxl.load_workbook(self._path)
            sheet = wb["auditoria"]
            sheet.append([datetime.now(tz=timezone.utc).isoformat(), evento, json.dumps(payload, default=str)])
            wb.save(self._path)
```

- [ ] **Step 6: Rodar testes**

```bash
uv run pytest tests/unit/test_excel_storage.py -v
```

Expected: 3 passed.

- [ ] **Step 7: Commit**

```bash
git add "Projetos/Automatização Bruno/src/storage/" \
        "Projetos/Automatização Bruno/tests/unit/test_excel_storage.py"
git commit -m "feat(bruno): ExcelStorage Fase A (saldos/movimentacoes/auditoria)"
```

---

### Task 18: Motor FIFO

**Files:**
- Create: `src/fifo/__init__.py`
- Create: `src/fifo/motor.py`
- Create: `tests/unit/test_fifo_motor.py`

- [ ] **Step 1: Criar pacote**

```bash
touch src/fifo/__init__.py
```

- [ ] **Step 2: Escrever teste failing**

`tests/unit/test_fifo_motor.py`:
```python
"""Testa motor FIFO."""
from datetime import datetime, timezone
from unittest.mock import MagicMock

import pytest

from src.fifo.motor import (
    FIFOMotor,
    InsufficientStockError,
    NoSaldoError,
)
from src.models import Movimentacao, SaldoLote


def _saldo(lote_id: str, qty: float, data: datetime) -> SaldoLote:
    return SaldoLote(
        lote_id=lote_id,
        codigo_peca="06332",
        nf_origem=f"NF-{lote_id}",
        qty_original=qty,
        qty_disponivel=qty,
        data_entrada=data,
    )


def test_baixa_lote_unico() -> None:
    storage = MagicMock()
    storage.read_saldos.return_value = [
        _saldo("L1", 200, datetime(2026, 1, 1, tzinfo=timezone.utc)),
    ]
    motor = FIFOMotor(storage)

    movs = motor.lancar(
        codigo="06332",
        qty=50,
        foto_url="u",
        confirmado_por="bruno",
        confidence=0.95,
    )

    assert len(movs) == 1
    assert movs[0].lote_baixado == "L1"
    assert movs[0].qty_baixada == 50
    storage.update_saldo.assert_called_once_with("L1", 150.0)
    storage.append_movimentacao.assert_called_once()


def test_baixa_cruza_dois_lotes_fifo() -> None:
    storage = MagicMock()
    storage.read_saldos.return_value = [
        _saldo("L1", 100, datetime(2026, 1, 1, tzinfo=timezone.utc)),
        _saldo("L2", 100, datetime(2026, 2, 1, tzinfo=timezone.utc)),
    ]
    motor = FIFOMotor(storage)

    movs = motor.lancar(
        codigo="06332",
        qty=150,
        foto_url="u",
        confirmado_por="bruno",
        confidence=0.95,
    )

    assert len(movs) == 2
    assert movs[0].lote_baixado == "L1"
    assert movs[0].qty_baixada == 100
    assert movs[1].lote_baixado == "L2"
    assert movs[1].qty_baixada == 50
    assert storage.update_saldo.call_count == 2
    storage.update_saldo.assert_any_call("L1", 0.0)
    storage.update_saldo.assert_any_call("L2", 50.0)


def test_qty_maior_que_total_disponivel_lanca_erro() -> None:
    storage = MagicMock()
    storage.read_saldos.return_value = [
        _saldo("L1", 50, datetime(2026, 1, 1, tzinfo=timezone.utc)),
    ]
    motor = FIFOMotor(storage)

    with pytest.raises(InsufficientStockError) as exc:
        motor.lancar("06332", 100, "u", "bruno", 0.9)

    assert exc.value.qty_disponivel == 50.0


def test_codigo_sem_lote_lanca_erro() -> None:
    storage = MagicMock()
    storage.read_saldos.return_value = []
    motor = FIFOMotor(storage)

    with pytest.raises(NoSaldoError):
        motor.lancar("99999", 10, "u", "bruno", 0.9)
```

- [ ] **Step 3: Rodar, ver falhar**

```bash
uv run pytest tests/unit/test_fifo_motor.py -v
```

Expected: FAIL.

- [ ] **Step 4: Implementar `src/fifo/motor.py`**

```python
"""Motor FIFO — abate da NF mais antiga até zerar."""
from datetime import datetime, timezone

from src.logging_setup import get_logger
from src.models import Movimentacao
from src.storage.base import Storage

_log = get_logger(__name__)


class NoSaldoError(Exception):
    """Código sem nenhum lote cadastrado em saldos."""


class InsufficientStockError(Exception):
    def __init__(self, codigo: str, qty_pedida: float, qty_disponivel: float) -> None:
        super().__init__(
            f"Saldo insuficiente para {codigo}: pedido={qty_pedida}, disponivel={qty_disponivel}"
        )
        self.codigo = codigo
        self.qty_pedida = qty_pedida
        self.qty_disponivel = qty_disponivel


class FIFOMotor:
    def __init__(self, storage: Storage) -> None:
        self._storage = storage

    def lancar(
        self,
        codigo: str,
        qty: float,
        foto_url: str,
        confirmado_por: str,
        confidence: float,
    ) -> list[Movimentacao]:
        saldos = self._storage.read_saldos(codigo)
        if not saldos:
            raise NoSaldoError(f"Código {codigo} sem lote cadastrado em saldos")

        total_disponivel = sum(l.qty_disponivel for l in saldos)
        if qty > total_disponivel:
            raise InsufficientStockError(codigo, qty, total_disponivel)

        movs: list[Movimentacao] = []
        restante = qty
        ts = datetime.now(tz=timezone.utc)

        for lote in saldos:  # já ordenado por data_entrada ASC
            if restante <= 0:
                break
            if lote.qty_disponivel <= 0:
                continue
            baixar = min(restante, lote.qty_disponivel)
            mov = Movimentacao(
                timestamp=ts,
                codigo_peca=codigo,
                qty_baixada=baixar,
                lote_baixado=lote.lote_id,
                nf_baixada=lote.nf_origem,
                foto_url=foto_url,
                confirmado_por=confirmado_por,
                confidence_inicial=confidence,
            )
            self._storage.update_saldo(lote.lote_id, lote.qty_disponivel - baixar)
            self._storage.append_movimentacao(mov)
            movs.append(mov)
            restante -= baixar

        _log.info(
            "fifo_lancado",
            codigo=codigo,
            qty_total=qty,
            n_lotes_afetados=len(movs),
        )
        return movs
```

- [ ] **Step 5: Rodar, ver passar**

```bash
uv run pytest tests/unit/test_fifo_motor.py -v
```

Expected: 4 passed.

- [ ] **Step 6: Commit**

```bash
git add "Projetos/Automatização Bruno/src/fifo/" \
        "Projetos/Automatização Bruno/tests/unit/test_fifo_motor.py"
git commit -m "feat(bruno): motor FIFO (baixa cross-lote ordenado por data_entrada)"
```

**🚦 GATE INTERNO POC-A-4:** Sprint 4 fechado. HITL + Storage + FIFO testados.

---

# SPRINT 5 — Channel Telegram + main + smoke fim-a-fim (T19-T20) — Estimado 4-6h

---

### Task 19: TelegramPollingChannel (Fase A)

**Files:**
- Create: `src/channels/__init__.py`
- Create: `src/channels/base.py`
- Create: `src/channels/telegram_polling.py`

- [ ] **Step 1: Criar pacote**

```bash
touch src/channels/__init__.py
```

- [ ] **Step 2: Implementar `src/channels/base.py`**

```python
"""Protocol para canal de mensagem (Telegram, WhatsApp futuro, etc.)."""
from typing import Protocol


class MessageChannel(Protocol):
    async def start(self) -> None:
        """Inicia loop de recepção (polling ou webhook)."""
        ...

    async def send_card(
        self,
        chat_id: int,
        text: str,
        buttons: list[tuple[str, str]],
        photo_bytes: bytes | None = None,
    ) -> None:
        """Envia card com botões inline."""
        ...

    async def send_text(self, chat_id: int, text: str) -> None:
        """Envia mensagem de texto simples."""
        ...
```

- [ ] **Step 3: Implementar `src/channels/telegram_polling.py`**

```python
"""TelegramPollingChannel — Fase A. Polling local."""
from typing import Awaitable, Callable

from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.constants import ParseMode
from telegram.ext import (
    Application,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

from src.logging_setup import get_logger

_log = get_logger(__name__)


PhotoHandler = Callable[[bytes, int], Awaitable[None]]
CallbackHandler = Callable[[str, int], Awaitable[None]]
TextHandler = Callable[[str, int], Awaitable[None]]


class TelegramPollingChannel:
    def __init__(
        self,
        token: str,
        allowed_user_ids: list[int],
        on_photo: PhotoHandler,
        on_callback: CallbackHandler,
        on_text: TextHandler,
    ) -> None:
        self._token = token
        self._allowed = set(allowed_user_ids)
        self._on_photo = on_photo
        self._on_callback = on_callback
        self._on_text = on_text
        self._app: Application | None = None

    async def start(self) -> None:
        self._app = (
            Application.builder().token(self._token).post_init(self._post_init).build()
        )
        self._app.add_handler(CommandHandler("start", self._cmd_start))
        self._app.add_handler(MessageHandler(filters.PHOTO, self._handle_photo))
        self._app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, self._handle_text))
        self._app.add_handler(CallbackQueryHandler(self._handle_callback))

        _log.info("telegram_polling_starting")
        async with self._app:
            await self._app.start()
            await self._app.updater.start_polling()
            # Roda até receber sinal externo
            try:
                import asyncio

                await asyncio.Event().wait()
            finally:
                await self._app.updater.stop()
                await self._app.stop()

    async def send_card(
        self,
        chat_id: int,
        text: str,
        buttons: list[tuple[str, str]],
        photo_bytes: bytes | None = None,
    ) -> None:
        assert self._app is not None
        keyboard = InlineKeyboardMarkup(
            [[InlineKeyboardButton(text=label, callback_data=cb) for (label, cb) in buttons[i:i+2]]
             for i in range(0, len(buttons), 2)]
        )
        if photo_bytes:
            await self._app.bot.send_photo(
                chat_id=chat_id,
                photo=photo_bytes,
                caption=text,
                parse_mode=ParseMode.MARKDOWN,
                reply_markup=keyboard,
            )
        else:
            await self._app.bot.send_message(
                chat_id=chat_id,
                text=text,
                parse_mode=ParseMode.MARKDOWN,
                reply_markup=keyboard,
            )

    async def send_text(self, chat_id: int, text: str) -> None:
        assert self._app is not None
        await self._app.bot.send_message(chat_id=chat_id, text=text, parse_mode=ParseMode.MARKDOWN)

    async def _post_init(self, app: Application) -> None:
        _log.info("telegram_bot_ready", username=app.bot.username)

    def _is_allowed(self, user_id: int) -> bool:
        ok = user_id in self._allowed
        if not ok:
            _log.warning("user_not_allowed", user_id=user_id)
        return ok

    async def _cmd_start(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        user = update.effective_user
        if not user or not self._is_allowed(user.id):
            return
        await update.message.reply_text(
            "Olá! Envie uma foto de peça que eu identifico e lanço o FIFO."
        )

    async def _handle_photo(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        user = update.effective_user
        if not user or not self._is_allowed(user.id):
            return
        if not update.message or not update.message.photo:
            return
        photo = update.message.photo[-1]  # maior resolução
        file = await photo.get_file()
        photo_bytes = bytes(await file.download_as_bytearray())
        await self._on_photo(photo_bytes, user.id)

    async def _handle_callback(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        query = update.callback_query
        user = update.effective_user
        if not query or not user or not self._is_allowed(user.id):
            return
        await query.answer()
        await self._on_callback(query.data or "", user.id)

    async def _handle_text(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        user = update.effective_user
        if not user or not self._is_allowed(user.id) or not update.message:
            return
        await self._on_text(update.message.text or "", user.id)
```

- [ ] **Step 4: Commit**

```bash
git add "Projetos/Automatização Bruno/src/channels/"
git commit -m "feat(bruno): TelegramPollingChannel Fase A (handlers photo/callback/text)"
```

---

### Task 20: main.py wiring DI Fase A

**Files:**
- Create: `Projetos/Automatização Bruno/src/main.py`

- [ ] **Step 1: Implementar `src/main.py`**

```python
"""Entrypoint Fase A — wiring DI + bot loop.

Uso:
    uv run python -m src.main
"""
import asyncio
import sys
from datetime import datetime, timezone

from src.agent.identify import IdentifierAgent
from src.channels.telegram_polling import TelegramPollingChannel
from src.config import AppConfig, AppPhase
from src.fifo.motor import FIFOMotor, InsufficientStockError, NoSaldoError
from src.hitl.card import render_alternatives_card, render_classification_card
from src.hitl.session import SessionStore
from src.logging_setup import get_logger, setup_logging
from src.models import ClassificationResult, TransactionState
from src.providers.embedding.google import GoogleProvider
from src.providers.embedding.openai import OpenAIProvider
from src.providers.embedding.resilient import ResilientEmbedding
from src.providers.llm.anthropic import AnthropicProvider
from src.providers.llm.openrouter import OpenRouterProvider
from src.providers.llm.resilient import ResilientLLM
from src.storage.excel import ExcelStorage
from src.vectorstore.chroma import ChromaDBStore


async def main() -> int:
    setup_logging()
    log = get_logger("main")
    cfg = AppConfig()

    if cfg.app_phase != AppPhase.A:
        log.error("wrong_phase", expected="A", got=cfg.app_phase.value)
        return 1

    # Providers
    llm = ResilientLLM(
        primary=AnthropicProvider(api_key=cfg.anthropic_api_key),
        fallback=OpenRouterProvider(api_key=cfg.openrouter_api_key),
    )
    embedding = ResilientEmbedding(
        primary=GoogleProvider(api_key=cfg.google_ai_key),
        fallback=OpenAIProvider(api_key=cfg.openai_api_key),
    )
    store = ChromaDBStore(persist_path=cfg.chroma_path)
    storage = ExcelStorage(cfg.excel_path)
    sessions = SessionStore(db_path=cfg.uploads_path.parent / "sessions.sqlite")
    fifo = FIFOMotor(storage)
    agent = IdentifierAgent(llm=llm, embedding=embedding, vector_store=store)

    # Estado em memória de quem está aguardando "Quantidade?"
    awaiting_qty: dict[int, str] = {}  # user_id → transaction_id

    channel: TelegramPollingChannel  # forward ref

    async def on_photo(photo_bytes: bytes, user_id: int) -> None:
        try:
            await channel.send_text(user_id, "🔄 Analisando foto...")
            result = await agent.identify(
                photo_bytes=photo_bytes,
                uploads_dir=cfg.uploads_path,
                user_id=user_id,
            )
            sessions.create(result, user_id=user_id)
            card = render_classification_card(result)
            await channel.send_card(
                chat_id=user_id,
                text=card.text,
                buttons=card.inline_buttons,
                photo_bytes=photo_bytes,
            )
        except Exception as e:
            log.exception("on_photo_failed", error=str(e))
            await channel.send_text(user_id, f"❌ Erro: {e}")

    async def on_callback(data: str, user_id: int) -> None:
        try:
            parts = data.split(":", 2)
            action = parts[0]
            tx_id = parts[1] if len(parts) > 1 else ""
            pending = sessions.get(tx_id)
            if not pending:
                await channel.send_text(user_id, "⚠️ Transação não encontrada ou expirada.")
                return

            result = ClassificationResult.model_validate_json(pending.classification_json)

            if action == "confirm":
                sessions.update_state(tx_id, TransactionState.CONFIRMADO)
                awaiting_qty[user_id] = tx_id
                await channel.send_text(
                    user_id,
                    f"✅ Confirmado `{result.identified_part.code}`. Qual a *quantidade*?",
                )
            elif action == "correct":
                awaiting_qty[user_id] = f"correct:{tx_id}"
                await channel.send_text(
                    user_id, "✏️ Digite o código correto (ex: 06332):"
                )
            elif action == "alts":
                card = render_alternatives_card(result)
                await channel.send_card(user_id, card.text, card.inline_buttons)
            elif action == "choose" and len(parts) == 3:
                # Substitui código pela alternativa escolhida
                novo_code = parts[2]
                result.identified_part.code = novo_code
                pending_updated = result.model_copy()
                # Atualizar JSON salvo
                # (simplificação: sobrescreve a sessão)
                sessions.create(pending_updated, user_id=user_id)
                sessions.update_state(tx_id, TransactionState.CONFIRMADO)
                awaiting_qty[user_id] = tx_id
                await channel.send_text(
                    user_id, f"✅ Escolhido `{novo_code}`. Qual a *quantidade*?"
                )
            elif action == "back":
                card = render_classification_card(result)
                await channel.send_card(user_id, card.text, card.inline_buttons)
            elif action == "cancel":
                sessions.update_state(tx_id, TransactionState.CANCELADO)
                awaiting_qty.pop(user_id, None)
                await channel.send_text(user_id, "❌ Transação cancelada.")
        except Exception as e:
            log.exception("on_callback_failed", data=data, error=str(e))
            await channel.send_text(user_id, f"❌ Erro: {e}")

    async def on_text(text: str, user_id: int) -> None:
        if user_id not in awaiting_qty:
            await channel.send_text(
                user_id, "Envie uma foto de peça para começar. Use /start para ajuda."
            )
            return
        token = awaiting_qty.pop(user_id)
        try:
            if token.startswith("correct:"):
                tx_id = token.split(":", 1)[1]
                pending = sessions.get(tx_id)
                if not pending:
                    return
                result = ClassificationResult.model_validate_json(pending.classification_json)
                result.identified_part.code = text.strip()
                sessions.create(result, user_id=user_id)  # sobrescreve
                sessions.update_state(tx_id, TransactionState.CONFIRMADO)
                awaiting_qty[user_id] = tx_id
                await channel.send_text(user_id, f"OK, código corrigido para `{text.strip()}`. Qual a *quantidade*?")
                return

            tx_id = token
            qty = float(text.replace(",", ".").strip())
            pending = sessions.get(tx_id)
            if not pending:
                await channel.send_text(user_id, "Transação expirada.")
                return
            result = ClassificationResult.model_validate_json(pending.classification_json)
            try:
                movs = fifo.lancar(
                    codigo=result.identified_part.code,
                    qty=qty,
                    foto_url=result.source_image_url,
                    confirmado_por="bruno",
                    confidence=result.identified_part.confidence_score,
                )
                sessions.update_state(tx_id, TransactionState.LANCADO)
                saldo_restante = sum(
                    s.qty_disponivel
                    for s in storage.read_saldos(result.identified_part.code)
                )
                resumo = "\n".join(
                    f"• `{m.lote_baixado}` ({m.nf_baixada}): {m.qty_baixada} PC" for m in movs
                )
                await channel.send_text(
                    user_id,
                    f"✅ *Lançado* `{result.identified_part.code}`: {qty} PC\n"
                    f"{resumo}\n"
                    f"_Saldo restante:_ {saldo_restante} PC",
                )
            except NoSaldoError:
                await channel.send_text(
                    user_id,
                    f"⚠️ Código `{result.identified_part.code}` sem lote cadastrado. "
                    f"Use /entrada para registrar nova NF (não implementado no POC).",
                )
            except InsufficientStockError as e:
                await channel.send_text(
                    user_id,
                    f"⚠️ Saldo insuficiente: pedido {e.qty_pedida}, disponível {e.qty_disponivel}.",
                )
        except ValueError:
            awaiting_qty[user_id] = token  # devolver
            await channel.send_text(user_id, "Quantidade inválida. Digite um número (ex: 34).")
        except Exception as e:
            log.exception("on_text_failed", error=str(e))
            await channel.send_text(user_id, f"❌ Erro: {e}")

    channel = TelegramPollingChannel(
        token=cfg.telegram_bot_token,
        allowed_user_ids=cfg.telegram_allowed_user_ids,
        on_photo=on_photo,
        on_callback=on_callback,
        on_text=on_text,
    )
    log.info("starting_phase_a", allowed_users=cfg.telegram_allowed_user_ids)
    await channel.start()
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
```

- [ ] **Step 2: Smoke local — Pedro testa enviando foto pelo Telegram**

```bash
# Garantir .env preenchido + ChromaDB já populado pelo ingest.py
uv run python -m src.main
```

Expected: log `telegram_polling_starting` e `telegram_bot_ready`. Pedro envia foto pelo Telegram → bot identifica → confirma → digita qty → FIFO lança.

Verifica:
- `logs/app.log` tem evento `identify_done` com confidence
- `data/saldos.xlsx` aba `movimentacoes` ganhou linha
- `data/uploads/2026-05-XX/` tem foto recebida

- [ ] **Step 3: Commit**

```bash
git add "Projetos/Automatização Bruno/src/main.py"
git commit -m "feat(bruno): main.py wiring Fase A (DI completo + handlers Telegram)"
```

**🚦 GATE POC-A:** Pedro envia 10 fotos manualmente. Sistema deve:
- Identificar com latência < 15s/foto
- Acertar ≥7/10 (relaxado pra Fase A)
- FIFO escrever sem corromper Excel
- Zero crash

Se passou: prossegue Sprint 6. Se falhou: ver Plano de Contingência abaixo.

---

# SPRINT 6 — Migração Fase B (VPS + Webhook + Sheets) (T21-T24) — Estimado 6-8h

---

### Task 21: TelegramWebhookChannel

**Files:**
- Create: `src/channels/telegram_webhook.py`

- [ ] **Step 1: Implementar `src/channels/telegram_webhook.py`**

```python
"""TelegramWebhookChannel — Fase B. Webhook via FastAPI."""
from typing import Awaitable, Callable

from fastapi import FastAPI, Request
from telegram import Bot, InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.constants import ParseMode
from telegram.ext import (
    Application,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

from src.logging_setup import get_logger

_log = get_logger(__name__)


PhotoHandler = Callable[[bytes, int], Awaitable[None]]
CallbackHandler = Callable[[str, int], Awaitable[None]]
TextHandler = Callable[[str, int], Awaitable[None]]


class TelegramWebhookChannel:
    def __init__(
        self,
        token: str,
        webhook_url: str,
        allowed_user_ids: list[int],
        on_photo: PhotoHandler,
        on_callback: CallbackHandler,
        on_text: TextHandler,
    ) -> None:
        self._token = token
        self._webhook_url = webhook_url
        self._allowed = set(allowed_user_ids)
        self._on_photo = on_photo
        self._on_callback = on_callback
        self._on_text = on_text
        self._app = Application.builder().token(token).updater(None).build()
        self._setup_handlers()

    def _setup_handlers(self) -> None:
        self._app.add_handler(CommandHandler("start", self._cmd_start))
        self._app.add_handler(MessageHandler(filters.PHOTO, self._handle_photo))
        self._app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, self._handle_text))
        self._app.add_handler(CallbackQueryHandler(self._handle_callback))

    def _is_allowed(self, user_id: int) -> bool:
        return user_id in self._allowed

    async def _cmd_start(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        user = update.effective_user
        if not user or not self._is_allowed(user.id):
            return
        await update.message.reply_text("Olá! Envie uma foto de peça.")

    async def _handle_photo(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        user = update.effective_user
        if not user or not self._is_allowed(user.id) or not update.message or not update.message.photo:
            return
        photo = update.message.photo[-1]
        file = await photo.get_file()
        photo_bytes = bytes(await file.download_as_bytearray())
        await self._on_photo(photo_bytes, user.id)

    async def _handle_callback(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        query = update.callback_query
        user = update.effective_user
        if not query or not user or not self._is_allowed(user.id):
            return
        await query.answer()
        await self._on_callback(query.data or "", user.id)

    async def _handle_text(self, update: Update, ctx: ContextTypes.DEFAULT_TYPE) -> None:
        user = update.effective_user
        if not user or not self._is_allowed(user.id) or not update.message:
            return
        await self._on_text(update.message.text or "", user.id)

    async def setup_webhook(self) -> None:
        await self._app.initialize()
        await self._app.start()
        await self._app.bot.set_webhook(url=self._webhook_url, allowed_updates=Update.ALL_TYPES)
        _log.info("webhook_set", url=self._webhook_url)

    async def shutdown(self) -> None:
        await self._app.bot.delete_webhook()
        await self._app.stop()
        await self._app.shutdown()

    async def process_update(self, payload: dict) -> None:
        update = Update.de_json(payload, self._app.bot)
        await self._app.process_update(update)

    async def send_card(
        self,
        chat_id: int,
        text: str,
        buttons: list[tuple[str, str]],
        photo_bytes: bytes | None = None,
    ) -> None:
        keyboard = InlineKeyboardMarkup(
            [[InlineKeyboardButton(text=label, callback_data=cb) for (label, cb) in buttons[i:i+2]]
             for i in range(0, len(buttons), 2)]
        )
        if photo_bytes:
            await self._app.bot.send_photo(
                chat_id=chat_id,
                photo=photo_bytes,
                caption=text,
                parse_mode=ParseMode.MARKDOWN,
                reply_markup=keyboard,
            )
        else:
            await self._app.bot.send_message(
                chat_id=chat_id, text=text, parse_mode=ParseMode.MARKDOWN, reply_markup=keyboard
            )

    async def send_text(self, chat_id: int, text: str) -> None:
        await self._app.bot.send_message(chat_id=chat_id, text=text, parse_mode=ParseMode.MARKDOWN)
```

- [ ] **Step 2: Commit**

```bash
git add "Projetos/Automatização Bruno/src/channels/telegram_webhook.py"
git commit -m "feat(bruno): TelegramWebhookChannel Fase B (FastAPI compatible)"
```

---

### Task 22: FastAPI server + Dockerfile

**Files:**
- Create: `Projetos/Automatização Bruno/src/server.py`
- Create: `Projetos/Automatização Bruno/deploy/Dockerfile`
- Create: `Projetos/Automatização Bruno/deploy/docker-compose.yml`

- [ ] **Step 1: Implementar `src/server.py`**

```python
"""Servidor FastAPI Fase B — recebe webhooks Telegram, faz wiring DI igual main.py mas com Sheets.

Uso:
    uv run uvicorn src.server:app --host 0.0.0.0 --port 8000
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response

from src.agent.identify import IdentifierAgent
from src.channels.telegram_webhook import TelegramWebhookChannel
from src.config import AppConfig, AppPhase
from src.fifo.motor import FIFOMotor, InsufficientStockError, NoSaldoError
from src.hitl.card import render_alternatives_card, render_classification_card
from src.hitl.session import SessionStore
from src.logging_setup import get_logger, setup_logging
from src.models import ClassificationResult, TransactionState
from src.providers.embedding.google import GoogleProvider
from src.providers.embedding.openai import OpenAIProvider
from src.providers.embedding.resilient import ResilientEmbedding
from src.providers.llm.anthropic import AnthropicProvider
from src.providers.llm.openrouter import OpenRouterProvider
from src.providers.llm.resilient import ResilientLLM
from src.storage.sheets import SheetsStorage
from src.vectorstore.chroma import ChromaDBStore

_log = get_logger("server")
_state: dict = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    cfg = AppConfig()
    if cfg.app_phase != AppPhase.B:
        raise RuntimeError("server.py exige APP_PHASE=B")

    llm = ResilientLLM(
        primary=AnthropicProvider(api_key=cfg.anthropic_api_key),
        fallback=OpenRouterProvider(api_key=cfg.openrouter_api_key),
    )
    embedding = ResilientEmbedding(
        primary=GoogleProvider(api_key=cfg.google_ai_key),
        fallback=OpenAIProvider(api_key=cfg.openai_api_key),
    )
    store = ChromaDBStore(persist_path=cfg.chroma_path)
    storage = SheetsStorage(
        creds_path=cfg.google_sheets_creds_path,
        sheet_id=cfg.google_sheet_id,
    )
    sessions = SessionStore(db_path=cfg.uploads_path.parent / "sessions.sqlite")
    fifo = FIFOMotor(storage)
    agent = IdentifierAgent(llm=llm, embedding=embedding, vector_store=store)
    awaiting_qty: dict[int, str] = {}

    # Reusar exatamente as mesmas funções on_photo/on_callback/on_text de main.py.
    # Para evitar duplicação grande, importamos do módulo de handlers compartilhado
    # (refatoração: extrair handlers para src/handlers.py em task futura. Por ora, inline).

    from src.handlers import build_handlers

    on_photo, on_callback, on_text = build_handlers(
        agent=agent,
        sessions=sessions,
        fifo=fifo,
        storage=storage,
        awaiting_qty=awaiting_qty,
        send_text=lambda uid, t: channel.send_text(uid, t),
        send_card=lambda uid, t, btns, ph=None: channel.send_card(uid, t, btns, ph),
    )

    webhook_url = f"https://{cfg.app_phase.value.lower()}.example.com/telegram/webhook"  # TODO ajustar via env
    channel = TelegramWebhookChannel(
        token=cfg.telegram_bot_token,
        webhook_url=webhook_url,
        allowed_user_ids=cfg.telegram_allowed_user_ids,
        on_photo=on_photo,
        on_callback=on_callback,
        on_text=on_text,
    )
    await channel.setup_webhook()

    _state["channel"] = channel
    _state["cfg"] = cfg
    yield
    await channel.shutdown()


app = FastAPI(lifespan=lifespan)


@app.post("/telegram/webhook")
async def telegram_webhook(request: Request) -> Response:
    payload = await request.json()
    channel: TelegramWebhookChannel = _state["channel"]
    await channel.process_update(payload)
    return Response(status_code=200)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "phase": _state.get("cfg", AppConfig()).app_phase.value}
```

- [ ] **Step 2: Extrair handlers compartilhados**

Refatoração necessária — `src/main.py` e `src/server.py` compartilham os mesmos handlers de mensagem.

Criar `src/handlers.py`:
```python
"""Handlers de mensagem reutilizados entre main.py (Fase A) e server.py (Fase B)."""
from typing import Awaitable, Callable

from src.agent.identify import IdentifierAgent
from src.fifo.motor import FIFOMotor, InsufficientStockError, NoSaldoError
from src.hitl.card import render_alternatives_card, render_classification_card
from src.hitl.session import SessionStore
from src.logging_setup import get_logger
from src.models import ClassificationResult, TransactionState
from src.storage.base import Storage

_log = get_logger(__name__)


SendText = Callable[[int, str], Awaitable[None]]
SendCard = Callable[..., Awaitable[None]]


def build_handlers(
    agent: IdentifierAgent,
    sessions: SessionStore,
    fifo: FIFOMotor,
    storage: Storage,
    awaiting_qty: dict[int, str],
    send_text: SendText,
    send_card: SendCard,
):
    """Retorna (on_photo, on_callback, on_text)."""

    async def on_photo(photo_bytes: bytes, user_id: int) -> None:
        try:
            await send_text(user_id, "🔄 Analisando foto...")
            from pathlib import Path
            result = await agent.identify(
                photo_bytes=photo_bytes,
                uploads_dir=Path("./data/uploads"),
                user_id=user_id,
            )
            sessions.create(result, user_id=user_id)
            card = render_classification_card(result)
            await send_card(user_id, card.text, card.inline_buttons, photo_bytes)
        except Exception as e:
            _log.exception("on_photo_failed", error=str(e))
            await send_text(user_id, f"❌ Erro: {e}")

    async def on_callback(data: str, user_id: int) -> None:
        try:
            parts = data.split(":", 2)
            action = parts[0]
            tx_id = parts[1] if len(parts) > 1 else ""
            pending = sessions.get(tx_id)
            if not pending:
                await send_text(user_id, "⚠️ Transação não encontrada.")
                return
            result = ClassificationResult.model_validate_json(pending.classification_json)

            if action == "confirm":
                sessions.update_state(tx_id, TransactionState.CONFIRMADO)
                awaiting_qty[user_id] = tx_id
                await send_text(
                    user_id,
                    f"✅ Confirmado `{result.identified_part.code}`. Qual a *quantidade*?",
                )
            elif action == "correct":
                awaiting_qty[user_id] = f"correct:{tx_id}"
                await send_text(user_id, "✏️ Digite o código correto:")
            elif action == "alts":
                card = render_alternatives_card(result)
                await send_card(user_id, card.text, card.inline_buttons)
            elif action == "choose" and len(parts) == 3:
                novo_code = parts[2]
                result.identified_part.code = novo_code
                sessions.create(result, user_id=user_id)
                sessions.update_state(tx_id, TransactionState.CONFIRMADO)
                awaiting_qty[user_id] = tx_id
                await send_text(user_id, f"✅ Escolhido `{novo_code}`. Qual a *quantidade*?")
            elif action == "back":
                card = render_classification_card(result)
                await send_card(user_id, card.text, card.inline_buttons)
            elif action == "cancel":
                sessions.update_state(tx_id, TransactionState.CANCELADO)
                awaiting_qty.pop(user_id, None)
                await send_text(user_id, "❌ Cancelada.")
        except Exception as e:
            _log.exception("on_callback_failed", error=str(e))
            await send_text(user_id, f"❌ Erro: {e}")

    async def on_text(text: str, user_id: int) -> None:
        if user_id not in awaiting_qty:
            await send_text(user_id, "Envie uma foto de peça. /start para ajuda.")
            return
        token = awaiting_qty.pop(user_id)
        try:
            if token.startswith("correct:"):
                tx_id = token.split(":", 1)[1]
                pending = sessions.get(tx_id)
                if not pending:
                    return
                result = ClassificationResult.model_validate_json(pending.classification_json)
                result.identified_part.code = text.strip()
                sessions.create(result, user_id=user_id)
                sessions.update_state(tx_id, TransactionState.CONFIRMADO)
                awaiting_qty[user_id] = tx_id
                await send_text(
                    user_id, f"OK, código `{text.strip()}`. Qual a *quantidade*?"
                )
                return

            tx_id = token
            qty = float(text.replace(",", ".").strip())
            pending = sessions.get(tx_id)
            if not pending:
                await send_text(user_id, "Transação expirada.")
                return
            result = ClassificationResult.model_validate_json(pending.classification_json)
            try:
                movs = fifo.lancar(
                    codigo=result.identified_part.code,
                    qty=qty,
                    foto_url=result.source_image_url,
                    confirmado_por="bruno",
                    confidence=result.identified_part.confidence_score,
                )
                sessions.update_state(tx_id, TransactionState.LANCADO)
                saldo_restante = sum(
                    s.qty_disponivel
                    for s in storage.read_saldos(result.identified_part.code)
                )
                resumo = "\n".join(
                    f"• `{m.lote_baixado}` ({m.nf_baixada}): {m.qty_baixada} PC" for m in movs
                )
                await send_text(
                    user_id,
                    f"✅ Lançado `{result.identified_part.code}`: {qty} PC\n{resumo}\n"
                    f"_Saldo restante:_ {saldo_restante} PC",
                )
            except NoSaldoError:
                await send_text(
                    user_id,
                    f"⚠️ Código `{result.identified_part.code}` sem lote cadastrado.",
                )
            except InsufficientStockError as e:
                await send_text(
                    user_id,
                    f"⚠️ Saldo insuficiente: pedido {e.qty_pedida}, disponível {e.qty_disponivel}.",
                )
        except ValueError:
            awaiting_qty[user_id] = token
            await send_text(user_id, "Quantidade inválida. Digite um número.")
        except Exception as e:
            _log.exception("on_text_failed", error=str(e))
            await send_text(user_id, f"❌ Erro: {e}")

    return on_photo, on_callback, on_text
```

E refatorar `src/main.py` para também usar `build_handlers` (DRY):

> No main.py, substituir as três funções `on_photo`, `on_callback`, `on_text` por:
> ```python
> from src.handlers import build_handlers
> awaiting_qty: dict[int, str] = {}
> on_photo, on_callback, on_text = build_handlers(
>     agent=agent, sessions=sessions, fifo=fifo, storage=storage,
>     awaiting_qty=awaiting_qty,
>     send_text=lambda uid, t: channel.send_text(uid, t),
>     send_card=lambda uid, t, btns, ph=None: channel.send_card(uid, t, btns, ph),
> )
> ```

- [ ] **Step 3: Criar `deploy/Dockerfile`**

```dockerfile
FROM python:3.12-slim

# uv para instalar dependências
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Cache de deps
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --extra fase-b --no-dev

# Código
COPY src ./src
COPY scripts ./scripts

# Dados persistentes em volume
VOLUME ["/app/data", "/app/logs"]

ENV PYTHONUNBUFFERED=1
EXPOSE 8000

CMD ["uv", "run", "uvicorn", "src.server:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 4: Criar `deploy/docker-compose.yml`**

```yaml
version: "3.9"
services:
  bot:
    build:
      context: ..
      dockerfile: deploy/Dockerfile
    env_file:
      - ../.env.production
    volumes:
      - bot_data:/app/data
      - bot_logs:/app/logs
      - ./secrets:/app/secrets:ro
    restart: unless-stopped
    ports:
      - "127.0.0.1:8000:8000"

volumes:
  bot_data:
  bot_logs:
```

- [ ] **Step 5: Commit**

```bash
git add "Projetos/Automatização Bruno/src/server.py" \
        "Projetos/Automatização Bruno/src/handlers.py" \
        "Projetos/Automatização Bruno/deploy/"
git commit -m "feat(bruno): FastAPI server Fase B + handlers compartilhados (DRY) + Dockerfile"
```

---

### Task 23: nginx + systemd (deploy VPS)

**Files:**
- Create: `Projetos/Automatização Bruno/deploy/nginx.conf`
- Create: `Projetos/Automatização Bruno/deploy/systemd/automacao-bruno.service`

- [ ] **Step 1: `nginx.conf`**

```nginx
server {
    listen 443 ssl http2;
    server_name bruno.thauma.consulting;

    ssl_certificate     /etc/letsencrypt/live/bruno.thauma.consulting/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/bruno.thauma.consulting/privkey.pem;

    location /telegram/webhook {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 90s;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000;
    }
}
```

- [ ] **Step 2: `systemd/automacao-bruno.service`**

```ini
[Unit]
Description=Automacao Bruno Telegram Bot (POC)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/automacao-bruno
ExecStart=/usr/bin/docker compose -f deploy/docker-compose.yml up -d
ExecStop=/usr/bin/docker compose -f deploy/docker-compose.yml down

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 3: Documentar deploy em `deploy/README.md`**

````markdown
# Deploy Automação Bruno na VPS Hostinger

## Pré-requisitos
- VPS Hostinger com Docker + Docker Compose
- Domínio `bruno.thauma.consulting` apontando para IP do VPS
- nginx + certbot já instalados (compartilhados com Higia)

## Setup inicial (uma vez)

```bash
# No VPS:
sudo mkdir -p /opt/automacao-bruno
sudo chown $USER:$USER /opt/automacao-bruno
cd /opt/automacao-bruno
git clone <repo> .

# Configurar .env.production (copiar .env.example)
cp .env.example .env.production
nano .env.production  # APP_PHASE=B + creds

# Subir certificado SSL
sudo certbot --nginx -d bruno.thauma.consulting

# Copiar nginx.conf
sudo cp deploy/nginx.conf /etc/nginx/sites-available/automacao-bruno
sudo ln -s /etc/nginx/sites-available/automacao-bruno /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Subir container
docker compose -f deploy/docker-compose.yml up -d --build

# Habilitar systemd unit
sudo cp deploy/systemd/automacao-bruno.service /etc/systemd/system/
sudo systemctl enable automacao-bruno
sudo systemctl start automacao-bruno
```

## Re-deploy

```bash
git pull
docker compose -f deploy/docker-compose.yml up -d --build
```

## Logs

```bash
docker compose -f deploy/docker-compose.yml logs -f --tail=100
tail -f /opt/automacao-bruno/data/../logs/app.log
```

## Carga inicial dos PDFs (uma vez)

```bash
docker compose -f deploy/docker-compose.yml exec bot \
  uv run scripts/ingest.py --pdf-dir /app/data/pdfs
```
````

- [ ] **Step 4: Commit**

```bash
git add "Projetos/Automatização Bruno/deploy/nginx.conf" \
        "Projetos/Automatização Bruno/deploy/systemd/" \
        "Projetos/Automatização Bruno/deploy/README.md"
git commit -m "feat(bruno): deploy VPS (nginx, systemd, doc operacional)"
```

---

### Task 24: SheetsStorage (Fase B)

**Files:**
- Create: `Projetos/Automatização Bruno/src/storage/sheets.py`

- [ ] **Step 1: Implementar `src/storage/sheets.py`**

```python
"""SheetsStorage Fase B — Google Sheets via gspread."""
import json
from datetime import datetime, timezone
from pathlib import Path

import gspread
from google.oauth2.service_account import Credentials

from src.logging_setup import get_logger
from src.models import Movimentacao, SaldoLote

_log = get_logger(__name__)


SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.readonly",
]


class SheetsStorage:
    """Storage Fase B com Google Sheets. Estrutura de abas igual ExcelStorage."""

    def __init__(self, creds_path: Path | str, sheet_id: str) -> None:
        creds = Credentials.from_service_account_file(str(creds_path), scopes=SCOPES)
        self._gc = gspread.authorize(creds)
        self._wb = self._gc.open_by_key(sheet_id)
        self._bootstrap_if_empty()

    def _bootstrap_if_empty(self) -> None:
        existing = {ws.title for ws in self._wb.worksheets()}
        for title, headers in [
            ("saldos", ["lote_id", "codigo_peca", "nf_origem", "qty_original", "qty_disponivel", "data_entrada"]),
            ("movimentacoes", ["timestamp", "codigo_peca", "qty_baixada", "lote_baixado", "nf_baixada", "foto_url", "confirmado_por", "confidence_inicial"]),
            ("auditoria", ["timestamp", "evento", "payload"]),
        ]:
            if title not in existing:
                ws = self._wb.add_worksheet(title=title, rows=1000, cols=len(headers))
                ws.update("A1", [headers])

    def read_saldos(self, codigo_peca: str) -> list[SaldoLote]:
        ws = self._wb.worksheet("saldos")
        rows = ws.get_all_records()
        saldos = [
            SaldoLote(
                lote_id=str(r["lote_id"]),
                codigo_peca=str(r["codigo_peca"]),
                nf_origem=str(r["nf_origem"]),
                qty_original=float(r["qty_original"]),
                qty_disponivel=float(r["qty_disponivel"]),
                data_entrada=datetime.fromisoformat(str(r["data_entrada"])),
            )
            for r in rows
            if str(r.get("codigo_peca")) == codigo_peca
        ]
        saldos.sort(key=lambda s: s.data_entrada)
        return saldos

    def update_saldo(self, lote_id: str, qty_nova: float) -> None:
        ws = self._wb.worksheet("saldos")
        cell = ws.find(lote_id, in_column=1)
        if cell is None:
            raise ValueError(f"lote_id {lote_id} não encontrado")
        ws.update_cell(cell.row, 5, qty_nova)
        _log.info("sheet_saldo_updated", lote_id=lote_id, qty_nova=qty_nova)

    def insert_lote(self, lote: SaldoLote) -> None:
        ws = self._wb.worksheet("saldos")
        ws.append_row(
            [
                lote.lote_id,
                lote.codigo_peca,
                lote.nf_origem,
                lote.qty_original,
                lote.qty_disponivel,
                lote.data_entrada.isoformat(),
            ],
            value_input_option="USER_ENTERED",
        )

    def append_movimentacao(self, mov: Movimentacao) -> None:
        ws = self._wb.worksheet("movimentacoes")
        ws.append_row(
            [
                mov.timestamp.isoformat(),
                mov.codigo_peca,
                mov.qty_baixada,
                mov.lote_baixado,
                mov.nf_baixada,
                mov.foto_url,
                mov.confirmado_por,
                mov.confidence_inicial,
            ],
            value_input_option="USER_ENTERED",
        )
        _log.info("sheet_mov_appended", lote=mov.lote_baixado, qty=mov.qty_baixada)

    def append_auditoria(self, evento: str, payload: dict) -> None:
        ws = self._wb.worksheet("auditoria")
        ws.append_row(
            [datetime.now(tz=timezone.utc).isoformat(), evento, json.dumps(payload, default=str)],
            value_input_option="USER_ENTERED",
        )
```

- [ ] **Step 2: Commit**

```bash
git add "Projetos/Automatização Bruno/src/storage/sheets.py"
git commit -m "feat(bruno): SheetsStorage Fase B (gspread)"
```

**🚦 GATE INTERNO POC-A-6:** Sprint 6 fechado. Containerizado, deploy script pronto.

---

# SPRINT 7 — Métricas + Demo + Gate Comercial (T25-T26) — Estimado 3-5h

---

### Task 25: Subir Fase B no VPS + Bruno usa autônomo

**Files:** nenhum código novo — operação.

- [ ] **Step 1: Build container local + smoke**

```bash
cd "Projetos/Automatização Bruno"
docker compose -f deploy/docker-compose.yml --env-file .env.fase-b up --build
# Em outro terminal:
curl http://localhost:8000/health
```

Expected: `{"status":"ok","phase":"B"}`.

- [ ] **Step 2: Push repo + ssh no VPS, seguir `deploy/README.md`**

```bash
git push origin main
ssh user@vps.hostinger
cd /opt/automacao-bruno && git pull && docker compose -f deploy/docker-compose.yml up -d --build
```

- [ ] **Step 3: Carga inicial dos PDFs no VPS (mesma `data/pdfs/`)**

```bash
scp -r data/pdfs/* user@vps:/opt/automacao-bruno/data/pdfs/
ssh user@vps 'cd /opt/automacao-bruno && docker compose exec bot uv run scripts/ingest.py'
```

- [ ] **Step 4: Setar webhook**

```bash
curl https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://bruno.thauma.consulting/telegram/webhook
```

- [ ] **Step 5: Smoke pessoal — Pedro envia 5 fotos via Telegram para o bot já no VPS**

Verificar:
- Bot responde
- Sheets recebe linha em `movimentacoes`
- Logs no VPS via `docker compose logs -f`

- [ ] **Step 6: Handoff para Bruno**

> **AÇÃO MANUAL — Pedro:** envia username do bot ao Bruno, instrui:
> "Manda foto da peça. Bot responde com identificação. Confirma/corrige. Diz a quantidade. Pronto. Use por 2-3 dias na rotina normal — não precisa avisar nada, eu acompanho os logs."

- [ ] **Step 7: Sócrates monitora dashboard de logs por 2-3 dias**

```bash
# diariamente:
ssh user@vps 'cd /opt/automacao-bruno && docker compose exec bot uv run scripts/metrics.py'
```

**🚦 GATE POC-B:** Após 2-3 dias de uso autônomo:
- ≥30 fotos processadas
- Taxa de confirmação sem correção ≥80%
- Zero erro de saldo
- Bruno conseguiu usar sem intervenção do Pedro

---

### Task 26: Script de métricas

**Files:**
- Create: `Projetos/Automatização Bruno/scripts/metrics.py`

- [ ] **Step 1: Implementar `scripts/metrics.py`**

```python
"""Calcula métricas a partir de logs/app.log + correcoes.jsonl."""
import json
from collections import Counter
from pathlib import Path
from statistics import mean


def main() -> int:
    log_path = Path("logs/app.log")
    if not log_path.exists():
        print("Sem logs/app.log")
        return 1

    events: list[dict] = []
    with log_path.open(encoding="utf-8") as f:
        for line in f:
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                pass

    identifies = [e for e in events if e.get("event") == "identify_done"]
    confirms = [e for e in events if e.get("event") == "fifo_lancado"]

    # Acerto top-1 = % confirmações sem correção (proxy: identifies seguidos de fifo_lancado mesmo code)
    print(f"Total identificações: {len(identifies)}")
    print(f"Total lançamentos FIFO: {len(confirms)}")
    if identifies:
        confidences = [float(e.get("confidence", 0)) for e in identifies]
        print(f"Confiança média top-1: {mean(confidences):.3f}")

    provider_use = Counter(
        e.get("llm_provider_used", "unknown")
        for e in identifies
        if e.get("llm_provider_used")
    )
    print(f"Uso de LLM provider: {dict(provider_use)}")

    emb_use = Counter(
        e.get("embedding_provider", "unknown")
        for e in events
        if e.get("event") == "identify_candidates"
    )
    print(f"Uso de Embedding provider: {dict(emb_use)}")

    # Correções
    cor_path = Path("data/correcoes.jsonl")
    if cor_path.exists():
        corrections = sum(1 for _ in cor_path.open(encoding="utf-8"))
        if identifies:
            print(f"Taxa de correção: {corrections / len(identifies):.1%}")

    # Latência
    durations = [e.get("duration_ms") for e in events if "duration_ms" in e]
    if durations:
        print(f"Latência média (ms): {mean(durations):.0f}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Smoke local**

```bash
uv run scripts/metrics.py
```

- [ ] **Step 3: Commit**

```bash
git add "Projetos/Automatização Bruno/scripts/metrics.py"
git commit -m "feat(bruno): scripts/metrics.py (acerto, latencia, uso de fallback)"
```

---

# Plano de contingência (se Gate POC-A falhar com <70%)

Se a precisão na Fase A for muito baixa, antes de partir pra Fase B:

1. **Inspecionar 3-5 fotos erradas** — qual padrão de erro?
2. **Refinar `GEOMETRY_PROMPT`** usando skill `voltagent-data-ai:prompt-engineer` — adicionar exemplos few-shot do domínio (se Bruno fornecer 3 fotos+códigos canônicos)
3. **Subir top_k** de 5 para 8 (mais candidatos, classificação mais robusta)
4. **Testar Abordagem B (vision-only)** rapidamente — usar mesmos 30-50 PDFs em system prompt único
5. **Avaliar embedding multimodal** (CLIP local) se top_k não resolver

Cada uma dessas opções dispara mini-spec e tasks novas. Sócrates decide qual seguir após análise dos erros.

---

# Spec coverage check (self-review)

Mapeamento de cada decisão D1-D12 do spec para tasks:

| Decisão spec | Task que implementa |
|--------------|---------------------|
| D1 RAG vetorial Abordagem A | T9-T13 (ingest end-to-end) |
| D2 Google `gemini-embedding-2-preview` | T4 (GoogleProvider) |
| D3 OpenAI `text-embedding-3-small` dim=768 fallback | T5 (OpenAIProvider) + T6 (composer) |
| D4 Anthropic `claude-sonnet-4-6` | T7 (AnthropicProvider) |
| D5 OpenRouter fallback | T8 + T9 |
| D6 Faseamento POC-A → POC-B | T20 (Fase A) + T21-T24 (Fase B) |
| D7 VPS Hostinger | T23 (deploy/) |
| D8 Excel A → Sheets B | T17 + T24 |
| D9 Polling A → Webhook B | T19 + T21 |
| D10 5 adapters | T4-T10, T17, T19 |
| D11 Sem CI Anthropic/Google | conftest mocka tudo; smoke separado |
| D12 Single-user allowlist | T19 (`_is_allowed`) |

Coverage 12/12 ✅.

Critério de aceite por gate (POC-A, POC-B, comercial) implementado pelos gates declarados nos sprints.

---

# Próximo passo

Após esse plano salvo: **Pedro escolhe modo de execução** (subagent-driven recomendado para delegar a Prometeu/Pitágoras/Hefesto). Sócrates valida gate entre sprints, não escreve código.
