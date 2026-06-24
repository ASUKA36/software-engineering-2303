/** 问答会话 ID（本次运行期间保持，新对话时重置） */
export class QaSession {
  private static sessionId: string = '';

  static getSessionId(): string {
    return QaSession.sessionId;
  }

  static setSessionId(id: string): void {
    QaSession.sessionId = id;
  }

  static clear(): void {
    QaSession.sessionId = '';
  }
}
