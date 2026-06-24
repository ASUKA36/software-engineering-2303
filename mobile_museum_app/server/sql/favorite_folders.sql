-- 收藏分组：在 MySQL 执行一次即可
USE overseas_chinese_artifacts;

CREATE TABLE IF NOT EXISTS `user_favorite_folder` (
  `folder_id`   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '收藏夹ID',
  `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `name`        VARCHAR(50)     NOT NULL COMMENT '收藏夹名称',
  `sort_order`  INT             NOT NULL DEFAULT 0 COMMENT '排序',
  `created_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`folder_id`),
  KEY `idx_user` (`user_id`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='用户收藏分组';

-- 若列已存在会报错，可忽略
ALTER TABLE `user_favorite`
  ADD COLUMN `folder_id` BIGINT UNSIGNED NULL COMMENT '所属收藏夹，NULL=默认' AFTER `object_id`;
