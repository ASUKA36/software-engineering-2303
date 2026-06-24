"""
从 Graph Agent 工具返回结果中提取溯源信息（detail_url 等）。
Neo4j 结果通常不含 detail_url，通过 artifact_id 桥接 MySQL 补全。
"""

import json
import re
import asyncio
from typing import Any, Optional

ARTIFACT_URI_RE = re.compile(r"entity:artifact:(\d+):([^\s\"\'\],}]+)")
MUSEUM_URI_RE = re.compile(r"entity:museum:(\d+)")
DATA_QUERY_TOOLS = frozenset({"execute_sql", "query_neo4j"})
MAX_SOURCES = 25
MAX_AGGREGATE_HINT_TASKS = 6
SOURCE_SAMPLE_TIMEOUT_SEC = 8

AGGREGATE_COUNT_KEYS = frozenset({
    "cnt", "count", "total", "artifact_count", "num", "quantity",
})

SOURCE_FILTER_FIELDS = frozenset({"museum", "dynasty", "type", "location", "artist"})

SQL_FILTER_PATTERNS = [
    re.compile(r"\b(museum|dynasty|type|location|artist)\b\s+LIKE\s+'%([^']+)%'", re.I),
    re.compile(r"\b(museum|dynasty|type|location|artist)\b\s*=\s*'([^']+)'", re.I),
]


def _source_dedup_key(row: dict) -> str:
    url = (row.get("url") or row.get("detail_url") or "").strip().lower()
    if url:
        return f"url:{url}"
    object_id = (row.get("object_id") or "").strip()
    if object_id:
        return f"oid:{object_id}"
    return ""


def _append_source_if_new(seen: set[str], sources: list[dict], row: dict) -> None:
    key = _source_dedup_key(row)
    if not key or key in seen:
        return
    url = (row.get("url") or row.get("detail_url") or "").strip()
    if not url:
        return
    seen.add(key)
    sources.append({
        k: v for k, v in row.items()
        if not k.startswith("_") and v is not None and k != "detail_url"
    })
    if "url" not in sources[-1]:
        sources[-1]["url"] = url

# (tool_name, json_content, museum_id_hint, optional_query_text)
QuerySnapshot = tuple[str, str, Optional[int], Optional[str]]


def _unpack_snapshot(item: QuerySnapshot | tuple) -> tuple[str, str, Optional[int], Optional[str]]:
    if len(item) >= 4:
        return item[0], item[1], item[2], item[3]
    if len(item) == 3:
        return item[0], item[1], item[2], None
    return item[0], item[1], None, None


def _records_from_tool_output(content: str) -> list[dict]:
    if not content or content.startswith("MySQL"):
        return []
    try:
        data = json.loads(content)
    except (json.JSONDecodeError, TypeError):
        return []
    if isinstance(data, dict):
        if data.get("error"):
            return []
        return [data]
    if isinstance(data, list):
        return [r for r in data if isinstance(r, dict) and not r.get("error")]
    return []


def _parse_artifact_uri(value: str) -> Optional[tuple[str, int, str]]:
    if not value:
        return None
    m = ARTIFACT_URI_RE.search(str(value))
    if not m:
        return None
    museum_id = int(m.group(1))
    object_id = m.group(2)
    return f"entity:artifact:{museum_id}:{object_id}", museum_id, object_id


def _museum_id_from_text(text: str) -> Optional[int]:
    if not text:
        return None
    found: Optional[int] = None
    for m in MUSEUM_URI_RE.finditer(text):
        found = int(m.group(1))
    return found


def _scan_artifact_ids_in_record(record: dict) -> set[str]:
    """扫描记录所有字段中的 entity:artifact URI。"""
    found: set[str] = set()
    for value in record.values():
        if not isinstance(value, str):
            continue
        for m in ARTIFACT_URI_RE.finditer(value):
            found.add(f"entity:artifact:{m.group(1)}:{m.group(2)}")
    return found


def _record_title(record: dict) -> Optional[str]:
    for key in ("title", "name", "a.title", "a.name", "Title", "Name"):
        value = record.get(key)
        if value and str(value).strip():
            return str(value).strip()
    return None


def _has_artifact_identity(record: dict) -> bool:
    if record.get("object_id") or record.get("detail_url") or record.get("url"):
        return True
    if _record_title(record):
        return True
    uri = record.get("uri") or record.get("artifact_id") or record.get("a.uri") or ""
    if str(uri).startswith("entity:artifact:"):
        return True
    return bool(_scan_artifact_ids_in_record(record))


def _collect_aggregate_hints(record: dict, hints: dict[str, set[str]]) -> None:
    if _has_artifact_identity(record):
        return
    for field, value in _aggregate_dimensions(record).items():
        _add_hint(hints, field, value)
    for raw, field in (
        (record.get("m.name") or record.get("museum_name"), "museum"),
        (record.get("d.name"), "dynasty"),
        (record.get("a.type") or record.get("artifact_type"), "type"),
    ):
        if raw and str(raw).strip():
            _add_hint(hints, field, str(raw).strip())


