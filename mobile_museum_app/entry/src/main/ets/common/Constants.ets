/**
 * 全部数据经 HTTP 访问 server/app.py → Neo4j 知识图谱筛选 + MySQL 详情。
 * App 端不落库、不使用本地 Mock。
 * 登录 token 仅保存在内存（退出 App 后需重新登录）。
 *
 * API_BASE：移动端业务 API（Flask app.py），默认 5000 端口
 * IMAGE_API_BASE：文物图片 API（服务器端/backend/main.py），默认 8000 端口
 */
export class AppConfig {
  static readonly API_BASE: string = 'http://10.4.109.63:5000';
  /** 与 服务器端/backend/Web组对接文档.md 一致，图片须走 8000 而非 5000 */
  static readonly IMAGE_API_BASE: string = 'http://47.96.152.190:8000';
  /** 知识问答子系统 API，见 server/09_联调说明.md */
  static readonly QA_API_BASE: string = 'http://10.4.161.20:8000';
  /** 知识问答子系统 Web 前端（Vite 开发服，联调用） */
  static readonly QA_WEB_URL: string = 'http://10.4.161.20:5173';
  static readonly CONNECT_TIMEOUT: number = 10000;
  static readonly READ_TIMEOUT: number = 20000;
  static readonly QA_READ_TIMEOUT: number = 120000;
  static readonly PAGE_SIZE: number = 50;
  /** 首页列表排除馆别：1=史密森尼 */
  static readonly HOME_EXCLUDE_MUSEUM_IDS: number[] = [1];
}

export class AppColors {
  static readonly PRIMARY: string = '#8B4513';
  static readonly BG: string = '#F5F0E8';
  static readonly CARD: string = '#FFFFFF';
  static readonly TEXT: string = '#2C2416';
  static readonly SUBTEXT: string = '#6B5E4F';
  static readonly ACCENT: string = '#C9A227';
  /** 筛选 Chip 未选中背景 */
  static readonly CHIP_BG: string = '#EDE6D9';
  /** 卡片描边 / 分隔 */
  static readonly BORDER: string = '#E8DFD0';
  /** 浅暖色块（输入框、次级按钮） */
  static readonly SURFACE: string = '#F7F2EA';
  /** 输入框背景 */
  static readonly INPUT_BG: string = '#FFFCF8';
}
