"""Converte PDF (página 1) em PNG de alta fidelidade."""
from pathlib import Path

import pymupdf

from src.logging_setup import get_logger

_log = get_logger(__name__)


def convert_pdf_to_png(pdf_path: Path, output_path: Path, dpi: int = 300) -> None:
    """Renderiza a página 1 do PDF em PNG escala de cinza com fundo branco.

    Args:
        pdf_path: Caminho para o PDF (suporta extensões .pdf e .PDF).
        output_path: Caminho de saída para o PNG (diretórios criados se necessário).
        dpi: Resolução de renderização (padrão 300 DPI para alta fidelidade).

    Raises:
        ValueError: Se o PDF não tiver nenhuma página.
    """
    doc = pymupdf.open(str(pdf_path))  # type: ignore[no-untyped-call]
    try:
        if doc.page_count == 0:
            raise ValueError(f"PDF vazio: {pdf_path}")
        page = doc[0]
        zoom = dpi / 72.0  # PyMuPDF default é 72 DPI
        matrix = pymupdf.Matrix(zoom, zoom)  # type: ignore[no-untyped-call]
        # colorspace=GRAY para reduzir tamanho; alpha=False para fundo branco
        pix = page.get_pixmap(matrix=matrix, colorspace=pymupdf.csGRAY, alpha=False)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        pix.save(str(output_path))  # type: ignore[no-untyped-call]
        _log.info(
            "pdf_to_png",
            pdf=str(pdf_path),
            png=str(output_path),
            dpi=dpi,
            size_kb=output_path.stat().st_size // 1024,
        )
    finally:
        doc.close()  # type: ignore[no-untyped-call]
