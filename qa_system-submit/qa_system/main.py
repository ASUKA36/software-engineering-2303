"""
main.py — 应用入口
启动 FastAPI 服务，注册所有路由。
运行方式: uvicorn main:app --reload --port 8000

前端由独立的 chat-web/（Vue 3 + Vite）服务；本服务只暴露后端 API 与 WebSocket。
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.qa_router import router as qa_router
from app.api.admin_router import router as admin_router
from app.api.ws_router import register_ws_router
from config import settings

app = FastAPI(
    title="知识问答子系统",
    description="基于知识图谱与大语言模型的文物问答服务",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(qa_router, prefix="/api/qa")
app.include_router(admin_router, prefix="/api/qa")
register_ws_router(app)


@app.on_event("startup")
async def startup():
    import logging
    from config import settings, ENV_FILE

    logging.info(
        "[Startup] env=%s mysql=%s@%s/%s neo4j=%s(enabled=%s) llm=%s model=%s key_set=%s",
        ENV_FILE,
        settings.MYSQL_USER,
        settings.MYSQL_HOST,
        settings.MYSQL_DB,
        settings.NEO4J_URI,
        settings.ENABLE_NEO4J,
        settings.LLM_BASE_URL,
        settings.LLM_MODEL_NAME,
        bool(settings.LLM_API_KEY),
    )

    from app.core.session_manager import get_session_manager
    sm = get_session_manager()
    await sm.ensure_table()


@app.on_event("shutdown")
async def shutdown():
    from app.db.mysql_client import MySQLClient
    await MySQLClient.close_pool()


@app.get("/")
async def index():
    """后端根路径。前端由 chat-web/ 独立提供。"""
    return {
        "service": "overseas-artifacts-qa-backend",
        "version": "1.0.0",
        "docs": "/docs",
        "api": "/api/qa",
        "admin_api": "/api/qa/admin (requires X-Admin-Key)",
        "websocket": "/api/qa/ws?session_id=...",
        "frontend_hint": "前端由 ../chat-web/ 启动 (默认 http://localhost:5173)",
    }


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "enable_mysql": settings.ENABLE_MYSQL,
        "enable_neo4j": settings.ENABLE_NEO4J,
    }