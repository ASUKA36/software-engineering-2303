# 海外藏中国文物 — 数据爬取与知识图谱子系统

**项目：** 海外藏中国文物知识管理与服务平台  
**模块：** 知识图谱构建子系统（爬虫 / 清洗 / 三元组 / Neo4j / 数据 API）  
**更新：** 2026-06-04

---

## 模块概述

本子系统负责从 **史密森尼（Smithsonian）**、**哈佛艺术博物馆（Harvard）**、**波士顿美术博物馆（MFA Boston）** 三家海外博物馆采集中国文物数据，完成清洗标准化后写入 **CSV + MySQL**，并导出知识图谱中间文件同步至 **Neo4j**。同时为 Web / App 提供只读 REST API（见 [`../backend/README.md`](../backend/README.md)）。

| 指标 | 数值 |
|------|------|
| MySQL 文物总条数 | **7151**（史密森尼 2244 + 哈佛 4644 + MFA 263） |
| 关系三元组（CSV） | **70,888** 条（`output/kg/relations/`） |
| Neo4j 图库边 | **143,623** 条 |
| 统一主键 | `(museum_id, object_id)` |
| 标准字段数 | **34** 列（`config.CSV_FIELDS`） |

---

## 目录结构

```
crawler/
├── museum_spider.py          # 统一入口（爬取 / enrich-wikidata / csv-sync）
├── README.md                 # 本文件
├── requirements.txt
├── run_incremental_update.sh # 增量爬取脚本（Linux/macOS）
│
├── museum_crawler/           # 核心 Python 包
│   ├── cli.py                # 命令行调度
│   ├── config.py             # CSV_FIELDS、museum_id、日志
│   ├── smithsonian.py        # 史密森尼爬虫
│   ├── harvard.py            # 哈佛爬虫
│   ├── mfa_boston.py         # MFA 爬虫（Playwright）
│   ├── http_client.py        # HTTP / 图片下载 / 退避
│   ├── record_build.py       # 统一记录构建
│   ├── text_geography.py     # 朝代 / 省份推断
│   ├── material_normalize.py # 材质规范化
│   ├── data_clean.py         # CSV 清洗逻辑
│   ├── quality.py            # 爬后质检
│   ├── db.py                 # MySQL UPSERT
│   ├── io_csv.py             # CSV 读写
│   ├── csv_db_sync.py        # CSV ↔ MySQL 双向同步
│   ├── kg_export.py          # 知识图谱导出
│   ├── entity_align.py       # 跨馆实体对齐
│   ├── neo4j_sync.py         # Neo4j MERGE 同步
│   └── wikidata_enrich.py    # 作者 Wikidata 补全
│
├── export_kg.py              # 从 CSV 导出 KG
├── sync_neo4j.py             # 同步 output/kg → Neo4j
├── clean_data.py             # 离线 CSV 清洗
├── enrich_wikidata.py        # 作者信息补全入口
├── csv_mysql_sync.py         # csv-sync 薄封装
│
├── output/                   # 产出目录（运行时生成）
│   ├── *.csv                 # 三馆文物 CSV
│   ├── images/               # 本地图片
│   ├── kg/                   # 三元组 / 实体 / 关系
│   └── clean/                # 清洗后 CSV
│
├── _check_mysql.py           # MySQL 连接与行数检测
├── _check_databases.py       # MySQL + Neo4j 联合检测
│
└── 实施报告-海外藏中国文物平台.md
    答辩-增量更新命令文档.md
```

---

## 环境准备

### 1. 安装依赖

```powershell
cd crawler
pip install -r requirements.txt

# MFA 爬虫需要浏览器（仅爬 MFA 时）
playwright install chromium
```

### 2. 配置环境变量

复制并编辑 `museum_crawler/.env`（或 `crawler/.env`）：

```env
# 史密森尼 API Key — https://api.data.gov/signup/
SI_DATA_GOV_API_KEY=你的Key

# 哈佛 API Key
HARVARD_ART_MUSEUMS_API_KEY=你的Key

# MySQL（配置后爬取自动写库）
MYSQL_HOST=47.96.152.190
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=你的密码
MYSQL_DATABASE=overseas_chinese_artifacts
MYSQL_TABLE=artifact

# Neo4j（可选，同步图库时使用）
NEO4J_URI=bolt://47.96.152.190:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=你的密码
```

> 勿将含真实密码的 `.env` 提交至 Git。

---

## 快速开始

### 爬取（答辩演示推荐）

```powershell
cd crawler

# 哈佛 20 条（最稳，约 1～2 分钟）
python museum_spider.py --museums harvard --limit 20 --ensure-mysql-table

# 三馆各 100 条
python museum_spider.py --museums all --limit 100 --ensure-mysql-table

# 只写 CSV，不写 MySQL
python museum_spider.py --museums harvard --limit 20 --no-mysql
```

### 查看帮助

```powershell
python museum_spider.py --help
```

---

## 常用命令

### 数据爬取

