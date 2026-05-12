"""Modelos de domínio (Pydantic v2)."""
from datetime import datetime
from enum import StrEnum
from typing import Literal

from pydantic import BaseModel, Field


class TransactionState(StrEnum):
    RECEBIDO = "RECEBIDO"
    IDENTIFICADO = "IDENTIFICADO"
    AGUARDANDO_CONFIRMACAO = "AGUARDANDO_CONFIRMACAO"
    CONFIRMADO = "CONFIRMADO"
    LANCADO = "LANCADO"
    ARQUIVADO = "ARQUIVADO"
    CANCELADO = "CANCELADO"


class IdentifiedPart(BaseModel):
    code: str
    description: str
    confidence_score: float = Field(ge=0.0, le=1.0)


class ProductionData(BaseModel):
    quantity: float | None = None
    unit: str = "PC"
    timestamp: datetime


class ClassificationResult(BaseModel):
    transaction_id: str
    identified_part: IdentifiedPart
    alternatives: list[IdentifiedPart] = Field(default_factory=list)
    reasoning: str
    source_image_url: str
    production_data: ProductionData | None = None
    llm_provider_used: Literal["anthropic", "openrouter"] | None = None
    embedding_provider_used: Literal["google", "openai"] | None = None


class SaldoLote(BaseModel):
    lote_id: str
    codigo_peca: str
    nf_origem: str
    qty_original: float
    qty_disponivel: float
    data_entrada: datetime


class Movimentacao(BaseModel):
    timestamp: datetime
    codigo_peca: str
    qty_baixada: float
    lote_baixado: str
    nf_baixada: str
    foto_url: str
    confirmado_por: str
    confidence_inicial: float


class PartCandidate(BaseModel):
    code: str
    distance: float
    metadata: dict[str, str]


class Card(BaseModel):
    text: str
    inline_buttons: list[tuple[str, str]]  # (label, callback_data)
    photo_url: str | None = None


class CardResponse(BaseModel):
    callback_data: str
    user_id: int
