"""Configuração centralizada de logging estruturado (structlog JSON)."""
import logging
import sys
from pathlib import Path

import structlog


def setup_logging(level: str = "INFO", logs_path: Path = Path("./logs")) -> None:
    logs_path.mkdir(parents=True, exist_ok=True)
    log_file = logs_path / "app.log"

    handlers: list[logging.Handler] = [
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(log_file, encoding="utf-8"),
    ]

    logging.basicConfig(
        format="%(message)s",
        level=getattr(logging, level.upper()),
        handlers=handlers,
    )

    structlog.configure(
        processors=[
            structlog.stdlib.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )


def get_logger(name: str) -> structlog.stdlib.BoundLogger:
    return structlog.get_logger(name)  # type: ignore[no-any-return]