def _record_to_row(record: dict, museum_id_hint: Optional[int] = None) -> Optional[dict]:
    uri_hint = record.get("uri") or record.get("artifact_id") or record.get("a.uri") or ""
    parsed = _parse_artifact_uri(uri_hint) if uri_hint else None

    object_id = record.get("object_id") or (parsed[2] if parsed else "")
    detail_url = record.get("detail_url") or record.get("url") or ""
    museum_id = record.get("museum_id") or (parsed[1] if parsed else None) or museum_id_hint

    scanned_ids = _scan_artifact_ids_in_record(record)
    primary_aid = parsed[0] if parsed else (
        uri_hint if str(uri_hint).startswith("entity:artifact:") else None
    )
    if not primary_aid and scanned_ids:
        primary_aid = next(iter(scanned_ids))

    if not object_id and not detail_url and not primary_aid and not _record_title(record):
        return None

    return {
        "museum": record.get("museum") or record.get("museum_name") or record.get("m.name") or "未知博物馆",
        "url": detail_url,
        "object_id": object_id or (parsed[2] if parsed else ""),
        "title": _record_title(record),
        "image_url": record.get("image_url"),
        "accession_number": record.get("accession_number"),
        "_artifact_ids": scanned_ids or ({primary_aid} if primary_aid else set()),
        "_museum_id": museum_id,
        "_title_key": _record_title(record),
    }


def _mysql_row_to_source(row: dict) -> dict:
    return {
        "museum": row.get("museum") or "未知博物馆",
        "url": row.get("detail_url") or "",
        "object_id": row.get("object_id") or "",
        "title": row.get("title"),
        "image_url": row.get("image_url"),
        "accession_number": row.get("accession_number"),
    }


def _aggregate_dimensions(record: dict) -> dict[str, str]:
    hints: dict[str, str] = {}
    for key in SOURCE_FILTER_FIELDS:
        val = record.get(key)
        if isinstance(val, str) and val.strip():
            hints[key] = val.strip()
    return hints


def _filters_from_sql(sql: str) -> list[tuple[str, str]]:
    if not sql:
        return []
    found: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for pattern in SQL_FILTER_PATTERNS:
        for match in pattern.finditer(sql):
            field = match.group(1).lower()
            value = match.group(2).strip()
            if field not in SOURCE_FILTER_FIELDS or not value:
                continue
            key = (field, value.lower())
            if key in seen:
                continue
            seen.add(key)
            found.append((field, value))
    return found


def _add_hint(hints: dict[str, set[str]], field: str, value: str) -> None:
    if field not in SOURCE_FILTER_FIELDS or not value.strip():
        return
    if len(hints[field]) >= MAX_AGGREGATE_HINT_TASKS:
        return
    hints[field].add(value.strip())


async def _append_sample_sources_from_hints(
    hints: dict[str, set[str]],
    seen: set[str],
    sources: list[dict],
    max_to_add: int,
) -> None:
    if max_to_add <= 0:
        return
    from app.db.mysql_client import MySQLClient

    try:
        added = 0
        dynasty = next(iter(hints.get("dynasty", [])), None)
        artifact_type = next(iter(hints.get("type", [])), None)

        if dynasty and max_to_add > added:
            rows = await MySQLClient.sample_distribution_sources(
                dynasty=dynasty,
                artifact_type=artifact_type,
                limit=min(max_to_add - added, 8),
            )
            for row in rows:
                before = len(sources)
                _append_source_if_new(seen, sources, _mysql_row_to_source(row))
                if len(sources) > before:
                    added += 1

        museums = list(hints.get("museum", set()))[:MAX_AGGREGATE_HINT_TASKS]
        if museums and max_to_add > added:
            rows = await MySQLClient.sample_artifacts_by_field_values(
                "museum", museums, limit=min(max_to_add - added, 8),
            )
            for row in rows:
                before = len(sources)
                _append_source_if_new(seen, sources, _mysql_row_to_source(row))
                if len(sources) > before:
                    added += 1

        task_keys: list[tuple[str, str]] = []
        seen_tasks: set[tuple[str, str]] = set()
        skip_fields = {"museum", "dynasty", "type"}
        for field in ("dynasty", "type", "location", "artist"):
            if field in skip_fields and hints.get(field):
                continue
            for value in list(hints.get(field, set()))[:3]:
                key = (field, value.lower())
                if key in seen_tasks:
                    continue
                seen_tasks.add(key)
                task_keys.append((field, value))

        for field, value in task_keys[:MAX_AGGREGATE_HINT_TASKS]:
            if added >= max_to_add:
                break
            rows = await MySQLClient.sample_artifacts_with_url(field, value, limit=1)
            for row in rows:
                if added >= max_to_add:
                    break
                before = len(sources)
                _append_source_if_new(seen, sources, _mysql_row_to_source(row))
                if len(sources) > before:
                    added += 1
    except Exception as exc:
        import logging
        logging.warning("[SourceExtractor] sample sources from hints failed: %s", exc)


