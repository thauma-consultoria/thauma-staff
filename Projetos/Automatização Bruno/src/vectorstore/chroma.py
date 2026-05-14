"""ChromaDBStore — persiste embeddings em duas coleções paralelas (google e openai)."""
from pathlib import Path

import chromadb
from chromadb.config import Settings

from src.logging_setup import get_logger
from src.models import PartCandidate

_log = get_logger(__name__)


_COLLECTIONS = {"google": "parts_google", "openai": "parts_openai"}


class ChromaDBStore:
    def __init__(self, persist_path: Path) -> None:
        persist_path.mkdir(parents=True, exist_ok=True)
        self._client = chromadb.PersistentClient(
            path=str(persist_path),
            settings=Settings(anonymized_telemetry=False),
        )
        # Garantir que as duas coleções existam
        for tag, name in _COLLECTIONS.items():
            self._client.get_or_create_collection(name=name, metadata={"provider": tag})

    def _coll(self, provider_tag: str):  # type: ignore[no-untyped-def]
        if provider_tag not in _COLLECTIONS:
            raise ValueError(f"provider_tag inválido: {provider_tag}")
        return self._client.get_or_create_collection(name=_COLLECTIONS[provider_tag])

    def add(
        self,
        id: str,
        embedding: list[float],
        metadata: dict[str, str],
        provider_tag: str,
    ) -> None:
        coll = self._coll(provider_tag)
        coll.upsert(ids=[id], embeddings=[embedding], metadatas=[metadata])
        _log.debug("chroma_add", id=id, provider=provider_tag, dim=len(embedding))

    def get_ids(self, provider_tag: str) -> list[str]:
        """Retorna todos os IDs presentes na coleção do provider indicado.

        Usa include=["metadatas"] como mínimo aceito pelos stubs chromadb;
        o que importa é result["ids"] que sempre vem independente do include.
        """
        coll = self._coll(provider_tag)
        result = coll.get(include=["metadatas"])
        ids: list[str] = list(result["ids"])
        return ids

    def query(
        self, embedding: list[float], top_k: int, provider_tag: str
    ) -> list[PartCandidate]:
        coll = self._coll(provider_tag)
        result = coll.query(query_embeddings=[embedding], n_results=top_k)

        # chromadb return is loosely typed; narrow with None checks
        ids_raw = result["ids"][0] if result["ids"] else []
        distances_raw = (
            result["distances"][0] if result["distances"] else []
        )
        metadatas_raw = (
            result["metadatas"][0] if result["metadatas"] else []
        )

        return [
            PartCandidate(
                code=str(id_),
                distance=float(dist),
                metadata={str(k): str(v) for k, v in (meta or {}).items()},
            )
            for id_, dist, meta in zip(
                ids_raw, distances_raw, metadatas_raw, strict=True
            )
        ]
