"""Protocol para providers de embedding."""
from typing import Protocol


class EmbeddingProvider(Protocol):
    name: str

    async def embed(self, text: str) -> list[float]: ...
