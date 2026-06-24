"""本地文物图片路径解析与 HTTP 路径生成（对齐 Web 组对接文档）。"""
from __future__ import annotations

import mimetypes
import os
from urllib.parse import quote

import config


def _encode_object_id(object_id: str) -> str:
    return quote(str(object_id), safe="")


def img_web_path(museum_id: int, object_id: str, index: int = 0) -> str:
    oid = _encode_object_id(object_id)
    if index <= 0:
        return f"/api/img/{museum_id}/{oid}"
    return f"/api/img/{museum_id}/{oid}/{index}"


def imgs_web_list(museum_id: int, object_id: str, image_count: int) -> list[str]:
    count = max(int(image_count or 0), 0)
    if count <= 0:
        return [img_web_path(museum_id, object_id, 0)]
    return [img_web_path(museum_id, object_id, i) for i in range(count)]


def collect_local_paths(image_path: str, image_paths: list[str], image_count: int) -> list[str]:
    paths: list[str] = []
    if image_paths:
        paths.extend(image_paths)
    elif image_path:
        paths.append(image_path)
    count = int(image_count or 0)
    if count > len(paths):
        paths.extend([""] * (count - len(paths)))
    elif count > 0:
        paths = paths[:count]
    return paths


def resolve_path_on_disk(path_str: str) -> str | None:
    if not path_str:
        return None
    raw = str(path_str).strip()
    if not raw:
        return None

    candidates = [raw]
    normalized = raw.replace("\\", os.sep).replace("/", os.sep)
    if normalized not in candidates:
        candidates.append(normalized)

    for root in config.IMAGE_ROOTS:
        root = root.strip()
        if not root:
            continue
        candidates.append(os.path.join(root, normalized))
        candidates.append(os.path.join(root, os.path.basename(normalized)))

    for candidate in candidates:
        if os.path.isfile(candidate):
            return os.path.abspath(candidate)
    return None


def resolve_artifact_image_file(
    museum_id: int,
    object_id: str,
    image_path: str,
    image_paths: list[str],
    image_count: int,
    index: int = 0,
) -> str | None:
    paths = collect_local_paths(image_path, image_paths, image_count)
    if not paths:
        return None
    if index < 0 or index >= len(paths):
        return None
    return resolve_path_on_disk(paths[index])


def has_local_image(
    image_path: str,
    image_paths: list[str],
    image_count: int,
    index: int = 0,
) -> bool:
    paths = collect_local_paths(image_path, image_paths, image_count)
    if not paths:
        return False
    target = paths[index] if index < len(paths) else paths[0]
    return resolve_path_on_disk(target) is not None


def guess_mimetype(file_path: str) -> str:
    mime, _ = mimetypes.guess_type(file_path)
    return mime or "application/octet-stream"
