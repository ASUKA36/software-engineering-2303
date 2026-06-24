# 海外藏中国文物知识问答系统

基于 **MySQL + Neo4j 知识图谱** 与 **大语言模型** 的文物问答服务，支持流式对话、多轮会话、RAG 检索，以及**知识图谱事实与 LLM 补充说明的分区标注**。

📄 **子系统整体介绍（推荐先读）**：[qa_system/docs/00_子系统整体介绍.md](./qa_system/docs/00_子系统整体介绍.md)

---

## 快速启动（推荐先看这里）

本项目分为 **后端**（`qa_system/`，FastAPI，端口 `8000`）和 **前端**（`chat-web/`，Vue 3 + Vite，端口 `5173`），需要**分别启动**。

### 环境要求

| 组件 | 版本建议 |
|------|----------|
| Python | 3.10+ |
| Node.js | 20.19+ 或 22.12+ |
| MySQL | 可访问的远程/本地库（文物数据） |
| Neo4j | 可选，建议开启（知识图谱查询） |
| LLM | 任意 OpenAI 兼容 API（DeepSeek、通义、SenseNova 等） |

---

### 第一次运行：安装依赖

#### 1. 配置环境变量

在 `qa_system/` 目录下创建 `.env` 文件（若已有则检查配置是否正确）：

```env
# 数据库 Tool 开关：on / off
ENABLE_MYSQL=on
ENABLE_NEO4J=on

# MySQL
MYSQL_HOST=你的MySQL地址
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=你的密码
MYSQL_DB=overseas_chinese_artifacts

# Neo4j（ENABLE_NEO4J=on 时必填）
NEO4J_URI=bolt://你的Neo4j地址:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=你的密码

# 大语言模型（OpenAI 兼容协议）
LLM_BASE_URL=https://api.example.com/v1
LLM_API_KEY=你的API密钥
LLM_MODEL_NAME=模型名称

LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=2048
LLM_TIMEOUT=60
LLM_MAX_RETRIES=2

SESSION_MAX_TURNS=5
```

> **注意**：`.env` 含密钥，不要提交到 Git。前端默认连接 `http://localhost:8000`，后端须先启动。

#### 2. 安装后端依赖

**Windows（PowerShell）：**

```powershell
cd qa_system
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**Linux / macOS：**

```bash
cd qa_system
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

#### 3. 安装前端依赖

```powershell
cd chat-web
npm install
```

---

### 日常启动（Windows PowerShell）

需要打开 **两个终端窗口**。

**终端 1 — 启动后端：**

```powershell
cd qa_system
.\.venv\Scripts\Activate.ps1
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**终端 2 — 启动前端：**

```powershell
cd chat-web
npm run dev
```

#### 访问地址

| 服务 | 地址 |
|------|------|
| 前端页面（主入口） | http://localhost:5173 |
| 后端 API 文档 | http://localhost:8000/docs |
| 健康检查 | http://localhost:8000/health |
| WebSocket | `ws://localhost:8000/api/qa/ws?session_id=...` |

浏览器打开 **http://localhost:5173** 即可开始提问。

#### 验证是否启动成功

```powershell
# 后端应返回 {"status":"ok", ...}
curl http://localhost:8000/health
```

---

### 日常启动（Linux / macOS，使用 Makefile）

在项目根目录：

```bash
# 首次：创建虚拟环境并安装依赖
make install-venv

# 一键启动后端 + 前端
make run

# 查看状态 / 日志 / 停止
make status
make logs
make stop
```

---

### Docker 仅启动后端

前端仍需本地 `npm run dev`，或在 `chat-web` 构建后自行部署静态资源。

```bash
# 在项目根目录准备 .env（变量名与 qa_system/.env 一致）
docker-compose up -d --build
docker-compose logs -f
```

---

## 停止服务

**Windows：** 在两个终端中分别按 `Ctrl + C`。

**Makefile：**

```bash
make stop
```

**Docker：**

```bash
docker-compose down
```

---

## 常见问题

### 1. 前端能打开，但提问无响应

- 确认后端已启动：`http://localhost:8000/health` 可访问
- 确认 `qa_system/.env` 中 `LLM_API_KEY`、数据库连接正确
- 查看后端终端报错（常见：MySQL/Neo4j 连不上、LLM Key 无效）

