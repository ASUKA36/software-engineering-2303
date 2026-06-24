#!/usr/bin/env python3
"""构建以图搜图向量索引。

默认：仅索引 artifact 表中有 image_path/image_paths 的条目（跳过仅有 image_url 官网链接的），
先读本机 IMAGE_ROOTS，若无文件则通过 WEB_IMAGE_API_BASE 读取服务器磁盘上的图片。

用法: python build_image_index.py [--limit N] [--local-only] [--workers 8] [--batch-size 32]
"""
from __future__ import annotations

import argparse
import logging
import sys
import time
from concurrent.futures import ThreadPoolExecutor

import db
import config
import image_resolver
import image_search
import kg

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def split_pipe_field(value):
    if not value:
        return []
    return [p.strip() for p in str(value).split("|") if p.strip()]


def has_local_path_record(image_path: str, image_paths: list[str]) -> bool:
    """数据库是否登记了本地磁盘路径（非仅 image_url 官网链接）。"""
    if image_paths:
        return True
    return bool(str(image_path or "").strip())


def fetch_row_image(row: dict, local_only: bool) -> bytes | None:
    museum_id = int(row["museum_id"])
    object_id = str(row["object_id"])
    image_paths = split_pipe_field(row.get("image_paths"))
    image_path = row.get("image_path") or ""
    image_count = int(row.get("image_count") or 0)
    return image_search.fetch_artifact_image_bytes(
        museum_id, object_id, image_path, image_paths, image_count, 0,
        local_only=local_only,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Build image search vector index")
    parser.add_argument("--limit", type=int, default=0, help="Max artifacts to index (0=all)")
    parser.add_argument(
        "--local-only",
        action="store_true",
        help="仅索引本机 IMAGE_ROOTS 下存在的文件，不请求 WEB_IMAGE_API_BASE",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=8,
        help="并行拉图线程数（默认 8）",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=32,
        help="GPU/CPU 批量提特征大小（默认 32）",
    )
    args = parser.parse_args()

    try:
        filter_sql, filter_args = kg.get_theme_filter_sql()
    except Exception as exc:
        logger.error("Neo4j theme filter failed: %s", exc)
        return 1

    sql = f"""
        SELECT museum_id, object_id, image_path, image_paths, image_count, dynasty
        FROM artifact
        WHERE {filter_sql}
        ORDER BY museum_id, object_id
    """
    rows = db.query_all(sql, filter_args)
    if args.limit > 0:
        rows = rows[: args.limit]

    local_only = args.local_only
    if local_only:
        logger.info("Indexing up to %s theme artifacts (local disk only)...", len(rows))
        logger.info("IMAGE_ROOTS: %s", "; ".join(config.IMAGE_ROOTS) or "(empty)")
    else:
        logger.info("Indexing up to %s theme artifacts (server disk paths)...", len(rows))
        logger.info("IMAGE_ROOTS: %s", "; ".join(config.IMAGE_ROOTS) or "(empty)")
        logger.info("WEB_IMAGE_API_BASE: %s", config.WEB_IMAGE_API_BASE)
        logger.info("Skipping artifacts with no image_path/image_paths (URL-only records)")

    candidates: list[dict] = []
    skip_url_only = 0
    skip_no_file = 0

    for row in rows:
        image_paths = split_pipe_field(row.get("image_paths"))
        image_path = row.get("image_path") or ""
        image_count = int(row.get("image_count") or 0)

        if not has_local_path_record(image_path, image_paths):
            skip_url_only += 1
            continue
        if local_only and not image_resolver.has_local_image(
            image_path, image_paths, image_count, 0
        ):
            skip_no_file += 1
            continue
        candidates.append(row)

    logger.info(
        "Eligible: %s (url-only skipped=%s, no local file skipped=%s)",
        len(candidates), skip_url_only, skip_no_file,
    )
    if not candidates:
        logger.error("No eligible artifacts to index.")
        return 1

    image_search.warmup_extractor()
    logger.info(
        "Fetching images with %s workers, batch size %s...",
        args.workers, args.batch_size,
    )

    vectors = []
    meta = []
    ok = 0
    skip = skip_url_only + skip_no_file
    processed = 0
    t0 = time.time()
    batch_size = max(1, args.batch_size)
    workers = max(1, args.workers)

    for start in range(0, len(candidates), batch_size):
        chunk = candidates[start:start + batch_size]
        fetched: list[tuple[dict, bytes]] = []

        with ThreadPoolExecutor(max_workers=workers) as pool:
            results = list(pool.map(
                lambda row: (row, fetch_row_image(row, local_only)),
                chunk,
            ))

        for row, data in results:
            processed += 1
            if not data:
                skip += 1
                skip_no_file += 1
                if processed <= 3:
                    logger.info(
                        "  [%s/%s] no image: museum_id=%s object_id=%s",
                        processed, len(candidates),
                        row["museum_id"], row["object_id"],
                    )
                continue
            fetched.append((row, data))

        if fetched:
            feats = image_search.extract_features_batch([d for _, d in fetched])
            for (row, _), feat in zip(fetched, feats):
                if feat is None:
                    skip += 1
                    continue
                vectors.append(feat)
                meta.append({
                    "museum_id": int(row["museum_id"]),
                    "object_id": str(row["object_id"]),
                    "image_index": 0,
                })
                ok += 1

        elapsed = time.time() - t0
        rate = processed / elapsed if elapsed > 0 else 0.0
        logger.info(
            "  progress %s/%s | indexed %s | skipped %s | %.1f img/s",
            processed, len(candidates), ok, skip, rate,
        )

    if not vectors:
        logger.error(
            "No images indexed. url-only=%s, no file=%s. Check WEB_IMAGE_API_BASE (%s).",
            skip_url_only,
            skip_no_file,
            config.WEB_IMAGE_API_BASE if not local_only else "N/A (--local-only)",
        )
        return 1

    import numpy as np

    image_search.save_index(np.stack(vectors), meta)
    logger.info(
        "Done: %s indexed, %s skipped (url-only=%s, no file=%s) in %.1fs -> %s",
        ok, skip, skip_url_only, skip_no_file, time.time() - t0, image_search.INDEX_DIR,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
