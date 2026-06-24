import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AppColors } from '../common/Constants';
import { AppTheme, AuthHero } from '../common/AppTheme';
import { MuseumService } from '../service/MuseumService';
import { UserSession } from '../store/UserSession';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State email: string = '';
  @State phone: string = '';
  @State submitting: boolean = false;

  async doRegister(): Promise<void> {
    if (this.submitting) {
      return;
    }
    if (this.username.trim().length === 0 || this.password.length < 6) {
      promptAction.showToast({ message: '请填写用户名和至少6位密码' });
      return;
    }
    if (this.email.trim().length === 0 && this.phone.trim().length === 0) {
      promptAction.showToast({ message: '请填写邮箱或手机号' });
      return;
    }
    this.submitting = true;
    const ar = await MuseumService.register(
      this.username.trim(),
      this.password,
      this.email.trim(),
      this.phone.trim()
    );
    this.submitting = false;
    if (ar.login === null) {
      promptAction.showToast({ message: ar.errorMessage.length > 0 ? ar.errorMessage : '注册失败' });
      return;
    }
    UserSession.saveLogin(ar.login.token, ar.login.user);
    promptAction.showToast({ message: '注册成功' });
    router.back();
    router.back();
  }

  build() {
    Column({ space: 12 }) {
      AuthHero({ title: '创建账号', emoji: '✨' })

      TextInput({ placeholder: '用户名', text: this.username })
        .onChange((v: string) => {
          this.username = v;
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

      TextInput({ placeholder: '邮箱', text: this.email })
        .onChange((v: string) => {
          this.email = v;
        })
        .width('85%')
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(12)
        .border({ width: 1, color: AppColors.BORDER })

      TextInput({ placeholder: '手机号', text: this.phone })
        .onChange((v: string) => {
          this.phone = v;
        })
        .width('85%')
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(12)
        .border({ width: 1, color: AppColors.BORDER })

      Text('邮箱与手机号至少填一项')
        .fontSize(12)
        .fontColor(AppColors.SUBTEXT)

      Button(this.submitting ? '注册中…' : '✦ 注册')
        .width('85%')
        .height(44)
        .borderRadius(22)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(AppColors.PRIMARY)
        .shadow(AppTheme.primaryBtnShadow())
        .enabled(!this.submitting)
        .onClick(() => this.doRegister())

      Text('← 返回登录')
        .fontColor(AppColors.SUBTEXT)
        .onClick(() => router.back())
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[AppColors.BG, 0], ['#E8DFD0', 1]]
    })
    .alignItems(HorizontalAlign.Center)
  }
}
