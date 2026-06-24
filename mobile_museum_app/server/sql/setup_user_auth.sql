-- 在 MySQL（47.96.152.190）上执行，启用 App 注册/登录/互动功能
USE overseas_chinese_artifacts;

-- 1. 若 user 表不存在，先建表（完整语句见项目根目录 数据库字段与连接.md）
-- CREATE TABLE IF NOT EXISTS `user` ( ... );

-- 2. 给 remote_user 授予用户相关表权限（root 登录后执行）
GRANT SELECT, INSERT, UPDATE, DELETE ON overseas_chinese_artifacts.`user` TO 'remote_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON overseas_chinese_artifacts.user_like TO 'remote_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON overseas_chinese_artifacts.user_favorite TO 'remote_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON overseas_chinese_artifacts.`comment` TO 'remote_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON overseas_chinese_artifacts.user_upload_photo TO 'remote_user'@'%';
FLUSH PRIVILEGES;
