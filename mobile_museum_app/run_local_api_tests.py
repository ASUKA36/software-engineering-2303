# -*- coding: utf-8 -*-
"""本地 Flask API 联调（server/app.py 启动后运行）。"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from datetime import datetime

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:5000"


def get(path: str) -> tuple[bool, int, object, str]:
    url = f"{BASE.rstrip('/')}{path}"
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            body = r.read()
            try:
                data = json.loads(body.decode("utf-8"))
            except json.JSONDecodeError:
                data = body.decode("utf-8", errors="replace")[:200]
            return True, r.status, data, url
    except urllib.error.HTTPError as e:
        return False, e.code, e.read().decode("utf-8", errors="replace")[:200], url
    except Exception as e:
        return False, 0, str(e), url


def main() -> int:
    cases: list[dict] = []

    ok, code, data, url = get("/api/health")
    db_ok = data.get("db") if isinstance(data, dict) else None
    kg_ok = data.get("knowledgeGraph") if isinstance(data, dict) else None
    theme_hint = data.get("theme") if isinstance(data, dict) else None
    cases.append({
        "name": "Flask 健康检查",
        "url": url,
        "passed": ok and code == 200 and data.get("code") == 0,
        "detail": f"HTTP {code}, db={db_ok}, knowledgeGraph={kg_ok}, theme={theme_hint!r}",
    })

    ok, code, data, url = get("/api/theme")
    theme_data = data.get("data") if isinstance(data, dict) else {}
    name = theme_data.get("name") if isinstance(theme_data, dict) else ""
    cases.append({
        "name": "Flask 专题信息",
        "url": url,
        "passed": ok and code == 200 and bool(name),
        "detail": f"HTTP {code}, theme={name!r}, count={theme_data.get('artifactCount')}",
    })

    ok, code, data, url = get("/api/artifacts?page=1&size=5")
    total = data.get("total") if isinstance(data, dict) else None
    lst = data.get("data") if isinstance(data, dict) else []
    count = len(lst) if isinstance(lst, list) else 0
    cases.append({
        "name": "Flask 文物列表",
        "url": url,
        "passed": ok and code == 200 and count > 0,
        "detail": f"HTTP {code}, total={total}, returned={count}",
    })

    if isinstance(lst, list) and lst:
        item = lst[0]
        mid = item.get("museumId") or item.get("museum_id")
        oid = item.get("objectId") or item.get("object_id")
        ok, code, data, url = get(f"/api/artifacts/{mid}/{oid}")
        title = (data.get("title") or "")[:30] if isinstance(data, dict) else ""
        cases.append({
            "name": "Flask 文物详情",
            "url": url,
            "passed": ok and code == 200,
            "detail": f"HTTP {code}, title={title!r}",
        })
    else:
        cases.append({
            "name": "Flask 文物详情",
            "url": f"{BASE}/api/artifacts/...",
            "passed": False,
            "detail": "无列表数据，跳过",
        })

    passed = sum(1 for c in cases if c["passed"])
    total_n = len(cases)
    print(f"=== 本地 Flask API 测试 ({passed}/{total_n} 通过) base={BASE} ===\n")
    for c in cases:
        mark = "PASS" if c["passed"] else "FAIL"
        print(f"[{mark}] {c['name']}")
        print(f"       {c['url']}")
        print(f"       {c['detail']}\n")

    report = {
        "test_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "base": BASE,
        "summary": {"total": total_n, "passed": passed, "failed": total_n - passed},
        "cases": cases,
    }
    out = "test_report_local.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(f"已写入 {out}")
    return 0 if passed == total_n else 1


if __name__ == "__main__":
    sys.exit(main())
