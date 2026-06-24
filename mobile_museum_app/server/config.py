import os

MYSQL_HOST = os.getenv("MYSQL_HOST", "47.96.152.190")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "!software2303")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "overseas_chinese_artifacts")
MYSQL_CHARSET = os.getenv("MYSQL_CHARSET", "utf8mb4")

API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "5000"))

# App 上传图片对外可访问根 URL（供内容审核引擎对图片 URL 打分）
PUBLIC_API_BASE = os.getenv("PUBLIC_API_BASE", "http://47.96.152.190:5000").rstrip("/")

# 内容审核：共用 MySQL + content-review-handoff 引擎（见 content-review-handoff/README.md）
CONTENT_REVIEW_ENABLED = os.getenv("CONTENT_REVIEW_ENABLED", "true").lower() in (
    "1",
    "true",
    "yes",
)

# Web 组图片 API（backend/main.py uvicorn --port 8000），本地无图时转发
WEB_IMAGE_API_BASE = os.getenv("WEB_IMAGE_API_BASE", "http://47.96.152.190:8000").rstrip("/")

UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads")

# 本地图片根目录（多个用 ; 分隔，与 Web 组 HARVARD_IMAGE_DIR 等一致）
_default_roots = r"C:\Users\Administrator\Desktop\harvard\harvard"
IMAGE_ROOTS = [
    p.strip()
    for p in os.getenv("IMAGE_ROOTS", _default_roots).split(";")
    if p.strip()
]

# Neo4j 知识图谱（专题文物筛选）
NEO4J_URI = os.getenv("NEO4J_URI", "bolt://47.96.152.190:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "!software2303")

# 展示专题：瓷器（Ceramics / Porcelain 等子类）
THEME_NAME = os.getenv("THEME_NAME", "瓷器")
THEME_NAME_EN = os.getenv("THEME_NAME_EN", "Ceramics & Porcelain")
THEME_DESCRIPTION = os.getenv(
    "THEME_DESCRIPTION",
    "从知识图谱选取海外藏中国瓷器专题，涵盖陶瓷、白瓷、青瓷等类型",
)
THEME_TYPE_IDS = [
    "entity:artifacttype:ceramics",
    "entity:artifacttype:ceramics-porcelain",
    "entity:artifacttype:ceramics-pottery-earthenware",
    "entity:artifacttype:ceramics-pottery-stoneware",
]

# 馆别编号 → 中文简称（与 Web 组对接文档一致）
MUSEUM_LABELS = {
    1: "史密森尼",
    2: "哈佛艺术博物馆",
    3: "波士顿 MFA",
}
# 首页列表默认排除的馆别（史密森尼）
HOME_EXCLUDE_MUSEUM_IDS = [
    int(x.strip())
    for x in os.getenv("HOME_EXCLUDE_MUSEUM_IDS", "1").split(",")
    if x.strip().isdigit()
]
