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
        # google-genai untyped return: embeddings e .values são Optional no stub, mas
        # garantidos não-nulos quando a chamada retorna sem exceção.
        embedding: list[float] = result.embeddings[0].values  # type: ignore[index,assignment]
        _log.debug("google_embed", dim=len(embedding))
        return list(embedding)
