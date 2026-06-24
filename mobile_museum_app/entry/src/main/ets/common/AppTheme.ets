import { AppColors } from './Constants';

/** 全局 UI 点缀：装饰线、Chip、分页、登录头图等 */
export class AppTheme {
  static cardShadow(): ShadowOptions {
    return { radius: 10, color: '#18000000', offsetX: 0, offsetY: 3 };
  }

  static softShadow(): ShadowOptions {
    return { radius: 6, color: '#12000000', offsetX: 0, offsetY: 2 };
  }

  static primaryBtnShadow(): ShadowOptions {
    return { radius: 8, color: '#408B4513', offsetX: 0, offsetY: 3 };
  }
}

@Component
export struct OrnamentLine {
  build() {
    Row() {
      Divider()
        .vertical(false)
        .width(32)
        .strokeWidth(2)
        .color(AppColors.ACCENT)
      Text('◆')
        .fontSize(7)
        .fontColor(AppColors.ACCENT)
        .margin({ left: 6, right: 6 })
      Divider()
        .vertical(false)
        .layoutWeight(1)
        .strokeWidth(1)
        .color(AppColors.BORDER)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}

@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop trailing: string = '';
  @Prop showQaEntry: boolean = false;
  onQaTap?: () => void;

  build() {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
          if (this.subtitle.length > 0) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor(AppColors.SUBTEXT)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 6 }) {
          if (this.showQaEntry) {
            Button('AI问答')
              .fontSize(11)
              .height(30)
              .padding({ left: 10, right: 10 })
              .backgroundColor(AppColors.PRIMARY)
              .fontColor(Color.White)
              .borderRadius(14)
              .shadow(AppTheme.primaryBtnShadow())
              .onClick(() => {
                if (this.onQaTap) {
                  this.onQaTap();
                }
              })
          }
          if (this.trailing.length > 0) {
            Text(this.trailing)
              .fontSize(10)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.SURFACE)
              .border({ width: 1, color: AppColors.ACCENT })
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(12)
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      OrnamentLine()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 6 })
  }
}

@Component
export struct FilterChip {
  @Prop label: string = '';
  @Prop selected: boolean = false;
  onTap?: () => void;

  build() {
    Text(this.label)
      .fontSize(12)
      .fontColor(this.selected ? Color.White : AppColors.TEXT)
      .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Normal)
      .backgroundColor(this.selected ? AppColors.PRIMARY : AppColors.CHIP_BG)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .borderRadius(18)
      .border({
        width: 1,
        color: this.selected ? AppColors.PRIMARY : AppColors.BORDER
      })
      .shadow(this.selected ? AppTheme.primaryBtnShadow() : { radius: 0, color: Color.Transparent, offsetY: 0 })
      .onClick(() => {
        if (this.onTap) {
          this.onTap();
        }
      })
  }
}

@Component
export struct PaginationBar {
  @Prop page: number = 1;
  @Prop totalPages: number = 1;
  onPrev?: () => void;
  onNext?: () => void;

  build() {
    Row({ space: 12 }) {
      Text('◀ 上一页')
        .fontSize(13)
        .fontColor(this.page > 1 ? AppColors.PRIMARY : AppColors.SUBTEXT)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(20)
        .border({ width: 1, color: this.page > 1 ? AppColors.ACCENT : AppColors.BORDER })
        .opacity(this.page > 1 ? 1 : 0.5)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.page > 1 && this.onPrev) {
            this.onPrev();
          }
        })

      Column({ space: 2 }) {
        Text(`${this.page}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
        Text(`共 ${this.totalPages} 页`)
          .fontSize(10)
          .fontColor(AppColors.SUBTEXT)
      }

      Text('下一页 ▶')
        .fontSize(13)
        .fontColor(this.page < this.totalPages ? AppColors.PRIMARY : AppColors.SUBTEXT)
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(20)
        .border({ width: 1, color: this.page < this.totalPages ? AppColors.ACCENT : AppColors.BORDER })
        .opacity(this.page < this.totalPages ? 1 : 0.5)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.page < this.totalPages && this.onNext) {
            this.onNext();
          }
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 24 })
  }
}

@Component
export struct AuthHero {
  @Prop title: string = '登录';
  @Prop emoji: string = '🏺';

  build() {
    Column({ space: 10 }) {
      Text(this.emoji)
        .fontSize(44)
      Text(this.title)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
      Text('海外藏中国瓷器 · 掌上博物馆')
        .fontSize(12)
        .fontColor(AppColors.SUBTEXT)
      OrnamentLine()
    }
    .width('88%')
    .padding({ top: 20, bottom: 16, left: 20, right: 20 })
    .margin({ top: 36, bottom: 20 })
    .backgroundColor(AppColors.CARD)
    .borderRadius(16)
    .border({ width: 1, color: AppColors.BORDER })
    .shadow(AppTheme.cardShadow())
  }
}

@Component
export struct SectionTitle {
  @Prop title: string = '';
  @Prop icon: string = '';

  build() {
    Row({ space: 8 }) {
      if (this.icon.length > 0) {
        Text(this.icon)
          .fontSize(16)
      }
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.PRIMARY)
      Blank()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 4 })
  }
}
