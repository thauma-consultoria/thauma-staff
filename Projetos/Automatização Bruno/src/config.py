"""Configuração da aplicação carregada de variáveis de ambiente."""
from enum import StrEnum
from pathlib import Path
from typing import Any

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, EnvSettingsSource, SettingsConfigDict


class AppPhase(StrEnum):
    A = "A"
    B = "B"


class _CsvEnvSource(EnvSettingsSource):
    """EnvSettingsSource que trata 'telegram_allowed_user_ids' como string CSV.

    pydantic-settings v2 chama json.loads() em campos cujo tipo é detectado
    como 'complex' (list, dict, …) antes de qualquer validator Pydantic.
    Sobrescrevemos prepare_field_value para devolver o valor raw (str) nesse
    campo, deixando o field_validator do modelo fazer a conversão.
    """

    _CSV_FIELDS = {"telegram_allowed_user_ids"}

    def prepare_field_value(
        self,
        field_name: str,
        field: Any,
        value: Any,
        value_is_complex: bool,
    ) -> Any:
        if field_name in self._CSV_FIELDS and isinstance(value, str):
            # Retorna a string bruta; o field_validator cuidará da conversão.
            return value
        return super().prepare_field_value(field_name, field, value, value_is_complex)


class AppConfig(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # LLM
    anthropic_api_key: str
    openrouter_api_key: str

    # Embedding
    google_ai_key: str
    openai_api_key: str

    # Telegram
    telegram_bot_token: str
    telegram_allowed_user_ids: list[int] = Field(default_factory=list)

    # Phase
    app_phase: AppPhase = AppPhase.A

    # Storage Fase B
    google_sheets_creds_path: Path | None = None
    google_sheet_id: str | None = None

    # Paths
    chroma_path: Path = Path("./data/chroma_db")
    excel_path: Path = Path("./data/saldos.xlsx")
    uploads_path: Path = Path("./data/uploads")
    logs_path: Path = Path("./logs")
    log_level: str = "INFO"

    @classmethod
    def settings_customise_sources(  # type: ignore[override]
        cls,
        settings_cls: type[BaseSettings],
        **kwargs: Any,
    ) -> tuple[Any, ...]:
        """Substitui EnvSettingsSource pela versão que suporta CSV."""
        init_kwargs = kwargs.get("init_settings")
        env_settings = _CsvEnvSource(settings_cls)
        dotenv_settings = kwargs.get("dotenv_settings")
        secrets_settings = kwargs.get("secrets_settings")
        sources = []
        if init_kwargs is not None:
            sources.append(init_kwargs)
        sources.append(env_settings)
        if dotenv_settings is not None:
            sources.append(dotenv_settings)
        if secrets_settings is not None:
            sources.append(secrets_settings)
        return tuple(sources)

    @field_validator("telegram_allowed_user_ids", mode="before")
    @classmethod
    def _split_ids(cls, v: str | list[int] | int) -> list[int]:
        """Converte string CSV ou int bare em list[int]."""
        if isinstance(v, str):
            return [int(x.strip()) for x in v.split(",") if x.strip()]
        if isinstance(v, int):
            return [v]
        return list(v)

    @model_validator(mode="after")
    def _validate_phase_b_creds(self) -> "AppConfig":
        if self.app_phase == AppPhase.B and not self.google_sheets_creds_path:
            raise ValueError("GOOGLE_SHEETS_CREDS_PATH é obrigatório em APP_PHASE=B")
        return self
