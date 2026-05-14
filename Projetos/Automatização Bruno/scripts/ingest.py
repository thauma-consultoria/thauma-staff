"""Script de ingestão offline: PDFs → PNGs → descrições → embeddings duais → ChromaDB.

Uso:
    uv run scripts/ingest.py [--pdf-dir PATH] [--limit N]

Por padrão lê PDFs de data/pdfs/ e persiste em data/chroma_db/.

Esquema de ID (chave primária no ChromaDB):
    Regex ^([A-Z]+\\d+) captura o prefixo+número do filename.
    Exemplos:
        DME07644_01.pdf       → code=DME07644
        DMS00578R01 - REF...  → code=DMS00578
        MEC01746_02-3D.PDF    → code=MEC01746

Idempotência por estágio:
    1. PNG existe em data/pdfs_png/<code>.png          → skip pdf_to_png
    2. Descrição existe em data/descriptions/<code>.txt → skip Sonnet
    3. Código presente em AMBAS coleções (google+openai) → skip embeddings+upsert
"""
import argparse
import asyncio
import re
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Protocol

from src.models import PartCandidate

# ---------------------------------------------------------------------------
# Protocols para tipagem dos providers (sem importar as implementações)
# ---------------------------------------------------------------------------


class _EmbeddingProvider(Protocol):
    async def embed(self, text: str) -> list[float]: ...


class _VectorStore(Protocol):
    def get_ids(self, provider_tag: str) -> list[str]: ...

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


class _LLMProvider(Protocol):
    async def describe_geometry(self, image_bytes: bytes) -> str: ...


# ---------------------------------------------------------------------------
# Utilitários importáveis (sem dependências de APIs) — testáveis com fakes
# ---------------------------------------------------------------------------

_CODE_RE = re.compile(r"^([A-Z]+\d+)")


def extract_code_and_meta(pdf_path: Path) -> dict[str, str]:
    """Extrai código primário e constrói metadata a partir do filename.

    Args:
        pdf_path: Path do arquivo PDF (apenas o filename é usado).

    Returns:
        dict com keys: code, filename, family, revision, is_3d, ingested_at.

    Raises:
        ValueError: Se o filename não começar com o padrão [A-Z]+[0-9]+.
    """
    stem = pdf_path.stem  # sem extensão
    m = _CODE_RE.match(stem)
    if not m:
        raise ValueError(f"Filename fora do padrão esperado: {pdf_path.name!r}")

    code = m.group(1)
    family_m = re.match(r"^([A-Z]+)", code)
    family = family_m.group(1) if family_m else code
    # revision = tudo após o código base, até o fim do stem
    revision = stem[len(code):]

    is_3d = "-3d" in stem.lower()

    return {
        "code": code,
        "filename": pdf_path.name,
        "family": family,
        "revision": revision,
        "is_3d": str(is_3d).lower(),
        "ingested_at": datetime.now(tz=UTC).isoformat(),
    }


def collect_pdfs(pdf_dir: Path) -> list[Path]:
    """Lista todos os PDFs do diretório (case-insensitive: .pdf e .PDF).

    Retorna lista ordenada sem duplicatas (diferentes arquivos no FS
    com nomes distintos são todos incluídos).
    """
    lower = list(pdf_dir.glob("*.pdf"))
    upper = list(pdf_dir.glob("*.PDF"))
    # Union por nome para evitar duplicatas em FS case-insensitive (Windows)
    seen: set[str] = set()
    combined: list[Path] = []
    for p in lower + upper:
        if p.name not in seen:
            seen.add(p.name)
            combined.append(p)
    return sorted(combined)


def is_already_indexed(code: str, store: _VectorStore) -> bool:
    """Retorna True somente se o código estiver em AMBAS coleções (google + openai)."""
    return code in store.get_ids("google") and code in store.get_ids("openai")


# ---------------------------------------------------------------------------
# Lógica de ingestão de um PDF (async, com efeitos colaterais de API)
# ---------------------------------------------------------------------------


async def _ingest_one(
    pdf: Path,
    png_dir: Path,
    desc_dir: Path,
    llm: _LLMProvider,
    google: _EmbeddingProvider,
    openai_emb: _EmbeddingProvider,
    store: _VectorStore,
    log: object,
) -> bool:
    """Processa um único PDF: PNG → descrição → embeddings → ChromaDB.

    Cada estágio é idempotente: verifica existência antes de executar.
    Retorna True em sucesso, False em erro (loga o erro internamente).
    """
    from src.ingestion.geometry_describer import describe_pdf_png
    from src.ingestion.pdf_to_png import convert_pdf_to_png
    from src.logging_setup import get_logger

    _log = get_logger(__name__)

    try:
        meta = extract_code_and_meta(pdf)
    except ValueError as e:
        _log.warning("skip_invalid_filename", pdf=pdf.name, error=str(e))
        return False

    code = meta["code"]
    png = png_dir / f"{code}.png"
    desc_file = desc_dir / f"{code}.txt"

    try:
        # Estágio 1: PDF → PNG
        if png.exists():
            _log.info("skip", stage="pdf_to_png", code=code, reason="png_exists")
        else:
            convert_pdf_to_png(pdf, png, dpi=300)

        # Estágio 2: Descrição geométrica via Sonnet
        if desc_file.exists():
            description = desc_file.read_text(encoding="utf-8")
            _log.info("skip", stage="describe", code=code, reason="desc_exists")
        else:
            png_bytes = png.read_bytes()
            description = await describe_pdf_png(png_bytes, llm)  # type: ignore[arg-type]
            desc_file.write_text(description, encoding="utf-8")

        # Estágio 3: Embeddings + upsert no ChromaDB
        if is_already_indexed(code, store):
            _log.info("skip", stage="embed_upsert", code=code, reason="already_indexed")
        else:
            emb_google = await google.embed(description)
            emb_openai = await openai_emb.embed(description)

            # Metadata trunca description para 500 chars (limite recomendado ChromaDB)
            chroma_meta = dict(meta)
            chroma_meta["description"] = description[:500]

            store.add(id=code, embedding=emb_google, metadata=chroma_meta, provider_tag="google")
            store.add(id=code, embedding=emb_openai, metadata=chroma_meta, provider_tag="openai")

        _log.info("ingest_ok", code=code, pdf=pdf.name)
        return True

    except Exception as e:
        _log.error("ingest_failed", code=code, pdf=pdf.name, error=str(e))
        return False


