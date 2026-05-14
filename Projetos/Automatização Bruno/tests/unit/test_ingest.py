"""Testa o pipeline de ingestão: extração de código, metadata, idempotência."""
from pathlib import Path

from scripts.ingest import (
    collect_pdfs,
    extract_code_and_meta,
    is_already_indexed,
)

# ---------------------------------------------------------------------------
# Testes de extração de código e metadata
# ---------------------------------------------------------------------------


class TestExtractCodeAndMeta:
    def test_dme_standard(self) -> None:
        meta = extract_code_and_meta(Path("DME07644_01.pdf"))
        assert meta["code"] == "DME07644"
        assert meta["filename"] == "DME07644_01.pdf"
        assert meta["family"] == "DME"
        assert meta["revision"] == "_01"
        assert meta["is_3d"] == "false"

    def test_mec_3d_uppercase_ext(self) -> None:
        meta = extract_code_and_meta(Path("MEC01746_02-3D.PDF"))
        assert meta["code"] == "MEC01746"
        assert meta["family"] == "MEC"
        assert meta["revision"] == "_02-3D"
        assert meta["is_3d"] == "true"

    def test_dms_with_spaces_and_dots(self) -> None:
        meta = extract_code_and_meta(Path("DMS00578R01 - REF - CH.C.09-1-1.pdf"))
        assert meta["code"] == "DMS00578"
        assert meta["family"] == "DMS"
        # revision é tudo após o código base até a extensão
        assert "R01" in meta["revision"]
        assert meta["is_3d"] == "false"

    def test_mec_no_3d(self) -> None:
        meta = extract_code_and_meta(Path("MEC00704_01.pdf"))
        assert meta["code"] == "MEC00704"
        assert meta["is_3d"] == "false"

    def test_is_3d_case_insensitive(self) -> None:
        # Garante que detecção de 3D seja case-insensitive (hipótese defensiva)
        meta = extract_code_and_meta(Path("MEC00581_01-3d.PDF"))
        assert meta["is_3d"] == "true"

    def test_ingested_at_present(self) -> None:
        meta = extract_code_and_meta(Path("DME07644_01.pdf"))
        assert "ingested_at" in meta
        # deve ser ISO timestamp com T
        assert "T" in meta["ingested_at"]


# ---------------------------------------------------------------------------
# Testes de glob case-insensitive
# ---------------------------------------------------------------------------


class TestCollectPdfs:
    def test_collects_lowercase_pdf(self, tmp_path: Path) -> None:
        (tmp_path / "DME07644_01.pdf").touch()
        pdfs = collect_pdfs(tmp_path)
        assert any(p.name == "DME07644_01.pdf" for p in pdfs)

    def test_collects_uppercase_extension(self, tmp_path: Path) -> None:
        (tmp_path / "DME07713_01.PDF").touch()
        pdfs = collect_pdfs(tmp_path)
        assert any(p.name == "DME07713_01.PDF" for p in pdfs)

    def test_collects_both_extensions(self, tmp_path: Path) -> None:
        (tmp_path / "A.pdf").touch()
        (tmp_path / "B.PDF").touch()
        (tmp_path / "C.txt").touch()  # não deve entrar
        pdfs = collect_pdfs(tmp_path)
        names = [p.name for p in pdfs]
        assert "A.pdf" in names
        assert "B.PDF" in names
        assert "C.txt" not in names

    def test_no_duplicates(self, tmp_path: Path) -> None:
        (tmp_path / "X.pdf").touch()
        (tmp_path / "X.PDF").touch()
        pdfs = collect_pdfs(tmp_path)
        # Cada arquivo físico diferente conta uma vez (nomes distintos no FS)
        assert len(pdfs) == len({p.name for p in pdfs})

    def test_empty_dir_returns_empty(self, tmp_path: Path) -> None:
        assert collect_pdfs(tmp_path) == []

    def test_returns_sorted(self, tmp_path: Path) -> None:
        (tmp_path / "Z.pdf").touch()
        (tmp_path / "A.pdf").touch()
        pdfs = collect_pdfs(tmp_path)
        names = [p.name for p in pdfs]
        assert names == sorted(names)


# ---------------------------------------------------------------------------
# Testes de idempotência (is_already_indexed)
# ---------------------------------------------------------------------------


class TestIsAlreadyIndexed:
    def test_not_indexed_when_no_ids(self) -> None:
        class FakeStore:
            def get_ids(self, provider_tag: str) -> list[str]:
                return []

            def add(self, **_: object) -> None: ...

            def query(self, **_: object) -> list[object]:
                return []

        assert not is_already_indexed("DME07644", FakeStore())

    def test_not_indexed_when_only_google(self) -> None:
        class FakeStore:
            def get_ids(self, provider_tag: str) -> list[str]:
                return ["DME07644"] if provider_tag == "google" else []

            def add(self, **_: object) -> None: ...

            def query(self, **_: object) -> list[object]:
                return []

        assert not is_already_indexed("DME07644", FakeStore())

    def test_indexed_when_both_collections_have_id(self) -> None:
        class FakeStore:
            def get_ids(self, provider_tag: str) -> list[str]:
                return ["DME07644"]  # presente em google e openai

            def add(self, **_: object) -> None: ...

            def query(self, **_: object) -> list[object]:
                return []

        assert is_already_indexed("DME07644", FakeStore())

    def test_not_indexed_different_code(self) -> None:
        class FakeStore:
            def get_ids(self, provider_tag: str) -> list[str]:
                return ["DME07650"]

            def add(self, **_: object) -> None: ...

            def query(self, **_: object) -> list[object]:
                return []

        assert not is_already_indexed("DME07644", FakeStore())
