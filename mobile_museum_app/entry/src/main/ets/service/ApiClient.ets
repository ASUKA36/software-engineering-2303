import { http } from '@kit.NetworkKit';
import { AppConfig } from '../common/Constants';
import { HttpRawResponse, WriteResult } from '../model/Models';
import { UserSession } from '../store/UserSession';
import { ApiEnvelope } from './ApiTypes';

interface BasicHttpHeader {
  'Content-Type': string;
}

interface AuthHttpHeader {
  'Content-Type': string;
  'Authorization': string;
}

interface HttpRequestOptions {
  method: http.RequestMethod;
  header: BasicHttpHeader | AuthHttpHeader;
  extraData?: string;
  connectTimeout: number;
  readTimeout: number;
  expectDataType: http.HttpDataType;
}

export class ApiClient {
  private static serverOnline: boolean = false;

  static isOnline(): boolean {
    return ApiClient.serverOnline;
  }

  static async ensureNetwork(): Promise<void> {
    if (ApiClient.serverOnline) {
      return;
    }
    try {
      const res = await ApiClient.requestRaw('GET', '/api/health', false);
      ApiClient.serverOnline = res.code === 200;
    } catch (e) {
      ApiClient.serverOnline = false;
    }
  }

  /** 从后台回到前台或手动刷新时重新探测 */
  static resetNetworkCheck(): void {
    ApiClient.serverOnline = false;
  }

  static async getJson(path: string, auth: boolean = false): Promise<string | null> {
    await ApiClient.ensureNetwork();
    if (!ApiClient.serverOnline) {
      return null;
    }
    const res = await ApiClient.requestRaw('GET', path, auth);
    if (res.code !== 200) {
      return null;
    }
    return res.body;
  }

  static async postWrite(path: string, payload: string, auth: boolean = false): Promise<HttpRawResponse | null> {
    await ApiClient.ensureNetwork();
    if (!ApiClient.serverOnline) {
      return null;
    }
    return await ApiClient.requestRaw('POST', path, auth, payload);
  }

  static async deleteWrite(path: string, auth: boolean = true): Promise<HttpRawResponse | null> {
    await ApiClient.ensureNetwork();
    if (!ApiClient.serverOnline) {
      return null;
    }
    return await ApiClient.requestRaw('DELETE', path, auth);
  }

  static async putWrite(path: string, payload: string, auth: boolean = true): Promise<HttpRawResponse | null> {
    await ApiClient.ensureNetwork();
    if (!ApiClient.serverOnline) {
      return null;
    }
    return await ApiClient.requestRaw('PUT', path, auth, payload);
  }

  static parseEnvelope(json: string): ApiEnvelope | null {
    if (json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as ApiEnvelope;
    } catch (e) {
      return null;
    }
  }

  static getCode(json: string): number {
    const env = ApiClient.parseEnvelope(json);
    if (env === null || env.code === undefined) {
      return -1;
    }
    return env.code;
  }

  static getMessage(json: string): string {
    const env = ApiClient.parseEnvelope(json);
    if (env === null || env.message === undefined) {
      return '';
    }
    return env.message;
  }

  static parseWriteResult(res: HttpRawResponse | null, offlineMsg: string): WriteResult {
    const out = new WriteResult();
    if (res === null) {
      out.success = false;
      out.message = offlineMsg;
      out.code = -1;
      return out;
    }
    out.code = ApiClient.getCode(res.body);
    out.message = ApiClient.getMessage(res.body);
    if (out.message.length === 0 && out.code === 0) {
      out.message = '操作成功';
    }
    out.success = res.code >= 200 && res.code < 300 && out.code === 0;
    if (!out.success && out.message.length === 0) {
      out.message = `请求失败(HTTP ${res.code})`;
    }
    return out;
  }

  private static buildHeader(auth: boolean): BasicHttpHeader | AuthHttpHeader {
    if (auth && UserSession.getToken().length > 0) {
      const ah: AuthHttpHeader = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${UserSession.getToken()}`
      };
      return ah;
    }
    const bh: BasicHttpHeader = {
      'Content-Type': 'application/json'
    };
    return bh;
  }

  private static async requestRaw(
    method: string,
    path: string,
    auth: boolean,
    body?: string
  ): Promise<HttpRawResponse> {
    const client = http.createHttp();
    const url = `${AppConfig.API_BASE}${path}`;
    const headerObj = ApiClient.buildHeader(auth);
    let reqMethod = http.RequestMethod.GET;
    if (method === 'POST') {
      reqMethod = http.RequestMethod.POST;
    } else if (method === 'DELETE') {
      reqMethod = http.RequestMethod.DELETE;
    } else if (method === 'PUT') {
      reqMethod = http.RequestMethod.PUT;
    }
    const options: HttpRequestOptions = {
      method: reqMethod,
      header: headerObj,
      extraData: body,
      connectTimeout: AppConfig.CONNECT_TIMEOUT,
      readTimeout: AppConfig.READ_TIMEOUT,
      expectDataType: http.HttpDataType.STRING
    };
    try {
      const resp = await client.request(url, options);
      const result = (resp.result as string) ?? '';
      client.destroy();
      return new HttpRawResponse(resp.responseCode, result);
    } catch (e) {
      client.destroy();
      return new HttpRawResponse(-1, '');
    }
  }
}
