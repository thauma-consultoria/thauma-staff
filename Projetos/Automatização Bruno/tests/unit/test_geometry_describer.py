"""Testa wrapper geometry_describer (chamada delegada ao LLMProvider)."""
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.ingestion.geometry_describer import describe_pdf_png


async def test_describe_calls_llm_provider() -> None:
    """describe_pdf_png deve delegar ao LLMProvider e retornar a descrição."""
    fake_llm = MagicMock()
    fake_llm.describe_geometry = AsyncMock(return_value="desc longa sobre a geometria da peca")

    desc = await describe_pdf_png(b"png_bytes_sinteticos", fake_llm)

    fake_llm.describe_geometry.assert_awaited_once_with(b"png_bytes_sinteticos")
    assert desc == "desc longa sobre a geometria da peca"


async def test_describe_returns_string() -> None:
    """Retorno deve ser str, mesmo que LLM devolva string vazia."""
    fake_llm = MagicMock()
    fake_llm.describe_geometry = AsyncMock(return_value="")

    result = await describe_pdf_png(b"qualquer", fake_llm)

    assert isinstance(result, str)
    assert result == ""


async def test_describe_propagates_exception() -> None:
    """Exceções do LLMProvider devem ser propagadas sem silêncio."""
    fake_llm = MagicMock()
    fake_llm.describe_geometry = AsyncMock(side_effect=RuntimeError("API down"))

    with pytest.raises(RuntimeError, match="API down"):
        await describe_pdf_png(b"png", fake_llm)
