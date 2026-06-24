import { UserInfo } from '../model/Models';

/**
 * 登录态仅保存在内存，用于本次运行期间携带 token 请求服务器。
 * 不写入本地 Preferences；退出 App 后需重新登录。
 */
export class UserSession {
  static readonly PROFILE_REFRESH_KEY: string = 'profileRefreshKey';
  private static token: string = '';
  private static user: UserInfo | null = null;

  static async init(): Promise<void> {
    AppStorage.setOrCreate(UserSession.PROFILE_REFRESH_KEY, 0);
  }

  static isLoggedIn(): boolean {
    return UserSession.token.length > 0 && UserSession.user !== null;
  }

  static getToken(): string {
    return UserSession.token;
  }

  static getUser(): UserInfo | null {
    return UserSession.user;
  }

  static saveLogin(token: string, user: UserInfo): void {
    UserSession.token = token;
    UserSession.user = user;
  }

  static bumpProfileRefresh(): void {
    const cur = AppStorage.get<number>(UserSession.PROFILE_REFRESH_KEY) ?? 0;
    AppStorage.set(UserSession.PROFILE_REFRESH_KEY, cur + 1);
  }

  static logout(): void {
    UserSession.token = '';
    UserSession.user = null;
  }
}
