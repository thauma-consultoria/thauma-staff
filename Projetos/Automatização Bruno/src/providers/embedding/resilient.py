"""ResilientEmbedding — composer com primário + fallback + circuit breaker simples."""
import asyncio
import time
from dataclasses import dataclass

from src.logging_setup import get_logger
from src.providers.embedding.base import EmbeddingProvider

_log = get_logger(__name__)


@dataclass
class _BreakerState:
    consecutive_failures: int = 0
    open_until: float = 0.0


class ResilientEmbedding:
    def __init__(
        self,
        primary: EmbeddingProvider,
        fallback: EmbeddingProvider,
        primary_retry: int = 2,
        retry_backoff_s: float = 2.0,
        breaker_threshold: int = 3,
        breaker_cooldown_s: float = 300.0,
    ) -> None:
        self._primary = primary
        self._fallback = fallback
        self._retry = primary_retry
        self._backoff = retry_backoff_s
        self._breaker_threshold = breaker_threshold
        self._breaker_cooldown = breaker_cooldown_s
        self._breaker = _BreakerState()

    async def embed_with_provider(self, text: str) -> tuple[list[float], str]:
        """Retorna (embedding, nome_do_provider_usado)."""
        if self._breaker_open():
            _log.info("breaker_open_skipping_primary", primary=self._primary.name)
            vec = await self._fallback.embed(text)
            return vec, self._fallback.name

        last_exc: Exception | None = None
        for attempt in range(self._retry + 1):
            try:
                vec = await self._primary.embed(text)
                self._record_success()
                return vec, self._primary.name
            except Exception as e:
                last_exc = e
                _log.warning(
                    "primary_embed_failed",
                    provider=self._primary.name,
                    attempt=attempt,
                    error=str(e),
                )
                if attempt < self._retry:
                    await asyncio.sleep(self._backoff * (2**attempt))

        self._record_failure()

        try:
            vec = await self._fallback.embed(text)
            return vec, self._fallback.name
        except Exception as e:
            raise RuntimeError(
                f"all providers failed: primary={last_exc!r} fallback={e!r}"
            ) from e

    async def embed(self, text: str) -> list[float]:
        vec, _ = await self.embed_with_provider(text)
        return vec

    @property
    def name(self) -> str:
        return f"resilient({self._primary.name}+{self._fallback.name})"

    def _breaker_open(self) -> bool:
        return time.monotonic() < self._breaker.open_until

    def _record_success(self) -> None:
        self._breaker.consecutive_failures = 0

    def _record_failure(self) -> None:
        self._breaker.consecutive_failures += 1
        if self._breaker.consecutive_failures >= self._breaker_threshold:
            self._breaker.open_until = time.monotonic() + self._breaker_cooldown
            _log.error(
                "breaker_opened",
                provider=self._primary.name,
                cooldown_s=self._breaker_cooldown,
            )
