# -*- coding: utf-8 -*-
"""掌上博物馆 — 项目联调测试脚本（conda py38 运行）。"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional

# App Constants.ets 中配置的服务地址
FLASK_API = "http://10.4.109.63:5000"
IMAGE_API = "http://47.96.152.190:8000"
QA_API = "http://10.4.161.20:8000"


@dataclass
class CaseResult:
    name: str
    url: str
    passed: bool
    detail: str = ""
    extra: dict[str, Any] = field(default_factory=dict)


def http_get(url: str, timeout: int = 15) -> tuple[bool, int, Any, str]:
    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = r.read()
            ctype = r.headers.get("Content-Type", "")
            if "json" in ctype or body[:1] in (b"{", b"["):
                try:
                    return True, r.status, json.loads(body.decode("utf-8", errors="replace")), ctype
                except json.JSONDecodeError:
                    return True, r.status, body.decode("utf-8", errors="replace")[:500], ctype
            return True, r.status, body, ctype
    except urllib.error.HTTPError as e:
        try:
            payload = e.read().decode("utf-8", errors="replace")[:300]
        except Exception:
            payload = str(e)
        return False, e.code, payload, ""
    except Exception as e:
        return False, 0, str(e), ""


def test_flask_health() -> CaseResult:
    ok, code, data, _ = http_get(f"{FLASK_API}/api/health")
    if not ok:
        return CaseResult("Flask 健康检查", f"{FLASK_API}/api/health", False, f"不可达: {data}")
    passed = code == 200 and isinstance(data, dict)
    mysql_ok = data.get("mysql") if isinstance(data, dict) else None
    neo4j_ok = data.get("neo4j") if isinstance(data, dict) else None
    detail = f"HTTP {code}, mysql={mysql_ok}, neo4j={neo4j_ok}"
    return CaseResult("Flask 健康检查", f"{FLASK_API}/api/health", passed, detail, {"body": data})


def test_flask_theme() -> CaseResult:
    ok, code, data, _ = http_get(f"{FLASK_API}/api/theme")
    if not ok:
        return CaseResult("Flask 专题信息", f"{FLASK_API}/api/theme", False, f"不可达: {data}")
    passed = code == 200 and isinstance(data, dict) and bool(data.get("name") or data.get("theme"))
    name = data.get("name") or data.get("theme") if isinstance(data, dict) else ""
    return CaseResult("Flask 专题信息", f"{FLASK_API}/api/theme", passed, f"HTTP {code}, theme={name!r}")


def test_flask_artifacts() -> CaseResult:
    ok, code, data, _ = http_get(f"{FLASK_API}/api/artifacts?page=1&size=5")
    if not ok:
        return CaseResult("Flask 文物列表", f"{FLASK_API}/api/artifacts", False, f"不可达: {data}")
    passed = code == 200 and isinstance(data, dict)
    total = data.get("total") if isinstance(data, dict) else None
    items = data.get("list") or data.get("artifacts") if isinstance(data, dict) else None
    count = len(items) if isinstance(items, list) else 0
    detail = f"HTTP {code}, total={total}, returned={count}"
    return CaseResult("Flask 文物列表", f"{FLASK_API}/api/artifacts", passed and count > 0, detail)


def test_image_api_health() -> CaseResult:
    ok, code, data, _ = http_get(f"{IMAGE_API}/api/health")
    if not ok:
        return CaseResult("图片 API 健康检查", f"{IMAGE_API}/api/health", False, f"不可达: {data}")
    passed = code == 200
    detail = f"HTTP {code}"
    if isinstance(data, dict):
        detail += f", mysql={data.get('mysql')}, roots={data.get('image_roots')}"
    return CaseResult("图片 API 健康检查", f"{IMAGE_API}/api/health", passed, detail, {"body": data})


def test_image_api_artifacts() -> CaseResult:
    ok, code, data, _ = http_get(f"{IMAGE_API}/api/artifacts?museum_id=2&size=5")
    if not ok:
        return CaseResult("图片 API 文物列表", f"{IMAGE_API}/api/artifacts", False, f"不可达: {data}")
    passed = code == 200 and isinstance(data, dict)
    lst = data.get("list", []) if isinstance(data, dict) else []
    hit = sum(1 for x in lst if x.get("has_local_image"))
    detail = f"HTTP {code}, total={data.get('total')}, has_local_image={hit}/{len(lst)}"
    return CaseResult("图片 API 文物列表", f"{IMAGE_API}/api/artifacts", passed and len(lst) > 0, detail)


def test_image_download() -> CaseResult:
    ok, code, data, _ = http_get(f"{IMAGE_API}/api/artifacts?museum_id=2&size=10")
    if not ok or not isinstance(data, dict):
        return CaseResult("图片下载", f"{IMAGE_API}/api/img/...", False, "无法获取文物列表")
    item = next((x for x in data.get("list", []) if x.get("has_local_image")), None)
    if not item:
        return CaseResult("图片下载", f"{IMAGE_API}/api/img/...", False, "无可用本地图片")
    img_path = item.get("img_web") or f"/api/img/{item['museum_id']}/{item['object_id']}"
    url = IMAGE_API + img_path if img_path.startswith("/") else img_path
    ok2, code2, body, ctype = http_get(url, timeout=30)
    size = len(body) if isinstance(body, (bytes, bytearray)) else 0
    passed = ok2 and code2 == 200 and size > 1000
    return CaseResult("图片下载", url, passed, f"HTTP {code2}, type={ctype}, size={size} bytes")


def test_qa_health() -> CaseResult:
    ok, code, data, _ = http_get(f"{QA_API}/health")
    if not ok:
        return CaseResult("问答 API 健康检查", f"{QA_API}/health", False, f"不可达: {data}")
    passed = code == 200
    status = data.get("status") if isinstance(data, dict) else data
    return CaseResult("问答 API 健康检查", f"{QA_API}/health", passed, f"HTTP {code}, status={status!r}")


def main() -> int:
    cases = [
        test_flask_health(),
        test_flask_theme(),
        test_flask_artifacts(),
        test_image_api_health(),
        test_image_api_artifacts(),
        test_image_download(),
        test_qa_health(),
    ]
    passed = sum(1 for c in cases if c.passed)
    total = len(cases)
    report = {
        "project": "掌上博物馆 mobile_museum",
        "test_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "conda_env": "py38",
        "python": sys.version.split()[0],
        "summary": {"total": total, "passed": passed, "failed": total - passed},
        "cases": [
            {"name": c.name, "url": c.url, "passed": c.passed, "detail": c.detail}
            for c in cases
        ],
    }
    out_json = "test_report.json"
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(f"=== 掌上博物馆测试 ({passed}/{total} 通过) ===\n")
    for c in cases:
        mark = "PASS" if c.passed else "FAIL"
        print(f"[{mark}] {c.name}")
        print(f"       {c.url}")
        print(f"       {c.detail}\n")
    print(f"JSON 报告已写入: {out_json}")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
