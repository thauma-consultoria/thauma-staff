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