| 命令 | 说明 |
|------|------|
| `--museums smithsonian` | 只爬史密森尼 |
| `--museums harvard` | 只爬哈佛 |
| `--museums mfa` | 只爬波士顿 MFA |
| `--museums all` | 三馆一起 |
| `--limit N` | 每馆最多 N 条（`0`=不限） |
| `--si-s3-only` | 史密森尼仅用 S3 开放数据（推荐） |
| `--no-mysql` | 跳过 MySQL 写库 |
| `--no-kg-export` | 跳过知识图谱导出 |
| `--ensure-mysql-table` | 首次部署自动建表 |

```powershell
# 史密森尼 S3 模式
python museum_spider.py --museums smithsonian --limit 50 --si-s3-only

# MFA 多图补全
python museum_spider.py --museums harvard --ham-repair-multi-images --limit 0 --no-mysql
```

### 数据清洗

```powershell
python clean_data.py
python clean_data.py --csv output/harvard_art_museums.csv
python normalize_csv_dates.py --csv output/harvard_art_museums.csv
```

### 作者信息补全（Wikidata）

```powershell
python enrich_wikidata.py --csv output/harvard_art_museums.csv --delay 1.5
python museum_spider.py enrich-wikidata --csv output/harvard_art_museums.csv
```

### CSV ↔ MySQL 同步

```powershell
python museum_spider.py csv-sync import --csv output/harvard_art_museums.csv
python museum_spider.py csv-sync export --csv output/from_db.csv --museum-id 2
```

### 知识图谱导出与 Neo4j 同步

```powershell
python export_kg.py
python sync_neo4j.py --test
python sync_neo4j.py
python sync_neo4j.py --wipe    # 清空后全量导入（慎用）
```

### 健康检查

```powershell
python _check_mysql.py
python _check_databases.py
```

---

## 三馆采集策略

| 博物馆 | museum_id | 策略要点 |
|--------|-----------|----------|
| 史密森尼 | 1 | S3 元数据主扫 + API 补漏；只认 `ids.si.edu` 可下图链 |
| 哈佛 | 2 | REST API（`culture=Chinese\|China`）；IIIF 多图严格入库 |
| MFA 波士顿 | 3 | Playwright 过 AWS WAF；默认有界面浏览器 |

---

## 产出物说明

| 路径 | 内容 |
|------|------|
| `output/smithsonian_institution.csv` | 史密森尼文物 |
| `output/harvard_art_museums.csv` | 哈佛文物 |
| `output/museum_of_fine_arts_boston.csv` | MFA 文物 |
| `output/images/{馆别}/` | 本地图片 |
| `output/kg/artifacts.csv` | 文物实体 |
| `output/kg/relations/*.csv` | 8 类关系三元组 |
| `output/kg/properties/*.csv` | 字面量属性 |
| `output/kg/align/` | 实体对齐表 |
| `crawler.log` | 运行日志 |

**编码：** CSV 统一 **UTF-8-SIG**；MySQL 使用 **utf8mb4**。

---

## 馆别编号

| museum_id | 博物馆 |
|-----------|--------|
| 1 | 史密森尼 Smithsonian |
| 2 | 哈佛 Harvard Art Museums |
| 3 | 波士顿 MFA Boston |

---

## 子系统对接

```
三馆爬虫 → CSV + 图片
         → MySQL artifact 表（7151 条）
         → output/kg/ 三元组（70888 关系）
         → Neo4j 图库（143623 边）
         → backend FastAPI（5 个 GET 接口）
         → Web / App 前端
```

- **Backend API：** [`../backend/README.md`](../backend/README.md)  
- **服务地址：** `http://47.96.152.190:8000`  
- **Neo4j Browser：** `http://47.96.152.190:7474`

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [实施报告-海外藏中国文物平台.md](./实施报告-海外藏中国文物平台.md) | 工程实施与课程对照 |
| [答辩-增量更新命令文档.md](./答辩-增量更新命令文档.md) | 增量爬取演示命令 |
| [../backend/Web组对接文档.md](../backend/Web组对接文档.md) | 前端 API 完整对接说明 |

---

## 常见问题

| 问题 | 处理 |
|------|------|
| 史密森尼 0 条 | 加 `--si-s3-only`；检查 `SI_DATA_GOV_API_KEY` |
| MFA 无链接 | 安装 Playwright；勿用 `--mfa-headless` |
| MySQL 连接失败 | 检查 `.env` 中 `MYSQL_HOST` + `MYSQL_DATABASE` |
| 图片 404（前端） | 配置 backend 的 `HARVARD_IMAGE_DIR` / `IMAGE_BASE_DIR` |
| Neo4j 同步慢 | 使用 `sync_neo4j.py --skip-properties` 先导入关系 |

---

## 一句话总结

在 `crawler/` 目录执行 `python museum_spider.py --museums harvard --limit 20 --ensure-mysql-table`，即可完成爬取、清洗、写库与 KG 导出；前端通过 `backend` 的 REST API 访问数据，不直连数据库。
