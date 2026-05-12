"""Configuração compartilhada para testes pytest."""
from pathlib import Path

import pytest


@pytest.fixture
def fixtures_dir() -> Path:
    """Diretório de fixtures de teste."""
    return Path(__file__).parent / "fixtures"


@pytest.fixture
def tmp_data_dir(tmp_path: Path) -> Path:
    """Diretório temporário emulando data/ do projeto."""
    for sub in ["pdfs", "pdfs_png", "descriptions", "chroma_db", "uploads"]:
        (tmp_path / sub).mkdir(parents=True, exist_ok=True)
    return tmp_path
