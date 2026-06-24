"""以图搜图 — ResNet50 特征向量 + 余弦相似度检索。"""
from __future__ import annotations

import io
import json
import logging
import os
import threading
from urllib.parse import quote
from urllib.request import Request, urlopen

import numpy as np
from PIL import Image

import config
import image_resolver

logger = logging.getLogger(__name__)

INDEX_DIR = os.path.join(os.path.dirname(__file__), "data", "image_index")
VECTORS_PATH = os.path.join(INDEX_DIR, "vectors.npy")
META_PATH = os.path.join(INDEX_DIR, "meta.json")

_model = None
_transform = None
_device = None
_index_lock = threading.Lock()
_vectors: np.ndarray | None = None
_meta: list[dict] | None = None


def _get_device():
    global _device
    if _device is not None:
        return _device
    try:
        import torch

        _device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info("Feature extractor device: %s", _device)
    except ImportError:
        _device = "cpu"
    return _device


def _get_resnet():
    global _model, _transform
    if _model is not None:
        return _model, _transform
    try:
        import torch
        from torchvision import models, transforms

        weights = models.ResNet50_Weights.IMAGENET1K_V2
        model = models.resnet50(weights=weights)
        model.fc = torch.nn.Identity()
        model.eval()
        device = _get_device()
        if device != "cpu":
            model = model.to(device)
        transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ])
        _model = model
        _transform = transform
        logger.info("Image search using ResNet50 feature extractor")
        return _model, _transform
    except ImportError:
        logger.warning("torch/torchvision not installed, using histogram fallback")
        return None, None


def warmup_extractor() -> None:
    """预加载模型（首次运行可能下载权重）。"""
    logger.info("Loading ResNet50 weights if needed...")
    model, transform = _get_resnet()
    if model is None or transform is None:
        logger.info("Using histogram fallback (no torch)")
        return
    import torch

    device = _get_device()
    with torch.no_grad():
        dummy = torch.zeros(1, 3, 224, 224)
        if device != "cpu":
            dummy = dummy.to(device)
        model(dummy)
    logger.info("Feature extractor ready")


def _histogram_feature(img: Image.Image) -> np.ndarray:
    """无 torch 时的轻量特征（颜色 + 灰度布局）。"""
    small = img.resize((32, 32)).convert("L")
    gray = np.array(small, dtype=np.float32).flatten() / 255.0
    rgb = np.array(img.resize((64, 64)).convert("RGB"), dtype=np.float32)
    hist_r = np.histogram(rgb[:, :, 0], bins=32, range=(0, 256))[0].astype(np.float32)
    hist_g = np.histogram(rgb[:, :, 1], bins=32, range=(0, 256))[0].astype(np.float32)
    hist_b = np.histogram(rgb[:, :, 2], bins=32, range=(0, 256))[0].astype(np.float32)
    parts = [gray, hist_r / (hist_r.sum() + 1e-6), hist_g / (hist_g.sum() + 1e-6), hist_b / (hist_b.sum() + 1e-6)]
    feat = np.concatenate(parts)
    return feat.astype(np.float32)


def _normalize(vec: np.ndarray) -> np.ndarray:
    norm = float(np.linalg.norm(vec))
    if norm > 0:
        return (vec / norm).astype(np.float32)
    return vec.astype(np.float32)


def extract_feature(image_bytes: bytes) -> np.ndarray:
    feats = extract_features_batch([image_bytes])
    if not feats or feats[0] is None:
        raise ValueError("failed to extract feature from image bytes")
    return feats[0]


def extract_features_batch(images_bytes: list[bytes]) -> list[np.ndarray | None]:
    """批量提取特征；失败项返回 None。"""
    if not images_bytes:
        return []

    model, transform = _get_resnet()
    if model is None or transform is None:
        out: list[np.ndarray | None] = []
        for raw in images_bytes:
            try:
                img = Image.open(io.BytesIO(raw)).convert("RGB")
                out.append(_normalize(_histogram_feature(img)))
            except Exception:
                out.append(None)
        return out

    import torch

    device = _get_device()
    tensors = []
    index_map: list[int] = []
    results: list[np.ndarray | None] = [None] * len(images_bytes)

    for i, raw in enumerate(images_bytes):
        try:
            img = Image.open(io.BytesIO(raw)).convert("RGB")
            tensors.append(transform(img))
            index_map.append(i)
        except Exception as exc:
            logger.debug("decode image failed: %s", exc)

    if not tensors:
        return results

    batch = torch.stack(tensors)
    if device != "cpu":
        batch = batch.to(device)
    with torch.no_grad():
        feats = model(batch).cpu().numpy().astype(np.float32)

    for j, src_i in enumerate(index_map):
        results[src_i] = _normalize(feats[j])
    return results


