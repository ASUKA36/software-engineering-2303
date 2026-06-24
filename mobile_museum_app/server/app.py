"""
海外藏中国文物 — 移动端 REST API
运行: pip install -r requirements.txt && python app.py
"""
from __future__ import annotations

import base64
import logging
import os
import secrets
import uuid
from datetime import datetime
from functools import wraps
from urllib.parse import quote
from urllib.request import Request, urlopen

import bcrypt
from flask import Flask, jsonify, request
from flask_cors import CORS

import config
import content_review
import db
import image_resolver
import image_search
import kg

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config["JSON_AS_ASCII"] = False
CORS(app)

os.makedirs(config.UPLOAD_DIR, exist_ok=True)


@app.after_request
def set_json_charset(response):
    if response.content_type and "application/json" in response.content_type:
        response.headers["Content-Type"] = "application/json; charset=utf-8"
    return response


# 简易会话 token -> user_id
SESSIONS: dict[str, int] = {}


def split_pipe_field(value):
    """解析 `` | `` 分隔的多值字段（兼容仅 ``|`` 分隔）。"""
    if not value:
        return []
    return [p.strip() for p in str(value).split("|") if p.strip()]


def enrich_image_fields(data, r):
    image_paths = split_pipe_field(r.get("image_paths"))
    image_path = r.get("image_path") or ""
    image_count = int(r.get("image_count") or 0)
    if image_count <= 0:
        image_count = max(len(image_paths), 1 if image_path else 0)
    museum_id = r["museum_id"]
    object_id = r["object_id"]
    imgs_web = image_resolver.imgs_web_list(museum_id, object_id, image_count)
    data["imgWeb"] = imgs_web[0] if imgs_web else ""
    data["imgsWeb"] = imgs_web
    data["hasLocalImage"] = image_resolver.has_local_image(
        image_path, image_paths, image_count
    )
    data["imageCount"] = image_count
    return data


def artifact_row(r, include_gallery=False):
    if not r:
        return None
    data = {
        "museumId": r["museum_id"],
        "objectId": r["object_id"],
        "title": r["title"],
        "artist": r.get("artist") or "",
        "dynasty": r.get("dynasty") or "",
        "period": r.get("period") or "",
        "periodStartYear": r.get("period_start_year"),
        "periodEndYear": r.get("period_end_year"),
        "type": r.get("type") or "",
        "material": r.get("material") or "",
        "culture": r.get("culture") or "",
        "description": r.get("description") or "",
        "dimensions": r.get("dimensions") or "",
        "museum": r.get("museum") or "",
        "location": r.get("location") or "",
        "imageUrl": r.get("image_url") or "",
        "imagePath": r.get("image_path") or "",
        "detailUrl": r.get("detail_url") or "",
    }
    enrich_image_fields(data, r)
    if include_gallery:
        image_urls = split_pipe_field(r.get("image_urls"))
        image_paths = split_pipe_field(r.get("image_paths"))
        data["imageUrls"] = image_urls
        data["imagePaths"] = image_paths
    if r.get("like_count") is not None:
        data["likeCount"] = int(r.get("like_count") or 0)
    if r.get("hot_score") is not None:
        data["hotScore"] = int(r.get("hot_score") or 0)
    return data


