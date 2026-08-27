# -*- coding: utf-8 -*-
"""产出目录解析：仓库数据在 data/output/，脚本不得再默认指向空的 output/。"""
from __future__ import annotations

import unittest
from pathlib import Path

from museum_crawler.config import (
    BASE_DIR,
    OUTPUT_DIR,
    default_harvard_csv,
    iter_museum_csv_paths,
    resolve_output_dir,
)


class ResolveOutputDirTest(unittest.TestCase):
    def test_prefers_nested_data_output_when_csv_exists(self) -> None:
        root = Path(self._tmp())
        nested = root / "data" / "output"
        nested.mkdir(parents=True)
        (nested / "smithsonian_institution.csv").write_text("object_id\n1\n", encoding="utf-8")
        (root / "output").mkdir()
        self.assertEqual(resolve_output_dir(root), nested)

    def test_falls_back_to_legacy_output(self) -> None:
        root = Path(self._tmp())
        legacy = root / "output"
        legacy.mkdir(parents=True)
        (legacy / "museum_of_fine_arts_boston.csv").write_text("object_id\n1\n", encoding="utf-8")
        self.assertEqual(resolve_output_dir(root), legacy)

    def test_empty_tree_uses_legacy_output(self) -> None:
        root = Path(self._tmp())
        self.assertEqual(resolve_output_dir(root), root / "output")

    def _tmp(self) -> str:
        import tempfile

        d = tempfile.mkdtemp(prefix="kg-output-")
        self.addCleanup(lambda: __import__("shutil").rmtree(d, ignore_errors=True))
        return d


class RepoCommittedDataTest(unittest.TestCase):
    def test_default_output_dir_is_committed_data(self) -> None:
        expected = BASE_DIR / "data" / "output"
        self.assertEqual(OUTPUT_DIR.resolve(), expected.resolve())
        self.assertTrue((OUTPUT_DIR / "smithsonian_institution.csv").is_file())
        self.assertTrue((OUTPUT_DIR / "kg" / "artifacts.csv").is_file())

    def test_iter_museum_csvs_covers_three_museums(self) -> None:
        names = {p.name for p in iter_museum_csv_paths(OUTPUT_DIR)}
        self.assertIn("smithsonian_institution.csv", names)
        self.assertIn("harvard_art_museums.fixed.csv", names)
        self.assertIn("museum_of_fine_arts_boston.csv", names)
        self.assertNotIn("harvard_art_museums.csv", names)

    def test_harvard_prefers_fixed_csv(self) -> None:
        self.assertEqual(default_harvard_csv().name, "harvard_art_museums.fixed.csv")

    def test_export_kg_finds_csvs_without_flags(self) -> None:
        paths = iter_museum_csv_paths(OUTPUT_DIR, include_clean=True)
        self.assertGreaterEqual(len(paths), 3)
        museums = {
            "smithsonian_institution.csv",
            "smithsonian_institution.cleaned.csv",
            "harvard_art_museums.fixed.csv",
            "harvard_art_museums.fixed.cleaned.csv",
            "harvard_art_museums.csv",
            "harvard_art_museums.cleaned.csv",
            "museum_of_fine_arts_boston.csv",
            "museum_of_fine_arts_boston.cleaned.csv",
        }
        self.assertTrue({p.name for p in paths} <= museums)


if __name__ == "__main__":
    unittest.main()
