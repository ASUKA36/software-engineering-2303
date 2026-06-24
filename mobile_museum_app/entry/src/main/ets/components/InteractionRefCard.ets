import { AppColors } from '../common/Constants';
import { AppTheme } from '../common/AppTheme';
import { UserArtifactRef } from '../model/Models';
import { MuseumService } from '../service/MuseumService';

@Component
export struct InteractionRefCard {
  ref: UserArtifactRef = {
    museumId: 0,
    objectId: '',
    title: '',
    dynasty: '',
    type: '',
    imageUrl: '',
    imagePath: ''
  };
  badge: string = '';
  badgeColor: string = AppColors.PRIMARY;
  showGroupButton: boolean = false;
  onTap?: () => void;
  onGroupTap?: () => void;

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(MuseumService.getRefImageSrc(this.ref))
          .width('100%')
          .height(140)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#EDE6D9')
          .borderRadius({ topLeft: 10, topRight: 10 })

        if (this.badge.length > 0) {
          Text(this.badge)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor(this.badgeColor)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
            .margin({ top: 8, right: 8 })
        }
      }
      .onClick(() => {
        if (this.onTap) {
          this.onTap();
        }
      })

      Column({ space: 4 }) {
        Text(this.ref.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.ref.dynasty} · ${this.ref.type}`)
          .fontSize(11)
          .fontColor(AppColors.SUBTEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.showGroupButton) {
          Row() {
            Blank()
            Text('设置分组')
              .fontSize(11)
              .fontColor(AppColors.PRIMARY)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#F7F2EA')
              .borderRadius(12)
              .onClick(() => {
                if (this.onGroupTap) {
                  this.onGroupTap();
                }
              })
          }
          .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
      .width('100%')
    }
    .width('100%')
    .backgroundColor(AppColors.CARD)
    .borderRadius(10)
    .border({ width: 1, color: AppColors.BORDER })
    .shadow(AppTheme.cardShadow())
  }
}