def fetch_artifact_image_bytes(
    museum_id: int,
    object_id: str,
    image_path: str,
    image_paths: list[str],
    image_count: int,
    index: int = 0,
    *,
    local_only: bool = False,
) -> bytes | None:
    file_path = image_resolver.resolve_artifact_image_file(
        museum_id, object_id, image_path, image_paths, image_count, index
    )
    if file_path:
        try:
            with open(file_path, "rb") as f:
                return f.read()
        except OSError as exc:
            logger.debug("read local image failed %s: %s", file_path, exc)

    if local_only:
        return None

    oid = quote(str(object_id), safe="")
    base = config.WEB_IMAGE_API_BASE
    url = f"{base}/api/img/{museum_id}/{oid}" if index <= 0 else f"{base}/api/img/{museum_id}/{oid}/{index}"
    try:
        req = Request(url, headers={"User-Agent": "mobile-museum-index/1.0"})
        with urlopen(req, timeout=20) as resp:
            data = resp.read()
            if data:
                return data
    except Exception as exc:
        logger.debug("fetch server image API failed %s: %s", url, exc)
    return None


def index_ready() -> bool:
    return os.path.isfile(VECTORS_PATH) and os.path.isfile(META_PATH)


def load_index(force: bool = False) -> tuple[np.ndarray, list[dict]]:
    global _vectors, _meta
    with _index_lock:
        if _vectors is not None and _meta is not None and not force:
            return _vectors, _meta
        if not index_ready():
            raise FileNotFoundError(
                f"Image index not found. Run: python build_image_index.py (expected {INDEX_DIR})"
            )
        _vectors = np.load(VECTORS_PATH)
        with open(META_PATH, encoding="utf-8") as f:
            _meta = json.load(f)
        if len(_meta) != len(_vectors):
            raise ValueError("Image index vectors/meta length mismatch")
        logger.info("Loaded image index: %s vectors", len(_vectors))
        return _vectors, _meta


def save_index(vectors: np.ndarray, meta: list[dict]) -> None:
    os.makedirs(INDEX_DIR, exist_ok=True)
    np.save(VECTORS_PATH, vectors.astype(np.float32))
    with open(META_PATH, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    with _index_lock:
        global _vectors, _meta
        _vectors = vectors.astype(np.float32)
        _meta = meta
    logger.info("Saved image index: %s vectors -> %s", len(meta), INDEX_DIR)


def search_by_feature(
    query_vec: np.ndarray,
    museum_ids: list[int] | None = None,
    dynasties: list[str] | None = None,
    dynasty_map: dict[tuple[int, str], str] | None = None,
    page: int = 1,
    size: int = 50,
) -> tuple[list[tuple[int, str, float]], int]:
    """返回 [(museum_id, object_id, similarity), ...] 及总数。"""
    vectors, meta = load_index()
    query = _normalize(query_vec)
    scores = vectors @ query

    hits: list[tuple[int, str, float]] = []
    museum_set = set(museum_ids) if museum_ids else None
    dynasty_map = dynasty_map or {}

    for i, item in enumerate(meta):
        mid = int(item["museum_id"])
        oid = str(item["object_id"])
        if museum_set is not None and mid not in museum_set:
            continue
        if dynasties:
            dyn = dynasty_map.get((mid, oid), "")
            if not any(d in dyn for d in dynasties):
                continue
        sim = float(scores[i])
        hits.append((mid, oid, sim))

    hits.sort(key=lambda x: x[2], reverse=True)
    total = len(hits)
    start = max(0, (page - 1) * size)
    end = start + size
    return hits[start:end], total


def search_by_image_bytes(
    image_bytes: bytes,
    museum_ids: list[int] | None = None,
    dynasties: list[str] | None = None,
    dynasty_map: dict[tuple[int, str], str] | None = None,
    page: int = 1,
    size: int = 50,
) -> tuple[list[tuple[int, str, float]], int]:
    feat = extract_feature(image_bytes)
    return search_by_feature(feat, museum_ids, dynasties, dynasty_map, page, size)
