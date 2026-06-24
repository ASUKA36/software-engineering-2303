-- 评论回复：为 comment 表增加 parent_id（回复目标评论 ID，NULL 表示顶级评论）
-- 若列已存在可跳过

ALTER TABLE comment
  ADD COLUMN parent_id BIGINT UNSIGNED NULL DEFAULT NULL
    COMMENT '回复的评论ID，NULL为顶级评论'
    AFTER object_id;

ALTER TABLE comment ADD KEY idx_parent (parent_id);
