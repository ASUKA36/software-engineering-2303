# -*- coding: utf-8 -*-
"""
全局配置：工作目录、日志、CSV 列定义、环境变量加载。

设计说明
--------
- ``BASE_DIR`` 指向 ``crawler/``（含 ``museum_spider.py`` 的目录）。
- ``OUTPUT_DIR`` 优先指向仓库内已提交的 ``data/output/``，否则为 ``output/``。
- 日志在 ``setup_logging()`` 中初始化一次，各子模块使用 ``logging.getLogger("spider")``。
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path

try:
    from dotenv import load_dotenv
except ImportError:  # 未安装 python-dotenv 时仍可跑只读脚本 / 单测
    def load_dotenv(*_args, **_kwargs):
        return False

# 本文件位于 museum_crawler/config.py → 包上级为 crawler/
BASE_DIR: Path = Path(__file__).resolve().parent.parent

# 优先加载 crawler/.env，再加载包内 museum_crawler/.env（二选一即可），最后当前工作目录
load_dotenv(BASE_DIR / ".env")
load_dotenv(Path(__file__).resolve().parent / ".env")
load_dotenv()

# 仓库提交的爬虫产出在 data/output/；本地全新爬取仍可用 output/
_MUSEUM_CSV_MARKERS: tuple[str, ...] = (
    "smithsonian_institution.csv",
    "harvard_art_museums.csv",
    "harvard_art_museums.fixed.csv",
    "museum_of_fine_arts_boston.csv",
)

MUSEUM_CSV_FILENAMES: tuple[str, ...] = _MUSEUM_CSV_MARKERS


def _output_dir_has_data(d: Path) -> bool:
    if not d.is_dir():
        return False
    if any((d / name).is_file() for name in _MUSEUM_CSV_MARKERS):
        return True
    return (d / "kg" / "artifacts.csv").is_file()


def resolve_output_dir(base_dir: Path | None = None) -> Path:
    """解析爬虫产出目录。

    优先使用已提交的 ``data/output``（含三馆 CSV / KG），
    否则回退到 ``output``（本地全新爬取）。
    """
    root = Path(base_dir) if base_dir is not None else BASE_DIR
    nested = root / "data" / "output"
    legacy = root / "output"
    if _output_dir_has_data(nested):
        return nested
    if _output_dir_has_data(legacy):
        return legacy
    if nested.is_dir():
        return nested
    return legacy


OUTPUT_DIR: Path = resolve_output_dir()


def iter_museum_csv_paths(
    out_dir: Path | None = None,
    *,
    include_clean: bool = False,
) -> list[Path]:
    """按馆去重后返回已存在的三馆 CSV（哈佛优先 ``*.fixed``）。"""
    d = Path(out_dir) if out_dir is not None else OUTPUT_DIR
    candidates: list[Path] = []
    if include_clean:
        clean_dir = d / "clean"
        candidates.extend(
            [
                clean_dir / "smithsonian_institution.cleaned.csv",
                clean_dir / "harvard_art_museums.fixed.cleaned.csv",
                clean_dir / "harvard_art_museums.cleaned.csv",
                clean_dir / "museum_of_fine_arts_boston.cleaned.csv",
            ]
        )
    candidates.extend(d / name for name in MUSEUM_CSV_FILENAMES)
    seen: set[str] = set()
    paths: list[Path] = []
    for p in candidates:
        key = p.name.replace(".fixed", "").replace(".cleaned", "")
        if key in seen:
            continue
        if p.exists() and p.stat().st_size > 0:
            seen.add(key)
            paths.append(p)
    return paths


def default_harvard_csv(out_dir: Path | None = None) -> Path:
    """哈佛主表：优先 ``harvard_art_museums.fixed.csv``。"""
    d = Path(out_dir) if out_dir is not None else OUTPUT_DIR
    for name in ("harvard_art_museums.fixed.csv", "harvard_art_museums.csv"):
        p = d / name
        if p.exists() and p.stat().st_size > 0:
            return p
    return d / "harvard_art_museums.csv"


LOG_PATH: Path = BASE_DIR / "crawler.log"

# 数值馆别：跨馆合并 CSV/数据库时与 object_id 组成联合唯一键，避免各馆 object_id 撞号
MUSEUM_ID_SMITHSONIAN: int = 1
MUSEUM_ID_HARVARD: int = 2
MUSEUM_ID_MFA_BOSTON: int = 3

# 与《数据库字段设计-三馆平台》《MySQL 设计方案》对齐的统一列名（三馆 CSV/MySQL 共用）
CSV_FIELDS: list[str] = [
    "object_id",
    "museum_id",  # 见上 MUSEUM_ID_*；与 object_id 一起可唯一定位一条藏品
    "title",
    "artist",
    "artist_province",
    "dynasty",
    # Wikidata / 维基增量补全（爬虫初跑为空，见 enrich_wikidata.py）
    "artist_wikidata_id",
    "artist_birth",
    "artist_death",
    "artist_bio",
    "artist_wikipedia_summary",
    "artist_enriched_at",
    "period",
    "period_start_year",  # 由 period 解析，供时间轴/统计
    "period_end_year",
    "type",
    "material",
    "culture",  # 文化/地域标签（对应设计方案 culture_raw）
    "description",
    "provenance",  # 流传经历/出处
    "bibliography",  # 参考文献 / Publication History
    "dimensions",
    "museum",
    "location",
    "detail_url",
    "image_url",  # 主图直链（多图时为第一张）
    "image_urls",  # 全部图直链，`` | `` 分隔（哈佛多图）
    "iiif_manifest_url",  # 主图 IIIF info.json / manifest；其余馆常为空
    "image_path",  # 主图本地相对路径
    "image_paths",  # 全部图本地路径，`` | `` 分隔
    "image_count",  # 成功落盘的图片张数
    "credit_line",
    "accession_number",
    "source_updated_at",  # 馆方源数据更新时间；无可靠字段时为空
    "crawl_date",
]


def blank_artist_enrichment() -> dict[str, str]:
    """三馆爬虫落库时与 Wikidata 增量脚本对齐的空占位。"""
    return {k: "" for k in (
        "artist_wikidata_id",
        "artist_birth",
        "artist_death",
        "artist_bio",
        "artist_wikipedia_summary",
        "artist_enriched_at",
    )}


def setup_logging(level: int = logging.INFO) -> logging.Logger:
    """
    配置根日志：文件 UTF-8 + 控制台。

    应在 ``cli.main`` 最先调用，保证后续模块的 ``getLogger("spider")`` 有处理器。
    """
    log = logging.getLogger("spider")
    if log.handlers:
        return log  # 避免重复 addHandler（如被多次 import / 调用）
    log.setLevel(level)
    fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
    fh = logging.FileHandler(LOG_PATH, encoding="utf-8")  # 持久化到 crawler.log
    fh.setFormatter(fmt)
    sh = logging.StreamHandler(sys.stdout)  # 终端实时输出
    sh.setFormatter(fmt)
    log.addHandler(fh)
    log.addHandler(sh)
    log.propagate = False  # 不向 root logger 冒泡，防止重复打印
    return log
