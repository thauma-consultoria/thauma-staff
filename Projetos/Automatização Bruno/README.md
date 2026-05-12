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
