"""Testa dataclasses de domínio."""
from datetime import UTC, datetime

from src.models import (
    ClassificationResult,
    IdentifiedPart,
    Movimentacao,
    SaldoLote,
)


def test_identified_part_serializes_to_dict() -> None:
    part = IdentifiedPart(code="06332", description="Base Coluna", confidence_score=0.98)
    assert part.code == "06332"
    assert part.confidence_score == 0.98


def test_classification_result_with_alternatives() -> None:
    result = ClassificationResult(
        transaction_id="BRUNO-2026-0001",
        identified_part=IdentifiedPart(code="06332", description="Base", confidence_score=0.98),
        alternatives=[IdentifiedPart(code="06351", description="X", confidence_score=0.45)],
        reasoning="4 furos + recorte X",
        source_image_url="data/uploads/1.jpg",
    )
    assert result.identified_part.code == "06332"
    assert len(result.alternatives) == 1


def test_saldo_lote_immutable_fields() -> None:
    lote = SaldoLote(
        lote_id="LOT-2026-001",
        codigo_peca="06332",
        nf_origem="NF-12345",
        qty_original=200.0,
        qty_disponivel=156.0,
        data_entrada=datetime(2026, 4, 15, tzinfo=UTC),
    )
    assert lote.qty_disponivel < lote.qty_original


def test_movimentacao_creation() -> None:
    mov = Movimentacao(
        timestamp=datetime.now(tz=UTC),
        codigo_peca="06332",
        qty_baixada=34.0,
        lote_baixado="LOT-2026-001",
        nf_baixada="NF-12345",
        foto_url="data/uploads/1.jpg",
        confirmado_por="bruno",
        confidence_inicial=0.98,
    )
    assert mov.qty_baixada == 34.0
