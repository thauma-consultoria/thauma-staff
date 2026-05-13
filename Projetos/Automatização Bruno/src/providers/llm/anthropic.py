"""AnthropicProvider — Claude Sonnet via Anthropic SDK direto."""
import base64
import json
from datetime import UTC, datetime
from typing import Any

from anthropic import AsyncAnthropic
from anthropic.types import TextBlock

from src.logging_setup import get_logger
from src.models import ClassificationResult, IdentifiedPart, ProductionData
from src.providers.llm.base import CandidateImage

_log = get_logger(__name__)


GEOMETRY_PROMPT = """Atue como um Engenheiro de Qualidade Industrial. \
Descreva a peça nesta imagem com foco em:
1. Contagem e disposição de furos com diâmetro relativo
2. Formato do perímetro (regular, irregular, simétrico)
3. Recortes internos (padrão em 'X', concavidades, abas)
4. Proporção largura/altura aproximada
5. Particularidades visuais marcantes

Use linguagem objetiva, 200-400 palavras. Não cite dimensões absolutas; descreva geometria \
comparável. Retorne apenas a descrição, sem preâmbulo."""


CLASSIFICATION_SYSTEM = """Você é um Engenheiro de Qualidade Industrial classificando uma peça \
em comparação com candidatas conhecidas. Analise a foto da peça desconhecida e compare \
visualmente com cada PNG de referência fornecida (que vêm dos PDFs CAD oficiais).

CRITÉRIOS DE ANÁLISE:
1. Contagem de furos e diâmetro aproximado
2. Formato do perímetro (irregular, simétrico, retangular)
3. Recortes internos (padrão em 'X' centralizado, concavidades)
4. Proporções relativas

RESTRIÇÃO: Retorne APENAS um objeto JSON válido com a estrutura abaixo.
Não adicione comentários, markdown, ou prefixos.

```json
{
  "code": "<código do PDF mais provável>",
  "confidence_score": <0.0 a 1.0>,
  "alternatives": [
    {"code": "<2º mais provável>", "confidence_score": <0.0 a 1.0>},
    {"code": "<3º mais provável>", "confidence_score": <0.0 a 1.0>}
  ],
  "reasoning": "<1-2 frases justificando a escolha geométrica>"
}
```"""


class AnthropicProvider:
    name = "anthropic"

    def __init__(self, api_key: str, model: str = "claude-sonnet-4-6") -> None:
        self._client = AsyncAnthropic(api_key=api_key)
        self._model = model

    async def describe_geometry(self, image_bytes: bytes) -> str:
        b64 = base64.standard_b64encode(image_bytes).decode("ascii")
        msg = await self._client.messages.create(
            model=self._model,
            max_tokens=1000,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/png",
                                "data": b64,
                            },
                        },
                        {"type": "text", "text": GEOMETRY_PROMPT},
                    ],
                }
            ],
        )
        text = "".join(b.text for b in msg.content if isinstance(b, TextBlock))
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
            {
                "type": "text",
                "text": "FOTO DA PEÇA DESCONHECIDA (a classificar):",
            },
            {
                "type": "image",
                "source": {"type": "base64", "media_type": "image/jpeg", "data": photo_b64},
            },
        ]
        # Bloco cacheável: candidatos repetidos entre chamadas terão hit (5min TTL).
        # cache_control="ephemeral" gera 25% premium na escrita, mas 10% no hit — economia
        # relevante quando o mesmo set de 5 candidatos aparece em várias fotos seguidas.
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
                    "type": "image",
                    "source": {"type": "base64", "media_type": "image/png", "data": cand_b64},
                    "cache_control": {"type": "ephemeral"},
                }
            )
        content.append({"type": "text", "text": "Retorne o JSON conforme instruído."})

        msg = await self._client.messages.create(
            model=self._model,
            max_tokens=1500,
            system=CLASSIFICATION_SYSTEM,
            messages=[{"role": "user", "content": content}],  # type: ignore[typeddict-item]
        )
        raw = "".join(b.text for b in msg.content if isinstance(b, TextBlock)).strip()
        # Tolerar fences ```json ... ``` que o modelo às vezes inclui apesar da instrução
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
            raw = raw.strip()

        parsed: dict[str, Any] = json.loads(raw)
        code = parsed["code"]
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
            llm_provider_used="anthropic",
        )
