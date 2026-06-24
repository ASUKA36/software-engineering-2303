import { router, promptAction } from '@kit.ArkUI';
import { AppColors, AppConfig } from '../common/Constants';
import { AppTheme } from '../common/AppTheme';
import { QaHistoryItem } from '../model/Models';
import { QaService } from '../service/QaService';
import { QaSession } from '../store/QaSession';

@Entry
@Component
struct QaChatPage {
  @State messages: QaHistoryItem[] = [];
  @State inputText: string = '';
  @State loading: boolean = true;
  @State asking: boolean = false;
  @State statusHint: string = '';
  @State online: boolean = false;

  aboutToAppear(): void {
    this.initSession();
  }

  async initSession(): Promise<void> {
    this.loading = true;
    QaService.resetOnlineCheck();
    this.online = await QaService.ensureOnline();
    if (!this.online) {
      this.statusHint = `未连接问答服务 · ${AppConfig.QA_API_BASE}`;
      this.loading = false;
      return;
    }
    this.statusHint = '已连接知识问答';
    let sid = QaSession.getSessionId();
    if (sid.length === 0) {
      const created = await QaService.createSession();
      if (created === null) {
        this.statusHint = '创建会话失败';
        this.loading = false;
        return;
      }
      sid = created;
      QaSession.setSessionId(sid);
    }
    this.messages = await QaService.getHistory(sid);
    this.loading = false;
  }

