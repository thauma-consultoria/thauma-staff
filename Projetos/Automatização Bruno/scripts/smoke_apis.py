"""Smoke test das 4 APIs externas. Roda manual com credenciais reais.

Uso:
    uv run scripts/smoke_apis.py

Nota: o bloco sys.path abaixo é intencional — necessário para importar src.*
quando o script é executado diretamente sem instalar o pacote como editable.
"""
# ruff: noqa: E402
import asyncio
import sys
from pathlib import Path

# Garante que a raiz do projeto está no sys.path para importar src.*
_root = Path(__file__).parent.parent
if str(_root) not in sys.path:
    sys.path.insert(0, str(_root))

import httpx
from anthropic import AsyncAnthropic
from anthropic.types import TextBlock
from google import genai
from openai import AsyncOpenAI

from src.config import AppConfig
from src.logging_setup import get_logger, setup_logging

# Modelos Google a tentar em ordem de preferência
_GOOGLE_EMBED_MODELS = [
    "gemini-embedding-2-preview",
    "text-embedding-004",
    "gemini-embedding-001",
]


async def test_anthropic(cfg: AppConfig) -> bool:
    client = AsyncAnthropic(api_key=cfg.anthropic_api_key)
    try:
        msg = await client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=10,
            messages=[{"role": "user", "content": "Diga 'pong'"}],
        )
        first = msg.content[0] if msg.content else None
        text = first.text if isinstance(first, TextBlock) else ""
        return "pong" in text.lower()
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
    log = get_logger("smoke")
    for model in _GOOGLE_EMBED_MODELS:
        try:
            result = client.models.embed_content(
                model=model,
                contents="ping",
            )
            embeddings = result.embeddings
            if embeddings and embeddings[0].values and len(embeddings[0].values) > 0:
                if model != _GOOGLE_EMBED_MODELS[0]:
                    log.warning(
                        "google_embedding_fallback",
                        intended_model=_GOOGLE_EMBED_MODELS[0],
                        used_model=model,
                    )
                return True
        except Exception as e:
            log.warning("google_model_failed", model=model, error=str(e))
    log.error("google_embedding_all_models_failed")
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
    cfg = AppConfig()  # type: ignore[call-arg]

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
