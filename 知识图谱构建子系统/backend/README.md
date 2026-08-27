# 海外藏中国文物 — Backend REST API

**项目：** 海外藏中国文物知识管理与服务平台  
**模块：** 后台接口子系统（只读 BFF 网关）  
**提供方：** 知识图谱构建组 / 爬虫数据组  
**更新：** 2026-06-04

**详细对接文档：** [Web组对接文档.md](./Web组对接文档.md)  
**数据来源：** [../crawler/README.md](../crawler/README.md)  
**示例页面：** [gallery.html](./gallery.html)、[web_demo.html](./web_demo.html)

---

## 模块概述

Backend 是基于 **FastAPI + Uvicorn** 的只读 REST 服务，部署于远程服务器，从 **MySQL `artifact` 表**读取爬虫采集的文物元数据，并通过 **图片路径解析器**将本地磁盘图片以 HTTP 形式返回给 Web 前端、掌上博物馆 App 等客户端。

**设计原则：** 前端不直连数据库，统一通过 HTTP 访问本服务。

| 指标 | 数值 |
|------|------|
| 部署地址 | `http://47.96.152.190:8000` |
| API 数量 | **5** 个 GET 接口 |
| 数据源 | MySQL `overseas_chinese_artifacts.artifact`（**7151** 条） |
| 主键 | `(museum_id, object_id)` |

---

## 服务地址

| 项目 | 地址 |
|------|------|
| **API 基址** | `http://47.96.152.190:8000` |
| **Swagger 文档** | http://47.96.152.190:8000/docs |
| **健康检查** | `GET /api/health` |
| **跨域 CORS** | 已开启（`allow_origins: *`） |

> 联调前请确认服务已启动。若 `/api/health` 超时，需在服务器执行 `uvicorn main:app --host 0.0.0.0 --port 8000`。

---

## 技术架构

```
浏览器 / Web / App
        ↓ HTTP GET
   main.py（FastAPI）
   ├── db_helper.py      → MySQL artifact 表（PyMySQL, utf8mb4）
   └── image_resolver.py → 本地图片磁盘 → FileResponse
        ↑
   crawler 爬虫写入的数据与图片
```

| 文件 | 职责 |
|------|------|
| `main.py` | 5 个 REST 路由、JSON 组装、`img_web` 生成 |
| `db_helper.py` | MySQL 连接（`DictCursor`，短连接） |
| `image_resolver.py` | 多根目录解析 `image_path` / `image_paths` |

---

## 接口列表

| 用途 | 方法 | 路径 |
|------|------|------|
| 健康检查 | GET | `/api/health` |
| 藏品列表（分页/筛选） | GET | `/api/artifacts` |
| 藏品详情 | GET | `/api/artifacts/{museum_id}/{object_id}` |
| 主图 | GET | `/api/img/{museum_id}/{object_id}` |
| 多图第 N 张 | GET | `/api/img/{museum_id}/{object_id}/{index}` |

**图片 URL 示例：**

```
http://47.96.152.190:8000/api/img/2/388077       ← 哈佛主图
http://47.96.152.190:8000/api/img/2/388077/1     ← 哈佛第 2 张
http://47.96.152.190:8000/api/img/3/98.12        ← MFA 主图
```

---

## 馆别编号 `museum_id`

| museum_id | 博物馆 | MySQL 约藏品数 |
|-----------|--------|----------------|
| 1 | 史密森尼 Smithsonian | 2244 |
| 2 | 哈佛艺术博物馆 Harvard | 4644 |
| 3 | 波士顿美术馆 MFA | 263 |
| **合计** | | **7151** |

**主键：** `(museum_id, object_id)`，与爬虫 `CSV_FIELDS` 一致。

---

## 前端对接规则（重要）

1. **不要用** 数据库字段 `image_path`、`image_url`（浏览器无法直接访问本地路径）。
2. **只用** 列表/详情返回的 **`img_web`**、**`imgs_web`**。
3. 图片完整地址 = **`API_BASE + img_web`**。
4. `has_local_image === false` 时显示占位图。
5. 列表必须**分页**，`size` 最大 **100**，勿一次拉全库。

---

## 列表接口

```
GET /api/artifacts?museum_id=2&page=1&size=24
GET /api/artifacts?museum_id=2&q=bowl&dynasty=Song
```

| 参数 | 说明 |
|------|------|
| museum_id | 1/2/3，不传则三馆混合 |
| page | 页码，从 1 开始 |
| size | 每页条数，默认 20，最大 100 |
| q | 标题关键词（模糊） |
| dynasty | 朝代（模糊） |
| material | 材质（模糊） |

**响应关键字段：**

