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


@pytest.fixture(autouse=True)
def _block_dotenv_in_tests(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    """Bloqueia o carregamento silencioso do .env real durante os testes.

    pydantic-settings resolve o env_file a partir de model_config no momento
    da instanciação. Substituir model_config por uma cópia com env_file
    apontando para um caminho inexistente garante que NENHUM teste acidentalmente
    vaze credenciais reais de produção — cada teste precisa declarar
    explicitamente os env vars de que depende via monkeypatch.setenv().
    """
    from src.config import AppConfig

    nonexistent = str(tmp_path / "this-env-file-does-not-exist.env")
    new_config = dict(AppConfig.model_config)
    new_config["env_file"] = nonexistent
    monkeypatch.setattr(AppConfig, "model_config", new_config)
