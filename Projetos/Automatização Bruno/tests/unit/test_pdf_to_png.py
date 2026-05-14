"""Testa conversão PDF → PNG via PyMuPDF."""
from pathlib import Path

import pytest

from src.ingestion.pdf_to_png import convert_pdf_to_png


def test_pdf_renders_png(fixtures_dir: Path, tmp_path: Path) -> None:
    pdf = fixtures_dir / "pdf_sample.pdf"
    if not pdf.exists():
        pytest.skip("fixture pdf_sample.pdf ausente — Pedro precisa fornecer")

    png = tmp_path / "out.png"
    convert_pdf_to_png(pdf, png, dpi=300)

    assert png.exists()
    assert png.stat().st_size > 1000  # pelo menos 1KB


def test_pdf_first_page_only(fixtures_dir: Path, tmp_path: Path) -> None:
    pdf = fixtures_dir / "pdf_sample.pdf"
    if not pdf.exists():
        pytest.skip("fixture pdf_sample.pdf ausente")

    png = tmp_path / "out.png"
    # Não deve falhar mesmo se PDF tem múltiplas páginas
    convert_pdf_to_png(pdf, png)
    assert png.exists()


def test_pdf_uppercase_extension(fixtures_dir: Path, tmp_path: Path) -> None:
    """PDF com extensão .PDF maiúscula deve ser tratado normalmente."""
    # Cria cópia com extensão maiúscula
    pdf_original = fixtures_dir / "pdf_sample.pdf"
    if not pdf_original.exists():
        pytest.skip("fixture pdf_sample.pdf ausente")

    pdf_upper = tmp_path / "SAMPLE_TEST.PDF"
    pdf_upper.write_bytes(pdf_original.read_bytes())

    png = tmp_path / "out_upper.png"
    convert_pdf_to_png(pdf_upper, png, dpi=150)

    assert png.exists()
    assert png.stat().st_size > 100


def test_pdf_creates_parent_dirs(fixtures_dir: Path, tmp_path: Path) -> None:
    """convert_pdf_to_png deve criar diretórios intermediários."""
    pdf = fixtures_dir / "pdf_sample.pdf"
    if not pdf.exists():
        pytest.skip("fixture pdf_sample.pdf ausente")

    nested_png = tmp_path / "sub" / "deep" / "out.png"
    assert not nested_png.parent.exists()

    convert_pdf_to_png(pdf, nested_png)

    assert nested_png.exists()


def test_empty_pdf_raises(tmp_path: Path) -> None:
    """PDF que abre sem páginas deve levantar ValueError.

    pymupdf 1.27+ não permite salvar doc com zero páginas, então simulamos
    o caso via um PDF mínimo válido ao qual removemos todas as páginas em memória
    usando open(filetype='pdf', stream=...) para que page_count seja 0.
    """
    # PDF mínimo com 0 páginas como bytes brutos (estrutura válida mas sem /Pages filho)
    # Usamos stream + filetype para abrir em memória sem página alguma
    zero_page_pdf = b"""%PDF-1.4
1 0 obj<</Type /Catalog /Pages 2 0 R>>endobj
2 0 obj<</Type /Pages /Kids [] /Count 0>>endobj
xref
0 3
0000000000 65535 f\r
0000000009 00000 n\r
0000000058 00000 n\r
trailer<</Size 3 /Root 1 0 R>>
startxref
110
%%EOF"""
    empty_pdf = tmp_path / "empty.pdf"
    empty_pdf.write_bytes(zero_page_pdf)

    with pytest.raises(ValueError, match="vazio"):
        convert_pdf_to_png(empty_pdf, tmp_path / "out.png")
