import { AppColors } from '../common/Constants';
import { UserInfo } from '../model/Models';

/** 个人页顶部：账号信息与待审核提醒 */
@Component
export struct ProfileAccountPanel {
  user: UserInfo = { userId: 0, username: '', nickname: '' };
  pendingComments: number = 0;
  pendingPhotos: number = 0;
  onPendingTap?: () => void;

  private accountLine(): string {
    const parts: string[] = [];
    if (this.user.username.length > 0) {
      parts.push(`账号 ${this.user.username}`);
    }
    if (this.user.email !== undefined && this.user.email.length > 0) {
      parts.push(this.user.email);
    } else if (this.user.phone !== undefined && this.user.phone.length > 0) {
      parts.push(this.user.phone);
    }
    return parts.join(' · ');
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Column() {
          Text('🏺')
            .fontSize(22)
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(22)

        Column({ space: 4 }) {
          Text(this.user.nickname.length > 0 ? this.user.nickname : this.user.username)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
          if (this.accountLine().length > 0) {
            Text(this.accountLine())
              .fontSize(12)
              .fontColor(AppColors.SUBTEXT)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      if (this.pendingComments > 0 || this.pendingPhotos > 0) {
        Row({ space: 8 }) {
          Text('⏳')
            .fontSize(14)
          Column({ space: 2 }) {
            Text('待审核内容')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#8B6914')
            Text(this.pendingSummary())
              .fontSize(12)
              .fontColor(AppColors.SUBTEXT)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('查看 ›')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF8E8')
        .borderRadius(10)
        .border({ width: 1, color: '#E8D4A8' })
        .onClick(() => {
          if (this.onPendingTap) {
            this.onPendingTap();
          }
        })
      } else {
        Row({ space: 8 }) {
          Text('✓')
            .fontSize(14)
            .fontColor('#2E7D32')
          Text('暂无待审核的评论或图片')
            .fontSize(12)
            .fontColor(AppColors.SUBTEXT)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }
    }
    .width('100%')
  }

  private pendingSummary(): string {
    const parts: string[] = [];
    if (this.pendingComments > 0) {
      parts.push(`${this.pendingComments} 条评论`);
    }
    if (this.pendingPhotos > 0) {
      parts.push(`${this.pendingPhotos} 张图片`);
    }
    return parts.join('、') + ' 等待审核';
  }
}
