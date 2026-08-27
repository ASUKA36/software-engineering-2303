#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从三馆 CSV 导出规范化知识图谱（三元组 / 实体 / N-Triples）。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from museum_crawler.config import BASE_DIR, OUTPUT_DIR, iter_museum_csv_paths, setup_logging
from museum_crawler.kg_export import export_knowledge_graph

log = setup_logging()


def _resolve_csv_paths(out_dir: Path, explicit: list[Path] | None) -> list[Path]:
    if explicit:
        return [p if p.is_absolute() else (BASE_DIR / p) for p in explicit]
    return iter_museum_csv_paths(out_dir, include_clean=True)


def main() -> int:
    ap = argparse.ArgumentParser(description="导出规范化知识图谱三元组")
    ap.add_argument(
        "--csv",
        type=Path,
        nargs="*",
        help="指定 CSV（默认自动选产出目录下三馆；哈佛优先 fixed 版）",
    )
    ap.add_argument(
        "--out-dir",
        type=Path,
        default=OUTPUT_DIR,
        help="输出目录（默认 data/output 或 output）",
    )
    ap.add_argument(
        "--nt",
        action="store_true",
        help="（已弃用）N-Triples 导出不再支持，保留参数仅为兼容",
    )
    args = ap.parse_args()

    out_dir = args.out_dir if args.out_dir.is_absolute() else BASE_DIR / args.out_dir
    csv_paths = _resolve_csv_paths(out_dir, list(args.csv) if args.csv else None)
    if not csv_paths:
        log.error("未找到可导出的 CSV，请先爬取或指定 --csv")
        return 1

    log.info("[KG] 输入 CSV: %s", ", ".join(p.name for p in csv_paths))
    stats = export_knowledge_graph(
        csv_paths,
        out_dir,
        export_nt=args.nt,
    )
    log.info(
        "[KG] 完成 → %s/kg/ (artifacts=%d, relations=%d, properties=%d)",
        out_dir,
        stats.get("artifact_count", 0),
        stats.get("relation_count", 0),
        stats.get("property_count", 0),
    )
    print(
        f"KG → {out_dir / 'kg'}  对齐表 → {out_dir / 'kg' / 'align'}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
