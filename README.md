# 海外藏中国文物知识管理与服务平台

**软件工程课程设计 · 计科2303**

面向海外博物馆馆藏中国文物的**知识管理与服务平台**：以**知识图谱**为核心，贯通数据采集、Web 服务、智能问答、移动端浏览与后台统一管理。

---

## 项目简介

| 项目 | 说明 |
|------|------|
| 课程 | 软件工程（课程设计） |
| 学院 | 信息科学与技术学院 |
| 专业班级 | 计科2303 |
| 代码仓库 | [ASUKA36/software-engineering-2303](https://github.com/ASUKA36/software-engineering-2303) |
| 组会 Wiki | [Wiki 首页](https://github.com/ASUKA36/software-engineering-2303/wiki) |

平台包含五个逻辑子系统，采用 **MySQL + Neo4j** 混合存储，Web / App / 后台共用业务库，问答子系统通过 RAG 结合大语言模型提供可溯源的智能问答。

---

## 子系统与代码路径

| 编号 | 子系统 | 负责人 | 路径 | 说明 |
|------|--------|--------|------|------|
| ① | 知识图谱构建 | 郭晨沛 | [`知识图谱构建子系统/`](知识图谱构建子系统/) | 爬虫、清洗、三元组、MySQL/Neo4j 入库、数据 API |
| ② | 海外文物知识服务（Web） | 万玉贤 | — | Web 前端与知识服务（见各组对接文档） |
| ③ | 知识问答 | 张芷淇 | [`qa_system-submit/`](qa_system-submit/) | FastAPI + Vue 3，RAG 流式问答 |
| ④ | 掌上博物馆 | 薛度扬 | [`mobile_museum_app/`](mobile_museum_app/) | HarmonyOS App + Flask 服务端 |
| ⑤ | 后台管理 | 陶湘园 | [`后台管理子系统/`](后台管理子系统/) | Spring Boot 管理端，RBAC、审核、图谱维护 |

各子系统详细运行说明见对应目录下的 `README.md`。

---

## 快速开始

### ① 知识图谱构建

```bash
cd 知识图谱构建子系统/crawler
pip install -r requirements.txt
# 配置 .env 后执行爬取 / 同步，详见 crawler/README.md
```

数据 API：`知识图谱构建子系统/backend/`（FastAPI，文物只读接口）。

### ③ 知识问答

```bash
# 后端
cd qa_system-submit/qa_system
pip install -r requirements.txt
# 配置 .env 后：uvicorn main:app --reload --port 8000

# 前端
cd qa_system-submit/chat-web
npm install && npm run dev
```

详见 [`qa_system-submit/README.md`](qa_system-submit/README.md)。

### ④ 掌上博物馆

1. 用 **DevEco Studio** 打开 `mobile_museum_app/`。
2. 启动 Python 服务端：

```bash
cd mobile_museum_app/server
pip install -r requirements.txt
python app.py
```

3. 修改 `entry/src/main/ets/common/Constants.ets` 中的 `API_BASE` 为本机局域网 IP。

详见 [`mobile_museum_app/README.md`](mobile_museum_app/README.md)。

### ⑤ 后台管理

```bash
cd 后台管理子系统
mvn spring-boot:run
```

默认超管：`admin` / `123456`（首次启动自动创建）。详见 [`后台管理子系统/README.md`](后台管理子系统/README.md)。

---

## 仓库结构

```
software-engineering-2303/
├── docs/                          # 课程设计文档
│   ├── 项目管理计划.md
│   └── 组会/                      # 全组周例会记录（第八～十四周）
├── 知识图谱构建子系统/              # ① 爬虫、图库、数据 API
├── qa_system-submit/              # ③ 问答后端 + chat-web 前端
├── mobile_museum_app/             # ④ HarmonyOS App + server
├── 后台管理子系统/                  # ⑤ Spring Boot 管理端
└── README.md                      # 本文件
```

---

## 文档

| 文档 | 位置 |
|------|------|
| 项目管理计划 | [`docs/项目管理计划.md`](docs/项目管理计划.md) |
| 组会记录（仓库内） | [`docs/组会/`](docs/组会/) |
| 组会记录（Wiki） | [GitHub Wiki](https://github.com/ASUKA36/software-engineering-2303/wiki) |
| 需求 / 设计 / 测试报告 | [`docs/`](docs/)（Word 文档） |
| 子系统对接说明 | 各子系统 README 及 `content-review-handoff` |

---

## 技术栈概览

| 层次 | 技术 |
|------|------|
| 数据层 | MySQL 8、Neo4j |
| 图谱构建 | Python 爬虫、CSV 清洗、Cypher 同步 |
| Web / 问答前端 | Vue 3 + Vite |
| 问答后端 | FastAPI、LangChain Agent、WebSocket 流式 |
| 移动端 | HarmonyOS ArkTS（DevEco Studio） |
| 后台管理 | Java 17、Spring Boot 3、JWT、单页管理 UI |
| 内容审核 | 共用 `sensitive_words` / `review_strategy_config`，handoff 包跨子系统复用 |

---

## 组内分工

| 姓名 | 学号 | 主要承担 |
|------|------|----------|
| 郭晨沛 | 2023040172 | 知识图谱构建子系统 |
| 万玉贤 | 2023040060 | 海外文物知识服务子系统（Web） |
| 张芷淇 | 2023040133 | 知识问答子系统 |
| 薛度扬 | 2023040176 | 掌上博物馆 |
| 陶湘园 | 2023040288 | 后台管理子系统 |

---

## 组会记录

全组周例会记录（第八周～第十四周）维护于：

- **GitHub Wiki**：[Wiki 首页](https://github.com/ASUKA36/software-engineering-2303/wiki)（推荐浏览）
- **本仓库**：[`docs/组会/`](docs/组会/)

Wiki 内容由 [`docs/组会/`](docs/组会/) 同步，推送方式见 [`scripts/push-wiki.ps1`](scripts/push-wiki.ps1)。

---

## 许可证与说明

本项目为北京化工大学软件工程课程设计成果，数据来源于公开博物馆网站，仅供教学与研究使用。
