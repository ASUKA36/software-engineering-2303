# crawler/data/output

本目录存放三馆爬虫产出数据（CSV、知识图谱中间文件、清洗结果）。

## 目录说明

| 路径 | 内容 |
|------|------|
| `*.csv` | 三馆文物主表（史密森尼、哈佛、MFA） |
| `clean/` | 清洗与质检后的 CSV |
| `kg/` | 知识图谱实体、关系、属性三元组 |
| `images/` | 本地图片（**未纳入 Git**，见下） |

## 关于 images/

`images/` 目录约 **40GB**、1.2 万+ 文件，超过 GitHub 单文件 100MB 与仓库体积限制，**未上传至本仓库**。

图片已部署在服务器本地，通过 Backend API `/api/img/{museum_id}/{object_id}` 访问。  
重新生成图片：在 `crawler/` 目录运行 `python museum_spider.py --museums all --limit 0`（默认写入本目录）。

脚本默认产出目录会优先解析为本路径（`museum_crawler.config.OUTPUT_DIR`）。不需要再手动指定 `--out-dir data/output`。

## 数据规模（2026-06）

- MySQL 文物记录：7151 条
- KG 关系 CSV：约 70888 条
- 三馆：史密森尼 / 哈佛 / MFA 波士顿
