# 掌上博物馆（HarmonyOS + Neo4j + MySQL）

基于 `app要求.md`：**从知识图谱选取瓷器专题**，MySQL 提供详情；实现文物列表/详情、搜索、登录注册、点赞收藏、评论（审核后展示）、用户上传照片。

## 目录结构

```
mobile_museum/
├── entry/                 # HarmonyOS ArkTS 客户端（DevEco Studio）
├── server/                # Python Flask REST API → Neo4j 筛选 + MySQL 详情
├── app要求.md
└── 数据库字段与连接.md
```

## 一、在 DevEco Studio 模拟器运行 App

1. 用 **DevEco Studio** 打开本项目根目录 `mobile_museum`。
2. 连接 **本地模拟器**（Phone），点击 Run。
3. **必须能访问 API**：App 仅通过 HTTP 读写服务器；连不上时列表为空并提示「未连接服务器」。登录 token 仅存内存，退出 App 后需重新登录。

### 连接 Neo4j + MySQL

1. 使用 conda **py38** 环境，进入 `server` 目录：

```bash
conda activate py38
pip install -r requirements.txt
python app.py
```

Windows 也可直接：`C:\anaconda\envs\py38\python.exe app.py`

2. 确认能访问 Neo4j（`服务器端/数据库和知识图谱连接方法.md`）与 MySQL（`server/config.py`）。
3. 修改 `entry/src/main/ets/common/Constants.ets` 中 `API_BASE`：
   - 模拟器访问电脑本机 API：改为电脑局域网 IP，例如 `http://192.168.1.100:5000`（不要用 localhost）。
   - 若 API 部署在 `47.96.152.190`：`http://47.96.152.190:5000`
4. 重新编译运行；首页显示「知识图谱·瓷器」表示已连上 API 并加载瓷器专题。

## 二、API 接口一览

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/health | 含 MySQL / Neo4j 状态 |
| GET | /api/theme | 当前专题（瓷器）信息 |
| GET | /api/artifacts | artifact（Neo4j 筛选瓷器 + MySQL 详情） |
| POST | /api/auth/register | **user** |
| POST | /api/auth/login | 更新 user.last_login_at |
| POST/DELETE | /api/artifacts/.../like | **user_like** |
| POST/DELETE | /api/artifacts/.../favorite | **user_favorite** |
| POST | /api/artifacts/.../comments | **comment**（audit_status=0） |
| DELETE | /api/user/comments/{id} | 用户删除自己的评论（status=0） |
| POST | /api/user/photos | **user_upload_photo**（status=0） |

请求头：`Authorization: Bearer <token>`

## 三、已实现 vs 未实现（库表缺口）

| 已实现 | 未实现（需扩展表或外部系统） |
|--------|------------------------------|
| 瓷器专题列表、按热度/年代/类型排序 | — |
| 详情、本地图加载、捏合缩放、多图 Swiper 切换 | 馆方音视频 |
| 关键字/朝代搜索（支持可选朝代列表点击）、按类型分组 | 语音导览、语音问答 |
| 手机/邮箱注册、密码登录 | 华为账号登录、隐私设置、浏览历史 |
| 点赞、收藏（支持分组收藏夹） | 浏览历史 |
| 评论提交、已审核展示、回复他人评论、用户删除自己的评论 | 评论点赞 |
| 上传照片（说明+地点+可选关联文物） | 选做：用户讲解/视频、用户动态 |

## 四、审核说明

- 评论、用户上传图片提交时，使用 **共用 MySQL + `content-review-handoff` 审核引擎**（与后台管理子系统 5 同库同算法，见 `content-review-handoff/README.md`）。
- 评论：低风险自动通过（`audit_status=1`）；中风险待审（`audit_status=0`）；高风险拒绝且**不入库**。
- 图片：一律 `status=0` 待人工审核，写入 `audit_method`、`auto_audit_score` 等字段供后台参考。
- 引擎不可用或 `CONTENT_REVIEW_ENABLED=false` 时，评论/图片回退为本地待审。
- 环境变量（`server/config.py`）：`CONTENT_REVIEW_ENABLED`、`PUBLIC_API_BASE`（上传图完整 URL 前缀，供图片风险评分）。
- 课设演示仍可在 MySQL 中手动通过：

```sql
UPDATE comment SET audit_status=1 WHERE comment_id=?;
UPDATE user_upload_photo SET status=1 WHERE photo_id=?;
```
