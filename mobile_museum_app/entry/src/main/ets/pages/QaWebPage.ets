import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { AppColors, AppConfig } from '../common/Constants';

@Entry
@Component
struct QaWebPage {
  private controller: webview.WebviewController = new webview.WebviewController();

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
          Text('问答组 Web 前端')
            .fontSize(11)
            .fontColor(AppColors.SUBTEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('刷新')
          .fontSize(12)
          .height(32)
          .padding({ left: 10, right: 10 })
          .backgroundColor(AppColors.SURFACE)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            this.controller.loadUrl(AppConfig.QA_WEB_URL);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Web({ src: AppConfig.QA_WEB_URL, controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .imageAccess(true)
        .onlineImageAccess(true)
        .databaseAccess(true)
        .mixedMode(MixedMode.All)
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }
}
