"""
config.py — 全局配置
读取 .env 文件中的所有配置项，整个项目统一从这里导入。
"""

from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# 固定从 qa_system 目录加载 .env，避免在错误 cwd 下启动时读不到配置
BASE_DIR = Path(__file__).resolve().parent
ENV_FILE = BASE_DIR / ".env"


def _env_bool(value: object) -> bool:
    """兼容 .env 里 on/off、true/false 等写法。"""
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    return str(value).strip().lower() in {"1", "true", "yes", "on", "y"}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ── 数据库 Tool 开关 ──────────────────────────────────────
    ENABLE_MYSQL: bool = True
    ENABLE_NEO4J: bool = False

    # ── Neo4j 图数据库 ────────────────────────────────────────
    NEO4J_URI: str = "bolt://47.96.152.190:7687"
    NEO4J_USER: str = "neo4j"
    NEO4J_PASSWORD: str = ""

    # ── MySQL 关系型数据库 ─────────────────────────────────────
    MYSQL_HOST: str = "47.96.152.190"
    MYSQL_PORT: int = 3306
    MYSQL_USER: str = "root"
    MYSQL_PASSWORD: str = ""
    MYSQL_DB: str = "overseas_chinese_artifacts"

    # ── 大语言模型（OpenAI 兼容协议）─────────────────────────
    LLM_BASE_URL: str = "https://api.deepseek.com/v1"
    LLM_API_KEY: str = ""
    LLM_MODEL_NAME: str = "deepseek-chat"

    # ── LLM 生成参数 ──────────────────────────────────────────
    LLM_TEMPERATURE: float = 0.1
    LLM_MAX_TOKENS: int = 2048
    LLM_TIMEOUT: int = 60
    LLM_MAX_RETRIES: int = 2

    # ── 会话配置（多轮对话）───────────────────────────────────
    SESSION_MAX_TURNS: int = 8

    # ── 性能调优 ──────────────────────────────────────────────
    # Graph Agent 最大工具轮数（每轮含一次 LLM 调用，越小越快）
    GRAPH_AGENT_MAX_TURNS: int = 8
    # 流式回答写入 MySQL 的批量字符数（越大越少写库，但断线续写粒度越粗）
    STREAM_DB_FLUSH_CHARS: int = 80

    # ── 管理员接口 ────────────────────────────────────────────
    # 管理类 API 鉴权密钥；留空则禁用管理接口
    ADMIN_API_KEY: str = ""
    # 管理员登录密码（前端 /admin 入口用）；留空则与 ADMIN_API_KEY 相同
    ADMIN_PASSWORD: str = ""

    @field_validator("ENABLE_MYSQL", "ENABLE_NEO4J", mode="before")
    @classmethod
    def parse_bool_switch(cls, value: object) -> bool:
        return _env_bool(value)


settings = Settings()