### 2. PowerShell 提示无法激活虚拟环境

以管理员运行一次：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. 端口被占用

- 后端换端口：`uvicorn main:app --reload --port 8001`
- 前端换端口：`npm run dev -- --port 5174`
- 若改后端端口，需同步修改 `chat-web/src/api/chat.ts` 中的 `HTTP_BASE` 和 `WS_BASE`

### 4. `npm install` 失败

确认 Node 版本 ≥ 20.19，可用 `node -v` 检查。

---

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                   Frontend (Vue 3 + Vite)                     │
│                   chat-web/  →  :5173                       │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP + WebSocket
┌───────────────────────────▼─────────────────────────────────┐
│                   Backend (FastAPI)                         │
│                   qa_system/  →  :8000                      │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  ws_router  │  │  qa_router   │  │   Main Agent     │   │
│  └──────┬──────┘  └──────────────┘  └────────┬─────────┘   │
│         │                                      │             │
│  ┌──────▼──────────────────────────────────────▼─────────┐  │
│  │                   Graph Agent                           │  │
│  │   MySQL Tool (execute_sql)  +  Neo4j Tool (query_neo4j) │  │
│  └──────────────────────────┬──────────────────────────────┘  │
└─────────────────────────────┼─────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
        ┌─────▼─────┐                   ┌─────▼─────┐
        │   MySQL   │                   │   Neo4j   │
        │ 文物结构化 │                   │ 知识图谱  │
        └───────────┘                   └───────────┘
```

### 双 Agent 分工

| Agent | 职责 | 文件 |
|-------|------|------|
| **Graph Agent** | 意图识别 + MySQL/Neo4j 查询 + 结果整理 | `qa_system/app/agents/graph_agent.py` |
| **Main Agent** | 基于查询结果生成补充说明 + 流式输出 | `qa_system/app/agents/main_agent.py` |

### 事实与 LLM 内容区分（课设要求）

- 回答正文仍为**单区块**，由大语言模型基于查询结果**润色生成**（与原先体验一致）
- 回答末尾附灰色备注，说明正文由 LLM 润色、事实数据来自 MySQL / Neo4j
- 溯源链接单独展示在回答下方

---

## 目录结构

```
qa_system-frame-opti/
├── qa_system/                 # 后端
│   ├── main.py                # FastAPI 入口
│   ├── config.py              # 读取 .env
│   ├── requirements.txt
│   ├── .env                   # 本地配置（勿提交）
│   └── app/
│       ├── agents/            # Graph / Main Agent
│       ├── api/               # REST + WebSocket 路由
│       ├── core/              # 会话、溯源、事实格式化
│       └── db/                # MySQL / Neo4j 客户端
├── chat-web/                  # 前端
│   ├── src/
│   │   ├── api/chat.ts        # 后端地址配置
│   │   ├── components/        # 消息展示（含事实/补充分区）
│   │   └── stores/chat.ts     # WebSocket 状态
│   └── package.json
├── docker-compose.yml
├── Makefile                   # Linux/macOS 一键脚本
└── README.md
```

---

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/qa/session` | 创建会话 |
| DELETE | `/api/qa/session/{id}` | 删除会话 |
| GET | `/api/qa/history/{id}` | 查询历史 |
| POST | `/api/qa/ask` | 非流式问答（REST） |
| WS | `/api/qa/ws?session_id=xxx` | 流式对话（前端使用） |

---

## 推送到 GitHub

```powershell
cd 项目根目录
git init
git branch -M main
git remote add origin https://github.com/ZQ-free/qa_system.git
git add .
git commit -m "更新代码"
git push -u origin main
```

推送前确认 `.gitignore` 已排除 `.env`、`node_modules/`、`.venv/` 等敏感或大体积目录。

---

## 开发调试

### 后端日志前缀

- `[GraphAgent]` — 图谱查询 Agent
- `[MainAgent]` — 主问答 Agent
- `[SessionManager]` — 会话与持久化
- `[WS]` — WebSocket 消息

### 修改后端地址

编辑 `chat-web/src/api/chat.ts`：

```ts
const WS_BASE = 'ws://localhost:8000/api/qa/ws'
const HTTP_BASE = 'http://localhost:8000/api/qa'
```
