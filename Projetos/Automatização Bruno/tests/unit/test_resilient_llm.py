"""Testa fallback do ResilientLLM."""
from datetime import UTC, datetime

import pytest

from src.models import ClassificationResult, IdentifiedPart, ProductionData
from src.providers.llm.base import CandidateImage
from src.providers.llm.resilient import ResilientLLM


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
            production_data=ProductionData(timestamp=datetime.now(tz=UTC)),
            llm_provider_used=self.name,  # type: ignore[arg-type]  # FakeLLM.name is str, not Literal
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
