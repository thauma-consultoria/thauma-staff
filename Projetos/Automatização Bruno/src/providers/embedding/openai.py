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
        _log.debug("openai_embed", dim=len(embedding), requested_dim=self._dimensions)
        return embedding
