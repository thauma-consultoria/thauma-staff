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
