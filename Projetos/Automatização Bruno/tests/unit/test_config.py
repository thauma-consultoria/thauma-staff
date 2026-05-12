"""Testa carregamento de configuração via env."""
import pytest

from src.config import AppConfig, AppPhase


def test_config_loads_phase_a_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_PHASE", "A")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-ant-test")
    monkeypatch.setenv("OPENROUTER_API_KEY", "sk-or-test")
    monkeypatch.setenv("GOOGLE_AI_KEY", "g-test")
    monkeypatch.setenv("OPENAI_API_KEY", "sk-test")
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "123:abc")
    monkeypatch.setenv("TELEGRAM_ALLOWED_USER_IDS", "123,456")

    cfg = AppConfig()

    assert cfg.app_phase == AppPhase.A
    assert cfg.anthropic_api_key == "sk-ant-test"
    assert cfg.telegram_allowed_user_ids == [123, 456]


def test_config_phase_b_requires_sheets_creds(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_PHASE", "B")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "x")
    monkeypatch.setenv("OPENROUTER_API_KEY", "x")
    monkeypatch.setenv("GOOGLE_AI_KEY", "x")
    monkeypatch.setenv("OPENAI_API_KEY", "x")
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "x")
    monkeypatch.setenv("TELEGRAM_ALLOWED_USER_IDS", "1")
    monkeypatch.delenv("GOOGLE_SHEETS_CREDS_PATH", raising=False)

    with pytest.raises(ValueError, match="GOOGLE_SHEETS_CREDS_PATH"):
        AppConfig()
