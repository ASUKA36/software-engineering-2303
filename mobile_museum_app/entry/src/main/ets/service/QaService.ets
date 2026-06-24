import { http } from '@kit.NetworkKit';
import { AppConfig } from '../common/Constants';
import { HttpRawResponse, QaAskResult, QaHistoryItem, QaRecoveredAnswer, QaSourceInfo } from '../model/Models';

interface QaHttpHeader {
  'Content-Type': string;
}

interface QaHttpOptions {
  method: http.RequestMethod;
  header: QaHttpHeader;
  extraData?: string;
  connectTimeout: number;
  readTimeout: number;
  expectDataType: http.HttpDataType;
}

interface QaHistoryRow {
  id?: number;
  role?: string;
  content?: string;
  intent?: string;
  entity?: string | null;
  sources?: QaSourceRow[];
  created_at?: string;
}

interface QaSourceRow {
  museum_name?: string;
  detail_url?: string;
  object_id?: string;
  image_url?: string | null;
  accession_number?: string | null;
}

interface QaHistoryJson {
  session_id?: string;
  history?: QaHistoryRow[];
}

interface QaAskJson {
  answer_id?: string;
  question?: string;
  answer?: string;
  not_found?: boolean;
  detail?: string;
  message?: string;
}

interface QaSessionJson {
  session_id?: string;
}

interface QaErrorJson {
  detail?: string;
  message?: string;
}

export class QaService {
  private static online: boolean = false;

  static isOnline(): boolean {
    return QaService.online;
  }

  static async ensureOnline(): Promise<boolean> {
    if (QaService.online) {
      return true;
    }
    try {
      const res = await QaService.requestRaw('GET', '/health', undefined, AppConfig.READ_TIMEOUT);
      QaService.online = res.code === 200;
    } catch (e) {
      QaService.online = false;
    }
    return QaService.online;
  }

  static resetOnlineCheck(): void {
    QaService.online = false;
  }

  static async createSession(): Promise<string | null> {
    const res = await QaService.requestRaw('POST', '/api/qa/session', undefined, AppConfig.READ_TIMEOUT);
    if (res.code !== 201 && res.code !== 200) {
      return null;
    }
    try {
      const parsed = JSON.parse(res.body) as QaSessionJson;
      const sid = parsed.session_id ?? '';
      return sid.length > 0 ? sid : null;
    } catch (e) {
      return null;
    }
  }

  static async deleteSession(sessionId: string): Promise<boolean> {
    if (sessionId.length === 0) {
      return true;
    }
    const res = await QaService.requestRaw(
      'DELETE',
      `/api/qa/session/${encodeURIComponent(sessionId)}`,
      undefined,
      AppConfig.READ_TIMEOUT
    );
    return res.code >= 200 && res.code < 300;
  }

  static async getHistory(sessionId: string): Promise<QaHistoryItem[]> {
    if (sessionId.length === 0) {
      return [];
    }
    const res = await QaService.requestRaw(
      'GET',
      `/api/qa/history/${encodeURIComponent(sessionId)}`,
      undefined,
      AppConfig.READ_TIMEOUT
    );
    if (res.code !== 200 || res.body.length === 0) {
      return [];
    }
    try {
      const parsed = JSON.parse(res.body) as QaHistoryJson;
      return QaService.mapHistory(parsed.history ?? []);
    } catch (e) {
      return [];
    }
  }

  static async ask(question: string, sessionId: string): Promise<QaAskResult> {
    const out = new QaAskResult();
    const q = question.trim();
    if (q.length === 0) {
      out.message = '请输入问题';
      return out;
    }
    if (!await QaService.ensureOnline()) {
      out.message = '无法连接问答服务，请确认与知识问答子系统在同一校园网';
      return out;
    }
    const apiQuestion = QaService.buildApiQuestion(q);
    const body = JSON.stringify({ question: apiQuestion, session_id: sessionId });
    const res = await QaService.requestRaw('POST', '/api/qa/ask', body, AppConfig.QA_READ_TIMEOUT);

    if (res.code >= 200 && res.code < 300) {
      try {
        const parsed = JSON.parse(res.body) as QaAskJson;
        out.success = true;
        out.answer = parsed.answer ?? '';
        out.answerId = parsed.answer_id ?? '';
        out.notFound = parsed.not_found === true;
        if (out.answer.length === 0) {
          out.message = '未收到回答内容';
          out.success = false;
        } else {
          out.isFallback = parsed.not_found === true || QaService.isFallbackAnswer(out.answer);
          out.notFound = out.isFallback;
          if (out.isFallback) {
            out.message = QaService.fallbackHint(out.answer);
          }
        }
        return out;
      } catch (e) {
        out.message = '解析回答失败';
      }
    }

    // 联调环境常见：ask 返回 500，但历史里已写入 user/assistant，改从历史恢复
    const recovered = await QaService.recoverAnswerFromHistory(sessionId, q, apiQuestion);
    if (recovered !== null) {
      out.success = true;
      out.answer = recovered.content;
      out.isFallback = recovered.isFallback;
      out.notFound = recovered.isFallback;
      out.message = recovered.isFallback ? QaService.fallbackHint(recovered.content) : '';
      return out;
    }

    if (res.code === -1) {
      out.message = '请求超时或网络中断，请稍后重试';
      return out;
    }
    out.message = QaService.parseErrorMessage(
      res.body,
      `问答服务异常(HTTP ${res.code})，请联系后端检查 Graph Agent`
    );
    return out;
  }

