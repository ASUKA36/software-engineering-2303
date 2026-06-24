import { router } from '@kit.ArkUI';
import { AppColors, AppConfig } from '../common/Constants';
import { AppTheme, FilterChip, PageHeader, PaginationBar } from '../common/AppTheme';
import { buildArtifactRouteParams } from '../common/RouteParams';
import { ArtifactCard } from '../components/ArtifactCard';
import { ArtifactItem } from '../model/Models';
import { MuseumService } from '../service/MuseumService';
import { ApiClient } from '../service/ApiClient';

@Component
export struct HomePage {
  @State artifacts: ArtifactItem[] = [];
  @State hotItems: ArtifactItem[] = [];
  @State hotIndex: number = 0;
  @State loading: boolean = true;
  @State hotLoading: boolean = true;
  @State sortType: string = 'period';
  @State dataSource: string = '';
  @State page: number = 1;
  @State total: number = 0;

  aboutToAppear(): void {
    this.refreshAll();
  }

  totalPages(): number {
    if (this.total <= 0) {
      return 1;
    }
    return Math.ceil(this.total / AppConfig.PAGE_SIZE);
  }

  async refreshAll(): Promise<void> {
    this.loading = true;
    this.hotLoading = true;
    await ApiClient.ensureNetwork();
    const res = await MuseumService.getArtifactsPage(
      this.sortType,
      this.page,
      AppConfig.PAGE_SIZE,
      AppConfig.HOME_EXCLUDE_MUSEUM_IDS
    );
    this.artifacts = res.items;
    this.total = res.total;

    let hot = await MuseumService.getHotArtifacts(8);
    if (hot.length === 0 && res.items.length > 0) {
      hot = res.items.slice(0, Math.min(8, res.items.length));
    }
    this.hotItems = hot;
    this.hotIndex = 0;
    this.hotLoading = false;

    if (ApiClient.isOnline()) {
      this.dataSource = this.total > 0 ? `知识图谱·瓷器 · 共${this.total}件` : '已连接·暂无瓷器数据';
    } else {
      this.dataSource = '未连接服务器';
    }
    this.loading = false;
  }

  openDetail(item: ArtifactItem): void {
    router.pushUrl({
      url: 'pages/ArtifactDetailPage',
      params: buildArtifactRouteParams(item.museumId, item.objectId)
    });
  }

  goNextPage(): void {
    if (this.page < this.totalPages()) {
      this.page += 1;
      this.refreshAll();
    }
  }

  goPrevPage(): void {
    if (this.page > 1) {
      this.page -= 1;
      this.refreshAll();
    }
  }

  build() {
    Column() {
      PageHeader({
        title: '瓷器专题',
        subtitle: '知识图谱精选 · 海外藏中国瓷',
        trailing: this.dataSource,
        showQaEntry: true,
        onQaTap: () => {
          router.pushUrl({ url: 'pages/QaWebPage' });
        }
      })

      this.hotCarousel()

      Row({ space: 8 }) {
        FilterChip({
          label: '按热度',
          selected: this.sortType === 'hot',
          onTap: () => {
            this.sortType = 'hot';
            this.page = 1;
            this.refreshAll();
          }
        })
        FilterChip({
          label: '按年代',
          selected: this.sortType === 'period',
          onTap: () => {
            this.sortType = 'period';
            this.page = 1;
            this.refreshAll();
          }
        })
        FilterChip({
          label: '按类型',
          selected: this.sortType === 'type',
          onTap: () => {
            this.sortType = 'type';
            this.page = 1;
            this.refreshAll();
          }
        })
      }
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.loading) {
        LoadingProgress()
          .width(48)
          .height(48)
          .margin({ top: 80 })
      } else if (this.artifacts.length === 0) {
        Column({ space: 8 }) {
          Text('暂无瓷器数据')
            .fontColor(AppColors.SUBTEXT)
          Text('请启动 server/app.py（py38）并检查 API_BASE')
            .fontSize(12)
            .fontColor(AppColors.SUBTEXT)
        }
        .margin({ top: 48 })
        .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            Grid() {
              ForEach(this.artifacts, (item: ArtifactItem) => {
                GridItem() {
                  ArtifactCard({
                    item: item,
                    onTap: () => this.openDetail(item)
                  })
                }
              }, (item: ArtifactItem) => `${item.museumId}_${item.objectId}`)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .padding(16)
            .width('100%')

            this.paginationBar()
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[AppColors.BG, 0], ['#EBE3D6', 1]]
    })
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
      if (isVisible) {
        this.refreshAll();
      }
    })
  }

  @Builder
  hotCarousel() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Text('🔥')
          .fontSize(16)
        Text('热门文物')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      if (this.hotLoading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
        }
        .width('100%')
        .height(168)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(12)
        .border({ width: 1, color: AppColors.BORDER })
        .margin({ left: 16, right: 16 })
      } else if (this.hotItems.length === 0) {
        Column() {
          Text('暂无热门文物')
            .fontSize(13)
            .fontColor(AppColors.SUBTEXT)
        }
        .width('100%')
        .height(168)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(12)
        .border({ width: 1, color: AppColors.BORDER })
        .margin({ left: 16, right: 16 })
      } else {
        Swiper() {
          ForEach(this.hotItems, (item: ArtifactItem, idx: number) => {
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(MuseumService.getImageSrc(item))
                .width('100%')
                .height(168)
                .objectFit(ImageFit.Cover)
                .backgroundColor('#E8E0D5')
              Column({ space: 4 }) {
                Text(item.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row() {
                  Text(`${item.dynasty} · ${item.period}`)
                    .fontSize(11)
                    .fontColor('#EEEEEE')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  if ((item.hotScore ?? item.likeCount ?? 0) > 0) {
                    Text(`🔥 ${item.hotScore ?? item.likeCount}`)
                      .fontSize(11)
                      .fontColor('#FFD700')
                  }
                }
                .width('100%')
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#99000000')
            }
            .width('100%')
            .height(168)
            .borderRadius(12)
            .clip(true)
            .border({ width: 1, color: AppColors.ACCENT })
            .shadow(AppTheme.softShadow())
            .onClick(() => this.openDetail(item))
          }, (item: ArtifactItem, idx: number) => `hot_${idx}_${item.museumId}_${item.objectId}`)
        }
        .width('100%')
        .height(168)
        .padding({ left: 16, right: 16 })
        .index(this.hotIndex)
        .autoPlay(this.hotItems.length > 1)
        .interval(3500)
        .loop(this.hotItems.length > 1)
        .indicator(this.hotItems.length > 1)
        .duration(500)
        .curve(Curve.EaseInOut)
        .onChange((index: number) => {
          this.hotIndex = index;
        })
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  paginationBar() {
    PaginationBar({
      page: this.page,
      totalPages: this.totalPages(),
      onPrev: () => this.goPrevPage(),
      onNext: () => this.goNextPage()
    })
  }
}
