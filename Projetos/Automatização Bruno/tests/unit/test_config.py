"""Testa carregamento de configuração via env."""
import pytest
from pydantic import ValidationError

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


def test_config_does_not_load_dotenv_in_tests(monkeypatch: pytest.MonkeyPatch) -> None:
    """Verifica que o autouse _block_dotenv_in_tests está ativo.

    Instanciar AppConfig sem nenhum env var setado deve levantar ValidationError.
    Se o .env real fosse carregado, os campos obrigatórios viriam preenchidos
    com credenciais de produção e o teste passaria silenciosamente — o que
    seria uma falha de isolamento.
    """
    for k in (
        "ANTHROPIC_API_KEY",
        "OPENROUTER_API_KEY",
        "GOOGLE_AI_KEY",
        "OPENAI_API_KEY",
        "TELEGRAM_BOT_TOKEN",
        "TELEGRAM_ALLOWED_USER_IDS",
    ):
        monkeypatch.delenv(k, raising=False)

    with pytest.raises(ValidationError):
        AppConfig()


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("123,456", [123, 456]),
        ("42", [42]),
        ("1, 2, 3", [1, 2, 3]),
        ("1, , 2", [1, 2]),
        ("", []),
    ],
)
def test_csv_env_source_parses_telegram_ids(
    monkeypatch: pytest.MonkeyPatch, raw: str, expected: list[int]
) -> None:
    """Fixa o parsing CSV de TELEGRAM_ALLOWED_USER_IDS.

    Protege contra:
    - pydantic-settings mudando o comportamento de list[...] em env vars
    - O workaround _CsvEnvSource derivando do comportamento documentado
    """
    monkeypatch.setenv("ANTHROPIC_API_KEY", "x")
    monkeypatch.setenv("OPENROUTER_API_KEY", "x")
    monkeypatch.setenv("GOOGLE_AI_KEY", "x")
    monkeypatch.setenv("OPENAI_API_KEY", "x")
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "x")
    monkeypatch.setenv("TELEGRAM_ALLOWED_USER_IDS", raw)

    cfg = AppConfig()
    assert cfg.telegram_allowed_user_ids == expected


def test_csv_env_source_rejects_non_integer(monkeypatch: pytest.MonkeyPatch) -> None:
    """Input inválido deve falhar explicitamente, nunca coagir silenciosamente."""
    monkeypatch.setenv("ANTHROPIC_API_KEY", "x")
    monkeypatch.setenv("OPENROUTER_API_KEY", "x")
    monkeypatch.setenv("GOOGLE_AI_KEY", "x")
    monkeypatch.setenv("OPENAI_API_KEY", "x")
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "x")
    monkeypatch.setenv("TELEGRAM_ALLOWED_USER_IDS", "1,abc,3")

    with pytest.raises((ValidationError, ValueError)):
        AppConfig()