  /** 为知识图谱检索补充掌上博物馆瓷器专题上下文 */
  static buildApiQuestion(userQuestion: string): string {
    const q = userQuestion.trim();
    if (q.length === 0) {
      return q;
    }
    if (q.includes('瓷器') || q.includes('文物') || q.includes('海外藏')) {
      return q;
    }
    return `关于海外藏中国瓷器：${q}`;
  }

  static isFallbackAnswer(content: string): boolean {
    const text = content.trim();
    if (text.length === 0) {
      return true;
    }
    if (text.includes('未获得有效结论') || text.includes('未检索到有效')) {
      return true;
    }
    return text.includes('抱歉') &&
      (text.includes('未检索到') || text.includes('请稍后') || text.includes('无法回答') ||
        text.includes('未获得'));
  }

  static fallbackHint(answer: string): string {
    const text = answer.trim();
    if (text.length > 0 && QaService.isFallbackAnswer(text)) {
      return text;
    }
    return '知识库暂未命中，请尝试具体文物名称或换种问法';
  }

  private static isSameUserQuestion(historyContent: string, userQ: string, apiQ: string): boolean {
    const stored = historyContent.trim();
    return stored === userQ || stored === apiQ;
  }

  private static findAnswerInHistory(
    history: QaHistoryItem[],
    userQuestion: string,
    apiQuestion: string
  ): QaHistoryItem | null {
    const q = userQuestion.trim();
    const apiQ = apiQuestion.trim();
    for (let i = history.length - 1; i >= 0; i--) {
      const item = history[i];
      if (item.role !== 'user' ||
        !QaService.isSameUserQuestion(item.content, q, apiQ)) {
        continue;
      }
      if (i + 1 < history.length && history[i + 1].role === 'assistant') {
        return history[i + 1];
      }
    }
    return null;
  }

  private static async recoverAnswerFromHistory(
    sessionId: string,
    userQuestion: string,
    apiQuestion: string
  ): Promise<QaRecoveredAnswer | null> {
    for (let attempt = 0; attempt < 4; attempt++) {
      const history = await QaService.getHistory(sessionId);
      const assistant = QaService.findAnswerInHistory(history, userQuestion, apiQuestion);
      if (assistant !== null && assistant.content.trim().length > 0) {
        const recovered = new QaRecoveredAnswer();
        recovered.content = assistant.content;
        recovered.isFallback = QaService.isFallbackAnswer(assistant.content);
        return recovered;
      }
      if (attempt < 3) {
        await QaService.delay(400 * (attempt + 1));
      }
    }
    return null;
  }

  private static delay(ms: number): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  static async submitFeedback(messageId: number, sessionId: string, isHelpful: boolean): Promise<boolean> {
    const body = JSON.stringify({
      message_id: messageId,
      session_id: sessionId,
      is_helpful: isHelpful
    });
    const res = await QaService.requestRaw('POST', '/api/qa/feedback', body, AppConfig.READ_TIMEOUT);
    return res.code >= 200 && res.code < 300;
  }

  private static mapHistory(rows: QaHistoryRow[]): QaHistoryItem[] {
    const items: QaHistoryItem[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const item: QaHistoryItem = {
        id: r.id ?? 0,
        role: r.role ?? '',
        content: r.content ?? '',
        intent: r.intent,
        entity: r.entity ?? undefined,
        createdAt: r.created_at
      };
      if (r.sources !== undefined && r.sources.length > 0) {
        const sources: QaSourceInfo[] = [];
        for (let j = 0; j < r.sources.length; j++) {
          const s = r.sources[j];
          sources.push({
            museumName: s.museum_name ?? '',
            detailUrl: s.detail_url ?? '',
            objectId: s.object_id ?? '',
            imageUrl: s.image_url ?? undefined,
            accessionNumber: s.accession_number ?? undefined
          });
        }
        item.sources = sources;
      }
      items.push(item);
    }
    return items;
  }

  private static parseErrorMessage(body: string, fallback: string): string {
    if (body.length === 0) {
      return fallback;
    }
    try {
      const parsed = JSON.parse(body) as QaErrorJson;
      const detail = parsed.detail;
      if (detail !== undefined && detail.length > 0) {
        return detail;
      }
      const msg = parsed.message;
      if (msg !== undefined && msg.length > 0) {
        return msg;
      }
    } catch (e) {
      // ignore
    }
    return fallback;
  }

  private static async requestRaw(
    method: string,
    path: string,
    body?: string,
    readTimeout: number = AppConfig.READ_TIMEOUT
  ): Promise<HttpRawResponse> {
    const client = http.createHttp();
    const url = `${AppConfig.QA_API_BASE}${path}`;
    let reqMethod = http.RequestMethod.GET;
    if (method === 'POST') {
      reqMethod = http.RequestMethod.POST;
    } else if (method === 'DELETE') {
      reqMethod = http.RequestMethod.DELETE;
    }
    const header: QaHttpHeader = { 'Content-Type': 'application/json' };
    const options: QaHttpOptions = {
      method: reqMethod,
      header: header,
      extraData: body,
      connectTimeout: AppConfig.CONNECT_TIMEOUT,
      readTimeout: readTimeout,
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
