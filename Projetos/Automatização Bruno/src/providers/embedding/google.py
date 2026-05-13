"""GoogleProvider — embedding via gemini-embedding-2-preview."""
import asyncio

from google import genai
from google.genai.types import EmbedContentConfig

from src.logging_setup import get_logger

_log = get_logger(__name__)


class GoogleProvider:
    name = "google"

    def __init__(
        self,
        api_key: str,
        model: str = "gemini-embedding-2-preview",
        output_dimensionality: int = 768,
    ) -> None:
        self._client = genai.Client(api_key=api_key)
        self._model = model
        self._output_dim = output_dimensionality

    async def embed(self, text: str) -> list[float]:
        # google-genai SDK é síncrono; envolver em to_thread para não bloquear loop.
        # output_dimensionality=768 trunca o embedding Matryoshka 3072 para alinhar
        # com OpenAI fallback (dim=768) e o schema do ChromaDB (T10).
        result = await asyncio.to_thread(
            self._client.models.embed_content,
            model=self._model,
            contents=text,
            config=EmbedContentConfig(output_dimensionality=self._output_dim),
        )
        embedding: list[float] = result.embeddings[0].values  # type: ignore[index,assignment]
        _log.debug("google_embed", dim=len(embedding), requested_dim=self._output_dim)
        return list(embedding)
