import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AppColors } from '../common/Constants';
import { AppTheme, AuthHero } from '../common/AppTheme';
import { MuseumService } from '../service/MuseumService';
import { UserSession } from '../store/UserSession';

@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  @State submitting: boolean = false;

  async doLogin(): Promise<void> {
    if (this.submitting) {
      return;
    }
    if (this.account.trim().length === 0 || this.password.length === 0) {
      promptAction.showToast({ message: '请输入账号和密码' });
      return;
    }
    this.submitting = true;
    const ar = await MuseumService.login(this.account.trim(), this.password);
    this.submitting = false;
    if (ar.login === null) {
      promptAction.showToast({ message: ar.errorMessage.length > 0 ? ar.errorMessage : '登录失败' });
      return;
    }
    UserSession.saveLogin(ar.login.token, ar.login.user);
    promptAction.showToast({ message: '登录成功' });
    router.back();
  }

  build() {
    Column({ space: 14 }) {
      AuthHero({ title: '欢迎回来', emoji: '🏺' })

      TextInput({ placeholder: '用户名 / 邮箱 / 手机号', text: this.account })
        .onChange((v: string) => {
          this.account = v;
        })
        .width('85%')
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(12)
        .border({ width: 1, color: AppColors.BORDER })

      TextInput({ placeholder: '密码（至少6位）', text: this.password })
        .type(InputType.Password)
        .onChange((v: string) => {
          this.password = v;
        })
        .width('85%')
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(12)
        .border({ width: 1, color: AppColors.BORDER })

      Button(this.submitting ? '登录中…' : '✦ 登录')
        .width('85%')
        .height(44)
        .borderRadius(22)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(AppColors.PRIMARY)
        .shadow(AppTheme.primaryBtnShadow())
        .enabled(!this.submitting)
        .onClick(() => this.doLogin())

      Text('没有账号？去注册 →')
        .fontSize(14)
        .fontColor(AppColors.PRIMARY)
        .onClick(() => router.pushUrl({ url: 'pages/RegisterPage' }))

      Text('← 返回')
        .fontSize(14)
        .fontColor(AppColors.SUBTEXT)
        .margin({ top: 16 })
        .onClick(() => router.back())
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[AppColors.BG, 0], ['#E8DFD0', 1]]
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }
}
