"""ResilientLLM — composer com primário + fallback + circuit breaker."""
import asyncio
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Any, cast

from src.logging_setup import get_logger
from src.models import ClassificationResult
from src.providers.llm.base import CandidateImage, LLMProvider

_log = get_logger(__name__)


@dataclass
class _BreakerState:
    consecutive_failures: int = 0
    open_until: float = 0.0


class ResilientLLM:
    def __init__(
        self,
        primary: LLMProvider,
        fallback: LLMProvider,
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

    @property
    def name(self) -> str:
        return f"resilient({self._primary.name}+{self._fallback.name})"

    async def describe_geometry(self, image_bytes: bytes) -> str:
        return cast(
            str,
            await self._call_with_fallback(
                lambda p: p.describe_geometry(image_bytes),
                op_name="describe_geometry",
            ),
        )

    async def vision_classify(
        self,
        photo_bytes: bytes,
        candidates: list[CandidateImage],
        transaction_id: str,
    ) -> ClassificationResult:
        return cast(
            ClassificationResult,
            await self._call_with_fallback(
                lambda p: p.vision_classify(photo_bytes, candidates, transaction_id),
                op_name="vision_classify",
            ),
        )

    async def _call_with_fallback(
        self,
        op: Callable[[LLMProvider], Awaitable[Any]],
        op_name: str,
    ) -> Any:
        if self._breaker_open():
            _log.info("breaker_open_skipping_primary", primary=self._primary.name, op=op_name)
            return await op(self._fallback)

        last_exc: Exception | None = None
        for attempt in range(self._retry + 1):
            try:
                result = await op(self._primary)
                self._record_success()
                return result
            except Exception as e:
                last_exc = e
                _log.warning(
                    "primary_llm_failed",
                    provider=self._primary.name,
                    op=op_name,
                    attempt=attempt,
                    error=str(e),
                )
                if attempt < self._retry:
                    await asyncio.sleep(self._backoff * (2**attempt))

        self._record_failure()

        try:
            return await op(self._fallback)
        except Exception as e:
            raise RuntimeError(
                f"all LLM providers failed: primary={last_exc!r} fallback={e!r}"
            ) from e

    def _breaker_open(self) -> bool:
        return time.monotonic() < self._breaker.open_until

    def _record_success(self) -> None:
        self._breaker.consecutive_failures = 0

    def _record_failure(self) -> None:
        self._breaker.consecutive_failures += 1
        if self._breaker.consecutive_failures >= self._breaker_threshold:
            self._breaker.open_until = time.monotonic() + self._breaker_cooldown
            _log.error("llm_breaker_opened", primary=self._primary.name)
