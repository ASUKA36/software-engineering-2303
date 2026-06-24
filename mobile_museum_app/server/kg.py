"""Neo4j 知识图谱 — 按专题类型筛选文物（museum_id, object_id）。"""
from __future__ import annotations

import logging
import threading

from neo4j import GraphDatabase

import config

logger = logging.getLogger(__name__)

_lock = threading.Lock()
_pairs: list[tuple[int, str]] | None = None
_pair_set: set[tuple[int, str]] | None = None
_filter_sql: tuple[str, tuple] | None = None
_theme_info: dict | None = None

_ARTIFACT_QUERY = """
MATCH (a:Artifact)-[:HAS_TYPE|hasType]->(t:ArtifactType)
WHERE t.id IN $typeIds OR t.canonical_id IN $typeIds
RETURN DISTINCT
  coalesce(a.museumId, a.museum_id) AS museumId,
  coalesce(a.objectId, a.object_id) AS objectId
"""


def _build_in_clause(pairs: list[tuple[int, str]]) -> tuple[str, tuple]:
    if not pairs:
        return "1=0", ()
    placeholders = ",".join(["(%s,%s)"] * len(pairs))
    args: list = []
    for museum_id, object_id in pairs:
        args.extend([museum_id, object_id])
    return f"(museum_id, object_id) IN ({placeholders})", tuple(args)


def _load_from_neo4j() -> list[tuple[int, str]]:
    driver = GraphDatabase.driver(
        config.NEO4J_URI,
        auth=(config.NEO4J_USER, config.NEO4J_PASSWORD),
    )
    try:
        with driver.session() as session:
            rows = session.run(_ARTIFACT_QUERY, typeIds=config.THEME_TYPE_IDS).data()
    finally:
        driver.close()

    pairs: list[tuple[int, str]] = []
    for row in rows:
        museum_id = row.get("museumId")
        object_id = row.get("objectId")
        if museum_id is None or not object_id:
            continue
        pairs.append((int(museum_id), str(object_id)))
    return pairs


def _ensure_loaded(force_reload: bool = False) -> None:
    global _pairs, _pair_set, _filter_sql, _theme_info
    with _lock:
        if _pairs is not None and not force_reload:
            return
        pairs = _load_from_neo4j()
        _pairs = pairs
        _pair_set = set(pairs)
        _filter_sql = _build_in_clause(pairs)
        _theme_info = {
            "name": config.THEME_NAME,
            "nameEn": config.THEME_NAME_EN,
            "description": config.THEME_DESCRIPTION,
            "typeIds": list(config.THEME_TYPE_IDS),
            "artifactCount": len(pairs),
            "source": "neo4j",
        }
        logger.info("Loaded %s theme artifacts from Neo4j", len(pairs))


def get_theme_pairs(force_reload: bool = False) -> list[tuple[int, str]]:
    _ensure_loaded(force_reload)
    with _lock:
        return list(_pairs or [])


def get_theme_filter_sql(force_reload: bool = False) -> tuple[str, tuple]:
    _ensure_loaded(force_reload)
    with _lock:
        assert _filter_sql is not None
        return _filter_sql


def get_theme_info(force_reload: bool = False) -> dict:
    _ensure_loaded(force_reload)
    with _lock:
        return dict(_theme_info or {})


def is_in_theme(museum_id, object_id) -> bool:
    _ensure_loaded(False)
    with _lock:
        return (int(museum_id), str(object_id)) in (_pair_set or set())


def check_connection() -> tuple[bool, str]:
    try:
        _ensure_loaded(force_reload=False)
        count = len(_pairs or [])
        return True, f"ok ({count} artifacts)"
    except Exception as exc:
        logger.exception("Neo4j theme load failed")
        return False, str(exc)