def _iter_data_query_outputs(messages: list[Any]) -> list[QuerySnapshot]:
    pending: dict[str, tuple[str, Optional[int]]] = {}
    outputs: list[QuerySnapshot] = []

    for msg in messages:
        if not isinstance(msg, dict):
            continue
        role = msg.get("role")
        if role == "assistant":
            for tc in msg.get("tool_calls") or []:
                fn = tc.get("function") or {}
                name = fn.get("name") or ""
                tid = tc.get("id")
                if not tid or name not in DATA_QUERY_TOOLS:
                    continue
                args_str = fn.get("arguments") or ""
                museum_id = _museum_id_from_text(args_str) if name == "query_neo4j" else None
                pending[tid] = (name, museum_id)
        elif role == "tool":
            tid = msg.get("tool_call_id")
            content = msg.get("content") or ""
            if tid and tid in pending:
                name, museum_id = pending[tid]
                outputs.append((name, content if isinstance(content, str) else str(content), museum_id, None))

    return outputs


async def _build_sources_from_outputs(outputs: list[QuerySnapshot]) -> list[dict]:
    from app.db.mysql_client import MySQLClient

    seen: set[str] = set()
    sources: list[dict] = []
    artifact_ids: set[str] = set()
    object_ids: set[str] = set()
    title_lookups: set[tuple[str, int]] = set()
    title_only: set[str] = set()
    aggregate_hints: dict[str, set[str]] = {f: set() for f in SOURCE_FILTER_FIELDS}

    for item in outputs:
        tool, content, museum_id_hint, query_text = _unpack_snapshot(item)

        if query_text:
            for field, value in _filters_from_sql(query_text):
                _add_hint(aggregate_hints, field, value)
        if tool == "query_neo4j" and query_text:
            for field, value in _filters_from_sql(query_text.replace("WHERE", " WHERE ")):
                _add_hint(aggregate_hints, field, value)

        for record in _records_from_tool_output(content):
            row = _record_to_row(record, museum_id_hint=museum_id_hint)
            if not row:
                _collect_aggregate_hints(record, aggregate_hints)
                continue

            url = (row.get("url") or "").strip()
            if url:
                clean = {k: v for k, v in row.items() if not k.startswith("_") and v is not None}
                _append_source_if_new(seen, sources, clean)
                continue

            for aid in row.get("_artifact_ids") or set():
                artifact_ids.add(aid)

            object_id = (row.get("object_id") or "").strip()
            museum_id = row.get("_museum_id")
            if object_id:
                object_ids.add(object_id)
                if museum_id is not None:
                    artifact_ids.add(f"entity:artifact:{int(museum_id)}:{object_id}")

            title = row.get("_title_key")
            if title and museum_id is not None:
                title_lookups.add((title, int(museum_id)))
            elif title:
                title_only.add(title)

    if artifact_ids:
        rows = await MySQLClient.get_artifacts_by_artifact_ids(list(artifact_ids))
        for row in rows:
            if not row.get("detail_url"):
                continue
            _append_source_if_new(seen, sources, _mysql_row_to_source(row))

    if object_ids:
        rows = await MySQLClient.get_artifacts_by_object_ids(list(object_ids))
        for row in rows:
            if not row.get("detail_url"):
                continue
            _append_source_if_new(seen, sources, _mysql_row_to_source(row))

    if title_lookups:
        rows = await MySQLClient.get_artifacts_by_titles(list(title_lookups))
        for row in rows:
            if not row.get("detail_url"):
                continue
            _append_source_if_new(seen, sources, _mysql_row_to_source(row))

    if title_only:
        rows = await MySQLClient.get_artifacts_by_title_names(list(title_only))
        for row in rows:
            if not row.get("detail_url"):
                continue
            _append_source_if_new(seen, sources, _mysql_row_to_source(row))

    if any(aggregate_hints.values()):
        await _append_sample_sources_from_hints(
            aggregate_hints,
            seen,
            sources,
            max_to_add=max(0, MAX_SOURCES - len(sources)),
        )

    return [s for s in sources[:MAX_SOURCES] if s.get("url")]


async def extract_sources_with_mysql(
    messages: list[Any] | None = None,
    query_snapshots: list[QuerySnapshot] | None = None,
) -> list[dict]:
    """
    完整溯源提取。优先使用 graph_agent 直接收集的 query_snapshots。
    """
    outputs = query_snapshots or []
    if not outputs and messages:
        outputs = _iter_data_query_outputs(messages)
    if not outputs:
        return []
    try:
        return await asyncio.wait_for(
            _build_sources_from_outputs(outputs),
            timeout=SOURCE_SAMPLE_TIMEOUT_SEC,
        )
    except asyncio.TimeoutError:
        import logging
        logging.warning("[SourceExtractor] source build timed out after %ss", SOURCE_SAMPLE_TIMEOUT_SEC)
        return []


def extract_sources_from_messages(messages: list[Any]) -> list[dict]:
    """同步包装（仅供非 async 上下文调用）。"""
    outputs = _iter_data_query_outputs(messages)
    if not outputs:
        return []
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            return []
    except RuntimeError:
        pass
    import asyncio
    return asyncio.run(_build_sources_from_outputs(outputs))
