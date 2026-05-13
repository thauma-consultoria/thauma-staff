"""OpenRouterProvider — fallback que roteia mesmo modelo via OpenRouter."""
import base64
import json
from datetime import UTC, datetime
from typing import Any

import httpx

from src.logging_setup import get_logger
from src.models import ClassificationResult, IdentifiedPart, ProductionData
from src.providers.llm.anthropic import CLASSIFICATION_SYSTEM, GEOMETRY_PROMPT
from src.providers.llm.base import CandidateImage

_log = get_logger(__name__)


class OpenRouterProvider:
    name = "openrouter"

    def __init__(
        self,
        api_key: str,
        model: str = "anthropic/claude-sonnet-4-6",
        base_url: str = "https://openrouter.ai/api/v1",
        timeout_s: float = 60.0,
    ) -> None:
        self._api_key = api_key
        self._model = model
        self._base_url = base_url
        self._timeout = timeout_s

    async def _post(self, payload: dict[str, Any]) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self._timeout) as http:
            r = await http.post(
                f"{self._base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self._api_key}",
                    "HTTP-Referer": "https://thauma.consulting/automacao-bruno",
                    "X-Title": "Automacao Bruno POC",
                },
                json=payload,
            )
            r.raise_for_status()
            return r.json()  # type: ignore[no-any-return]

    async def describe_geometry(self, image_bytes: bytes) -> str:
        b64 = base64.standard_b64encode(image_bytes).decode("ascii")
        payload: dict[str, Any] = {
            "model": self._model,
            "max_tokens": 1000,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": GEOMETRY_PROMPT},
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/png;base64,{b64}"},
                        },
                    ],
                }
            ],
        }
        r = await self._post(payload)
        text: str = r["choices"][0]["message"]["content"]
        _log.info("describe_geometry_ok", chars=len(text), provider=self.name)
        return text

    async def vision_classify(
        self,
        photo_bytes: bytes,
        candidates: list[CandidateImage],
        transaction_id: str,
    ) -> ClassificationResult:
        photo_b64 = base64.standard_b64encode(photo_bytes).decode("ascii")
        content: list[dict[str, Any]] = [
            {"type": "text", "text": "FOTO DA PEÇA DESCONHECIDA (a classificar):"},
            {
                "type": "image_url",
                "image_url": {"url": f"data:image/jpeg;base64,{photo_b64}"},
            },
        ]
        for idx, cand in enumerate(candidates, start=1):
            cand_b64 = base64.standard_b64encode(cand.png_bytes).decode("ascii")
            content.append(
                {
                    "type": "text",
                    "text": (
                        f"CANDIDATO {idx} — código `{cand.code}`. Descrição: {cand.description}"
                    ),
                }
            )
            content.append(
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/png;base64,{cand_b64}"},
                }
            )
        content.append({"type": "text", "text": "Retorne o JSON conforme instruído."})

        payload: dict[str, Any] = {
            "model": self._model,
            "max_tokens": 1500,
            "messages": [
                {"role": "system", "content": CLASSIFICATION_SYSTEM},
                {"role": "user", "content": content},
            ],
        }
        r = await self._post(payload)
        raw: str = r["choices"][0]["message"]["content"].strip()
        # Tolerar fences ```json ... ``` que o modelo às vezes inclui apesar da instrução
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
            raw = raw.strip()

        parsed: dict[str, Any] = json.loads(raw)
        code: str = parsed["code"]
        candidate_by_code = {c.code: c for c in candidates}
        chosen_desc = candidate_by_code[code].description if code in candidate_by_code else ""

        return ClassificationResult(
            transaction_id=transaction_id,
            identified_part=IdentifiedPart(
                code=code,
                description=chosen_desc[:200],
                confidence_score=float(parsed["confidence_score"]),
            ),
            alternatives=[
                IdentifiedPart(
                    code=alt["code"],
                    description=candidate_by_code[alt["code"]].description[:200]
                    if alt["code"] in candidate_by_code
                    else "",
                    confidence_score=float(alt["confidence_score"]),
                )
                for alt in parsed.get("alternatives", [])
            ],
            reasoning=parsed.get("reasoning", ""),
            source_image_url="",
            production_data=ProductionData(timestamp=datetime.now(tz=UTC)),
            llm_provider_used="openrouter",
        )
