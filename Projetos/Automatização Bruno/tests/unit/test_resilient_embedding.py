"""Testa fallback + circuit breaker do ResilientEmbedding."""
import pytest

from src.providers.embedding.resilient import ResilientEmbedding


class FakeProvider:
    def __init__(self, name: str, fail_n_times: int = 0, vector: list[float] | None = None) -> None:
        self.name = name
        self._fail_remaining = fail_n_times
        self._vector = vector or [0.1] * 768
        self.call_count = 0

    async def embed(self, text: str) -> list[float]:
        self.call_count += 1
        if self._fail_remaining > 0:
            self._fail_remaining -= 1
            raise RuntimeError(f"{self.name} simulated failure")
        return self._vector


async def test_primary_success_no_fallback() -> None:
    primary = FakeProvider("p", vector=[1.0] * 768)
    fallback = FakeProvider("f", vector=[2.0] * 768)
    r = ResilientEmbedding(primary=primary, fallback=fallback)

    vec, used = await r.embed_with_provider("texto")

    assert vec == [1.0] * 768
    assert used == "p"
    assert primary.call_count == 1
    assert fallback.call_count == 0


async def test_primary_fails_then_fallback_used() -> None:
    primary = FakeProvider("p", fail_n_times=10)
    fallback = FakeProvider("f", vector=[2.0] * 768)
    r = ResilientEmbedding(primary=primary, fallback=fallback, primary_retry=2)

    vec, used = await r.embed_with_provider("texto")

    assert vec == [2.0] * 768
    assert used == "f"
    assert primary.call_count == 3  # 1 inicial + 2 retries
    assert fallback.call_count == 1


async def test_circuit_breaker_skips_primary_after_threshold() -> None:
    primary = FakeProvider("p", fail_n_times=100)
    fallback = FakeProvider("f", vector=[2.0] * 768)
    r = ResilientEmbedding(
        primary=primary,
        fallback=fallback,
        primary_retry=0,
        breaker_threshold=2,
        breaker_cooldown_s=60,
    )

    # 1ª chamada: primary falha 1x → fallback
    await r.embed_with_provider("a")
    # 2ª chamada: primary falha 2x → breaker abre
    await r.embed_with_provider("b")
    # 3ª chamada: breaker aberto → vai direto pro fallback, primary não chamado
    primary_calls_before = primary.call_count
    await r.embed_with_provider("c")
    assert primary.call_count == primary_calls_before  # primary não foi chamado


async def test_both_fail_raises() -> None:
    primary = FakeProvider("p", fail_n_times=10)
    fallback = FakeProvider("f", fail_n_times=10)
    r = ResilientEmbedding(primary=primary, fallback=fallback, primary_retry=1)

    with pytest.raises(RuntimeError, match="all providers failed"):
        await r.embed_with_provider("texto")