# ---------------------------------------------------------------------------
# Smoke query (valida self-retrieval após ingestão completa)
# ---------------------------------------------------------------------------


async def _smoke_query(
    google_provider: _EmbeddingProvider,
    store: _VectorStore,
    pdf_dir: Path,
    desc_dir: Path,
) -> None:
    """Seleciona um PDF aleatório, gera embedding fresh, busca top-5 em parts_google.

    Esperado: código próprio aparece em rank 1-3.
    Imprime resultado: smoke_query code=<X> rank=<1-5 ou nao_achado>
    """
    import random

    from src.logging_setup import get_logger

    log = get_logger("smoke_query")

    pdfs = collect_pdfs(pdf_dir)
    if not pdfs:
        log.warning("smoke_query_skip", reason="no_pdfs")
        return

    chosen = random.choice(pdfs)
    try:
        meta = extract_code_and_meta(chosen)
    except ValueError:
        log.warning("smoke_query_skip", reason="invalid_filename", pdf=chosen.name)
        return

    code = meta["code"]
    desc_file = desc_dir / f"{code}.txt"
    if not desc_file.exists():
        log.warning("smoke_query_skip", reason="desc_missing", code=code)
        return

    description = desc_file.read_text(encoding="utf-8")
    embedding = await google_provider.embed(description)
    results = store.query(embedding=embedding, top_k=5, provider_tag="google")

    result_codes = [r.code for r in results]

    if code in result_codes:
        rank = result_codes.index(code) + 1
        log.info("smoke_query_result", code=code, rank=rank, top5=result_codes)
        print(f"smoke_query code={code} rank={rank}")
    else:
        log.warning("smoke_query_result", code=code, rank="nao_achado", top5=result_codes)
        print(f"smoke_query code={code} rank=nao_achado")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


async def main() -> int:
    from src.config import AppConfig
    from src.logging_setup import get_logger, setup_logging
    from src.providers.embedding.google import GoogleProvider
    from src.providers.embedding.openai import OpenAIProvider
    from src.providers.llm.anthropic import AnthropicProvider
    from src.providers.llm.openrouter import OpenRouterProvider
    from src.providers.llm.resilient import ResilientLLM
    from src.vectorstore.chroma import ChromaDBStore

    parser = argparse.ArgumentParser(
        description="Ingere PDFs CAD no ChromaDB via embeddings duais (Google + OpenAI)."
    )
    parser.add_argument(
        "--pdf-dir",
        type=Path,
        default=Path("data/pdfs"),
        help="Diretório com os PDFs (padrão: data/pdfs)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limita a N PDFs para debug (padrão: todos)",
    )
    parser.add_argument(
        "--skip-smoke",
        action="store_true",
        help="Pula o smoke query final",
    )
    args = parser.parse_args()

    setup_logging()
    log = get_logger("ingest")
    cfg = AppConfig()  # type: ignore[call-arg]  # campos lidos do .env em runtime

    pdf_dir: Path = args.pdf_dir
    if not pdf_dir.exists():
        log.error("pdf_dir_missing", path=str(pdf_dir))
        return 1

    pdfs = collect_pdfs(pdf_dir)
    if args.limit:
        pdfs = pdfs[: args.limit]

    if not pdfs:
        log.error("no_pdfs_found", pdf_dir=str(pdf_dir))
        return 1

    log.info("ingest_start", total=len(pdfs), pdf_dir=str(pdf_dir))

    png_dir = Path("data/pdfs_png")
    desc_dir = Path("data/descriptions")
    png_dir.mkdir(parents=True, exist_ok=True)
    desc_dir.mkdir(parents=True, exist_ok=True)

    llm = ResilientLLM(
        primary=AnthropicProvider(api_key=cfg.anthropic_api_key),
        fallback=OpenRouterProvider(api_key=cfg.openrouter_api_key),
    )
    google = GoogleProvider(api_key=cfg.google_ai_key)
    openai_emb = OpenAIProvider(api_key=cfg.openai_api_key)
    store = ChromaDBStore(persist_path=cfg.chroma_path)

    ok_count = 0
    for pdf in pdfs:
        ok = await _ingest_one(pdf, png_dir, desc_dir, llm, google, openai_emb, store, log)
        if ok:
            ok_count += 1

    log.info("ingest_done", ok=ok_count, total=len(pdfs), failed=len(pdfs) - ok_count)

    if not args.skip_smoke:
        await _smoke_query(google, store, pdf_dir, desc_dir)

    return 0 if ok_count == len(pdfs) else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