```json
{
  "museum_id": 2,
  "object_id": "388077",
  "title": "Study for Vermicular Calligraphy I",
  "artist": "Cui Fei 崔斐",
  "dynasty": "",
  "material": "Ink rubbing on Xuan paper",
  "type": "Rubbings",
  "museum": "Harvard Art Museums",
  "image_count": 2,
  "img_web": "/api/img/2/388077",
  "imgs_web": ["/api/img/2/388077", "/api/img/2/388077/1"],
  "has_local_image": true
}
```

---

## 前端代码示例

```javascript
const API_BASE = "http://47.96.152.190:8000";

// 列表
const res = await fetch(
  `${API_BASE}/api/artifacts?museum_id=2&page=1&size=24`
);
const { list, total } = await res.json();

// 图片（仅 has_local_image 为 true 时）
list.filter((x) => x.has_local_image).forEach((item) => {
  const img = document.createElement("img");
  img.src = API_BASE + item.img_web;
  img.alt = item.title;
  img.loading = "lazy";
  document.body.appendChild(img);
});

// 详情
const detail = await fetch(`${API_BASE}/api/artifacts/2/388077`).then((r) =>
  r.json()
);
```

---

## 本地开发与部署

### 安装依赖

```powershell
cd backend
pip install -r requirements.txt
```

### 配置 `.env`

复制 `.env.example` 为 `.env`：

```env
MYSQL_HOST=47.96.152.190
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=你的密码
MYSQL_DATABASE=overseas_chinese_artifacts
MYSQL_TABLE=artifact

# 图片根目录（按部署机实际路径配置）
HARVARD_IMAGE_DIR=C:\Users\Administrator\Desktop\harvard\harvard
IMAGE_EXTRA_DIRS=C:\Users\Administrator\Desktop\mfa\mfa
```

也可复用 `crawler/.env` 中的 `MYSQL_*`（`main.py` 会自动加载）。

### 启动服务

```powershell
cd backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

生产环境去掉 `--reload`，并配置 Windows 计划任务或 NSSM 保持常驻。

---

## 联调自检

- [ ] `GET /api/health` → `ok: true`, `mysql: true`
- [ ] `GET /api/artifacts?museum_id=2&size=5` → 有列表且 `has_local_image: true`
- [ ] `GET /api/img/2/388077` → 浏览器能显示图片
- [ ] 本地打开 `gallery.html` 瀑布流正常

**PowerShell 快速检测：**

```powershell
Invoke-WebRequest -Uri "http://47.96.152.190:8000/api/health" -UseBasicParsing
Invoke-WebRequest -Uri "http://47.96.152.190:8000/api/artifacts?museum_id=2&size=3" -UseBasicParsing
```

---

## 项目结构

```
backend/
├── README.md              # 本文件
├── Web组对接文档.md        # 完整 API 对接说明（给 Web 组）
├── main.py                # FastAPI 主程序（全部路由）
├── db_helper.py           # MySQL 连接（PyMySQL）
├── image_resolver.py      # 本地图片路径解析
├── requirements.txt       # fastapi, uvicorn, PyMySQL, python-dotenv
├── .env.example           # 环境变量模板
├── gallery.html           # 瀑布流联调 Demo（推荐）
├── web_demo.html          # 简单联调页
└── test_output/           # 远程测试页面
```

---

## 与子系统关系

| 上游 | 说明 |
|------|------|
| [crawler](../crawler/) | 爬取数据写入 MySQL + 本地图片 |
| MySQL | 本服务唯一关系型数据源 |
| Neo4j | **本服务不查询**；图谱由 Web 组 / 问答组另行对接 |

| 下游 | 说明 |
|------|------|
| 海外文物知识服务（Web） | Vue 前端调用本 API |
| 掌上博物馆（HarmonyOS） | 部分能力走 Flask :5000，基础文物数据可复用本 API |
| 后台管理子系统 | 直写共用 MySQL，管理端独立 Spring Boot API |

---

## 常见问题

| 问题 | 处理 |
|------|------|
| API 超时 / 无法访问 | 服务器上 backend 进程未启动或 8000 端口未放行 |
| `503 MySQL 未配置` | 检查 `backend/.env` 或 `crawler/.env` 中 `MYSQL_*` |
| `has_local_image: false` | 本地无图或 `HARVARD_IMAGE_DIR` 路径未配对 |
| 图片 404 | 确认 `image_resolver` 能找到 `crawler/data/output/images/` 或 `crawler/output/images/` 下文件 |
| 需要 MySQL 账号？ | **仅展示走 API 即可**；用户/收藏等扩展功能联系后台管理组 |

---

## 一句话总结

基址 `http://47.96.152.190:8000`，列表调 `/api/artifacts`，图片用返回的 `img_web` 拼完整 URL；五个接口均部署在服务器端，前端 HTTP 调用即可，无需直连数据库。

**在线调试：** http://47.96.152.190:8000/docs