def require_auth(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        token = auth.replace("Bearer ", "").strip() if auth else ""
        uid = SESSIONS.get(token)
        if not uid:
            return jsonify({"code": 401, "message": "请先登录"}), 401
        request.user_id = uid
        return f(*args, **kwargs)

    return wrapper


def _query_user_stats(user_id: int) -> dict:
    fav = db.query_one(
        "SELECT COUNT(*) AS c FROM user_favorite WHERE user_id=%s",
        (user_id,),
    )
    likes = db.query_one(
        "SELECT COUNT(*) AS c FROM user_like WHERE user_id=%s",
        (user_id,),
    )
    comments = db.query_one(
        "SELECT COUNT(*) AS c FROM comment WHERE user_id=%s AND status=1",
        (user_id,),
    )
    return {
        "favoriteCount": int(fav["c"]) if fav else 0,
        "likeCount": int(likes["c"]) if likes else 0,
        "commentCount": int(comments["c"]) if comments else 0,
    }


def normalize_optional_str(value) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text if text else None


def _client_ip() -> str:
    forwarded = request.headers.get("X-Forwarded-For", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.remote_addr or ""


def _record_login_log(
    user_id: int | None,
    username: str,
    result: str = "SUCCESS",
    user_type: str = "APP",
    source_system: str = "app",
) -> None:
    """写入已有 login_logs 表（见 schema-6plus15），失败不影响登录流程。"""
    ua = (request.headers.get("User-Agent") or "")[:255]
    try:
        db.execute(
            """
            INSERT INTO login_logs
              (user_type, user_id, username, result, ip_address, source_system, user_agent, login_time)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (user_type, user_id, username, result, _client_ip(), source_system, ua, datetime.now()),
        )
    except Exception as e:
        logger.warning("insert login_logs failed user=%s: %s", username, e)


def map_db_error(err: Exception, action: str = "操作") -> tuple[str, int]:
    msg = str(err)
    if "Duplicate" in msg or "1062" in msg:
        return "用户名/邮箱/手机号已存在", 400
    if "1146" in msg or "doesn't exist" in msg.lower() or "不存在" in msg:
        return "用户表不存在，请在 MySQL 执行 数据库字段与连接.md 中的 user 建表语句", 500
    if "1142" in msg or "denied" in msg.lower() or "拒绝" in msg:
        return "数据库账号无写入 user 表权限，请执行 GRANT INSERT ON overseas_chinese_artifacts.user", 500
    if "1054" in msg or "Unknown column" in msg:
        return "用户表字段与程序不匹配，请对照文档更新表结构", 500
    if "1364" in msg:
        return "用户表缺少默认值，请检查表结构", 500
    if app.debug:
        return f"{action}失败：{msg}", 500
    return f"{action}失败，请稍后重试", 500


def artifact_select_fields():
    return """
        museum_id, object_id, title, artist, dynasty, period,
        period_start_year, period_end_year, type, material, culture,
        description, dimensions, museum, location, image_url, image_path, detail_url,
        image_urls, image_paths, image_count, hot_score
    """


def alias_theme_filter(filter_sql: str, alias: str = "a") -> str:
    return filter_sql.replace("museum_id", f"{alias}.museum_id").replace("object_id", f"{alias}.object_id")


def aliased_artifact_fields(alias: str = "a") -> str:
    raw = artifact_select_fields().replace("\n", " ")
    parts = [p.strip() for p in raw.split(",") if p.strip()]
    return ", ".join(f"{alias}.{p}" for p in parts)


def parse_museum_id_list(values) -> list[int]:
    ids: list[int] = []
    for raw in values or []:
        try:
            mid = int(raw)
            if mid > 0 and mid not in ids:
                ids.append(mid)
        except (TypeError, ValueError):
            continue
    return ids


def museum_exclude_clause(alias: str | None, exclude_ids: list[int]) -> tuple[str, tuple]:
    if not exclude_ids:
        return "", ()
    col = f"{alias}.museum_id" if alias else "museum_id"
    placeholders = ",".join(["%s"] * len(exclude_ids))
    return f" AND {col} NOT IN ({placeholders})", tuple(exclude_ids)


def theme_filter_or_error():
    """返回专题筛选 SQL 片段；知识图谱不可用时抛出异常。"""
    return kg.get_theme_filter_sql()


@app.get("/api/theme")
def theme_info():
    try:
        return jsonify({"code": 0, "data": kg.get_theme_info()})
    except Exception as e:
        logger.exception("theme info failed")
        return jsonify({"code": 503, "message": "知识图谱连接失败", "detail": str(e)}), 503


def _web_image_proxy_url(museum_id, object_id, index=0):
    oid = quote(str(object_id), safe="")
    base = config.WEB_IMAGE_API_BASE
    if index <= 0:
        return f"{base}/api/img/{museum_id}/{oid}"
    return f"{base}/api/img/{museum_id}/{oid}/{index}"


def _proxy_image_from_web_api(museum_id, object_id, index=0):
    from flask import Response

    url = _web_image_proxy_url(museum_id, object_id, index)
    try:
        req = Request(url, headers={"User-Agent": "mobile-museum/1.0"})
        with urlopen(req, timeout=20) as resp:
            data = resp.read()
            ctype = resp.headers.get("Content-Type", "image/jpeg")
            return Response(data, mimetype=ctype.split(";")[0].strip())
    except Exception as e:
        logger.warning("proxy image from %s failed: %s", url, e)
        return None


def _serve_artifact_image(museum_id, object_id, index=0):
    from flask import send_file

    r = db.query_one(
        """
        SELECT museum_id, object_id, image_path, image_paths, image_count
        FROM artifact WHERE museum_id=%s AND object_id=%s
        """,
        (museum_id, object_id),
    )
    if not r:
        return jsonify({"code": 404, "message": "文物不存在"}), 404
    paths = split_pipe_field(r.get("image_paths"))
    file_path = image_resolver.resolve_artifact_image_file(
        museum_id,
        object_id,
        r.get("image_path") or "",
        paths,
        r.get("image_count") or 0,
        index,
    )
    if file_path:
        return send_file(file_path, mimetype=image_resolver.guess_mimetype(file_path))
    proxied = _proxy_image_from_web_api(museum_id, object_id, index)
    if proxied is not None:
        return proxied
    return jsonify({"code": 404, "message": "本地图片不存在，Web 图片服务不可用"}), 404


@app.get("/api/img/<int:museum_id>/<path:object_id>")
def serve_artifact_image(museum_id, object_id):
    return _serve_artifact_image(museum_id, object_id, 0)


@app.get("/api/img/<int:museum_id>/<path:object_id>/<int:index>")
def serve_artifact_image_at(museum_id, object_id, index):
    return _serve_artifact_image(museum_id, object_id, index)


@app.get("/api/dynasties")
def list_dynasties():
    try:
        filter_sql, filter_args = theme_filter_or_error()
    except Exception as e:
        logger.exception("list_dynasties kg filter failed")
        return jsonify({"code": 503, "message": "知识图谱连接失败", "detail": str(e)}), 503

    sql = f"""
        SELECT DISTINCT dynasty
        FROM artifact
        WHERE {filter_sql}
          AND dynasty IS NOT NULL AND dynasty != ''
        ORDER BY dynasty
    """
    rows = db.query_all(sql, filter_args)
    dynasties = [r["dynasty"] for r in rows if r.get("dynasty")]
    return jsonify({"code": 0, "data": dynasties})


@app.get("/api/types")
def list_types():
    try:
        filter_sql, filter_args = theme_filter_or_error()
    except Exception as e:
        logger.exception("list_types kg filter failed")
        return jsonify({"code": 503, "message": "知识图谱连接失败", "detail": str(e)}), 503

    sql = f"""
        SELECT DISTINCT type
        FROM artifact
        WHERE {filter_sql}
          AND type IS NOT NULL AND type != ''
        ORDER BY type
    """
    rows = db.query_all(sql, filter_args)
    types = [r["type"] for r in rows if r.get("type")]
    return jsonify({"code": 0, "data": types})


@app.get("/api/museums")
def list_museums():
    try:
        filter_sql, filter_args = theme_filter_or_error()
    except Exception as e:
        logger.exception("list_museums kg filter failed")
        return jsonify({"code": 503, "message": "知识图谱连接失败", "detail": str(e)}), 503

    sql = f"""
        SELECT museum_id, MAX(museum) AS museum, COUNT(*) AS cnt
        FROM artifact
        WHERE {filter_sql}
        GROUP BY museum_id
        ORDER BY museum_id
    """
    rows = db.query_all(sql, filter_args)
    data = []
    for r in rows:
        mid = int(r["museum_id"])
        data.append({
            "museumId": mid,
            "name": config.MUSEUM_LABELS.get(mid, r.get("museum") or f"馆别{mid}"),
            "museum": r.get("museum") or "",
            "count": int(r.get("cnt") or 0),
        })
    return jsonify({"code": 0, "data": data})


@app.get("/api/health")
def health():
    result = {"code": 0, "db": "ok", "theme": config.THEME_NAME, "imageRoots": config.IMAGE_ROOTS}
    try:
        db.query_one("SELECT 1 AS ok")
    except Exception as e:
        return jsonify({"code": 0, "db": "error", "detail": str(e)})
    try:
        db.query_one("SELECT COUNT(*) AS c FROM `user`")
        result["userTable"] = "ok"
    except Exception as e:
        result["userTable"] = "error"
        result["userTableDetail"] = str(e)
    kg_ok, kg_detail = kg.check_connection()
    result["knowledgeGraph"] = "ok" if kg_ok else "error"
    result["knowledgeGraphDetail"] = kg_detail
    result["imageSearchIndex"] = "ready" if image_search.index_ready() else "missing"
    if kg_ok:
        result["themeArtifactCount"] = kg.get_theme_info().get("artifactCount", 0)
    cr_ok, cr_detail = content_review.check_health()
    result["contentReview"] = "ok" if cr_ok else ("disabled" if not content_review.is_enabled() else "error")
    result["contentReviewDetail"] = cr_detail
    return jsonify(result)


_HOT_SCORE_READY = False


def _backfill_hot_scores():
    db.execute(
        """
        UPDATE artifact a
        LEFT JOIN (
            SELECT museum_id, object_id, COUNT(*) AS cnt
            FROM user_like GROUP BY museum_id, object_id
        ) l ON a.museum_id = l.museum_id AND a.object_id = l.object_id
        LEFT JOIN (
            SELECT museum_id, object_id, COUNT(*) AS cnt
            FROM user_favorite GROUP BY museum_id, object_id
        ) f ON a.museum_id = f.museum_id AND a.object_id = f.object_id
        SET a.hot_score = COALESCE(l.cnt, 0) + COALESCE(f.cnt, 0)
        """
    )


def _ensure_hot_score_schema():
    global _HOT_SCORE_READY
    if _HOT_SCORE_READY:
        return True
    try:
        cols = db.query_all(
            "SELECT COLUMN_NAME AS c FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA=%s AND TABLE_NAME='artifact' AND COLUMN_NAME='hot_score'",
            (config.MYSQL_DATABASE,),
        )
        if not cols:
            db.execute(
                "ALTER TABLE artifact ADD COLUMN hot_score INT NOT NULL DEFAULT 0 "
                "COMMENT '热度=点赞数+收藏数' AFTER image_count"
            )
            _backfill_hot_scores()
        _HOT_SCORE_READY = True
        return True
    except Exception as e:
        logger.warning("hot_score schema not ready: %s", e)
        return False


def sync_artifact_hot_score(museum_id, object_id):
    """将 artifact.hot_score 同步为当前点赞数 + 收藏数。"""
    if not _ensure_hot_score_schema():
        return
    likes = db.query_one(
        "SELECT COUNT(*) AS c FROM user_like WHERE museum_id=%s AND object_id=%s",
        (museum_id, object_id),
    )
    favs = db.query_one(
        "SELECT COUNT(*) AS c FROM user_favorite WHERE museum_id=%s AND object_id=%s",
        (museum_id, object_id),
    )
    score = int(likes["c"] if likes else 0) + int(favs["c"] if favs else 0)
    db.execute(
        "UPDATE artifact SET hot_score=%s WHERE museum_id=%s AND object_id=%s",
        (score, museum_id, object_id),
    )


def _query_hot_artifacts(size: int, offset: int = 0, exclude_museum_ids: list[int] | None = None):
    _ensure_hot_score_schema()
    filter_sql, filter_args = theme_filter_or_error()
    hot_filter = alias_theme_filter(filter_sql)
    exclude_sql, exclude_args = museum_exclude_clause("a", exclude_museum_ids or [])
    sql = f"""
        SELECT {aliased_artifact_fields("a")}, a.hot_score,
               (SELECT COUNT(*) FROM user_like l
                WHERE l.museum_id = a.museum_id AND l.object_id = a.object_id) AS like_count
        FROM artifact a
        WHERE {hot_filter}{exclude_sql}
        ORDER BY a.hot_score DESC, a.period_start_year DESC, a.title ASC
        LIMIT %s OFFSET %s
    """
    return db.query_all(sql, filter_args + exclude_args + (size, offset))


@app.get("/api/artifacts/hot")
def hot_artifacts():
    size = min(20, max(1, int(request.args.get("size", 8))))
    try:
        rows = _query_hot_artifacts(size, 0)
    except Exception as e:
        logger.exception("hot_artifacts failed")
        return jsonify({"code": 503, "message": "热门文物加载失败", "detail": str(e)}), 503
    return jsonify({
        "code": 0,
        "data": [artifact_row(r) for r in rows],
        "size": size,
    })


@app.get("/api/artifacts")
def list_artifacts():
    sort = request.args.get("sort", "period")
    order = "DESC" if request.args.get("order", "desc").lower() == "desc" else "ASC"
    page = max(1, int(request.args.get("page", 1)))
    size = min(50, max(1, int(request.args.get("size", 50))))
    offset = (page - 1) * size

    order_sql = "period_start_year"
    if sort == "type":
        order_sql = "type"
    elif sort == "title":
        order_sql = "title"

    try:
        filter_sql, filter_args = theme_filter_or_error()
    except Exception as e:
        logger.exception("list_artifacts kg filter failed")
        return jsonify({"code": 503, "message": "知识图谱连接失败", "detail": str(e)}), 503

    exclude_ids = parse_museum_id_list(request.args.getlist("exclude_museum_id"))
    exclude_sql, exclude_args = museum_exclude_clause(None, exclude_ids)
    where_sql = filter_sql + exclude_sql
    query_args = filter_args + exclude_args

    if sort == "hot":
        _ensure_hot_score_schema()
        sql = f"""
            SELECT {artifact_select_fields()}
            FROM artifact
            WHERE {where_sql}
            ORDER BY hot_score DESC, period_start_year DESC, title ASC
            LIMIT %s OFFSET %s
        """
        rows = db.query_all(sql, query_args + (size, offset))
    else:
        sql = f"""
            SELECT {artifact_select_fields()}
            FROM artifact
            WHERE {where_sql}
            ORDER BY {order_sql} {order}, title ASC
            LIMIT %s OFFSET %s
        """
        rows = db.query_all(sql, query_args + (size, offset))
    total = db.query_one(f"SELECT COUNT(*) AS c FROM artifact WHERE {where_sql}", query_args)
    theme = kg.get_theme_info()
    return jsonify({
        "code": 0,
        "data": [artifact_row(r) for r in rows],
        "total": total["c"] if total else 0,
        "page": page,
        "size": size,
        "theme": theme,
    })


@app.get("/api/artifacts/search")
def search_artifacts():
    q = (request.args.get("q") or "").strip()
    dynasties = request.args.getlist("dynasty")
    types = request.args.getlist("type")
    museum_ids = []
    for raw in request.args.getlist("museum_id"):
        try:
            mid = int(raw)
            if mid > 0 and mid not in museum_ids:
                museum_ids.append(mid)
        except (TypeError, ValueError):
            continue
    if not q and not dynasties and not types and not museum_ids:
        return jsonify({"code": 400, "message": "请输入关键词、朝代、类型或博物馆"}), 400

    page = max(1, int(request.args.get("page", 1)))
    size = min(50, max(1, int(request.args.get("size", 50))))
    offset = (page - 1) * size

    try:
        filter_sql, filter_args = theme_filter_or_error()
    except Exception as e:
        logger.exception("search_artifacts kg filter failed")
        return jsonify({"code": 503, "message": "知识图谱连接失败", "detail": str(e)}), 503

    conditions = [filter_sql]
    args = list(filter_args)
    if q:
        conditions.append(
            "(title LIKE %s OR description LIKE %s OR type LIKE %s OR culture LIKE %s)"
        )
        like = f"%{q}%"
        args.extend([like, like, like, like])
    if dynasties:
        dyn_conds = []
        for d in dynasties:
            dyn_conds.append("(dynasty LIKE %s OR period LIKE %s)")
            args.extend([f"%{d}%", f"%{d}%"])
        conditions.append(f"({' OR '.join(dyn_conds)})")
    if types:
        type_conds = []
        for t in types:
            type_conds.append("type LIKE %s")
            args.append(f"%{t}%")
        conditions.append(f"({' OR '.join(type_conds)})")
    if museum_ids:
        placeholders = ",".join(["%s"] * len(museum_ids))
        conditions.append(f"museum_id IN ({placeholders})")
        args.extend(museum_ids)

    where = " AND ".join(conditions)
    count_row = db.query_one(f"SELECT COUNT(*) AS c FROM artifact WHERE {where}", tuple(args))
    total = int(count_row["c"]) if count_row else 0
    sql = f"""
        SELECT {artifact_select_fields()}
        FROM artifact WHERE {where}
        ORDER BY period_start_year DESC
        LIMIT %s OFFSET %s
    """
    rows = db.query_all(sql, tuple(args) + (size, offset))

    return jsonify({
        "code": 0,
        "data": [artifact_row(r) for r in rows],
        "total": total,
        "page": page,
        "size": size,
        "theme": kg.get_theme_info(),
    })


@app.post("/api/artifacts/search-by-image")
def search_artifacts_by_image():
    body = request.get_json(force=True, silent=True) or {}
    image_b64 = (body.get("imageBase64") or "").strip()
    if not image_b64:
        return jsonify({"code": 400, "message": "请选择要搜索的图片"}), 400

    try:
        raw = base64.b64decode(image_b64.split(",")[-1])
    except Exception:
        return jsonify({"code": 400, "message": "图片数据无效"}), 400

    if not image_search.index_ready():
        return jsonify({
            "code": 503,
            "message": "以图搜图索引未就绪，请在服务器执行 python build_image_index.py",
        }), 503

    page = max(1, int(body.get("page") or 1))
    size = min(50, max(1, int(body.get("size") or 50)))

    museum_ids = []
    for raw_id in body.get("museum_id") or body.get("museumIds") or []:
        try:
            mid = int(raw_id)
            if mid > 0 and mid not in museum_ids:
                museum_ids.append(mid)
        except (TypeError, ValueError):
            continue

    dynasties = [str(d).strip() for d in (body.get("dynasty") or body.get("dynasties") or []) if str(d).strip()]

    try:
        filter_sql, filter_args = theme_filter_or_error()
    except Exception as e:
        logger.exception("search_by_image kg filter failed")
        return jsonify({"code": 503, "message": "知识图谱连接失败", "detail": str(e)}), 503

    dynasty_map: dict[tuple[int, str], str] = {}
    if dynasties:
        sql = f"SELECT museum_id, object_id, dynasty, period FROM artifact WHERE {filter_sql}"
        for row in db.query_all(sql, filter_args):
            key = (int(row["museum_id"]), str(row["object_id"]))
            dynasty_map[key] = f"{row.get('dynasty') or ''} {row.get('period') or ''}"

    try:
        hits, total = image_search.search_by_image_bytes(
            raw,
            museum_ids if museum_ids else None,
            dynasties if dynasties else None,
            dynasty_map if dynasties else None,
            page,
            size,
        )
    except FileNotFoundError as e:
        return jsonify({"code": 503, "message": str(e)}), 503
    except Exception as e:
        logger.exception("search_by_image failed")
        return jsonify({"code": 500, "message": "以图搜图失败", "detail": str(e)}), 500

    if not hits:
        return jsonify({
            "code": 0,
            "data": [],
            "total": 0,
            "page": page,
            "size": size,
            "theme": kg.get_theme_info(),
        })

    pair_clauses = []
    pair_args: list = []
    for mid, oid, _ in hits:
        pair_clauses.append("(museum_id=%s AND object_id=%s)")
        pair_args.extend([mid, oid])
    sql = f"""
        SELECT {artifact_select_fields()}
        FROM artifact
        WHERE {filter_sql} AND ({' OR '.join(pair_clauses)})
    """
    rows = db.query_all(sql, filter_args + tuple(pair_args))
    row_map = {(int(r["museum_id"]), str(r["object_id"])): r for r in rows}

    data = []
    for mid, oid, sim in hits:
        r = row_map.get((mid, oid))
        if not r:
            continue
        item = artifact_row(r)
        item["similarity"] = round(sim, 4)
        data.append(item)

    return jsonify({
        "code": 0,
        "data": data,
        "total": total,
        "page": page,
        "size": size,
        "theme": kg.get_theme_info(),
    })


@app.get("/api/artifacts/<int:museum_id>/<object_id>")
def get_artifact(museum_id, object_id):
    r = db.query_one(
        """
        SELECT museum_id, object_id, title, artist, dynasty, period,
               period_start_year, period_end_year, type, material, culture,
               description, dimensions, museum, location, image_url, image_path, detail_url,
               image_urls, image_paths, image_count, hot_score,
               provenance, bibliography, credit_line, accession_number
        FROM artifact WHERE museum_id = %s AND object_id = %s
        """,
        (museum_id, object_id),
    )
    if not r:
        return jsonify({"code": 404, "message": "文物不存在"}), 404
    if not kg.is_in_theme(museum_id, object_id):
        return jsonify({"code": 404, "message": "该文物不在当前专题范围内"}), 404
    data = artifact_row(r, include_gallery=True)
    data["provenance"] = r.get("provenance") or ""
    data["bibliography"] = r.get("bibliography") or ""
    data["creditLine"] = r.get("credit_line") or ""
    data["accessionNumber"] = r.get("accession_number") or ""
    return jsonify({"code": 0, "data": data})


@app.post("/api/auth/register")
def register():
    body = request.get_json(force=True, silent=True) or {}
    username = (body.get("username") or "").strip()
    password = (body.get("password") or "").strip()
    email = normalize_optional_str(body.get("email"))
    phone = normalize_optional_str(body.get("phone"))
    if not username or not password:
        return jsonify({"code": 400, "message": "用户名和密码不能为空"}), 400
    if len(password) < 6:
        return jsonify({"code": 400, "message": "密码至少6位"}), 400
    if not email and not phone:
        return jsonify({"code": 400, "message": "请填写邮箱或手机号"}), 400

    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    try:
        uid = db.execute(
            """
            INSERT INTO `user` (username, password, email, phone, user_source, nickname, status)
            VALUES (%s, %s, %s, %s, 'app', %s, 1)
            """,
            (username, hashed, email, phone, username),
        )
    except Exception as e:
        logger.exception("register failed")
        message, status = map_db_error(e, "注册")
        return jsonify({"code": status, "message": message}), status

    token = secrets.token_hex(24)
    SESSIONS[token] = uid
    _record_login_log(uid, username)
    content_review.report_login(uid, _client_ip(), "app")
    return jsonify({
        "code": 0,
        "token": token,
        "user": {"userId": uid, "username": username, "nickname": username},
        "stats": _query_user_stats(uid),
    })


@app.post("/api/auth/login")
def login():
    body = request.get_json(force=True, silent=True) or {}
    account = (body.get("account") or body.get("username") or "").strip()
    password = (body.get("password") or "").strip()
    if not account or not password:
        return jsonify({"code": 400, "message": "账号和密码不能为空"}), 400

    user = db.query_one(
        """
        SELECT user_id, username, nickname, password, email, phone, avatar_url, status
        FROM `user`
        WHERE username = %s OR email = %s OR phone = %s
        LIMIT 1
        """,
        (account, account, account),
    )
    if not user or user["status"] != 1:
        return jsonify({"code": 401, "message": "账号不存在或已禁用"}), 401

    if not bcrypt.checkpw(password.encode(), user["password"].encode()):
        return jsonify({"code": 401, "message": "密码错误"}), 401

    db.execute(
        "UPDATE `user` SET last_login_at = %s WHERE user_id = %s",
        (datetime.now(), user["user_id"]),
    )
    _record_login_log(user["user_id"], user["username"])
    content_review.report_login(user["user_id"], _client_ip(), "app")
    token = secrets.token_hex(24)
    SESSIONS[token] = user["user_id"]
    return jsonify({
        "code": 0,
        "token": token,
        "user": {
            "userId": user["user_id"],
            "username": user["username"],
            "nickname": user.get("nickname") or user["username"],
            "email": user.get("email") or "",
            "phone": user.get("phone") or "",
            "avatarUrl": user.get("avatar_url") or "",
        },
        "stats": _query_user_stats(user["user_id"]),
    })


@app.get("/api/user/me")
@require_auth
def me():
    user = db.query_one(
        "SELECT user_id, username, nickname, email, phone, avatar_url FROM `user` WHERE user_id = %s",
        (request.user_id,),
    )
    if not user:
        return jsonify({"code": 404, "message": "用户不存在"}), 404
    return jsonify({
        "code": 0,
        "user": {
            "userId": user["user_id"],
            "username": user["username"],
            "nickname": user.get("nickname") or user["username"],
            "email": user.get("email") or "",
            "phone": user.get("phone") or "",
            "avatarUrl": user.get("avatar_url") or "",
        },
    })


@app.get("/api/user/stats")
@require_auth
def user_stats():
    return jsonify({
        "code": 0,
        "data": _query_user_stats(request.user_id),
    })


@app.get("/api/user/favorites")
@require_auth
def my_favorites():
    folder_id = request.args.get("folderId")
    has_folders = _ensure_folder_schema()
    select_folder = ", f.favorite_id, f.folder_id" if has_folders else ", f.favorite_id"
    sql = f"""
        SELECT f.museum_id, f.object_id, f.created_at{select_folder},
               a.title, a.dynasty, a.type, a.image_url, a.image_path,
               a.image_paths, a.image_count
        FROM user_favorite f
        JOIN artifact a ON a.museum_id = f.museum_id AND a.object_id = f.object_id
        WHERE f.user_id = %s
    """
    args = [request.user_id]
    if has_folders and folder_id is not None and folder_id != "":
        if str(folder_id) == "0":
            sql += " AND f.folder_id IS NULL"
        else:
            sql += " AND f.folder_id = %s"
            args.append(int(folder_id))
    sql += " ORDER BY f.created_at DESC"
    rows = db.query_all(sql, tuple(args))
    stats = _query_user_stats(request.user_id)
    return jsonify({
        "code": 0,
        "data": [_favorite_row(r) for r in rows],
        "total": stats["favoriteCount"],
        "stats": stats,
        "foldersEnabled": has_folders,
    })


@app.get("/api/user/likes")
@require_auth
def my_likes():
    rows = db.query_all(
        """
        SELECT l.museum_id, l.object_id, l.created_at,
               a.title, a.dynasty, a.type, a.image_url, a.image_path,
               a.image_paths, a.image_count
        FROM user_like l
        JOIN artifact a ON a.museum_id = l.museum_id AND a.object_id = l.object_id
        WHERE l.user_id = %s
        ORDER BY l.created_at DESC
        """,
        (request.user_id,),
    )
    stats = _query_user_stats(request.user_id)
    return jsonify({
        "code": 0,
        "data": [_favorite_row(r) for r in rows],
        "total": stats["likeCount"],
        "stats": stats,
    })


def _favorite_row(r):
    row = {
        "favoriteId": r.get("favorite_id"),
        "museumId": r["museum_id"],
        "objectId": r["object_id"],
        "title": r.get("title") or "",
        "dynasty": r.get("dynasty") or "",
        "type": r.get("type") or "",
        "imageUrl": r.get("image_url") or "",
        "imagePath": r.get("image_path") or "",
        "createdAt": r["created_at"].isoformat() if r.get("created_at") else "",
    }
    if "folder_id" in r:
        row["folderId"] = r.get("folder_id")
    enrich_image_fields(row, r)
    return row


_FOLDER_SCHEMA_READY = False


def _ensure_folder_schema():
    global _FOLDER_SCHEMA_READY
    if _FOLDER_SCHEMA_READY:
        return True
    try:
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS user_favorite_folder (
              folder_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
              user_id BIGINT UNSIGNED NOT NULL,
              name VARCHAR(50) NOT NULL,
              sort_order INT NOT NULL DEFAULT 0,
              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
              PRIMARY KEY (folder_id),
              KEY idx_user (user_id, sort_order)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """
        )
        cols = db.query_all(
            "SELECT COLUMN_NAME AS c FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA=%s AND TABLE_NAME='user_favorite' AND COLUMN_NAME='folder_id'",
            (config.MYSQL_DATABASE,),
        )
        if not cols:
            db.execute(
                "ALTER TABLE user_favorite ADD COLUMN folder_id BIGINT UNSIGNED NULL AFTER object_id"
            )
        _FOLDER_SCHEMA_READY = True
        return True
    except Exception as e:
        logger.warning("Favorite folder schema not ready: %s", e)
        return False


def _folder_row(r):
    return {
        "folderId": r["folder_id"],
        "name": r["name"],
        "itemCount": r.get("item_count") or 0,
        "sortOrder": r.get("sort_order") or 0,
        "createdAt": r["created_at"].isoformat() if r.get("created_at") else "",
    }


@app.get("/api/user/favorite-folders")
@require_auth
def list_favorite_folders():
    if not _ensure_folder_schema():
        return jsonify({"code": 0, "data": [], "foldersEnabled": False})
    rows = db.query_all(
        """
        SELECT ff.folder_id, ff.name, ff.sort_order, ff.created_at,
               COUNT(f.favorite_id) AS item_count
        FROM user_favorite_folder ff
        LEFT JOIN user_favorite f
          ON f.folder_id = ff.folder_id AND f.user_id = ff.user_id
        WHERE ff.user_id = %s
        GROUP BY ff.folder_id, ff.name, ff.sort_order, ff.created_at
        ORDER BY ff.sort_order ASC, ff.created_at ASC
        """,
        (request.user_id,),
    )
    default_count = db.query_one(
        "SELECT COUNT(*) AS c FROM user_favorite WHERE user_id=%s AND folder_id IS NULL",
        (request.user_id,),
    )
    data = [_folder_row(r) for r in rows]
    data.insert(
        0,
        {
            "folderId": 0,
            "name": "默认收藏",
            "itemCount": default_count["c"] if default_count else 0,
            "sortOrder": -1,
            "createdAt": "",
        },
    )
    stats = _query_user_stats(request.user_id)
    return jsonify({"code": 0, "data": data, "foldersEnabled": True, "stats": stats})


@app.post("/api/user/favorite-folders")
@require_auth
def create_favorite_folder():
    if not _ensure_folder_schema():
        return jsonify({"code": 500, "message": "收藏分组功能未就绪，请执行 server/sql/favorite_folders.sql"}), 500
    body = request.get_json(force=True, silent=True) or {}
    name = (body.get("name") or "").strip()
    if not name:
        return jsonify({"code": 400, "message": "请输入收藏夹名称"}), 400
    if len(name) > 50:
        return jsonify({"code": 400, "message": "名称最多50字"}), 400
    fid = db.execute(
        "INSERT INTO user_favorite_folder (user_id, name) VALUES (%s, %s)",
        (request.user_id, name),
    )
    row = db.query_one(
        "SELECT folder_id, name, sort_order, created_at FROM user_favorite_folder WHERE folder_id=%s",
        (fid,),
    )
    out = _folder_row({**row, "item_count": 0})
    return jsonify({"code": 0, "data": out})


@app.put("/api/user/favorite-folders/<int:folder_id>")
@require_auth
def rename_favorite_folder(folder_id):
    if not _ensure_folder_schema():
        return jsonify({"code": 500, "message": "收藏分组功能未就绪"}), 500
    body = request.get_json(force=True, silent=True) or {}
    name = (body.get("name") or "").strip()
    if not name:
        return jsonify({"code": 400, "message": "请输入收藏夹名称"}), 400
    updated = db.execute(
        "UPDATE user_favorite_folder SET name=%s WHERE folder_id=%s AND user_id=%s",
        (name, folder_id, request.user_id),
    )
    if not updated:
        return jsonify({"code": 404, "message": "收藏夹不存在"}), 404
    return jsonify({"code": 0, "message": "已更新"})


@app.delete("/api/user/favorite-folders/<int:folder_id>")
@require_auth
def delete_favorite_folder(folder_id):
    if not _ensure_folder_schema():
        return jsonify({"code": 500, "message": "收藏分组功能未就绪"}), 500
    db.execute(
        "UPDATE user_favorite SET folder_id=NULL WHERE user_id=%s AND folder_id=%s",
        (request.user_id, folder_id),
    )
    db.execute(
        "DELETE FROM user_favorite_folder WHERE folder_id=%s AND user_id=%s",
        (folder_id, request.user_id),
    )
    return jsonify({"code": 0, "message": "已删除"})


@app.put("/api/artifacts/<int:museum_id>/<object_id>/favorite-folder")
@require_auth
def move_favorite_folder(museum_id, object_id):
    if not _ensure_folder_schema():
        return jsonify({"code": 500, "message": "收藏分组功能未就绪"}), 500
    body = request.get_json(force=True, silent=True) or {}
    folder_id = body.get("folderId")
    if folder_id == 0:
        folder_id = None
    elif folder_id is not None:
        folder_id = int(folder_id)
        owned = db.query_one(
            "SELECT 1 FROM user_favorite_folder WHERE folder_id=%s AND user_id=%s",
            (folder_id, request.user_id),
        )
        if not owned:
            return jsonify({"code": 404, "message": "收藏夹不存在"}), 404
    updated = db.execute(
        """
        UPDATE user_favorite SET folder_id=%s
        WHERE user_id=%s AND museum_id=%s AND object_id=%s
        """,
        (folder_id, request.user_id, museum_id, object_id),
    )
    if not updated:
        return jsonify({"code": 404, "message": "尚未收藏该文物"}), 404
    return jsonify({"code": 0, "message": "已移动"})


def _audit_status_text(audit_status):
    return {0: "待审核", 1: "已通过", 2: "已拒绝", 3: "复审"}.get(audit_status, "未知")


_COMMENT_REPLY_READY = False


def _ensure_comment_reply_schema():
    global _COMMENT_REPLY_READY
    if _COMMENT_REPLY_READY:
        return True
    try:
        cols = db.query_all(
            "SELECT COLUMN_NAME AS c FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA=%s AND TABLE_NAME='comment' AND COLUMN_NAME='parent_id'",
            (config.MYSQL_DATABASE,),
        )
        if not cols:
            db.execute(
                "ALTER TABLE comment ADD COLUMN parent_id BIGINT UNSIGNED NULL DEFAULT NULL "
                "COMMENT '回复的评论ID，NULL为顶级评论' AFTER object_id"
            )
            db.execute("ALTER TABLE comment ADD KEY idx_parent (parent_id)")
        _COMMENT_REPLY_READY = True
        return True
    except Exception as e:
        logger.warning("comment parent_id schema not ready: %s", e)
        return False


def _comment_public_row(r):
    parent_id = r.get("parent_id")
    row = {
        "commentId": r["comment_id"],
        "userId": r["user_id"],
        "nickname": r.get("nickname") or r.get("username") or "用户",
        "content": r["content"],
        "createdAt": r["created_at"].strftime("%Y-%m-%d %H:%M") if r.get("created_at") else "",
        "parentId": parent_id,
    }
    if parent_id:
        row["replyToNickname"] = (
            r.get("reply_to_nickname") or r.get("reply_to_username") or "用户"
        )
        row["replyToUserId"] = r.get("reply_to_user_id")
    return row


def _comment_reject_reason(r):
    if r.get("audit_status") == 1:
        return ""
    if r.get("delete_reason"):
        return r["delete_reason"]
    hits = r.get("sensitive_words_hit")
    if hits:
        return f"内容违规无法发布，请修改后重试（命中：{hits}）"
    auto_score = r.get("auto_audit_status")
    if r.get("audit_status") == 0:
        if auto_score is not None and int(auto_score) >= 60:
            return f"风险评分较高（{auto_score}），等待人工审核"
        return "等待管理员审核，请耐心等待"
    if r.get("audit_status") == 2:
        return "审核未通过，请修改后重新提交"
    if r.get("audit_status") == 3:
        return "正在复审中"
    return "未通过审核"


def _photo_reject_reason(r):
    st = r.get("status")
    if st == 1:
        return ""
    if r.get("reject_reason"):
        return r["reject_reason"]
    hits = r.get("sensitive_words_hit")
    if hits:
        return f"内容违规无法发布，请修改后重试（命中：{hits}）"
    auto_score = r.get("auto_audit_score")
    if st == 0:
        if auto_score is not None and float(auto_score) >= 60:
            return f"风险评分较高（{auto_score}），等待人工审核"
        return "等待管理员审核，请耐心等待"
    if st == 2:
        return "审核未通过，请更换图片或修改说明后重新提交"
    if st == 3:
        return "正在复审中"
    if st == 4:
        return "内容已被屏蔽"
    return "未通过审核"


@app.get("/api/artifacts/<int:museum_id>/<object_id>/status")
@require_auth
def artifact_status(museum_id, object_id):
    liked = db.query_one(
        "SELECT 1 FROM user_like WHERE user_id=%s AND museum_id=%s AND object_id=%s",
        (request.user_id, museum_id, object_id),
    )
    fav = db.query_one(
        "SELECT 1 FROM user_favorite WHERE user_id=%s AND museum_id=%s AND object_id=%s",
        (request.user_id, museum_id, object_id),
    )
    return jsonify({"code": 0, "liked": bool(liked), "favorited": bool(fav)})


@app.post("/api/artifacts/<int:museum_id>/<object_id>/like")
@require_auth
def like_artifact(museum_id, object_id):
    exists = db.query_one(
        "SELECT 1 FROM artifact WHERE museum_id=%s AND object_id=%s",
        (museum_id, object_id),
    )
    if not exists:
        return jsonify({"code": 404, "message": "文物不存在"}), 404
    try:
        db.execute(
            "INSERT INTO user_like (user_id, museum_id, object_id) VALUES (%s,%s,%s)",
            (request.user_id, museum_id, object_id),
        )
    except Exception:
        pass
    sync_artifact_hot_score(museum_id, object_id)
    return jsonify({"code": 0, "liked": True})


@app.delete("/api/artifacts/<int:museum_id>/<object_id>/like")
@require_auth
def unlike_artifact(museum_id, object_id):
    db.execute(
        "DELETE FROM user_like WHERE user_id=%s AND museum_id=%s AND object_id=%s",
        (request.user_id, museum_id, object_id),
    )
    sync_artifact_hot_score(museum_id, object_id)
    return jsonify({"code": 0, "liked": False})


@app.post("/api/artifacts/<int:museum_id>/<object_id>/favorite")
@require_auth
def favorite_artifact(museum_id, object_id):
    exists = db.query_one(
        "SELECT 1 FROM artifact WHERE museum_id=%s AND object_id=%s",
        (museum_id, object_id),
    )
    if not exists:
        return jsonify({"code": 404, "message": "文物不存在"}), 404
    body = request.get_json(force=True, silent=True) or {}
    folder_id = body.get("folderId")
    has_folders = _ensure_folder_schema()
    if has_folders and folder_id is not None and int(folder_id) != 0:
        folder_id = int(folder_id)
        owned = db.query_one(
            "SELECT 1 FROM user_favorite_folder WHERE folder_id=%s AND user_id=%s",
            (folder_id, request.user_id),
        )
        if not owned:
            return jsonify({"code": 404, "message": "收藏夹不存在"}), 404
    else:
        folder_id = None
    try:
        if has_folders:
            db.execute(
                """
                INSERT INTO user_favorite (user_id, museum_id, object_id, folder_id)
                VALUES (%s,%s,%s,%s)
                ON DUPLICATE KEY UPDATE folder_id=VALUES(folder_id)
                """,
                (request.user_id, museum_id, object_id, folder_id),
            )
        else:
            db.execute(
                "INSERT INTO user_favorite (user_id, museum_id, object_id) VALUES (%s,%s,%s)",
                (request.user_id, museum_id, object_id),
            )
    except Exception:
        pass
    sync_artifact_hot_score(museum_id, object_id)
    return jsonify({"code": 0, "favorited": True})


@app.delete("/api/artifacts/<int:museum_id>/<object_id>/favorite")
@require_auth
def unfavorite_artifact(museum_id, object_id):
    db.execute(
        "DELETE FROM user_favorite WHERE user_id=%s AND museum_id=%s AND object_id=%s",
        (request.user_id, museum_id, object_id),
    )
    sync_artifact_hot_score(museum_id, object_id)
    return jsonify({"code": 0, "favorited": False})


@app.get("/api/artifacts/<int:museum_id>/<object_id>/comments")
def list_comments(museum_id, object_id):
    has_reply = _ensure_comment_reply_schema()
    if has_reply:
        rows = db.query_all(
            """
            SELECT c.comment_id, c.user_id, c.content, c.created_at, c.parent_id,
                   u.nickname, u.username,
                   pu.nickname AS reply_to_nickname, pu.username AS reply_to_username,
                   pc.user_id AS reply_to_user_id
            FROM comment c
            JOIN user u ON u.user_id = c.user_id
            LEFT JOIN comment pc ON pc.comment_id = c.parent_id
            LEFT JOIN user pu ON pu.user_id = pc.user_id
            WHERE c.museum_id=%s AND c.object_id=%s
              AND c.audit_status=1 AND c.status=1
              AND (c.parent_id IS NULL OR EXISTS (
                SELECT 1 FROM comment pc
                WHERE pc.comment_id = c.parent_id
                  AND pc.audit_status=1 AND pc.status=1
              ))
            ORDER BY COALESCE(c.parent_id, c.comment_id) DESC,
                     (c.parent_id IS NULL) DESC,
                     c.created_at ASC
            LIMIT 200
            """,
            (museum_id, object_id),
        )
    else:
        rows = db.query_all(
            """
            SELECT c.comment_id, c.user_id, c.content, c.created_at, u.nickname, u.username
            FROM comment c
            JOIN user u ON u.user_id = c.user_id
            WHERE c.museum_id=%s AND c.object_id=%s
              AND c.audit_status=1 AND c.status=1
            ORDER BY c.created_at DESC
            LIMIT 100
            """,
            (museum_id, object_id),
        )
    return jsonify({"code": 0, "data": [_comment_public_row(r) for r in rows]})


@app.get("/api/artifacts/<int:museum_id>/<object_id>/photos")
def list_artifact_photos(museum_id, object_id):
    rows = db.query_all(
        """
        SELECT p.photo_id, p.museum_id, p.object_id, p.photo_url, p.description,
               p.location, p.status, p.created_at, u.nickname, u.username
        FROM user_upload_photo p
        LEFT JOIN `user` u ON u.user_id = p.user_id
        WHERE p.museum_id=%s AND p.object_id=%s AND p.status=1
        ORDER BY p.created_at DESC
        LIMIT 100
        """,
        (museum_id, object_id),
    )
    return jsonify({
        "code": 0,
        "data": [
            {
                "photoId": r["photo_id"],
                "museumId": r.get("museum_id"),
                "objectId": r.get("object_id"),
                "photoUrl": r["photo_url"],
                "description": r.get("description") or "",
                "location": r.get("location") or "",
                "status": r["status"],
                "statusText": "已通过",
                "nickname": r.get("nickname") or r.get("username") or "用户",
                "createdAt": r["created_at"].strftime("%Y-%m-%d %H:%M") if r.get("created_at") else "",
            }
            for r in rows
        ],
    })


@app.post("/api/artifacts/<int:museum_id>/<object_id>/comments")
@require_auth
def add_comment(museum_id, object_id):
    body = request.get_json(force=True, silent=True) or {}
    content = (body.get("content") or "").strip()
    if not content:
        return jsonify({"code": 400, "message": "评论内容不能为空"}), 400
    exists = db.query_one(
        "SELECT 1 FROM artifact WHERE museum_id=%s AND object_id=%s",
        (museum_id, object_id),
    )
    if not exists:
        return jsonify({"code": 404, "message": "文物不存在"}), 404

    parent_id = None
    raw_parent = body.get("parentId")
    if raw_parent is not None and str(raw_parent).strip() not in ("", "0"):
        if not _ensure_comment_reply_schema():
            return jsonify({"code": 500, "message": "评论回复功能未就绪，请执行 server/sql/comment_reply.sql"}), 500
        parent_id = int(raw_parent)
        parent = db.query_one(
            """
            SELECT comment_id, user_id, museum_id, object_id, audit_status, status
            FROM comment WHERE comment_id=%s
            """,
            (parent_id,),
        )
        if not parent:
            return jsonify({"code": 404, "message": "被回复的评论不存在"}), 404
        if parent["museum_id"] != museum_id or parent["object_id"] != object_id:
            return jsonify({"code": 400, "message": "只能回复同一文物的评论"}), 400
        if parent["audit_status"] != 1 or parent["status"] != 1:
            return jsonify({"code": 400, "message": "只能回复已通过的评论"}), 400

    review = content_review.submit_comment(
        request.user_id, museum_id, object_id, content, "app"
    )
    if review.review_ok and review.rejected:
        reason = review.message or "内容违规无法发布"
        return jsonify({
            "code": 400,
            "message": reason,
            "rejectReason": reason,
        }), 400

    audit_status = review.audit_status if review.review_ok else 0
    audit_method = review.audit_method if review.review_ok else 1
    auto_audit_status = review.auto_audit_status if review.review_ok else None
    sensitive_hit = review.sensitive_words
    msg = review.message or (
        "评论已发布" if audit_status == 1 else "评论已提交，审核通过后将展示"
    )

    has_reply = _ensure_comment_reply_schema()
    if has_reply and parent_id is not None:
        cid = db.execute(
            """
            INSERT INTO comment
              (user_id, museum_id, object_id, parent_id, content, source,
               audit_method, audit_status, auto_audit_status, sensitive_words_hit, status)
            VALUES (%s, %s, %s, %s, %s, 'app', %s, %s, %s, %s, 1)
            """,
            (
                request.user_id, museum_id, object_id, parent_id, content,
                audit_method, audit_status, auto_audit_status, sensitive_hit,
            ),
        )
    else:
        cid = db.execute(
            """
            INSERT INTO comment
              (user_id, museum_id, object_id, content, source,
               audit_method, audit_status, auto_audit_status, sensitive_words_hit, status)
            VALUES (%s, %s, %s, %s, 'app', %s, %s, %s, %s, 1)
            """,
            (
                request.user_id, museum_id, object_id, content,
                audit_method, audit_status, auto_audit_status, sensitive_hit,
            ),
        )
    return jsonify({
        "code": 0,
        "message": msg,
        "commentId": cid,
        "parentId": parent_id,
        "auditStatus": audit_status,
        "displayable": review.displayable if review.review_ok else False,
        "rejectReason": _comment_reject_reason({
            "audit_status": audit_status,
            "delete_reason": None,
            "sensitive_words_hit": sensitive_hit,
            "auto_audit_status": auto_audit_status,
        }) if audit_status != 1 else "",
    })


@app.get("/api/user/comments")
@require_auth
def my_comments():
    has_reply = _ensure_comment_reply_schema()
    if has_reply:
        rows = db.query_all(
            """
            SELECT c.comment_id, c.museum_id, c.object_id, c.content, c.audit_status,
                   c.parent_id, c.delete_reason, c.sensitive_words_hit, c.auto_audit_status,
                   c.created_at, a.title,
                   pu.nickname AS reply_to_nickname, pu.username AS reply_to_username
            FROM comment c
            LEFT JOIN artifact a ON a.museum_id = c.museum_id AND a.object_id = c.object_id
            LEFT JOIN comment pc ON pc.comment_id = c.parent_id
            LEFT JOIN user pu ON pu.user_id = pc.user_id
            WHERE c.user_id=%s AND c.status=1
            ORDER BY c.created_at DESC
            LIMIT 200
            """,
            (request.user_id,),
        )
    else:
        rows = db.query_all(
            """
            SELECT c.comment_id, c.museum_id, c.object_id, c.content, c.audit_status,
                   c.delete_reason, c.sensitive_words_hit, c.auto_audit_status, c.created_at, a.title
            FROM comment c
            LEFT JOIN artifact a ON a.museum_id = c.museum_id AND a.object_id = c.object_id
            WHERE c.user_id=%s AND c.status=1
            ORDER BY c.created_at DESC
            LIMIT 200
            """,
            (request.user_id,),
        )
    stats = _query_user_stats(request.user_id)

    def _my_comment_row(r):
        item = {
            "commentId": r["comment_id"],
            "museumId": r["museum_id"],
            "objectId": r["object_id"],
            "artifactTitle": r.get("title") or "未知文物",
            "content": r["content"],
            "auditStatus": r["audit_status"],
            "statusText": _audit_status_text(r["audit_status"]),
            "rejectReason": _comment_reject_reason(r),
            "createdAt": r["created_at"].strftime("%Y-%m-%d %H:%M") if r.get("created_at") else "",
        }
        if has_reply and r.get("parent_id"):
            item["parentId"] = r["parent_id"]
            item["replyToNickname"] = (
                r.get("reply_to_nickname") or r.get("reply_to_username") or "用户"
            )
        return item

    return jsonify({
        "code": 0,
        "data": [_my_comment_row(r) for r in rows],
        "total": stats["commentCount"],
        "stats": stats,
    })


@app.delete("/api/user/comments/<int:comment_id>")
@require_auth
def delete_comment(comment_id):
    row = db.query_one(
        "SELECT comment_id, user_id, status FROM comment WHERE comment_id=%s",
        (comment_id,),
    )
    if not row:
        return jsonify({"code": 404, "message": "评论不存在"}), 404
    if row["user_id"] != request.user_id:
        return jsonify({"code": 403, "message": "无权删除该评论"}), 403
    if row["status"] != 1:
        return jsonify({"code": 400, "message": "评论已删除"}), 400
    db.execute(
        "UPDATE comment SET status=0 WHERE comment_id=%s AND user_id=%s",
        (comment_id, request.user_id),
    )
    return jsonify({"code": 0, "message": "评论已删除"})


@app.get("/api/user/photos")
@require_auth
def my_photos():
    rows = db.query_all(
        """
        SELECT p.photo_id, p.museum_id, p.object_id, p.photo_url, p.description,
               p.location, p.status, p.reject_reason, p.auto_audit_score, p.auto_audit_status,
               p.created_at, a.title
        FROM user_upload_photo p
        LEFT JOIN artifact a ON a.museum_id = p.museum_id AND a.object_id = p.object_id
        WHERE p.user_id=%s
        ORDER BY p.created_at DESC
        LIMIT 200
        """,
        (request.user_id,),
    )
    status_map = {0: "待审核", 1: "已通过", 2: "已拒绝", 3: "复审", 4: "已屏蔽"}
    return jsonify({
        "code": 0,
        "data": [
            {
                "photoId": r["photo_id"],
                "museumId": r.get("museum_id"),
                "objectId": r.get("object_id"),
                "artifactTitle": r.get("title") or "未知文物",
                "photoUrl": r["photo_url"],
                "description": r.get("description") or "",
                "location": r.get("location") or "",
                "status": r["status"],
                "statusText": status_map.get(r["status"], "未知"),
                "rejectReason": _photo_reject_reason(r),
                "createdAt": r["created_at"].strftime("%Y-%m-%d %H:%M") if r.get("created_at") else "",
            }
            for r in rows
        ],
    })


@app.post("/api/user/photos")
@require_auth
def upload_photo():
    body = request.get_json(force=True, silent=True) or {}
    description = (body.get("description") or "").strip()
    location = (body.get("location") or "").strip()
    museum_id = body.get("museumId")
    object_id = (body.get("objectId") or "").strip() or None
    image_b64 = body.get("imageBase64") or ""

    if not description:
        return jsonify({"code": 400, "message": "请填写照片说明"}), 400
    if not image_b64:
        return jsonify({"code": 400, "message": "请选择要上传的图片"}), 400

    photo_url = ""
    try:
        raw = base64.b64decode(image_b64.split(",")[-1])
        fname = f"{uuid.uuid4().hex}.jpg"
        path = os.path.join(config.UPLOAD_DIR, fname)
        with open(path, "wb") as f:
            f.write(raw)
        photo_url = f"/uploads/{fname}"
    except Exception:
        return jsonify({"code": 400, "message": "图片数据无效"}), 400

    public_url = content_review.public_upload_url(photo_url)
    review = content_review.submit_photo(
        request.user_id,
        public_url,
        description,
        int(museum_id) if museum_id is not None else None,
        object_id,
        "app",
    )
    if review.review_ok and review.rejected:
        reason = review.message or "提交失败"
        return jsonify({
            "code": 400,
            "message": reason,
            "rejectReason": reason,
        }), 400

    photo_status = review.audit_status if review.review_ok else 0
    audit_method = review.audit_method if review.review_ok else 2
    auto_audit_status = review.auto_audit_status if review.review_ok else 1
    auto_audit_score = review.auto_audit_score if review.review_ok else 0.0

    pid = db.execute(
        """
        INSERT INTO user_upload_photo
          (user_id, museum_id, object_id, photo_url, description, location, source,
           status, audit_method, auto_audit_status, auto_audit_score)
        VALUES (%s, %s, %s, %s, %s, %s, 'app', %s, %s, %s, %s)
        """,
        (
            request.user_id, museum_id, object_id, photo_url, description, location,
            photo_status, audit_method, auto_audit_status, auto_audit_score,
        ),
    )
    msg = review.message or "已提交，等待人工审核"
    pending_row = {
        "status": photo_status,
        "reject_reason": None,
        "auto_audit_score": auto_audit_score,
    }
    return jsonify({
        "code": 0,
        "message": msg,
        "photoId": pid,
        "reviewStatus": review.review_status if review.review_ok else "PENDING",
        "rejectReason": _photo_reject_reason(pending_row) if photo_status != 1 else "",
    })


@app.route("/uploads/<path:filename>")
def serve_upload(filename):
    from flask import send_from_directory

    return send_from_directory(config.UPLOAD_DIR, filename)


if __name__ == "__main__":
    _ensure_hot_score_schema()
    _ensure_comment_reply_schema()
    print(f"API http://{config.API_HOST}:{config.API_PORT}")
    app.run(host=config.API_HOST, port=config.API_PORT, debug=True)
