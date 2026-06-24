"""
内容审核 — 共用 MySQL + ContentReviewEngine。

对接说明：content-review-handoff/README.md
不再调用 admin-backend 8080 /api/integration/**。
"""
from __future__ import annotations

import logging
import sys
from dataclasses import dataclass
from pathlib import Path

import config
import db

_HANDOFF = Path(__file__).resolve().parent.parent / "content-review-handoff"
if str(_HANDOFF) not in sys.path:
    sys.path.insert(0, str(_HANDOFF))

from content_review_engine import (  # noqa: E402
    ReviewDecision,
    SensitiveLevel,
    SensitiveWord,
    submit_comment as engine_submit_comment,
    submit_photo as engine_submit_photo,
    strategy_from_db,
)

logger = logging.getLogger(__name__)


@dataclass
class ReviewResult:
    """本地引擎审核结果；review_ok=False 表示引擎未执行，调用方走待审兜底。"""

    review_ok: bool = False
    review_status: str = "PENDING"
    displayable: bool = False
    pending_manual: bool = True
    message: str = ""
    sensitive_words: str | None = None
    audit_status: int = 0
    audit_method: int = 1
    auto_audit_status: int | None = None
    auto_audit_score: float | None = None

    @property
    def integration_ok(self) -> bool:
        """兼容 app.py 旧字段名。"""
        return self.review_ok

    @property
    def rejected(self) -> bool:
        return self.review_status == "REJECTED"


def is_enabled() -> bool:
    return bool(getattr(config, "CONTENT_REVIEW_ENABLED", True))


def _load_sensitive_words() -> list[SensitiveWord]:
    rows = db.query_all(
        "SELECT word, level FROM sensitive_words WHERE enabled = 1 ORDER BY word ASC"
    )
    result: list[SensitiveWord] = []
    for row in rows:
        level_raw = str(row.get("level") or "LIGHT").upper()
        level = SensitiveLevel.SEVERE if level_raw == "SEVERE" else SensitiveLevel.LIGHT
        word = (row.get("word") or "").strip()
        if word:
            result.append(SensitiveWord(word=word, level=level))
    return result


def _load_strategy():
    row = db.query_one(
        """
        SELECT low_risk_max_score, medium_risk_max_score,
               low_risk_action, medium_risk_action, high_risk_action
        FROM review_strategy_config WHERE id = 1
        """
    )
    return strategy_from_db(row or {})


def _user_exists(user_id: int) -> bool:
    return (
        db.query_one("SELECT 1 FROM `user` WHERE user_id = %s LIMIT 1", (user_id,))
        is not None
    )


def _comment_review_result(result) -> ReviewResult:
    if result.decision == ReviewDecision.REJECT:
        return ReviewResult(
            review_ok=True,
            review_status="REJECTED",
            displayable=False,
            pending_manual=False,
            message=result.user_message,
            sensitive_words=result.sensitive_words_hit,
            audit_status=2,
            audit_method=result.audit_method,
            auto_audit_status=result.auto_audit_status,
        )
    if result.decision == ReviewDecision.INSERT_APPROVED:
        return ReviewResult(
            review_ok=True,
            review_status="APPROVED",
            displayable=True,
            pending_manual=False,
            message=result.user_message or "评论已发布",
            sensitive_words=result.sensitive_words_hit,
            audit_status=result.audit_status,
            audit_method=result.audit_method,
            auto_audit_status=result.auto_audit_status,
        )
    return ReviewResult(
        review_ok=True,
        review_status="PENDING",
        displayable=False,
        pending_manual=True,
        message=result.user_message or "评论已提交，等待审核",
        sensitive_words=result.sensitive_words_hit,
        audit_status=result.audit_status,
        audit_method=result.audit_method,
        auto_audit_status=result.auto_audit_status,
    )


def check_health() -> tuple[bool, str]:
    if not is_enabled():
        return False, "disabled"
    try:
        db.query_one("SELECT COUNT(*) AS c FROM sensitive_words WHERE enabled = 1")
        db.query_one("SELECT id FROM review_strategy_config WHERE id = 1 LIMIT 1")
        return True, "mysql+content_review_engine"
    except Exception as e:
        logger.warning("content review health check failed: %s", e)
        return False, str(e)


def submit_comment(
    user_id: int,
    museum_id: int,
    object_id: str,
    content: str,
    source: str = "app",
) -> ReviewResult:
    if not is_enabled():
        return ReviewResult(
            review_ok=False,
            message="内容审核未启用，已转为本地待审核",
        )
    if not _user_exists(user_id):
        return ReviewResult(
            review_ok=True,
            review_status="REJECTED",
            message="用户不存在",
        )
    try:
        words = _load_sensitive_words()
        strategy = _load_strategy()
        result = engine_submit_comment(content, words, strategy)
        return _comment_review_result(result)
    except Exception as e:
        logger.exception("submit_comment review failed user=%s", user_id)
        return ReviewResult(
            review_ok=False,
            message="审核服务暂不可用，已转为本地待审核",
        )


def submit_photo(
    user_id: int,
    photo_url: str,
    description: str = "",
    museum_id: int | None = None,
    object_id: str | None = None,
    source: str = "app",
) -> ReviewResult:
    del museum_id, object_id, source
    if not is_enabled():
        return ReviewResult(
            review_ok=False,
            review_status="PENDING",
            pending_manual=True,
            message="照片已上传，审核通过后将公开展示",
            audit_status=0,
            audit_method=2,
            auto_audit_status=1,
            auto_audit_score=0.0,
        )
    if not _user_exists(user_id):
        return ReviewResult(
            review_ok=True,
            review_status="REJECTED",
            message="用户不存在",
        )
    try:
        words = _load_sensitive_words()
        result = engine_submit_photo(description, photo_url, words)
        return ReviewResult(
            review_ok=True,
            review_status="PENDING",
            displayable=False,
            pending_manual=True,
            message=result.user_message or "已提交，等待人工审核",
            sensitive_words=result.sensitive_words_hit,
            audit_status=result.status,
            audit_method=result.audit_method,
            auto_audit_status=result.auto_audit_status,
            auto_audit_score=result.auto_audit_score,
        )
    except Exception as e:
        logger.exception("submit_photo review failed user=%s", user_id)
        return ReviewResult(
            review_ok=False,
            review_status="PENDING",
            pending_manual=True,
            message="照片已上传，审核通过后将公开展示",
            audit_status=0,
            audit_method=2,
            auto_audit_status=1,
            auto_audit_score=0.0,
        )


def report_login(user_id: int, ip_address: str = "", source: str = "app") -> None:
    """旧 integration 登录上报已废弃，保留空实现以免改动登录流程。"""
    del user_id, ip_address, source


def public_upload_url(relative_path: str) -> str:
    """将 /uploads/xxx 转为完整 URL，供图片风险评分使用。"""
    base = config.PUBLIC_API_BASE.rstrip("/")
    path = relative_path if relative_path.startswith("/") else f"/{relative_path}"
    return f"{base}{path}"