  async startNewChat(): Promise<void> {
    const result = await promptAction.showDialog({
      title: '新对话',
      message: '将清空当前会话记录并开始新对话，确定继续吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: AppColors.PRIMARY }
      ]
    });
    if (result.index !== 1) {
      return;
    }
    this.loading = true;
    const old = QaSession.getSessionId();
    if (old.length > 0) {
      await QaService.deleteSession(old);
    }
    QaSession.clear();
    const created = await QaService.createSession();
    if (created === null) {
      promptAction.showToast({ message: '创建新会话失败' });
      this.loading = false;
      return;
    }
    QaSession.setSessionId(created);
    this.messages = [];
    this.loading = false;
    promptAction.showToast({ message: '已开始新对话' });
  }

  async sendQuestion(): Promise<void> {
    const text = this.inputText.trim();
    if (text.length === 0 || this.asking) {
      return;
    }
    if (!this.online) {
      promptAction.showToast({ message: '问答服务未连接' });
      return;
    }
    const sid = QaSession.getSessionId();
    if (sid.length === 0) {
      promptAction.showToast({ message: '会话未就绪，请稍后重试' });
      return;
    }
    this.asking = true;
    this.inputText = '';
    const result = await QaService.ask(text, sid);
    this.messages = await QaService.getHistory(sid);
    this.asking = false;
    if (!result.success) {
      promptAction.showToast({ message: result.message.length > 0 ? result.message : '提问失败' });
      this.inputText = text;
    }
  }

  async submitFeedback(item: QaHistoryItem, helpful: boolean): Promise<void> {
    const sid = QaSession.getSessionId();
    if (item.id <= 0 || sid.length === 0) {
      return;
    }
    const ok = await QaService.submitFeedback(item.id, sid, helpful);
    promptAction.showToast({ message: ok ? '感谢反馈' : '反馈提交失败' });
  }

  isUser(role: string): boolean {
    return role === 'user';
  }

  isFallbackMessage(content: string): boolean {
    return QaService.isFallbackAnswer(content);
  }

  async askSample(question: string): Promise<void> {
    this.inputText = question;
    await this.sendQuestion();
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Text('← 返回')
          .fontSize(15)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(16)
          .border({ width: 1, color: AppColors.BORDER })
          .onClick(() => router.back())
        Column({ space: 2 }) {
          Text('文物 AI 问答')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
          Text(this.statusHint)
            .fontSize(11)
            .fontColor(AppColors.SUBTEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('新对话')
          .fontSize(12)
          .height(32)
          .padding({ left: 10, right: 10 })
          .backgroundColor(AppColors.SURFACE)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => this.startNewChat())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        LoadingProgress()
          .width(48)
          .height(48)
          .margin({ top: 80 })
      } else if (!this.online) {
        Column({ space: 10 }) {
          Text('无法连接问答服务')
            .fontSize(16)
            .fontColor(AppColors.TEXT)
          Text('请确认：\n1. 知识问答子系统已启动（端口 8000）\n2. 手机与服务器在同一校园网/WiFi\n3. Constants.ets 中 QA_API_BASE 地址正确')
            .fontSize(13)
            .fontColor(AppColors.SUBTEXT)
          Button('重试连接')
            .onClick(() => this.initSession())
        }
        .padding(24)
        .layoutWeight(1)
      } else {
        Scroll() {
          Column({ space: 10 }) {
            if (this.messages.length === 0 && !this.asking) {
              Column({ space: 10 }) {
                Text('💬 向 AI 提问文物相关问题')
                  .fontSize(15)
                  .fontColor(AppColors.TEXT)
                Text('尽量包含朝代、器型或具体文物名称，命中率更高')
                  .fontSize(13)
                  .fontColor(AppColors.SUBTEXT)
                this.sampleQuestionChip('青花瓷有什么特点？')
                this.sampleQuestionChip('宋代官窑瓷器有哪些？')
                this.sampleQuestionChip('明代景德镇瓷器')
              }
              .width('100%')
              .padding(24)
              .alignItems(HorizontalAlign.Center)
            }

            ForEach(this.messages, (m: QaHistoryItem) => {
              this.messageBubble(m)
            }, (m: QaHistoryItem) => `qa_${m.id}_${m.role}`)

            if (this.asking) {
              Row() {
                LoadingProgress()
                  .width(24)
                  .height(24)
                Text('正在思考…')
                  .fontSize(13)
                  .fontColor(AppColors.SUBTEXT)
                  .margin({ left: 8 })
              }
              .padding(12)
              .backgroundColor(AppColors.CARD)
              .borderRadius(12)
              .margin({ left: 16, right: 48 })
            }
          }
          .padding({ top: 8, bottom: 16 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Row({ space: 8 }) {
          TextInput({ placeholder: '输入文物相关问题…', text: this.inputText })
            .layoutWeight(1)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(12)
            .enabled(!this.asking)
            .onChange((v: string) => {
              this.inputText = v;
            })
          Button(this.asking ? '…' : '发送')
            .height(40)
            .padding({ left: 16, right: 16 })
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(Color.White)
            .enabled(!this.asking)
            .onClick(() => this.sendQuestion())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 20 })
        .backgroundColor(AppColors.CARD)
        .border({ width: { top: 1 }, color: AppColors.BORDER })
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[AppColors.BG, 0], ['#EBE3D6', 1]]
    })
  }

  @Builder
  sampleQuestionChip(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(AppColors.PRIMARY)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(16)
      .border({ width: 1, color: AppColors.ACCENT })
      .onClick(() => this.askSample(label))
  }

  @Builder
  messageBubble(m: QaHistoryItem) {
    Column({ space: 6 }) {
      if (!this.isUser(m.role) && this.isFallbackMessage(m.content)) {
        Text('未命中知识库')
          .fontSize(11)
          .fontColor('#B8860B')
          .fontWeight(FontWeight.Medium)
      }

      Text(m.content)
        .fontSize(14)
        .fontColor(this.isUser(m.role) ? Color.White : AppColors.TEXT)
        .width('100%')

      if (!this.isUser(m.role) && this.isFallbackMessage(m.content)) {
        Text('可换具体文物名、朝代+器型重试，或联系问答后端检查 Graph Agent')
          .fontSize(11)
          .fontColor(AppColors.SUBTEXT)
      }

      if (!this.isUser(m.role) && m.sources !== undefined && m.sources.length > 0) {
        Text(`参考来源 ${m.sources.length} 条`)
          .fontSize(11)
          .fontColor(AppColors.SUBTEXT)
      }

      if (!this.isUser(m.role) && m.id > 0 && !this.isFallbackMessage(m.content)) {
        Row({ space: 8 }) {
          Button('有帮助')
            .fontSize(11)
            .height(28)
            .padding({ left: 10, right: 10 })
            .backgroundColor(AppColors.SURFACE)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => this.submitFeedback(m, true))
          Button('不准确')
            .fontSize(11)
            .height(28)
            .padding({ left: 10, right: 10 })
            .backgroundColor('#FCE8E8')
            .fontColor('#C44E4E')
            .onClick(() => this.submitFeedback(m, false))
        }
      }

      if (m.createdAt !== undefined && m.createdAt.length > 0) {
        Text(m.createdAt)
          .fontSize(10)
          .fontColor(this.isUser(m.role) ? '#EEEEEE' : AppColors.SUBTEXT)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .backgroundColor(this.isUser(m.role) ? AppColors.PRIMARY :
      (this.isFallbackMessage(m.content) ? '#FFF8E8' : AppColors.CARD))
    .borderRadius(12)
    .border(this.isUser(m.role) ? { width: 0 } :
      { width: 1, color: this.isFallbackMessage(m.content) ? '#E8D4A8' : AppColors.BORDER })
    .margin({
      left: this.isUser(m.role) ? 48 : 16,
      right: this.isUser(m.role) ? 16 : 48
    })
    .shadow(this.isUser(m.role) ? { radius: 0, color: Color.Transparent, offsetY: 0 } : AppTheme.softShadow())
  }
}
