import { AppColors } from '../common/Constants';
import { AppTheme } from '../common/AppTheme';
import { ArtifactItem } from '../model/Models';
import { MuseumService } from '../service/MuseumService';

@Component
export struct ArtifactCard {
  item: ArtifactItem = {
    museumId: 0,
    objectId: '',
    title: '',
    artist: '',
    dynasty: '',
    period: '',
    type: '',
    material: '',
    culture: '',
    description: '',
    dimensions: '',
    museum: '',
    location: '',
    imageUrl: '',
    imagePath: '',
    detailUrl: ''
  };
  onTap?: () => void;
  showSimilarity: boolean = false;

  similarityText(): string {
    if (this.item.similarity === undefined) {
      return '';
    }
    const pct = Math.round(this.item.similarity * 100);
    return `相似度 ${pct}%`;
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(MuseumService.getImageSrc(this.item))
          .width('100%')
          .height(160)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 10, topRight: 10 })
        if (this.showSimilarity && this.item.similarity !== undefined) {
          Text(this.similarityText())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(139, 69, 19, 0.85)')
            .borderRadius({ topRight: 8, bottomRight: 8 })
            .margin({ left: 0, bottom: 6 })
        }
        Row()
          .width('100%')
          .height(3)
          .backgroundColor(AppColors.ACCENT)
          .borderRadius({ bottomLeft: 2, bottomRight: 2 })
      }

      Column({ space: 4 }) {
        Text(this.item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text(`${this.item.dynasty} · ${this.item.type}`)
            .fontSize(12)
            .fontColor(AppColors.SUBTEXT)
        }
        Text(this.item.museum)
          .fontSize(11)
          .fontColor(AppColors.SUBTEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
      .width('100%')
    }
    .backgroundColor(AppColors.CARD)
    .borderRadius(10)
    .border({ width: 1, color: AppColors.BORDER })
    .shadow(AppTheme.cardShadow())
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }
}
