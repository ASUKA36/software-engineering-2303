-- 文物热度字段：hot_score = 点赞数 + 收藏数（由 server/app.py 自动维护）
ALTER TABLE artifact
  ADD COLUMN hot_score INT NOT NULL DEFAULT 0 COMMENT '热度=点赞数+收藏数'
  AFTER image_count;

-- 首次迁移后回填（也可由服务端启动时自动执行）
UPDATE artifact a
LEFT JOIN (
  SELECT museum_id, object_id, COUNT(*) AS cnt
  FROM user_like GROUP BY museum_id, object_id
) l ON a.museum_id = l.museum_id AND a.object_id = l.object_id
LEFT JOIN (
  SELECT museum_id, object_id, COUNT(*) AS cnt
  FROM user_favorite GROUP BY museum_id, object_id
) f ON a.museum_id = f.museum_id AND a.object_id = f.object_id
SET a.hot_score = COALESCE(l.cnt, 0) + COALESCE(f.cnt, 0);
