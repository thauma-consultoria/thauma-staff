"""Testa ChromaDBStore com duas coleções paralelas."""
from pathlib import Path

from src.vectorstore.chroma import ChromaDBStore


def test_add_and_query_in_google_collection(tmp_path: Path) -> None:
    store = ChromaDBStore(persist_path=tmp_path / "chroma")

    store.add(
        id="06332",
        embedding=[0.1] * 768,
        metadata={"description": "base com 4 furos"},
        provider_tag="google",
    )
    store.add(
        id="06351",
        embedding=[0.9] * 768,
        metadata={"description": "outra peça"},
        provider_tag="google",
    )

    results = store.query(embedding=[0.1] * 768, top_k=2, provider_tag="google")
    assert len(results) == 2
    assert results[0].code == "06332"  # mais próximo


def test_collections_isolated_by_tag(tmp_path: Path) -> None:
    store = ChromaDBStore(persist_path=tmp_path / "chroma")

    store.add(
        id="A", embedding=[0.1] * 768, metadata={"d": "x"}, provider_tag="google"
    )
    store.add(
        id="B", embedding=[0.1] * 768, metadata={"d": "y"}, provider_tag="openai"
    )

    google_results = store.query([0.1] * 768, top_k=10, provider_tag="google")
    openai_results = store.query([0.1] * 768, top_k=10, provider_tag="openai")

    assert {r.code for r in google_results} == {"A"}
    assert {r.code for r in openai_results} == {"B"}
