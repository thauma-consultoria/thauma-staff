"""Wrapper fino para geração de descrição geométrica via LLMProvider."""
from src.providers.llm.base import LLMProvider


async def describe_pdf_png(png_bytes: bytes, llm: LLMProvider) -> str:
    """Gera descrição geométrica de uma imagem PNG via LLMProvider.

    Args:
        png_bytes: Bytes brutos do PNG renderizado do PDF.
        llm: Provedor LLM (AnthropicProvider, ResilientLLM, etc.).

    Returns:
        Descrição textual da geometria da peça (200-400 palavras esperadas).
    """
    return await llm.describe_geometry(png_bytes)
