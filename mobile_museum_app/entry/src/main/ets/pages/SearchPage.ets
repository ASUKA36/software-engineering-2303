import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppColors, AppConfig } from '../common/Constants';
import { AppTheme, FilterChip, PageHeader, PaginationBar } from '../common/AppTheme';
import { buildArtifactRouteParams } from '../common/RouteParams';
import { ImagePickerUtil } from '../common/ImagePickerUtil';
import { ArtifactCard } from '../components/ArtifactCard';
import { ArtifactItem, MuseumOption } from '../model/Models';
import { MuseumService } from '../service/MuseumService';
import { SpeechSearchService } from '../service/SpeechSearchService';

@Component
export struct SearchPage {
  @State keyword: string = '';
  @State dynasties: string[] = [];
  @State selectedDynasties: string[] = [];
  @State museums: MuseumOption[] = [];
  @State selectedMuseumIds: number[] = [];
  @State flatItems: ArtifactItem[] = [];
  @State searched: boolean = false;
  @State loading: boolean = false;
  @State page: number = 1;
  @State total: number = 0;
  @State voiceListening: boolean = false;
  @State voiceHint: string = '';
  @State imageSearchMode: boolean = false;
  @State queryImageBase64: string = '';

  aboutToAppear(): void {
    MuseumService.getDynasties().then((list: string[]) => {
      this.dynasties = list;
    });
    MuseumService.getMuseums().then((list: MuseumOption[]) => {
      this.museums = list;
    });
  }

  aboutToDisappear(): void {
    SpeechSearchService.stopListen();
  }

  toggleDynasty(d: string): void {
    const idx = this.selectedDynasties.indexOf(d);
    if (idx >= 0) {
      this.selectedDynasties.splice(idx, 1);
    } else {
      this.selectedDynasties.push(d);
    }
    this.doSearch();
  }

  toggleMuseum(museumId: number): void {
    const idx = this.selectedMuseumIds.indexOf(museumId);
    if (idx >= 0) {
      this.selectedMuseumIds.splice(idx, 1);
    } else {
      this.selectedMuseumIds.push(museumId);
    }
    this.doSearch();
  }

  totalPages(): number {
    if (this.total <= 0) {
      return 1;
    }
    return Math.ceil(this.total / AppConfig.PAGE_SIZE);
  }

  async doSearch(resetPage: boolean = true): Promise<void> {
    if (this.imageSearchMode) {
      await this.doImageSearch(resetPage);
      return;
    }
    if (!this.keyword && this.selectedDynasties.length === 0 &&
      this.selectedMuseumIds.length === 0) {
      return;
    }
    if (resetPage) {
      this.page = 1;
    }
    this.loading = true;
    const res = await MuseumService.search(
      this.keyword,
      this.selectedDynasties,
      [],
      this.selectedMuseumIds,
      this.page,
      AppConfig.PAGE_SIZE
    );
    this.flatItems = res.items;
    this.total = res.total;
    this.searched = true;
    this.loading = false;
  }

  async doImageSearch(resetPage: boolean = true): Promise<void> {
    if (this.queryImageBase64.length === 0) {
      promptAction.showToast({ message: '请先从相册选择图片' });
      return;
    }
    if (resetPage) {
      this.page = 1;
    }
    this.loading = true;
    const res = await MuseumService.searchByImage(
      this.queryImageBase64,
      this.selectedDynasties,
      this.selectedMuseumIds,
      this.page,
      AppConfig.PAGE_SIZE
    );
    this.flatItems = res.items;
    this.total = res.total;
    this.searched = true;
    this.loading = false;
    if (res.errorMessage.length > 0) {
      promptAction.showToast({ message: res.errorMessage });
    }
  }

  async pickImageFromAlbum(): Promise<void> {
    const b64 = await ImagePickerUtil.pickImageBase64();
    if (b64.length === 0) {
      return;
    }
    this.imageSearchMode = true;
    this.queryImageBase64 = b64;
    this.keyword = '';
    await this.doImageSearch();
  }

  clearImageSearch(): void {
    this.imageSearchMode = false;
    this.queryImageBase64 = '';
    this.flatItems = [];
    this.searched = false;
    this.total = 0;
    this.page = 1;
  }

  goNextPage(): void {
    if (this.page < this.totalPages()) {
      this.page += 1;
      this.doSearch(false);
    }
  }

  goPrevPage(): void {
    if (this.page > 1) {
      this.page -= 1;
      this.doSearch(false);
    }
  }

  async toggleVoiceSearch(): Promise<void> {
    if (this.voiceListening) {
      await SpeechSearchService.stopListen();
      this.voiceListening = false;
      this.voiceHint = '';
      return;
    }
    const ctx = getContext(this) as common.UIAbilityContext;
    const granted = await SpeechSearchService.ensureMicPermission(ctx);
    if (!granted) {
      promptAction.showToast({ message: '需要麦克风权限才能语音搜索' });
      return;
    }
    this.voiceListening = true;
    this.voiceHint = '请说出文物名称或关键字…';
    const started = await SpeechSearchService.startListen((text: string, isFinal: boolean) => {
      if (text.length > 0) {
        this.keyword = text;
        this.voiceHint = `识别：${text}`;
      }
      if (isFinal) {
        this.voiceListening = false;
        if (text.length > 0) {
          this.doSearch();
        } else {
          promptAction.showToast({ message: '未识别到有效内容' });
        }
      }
    });
    if (!started) {
      this.voiceListening = false;
      this.voiceHint = '';
      promptAction.showToast({ message: '语音识别不可用，请检查系统语音能力' });
    }
  }

  openDetail(item: ArtifactItem): void {
    router.pushUrl({
      url: 'pages/ArtifactDetailPage',
      params: buildArtifactRouteParams(item.museumId, item.objectId)
    });
  }

  build() {
    Column() {
      PageHeader({
        title: '瓷器搜索',
        subtitle: this.imageSearchMode ? '以图搜图 · 相似度排序' : '名称 · 朝代 · 博物馆',
        showQaEntry: true,
        onQaTap: () => {
          router.pushUrl({ url: 'pages/QaWebPage' });
        }
      })

      Row({ space: 8 }) {
        Text('🔎')
          .fontSize(18)
        TextInput({ placeholder: '名称 / 关键字', text: this.keyword })
          .layoutWeight(1)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(12)
          .onChange((v: string) => {
            this.keyword = v;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
      .backgroundColor(AppColors.CARD)
      .borderRadius(14)
      .border({ width: 1, color: AppColors.BORDER })
      .shadow(AppTheme.softShadow())
      .margin({ left: 16, right: 16, bottom: 10 })

      if (this.dynasties.length > 0) {
        Text('朝代（多选）')
          .fontSize(12)
          .fontColor(AppColors.SUBTEXT)
          .padding({ left: 16, bottom: 4 })
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.dynasties, (d: string) => {
              FilterChip({
                label: d,
                selected: this.selectedDynasties.indexOf(d) >= 0,
                onTap: () => this.toggleDynasty(d)
              })
            }, (d: string) => d)
          }
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Horizontal)
      }

      if (this.museums.length > 0) {
        Text('博物馆（多选）')
          .fontSize(12)
          .fontColor(AppColors.SUBTEXT)
          .padding({ left: 16, bottom: 4 })
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.museums, (m: MuseumOption) => {
              FilterChip({
                label: `${m.name}（${m.count}）`,
                selected: this.selectedMuseumIds.indexOf(m.museumId) >= 0,
                onTap: () => this.toggleMuseum(m.museumId)
              })
            }, (m: MuseumOption) => `m_${m.museumId}`)
          }
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Horizontal)
      }

      Row({ space: 12 }) {
        Button('🔍 搜索')
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(AppColors.PRIMARY)
          .shadow(AppTheme.primaryBtnShadow())
          .onClick(() => this.doSearch())
        Button(this.voiceListening ? '🎙 停止' : '🎙 语音')
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.voiceListening ? AppColors.ACCENT : '#8B7355')
          .onClick(() => this.toggleVoiceSearch())
        Button('📷 相册')
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.imageSearchMode ? AppColors.ACCENT : '#6B8E6B')
          .onClick(() => this.pickImageFromAlbum())
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.imageSearchMode && this.queryImageBase64.length > 0) {
        Row({ space: 12 }) {
          Image(`data:image/jpeg;base64,${this.queryImageBase64}`)
            .width(72)
            .height(72)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .border({ width: 1, color: AppColors.BORDER })
          Column({ space: 4 }) {
            Text('已选查询图片')
              .fontSize(13)
              .fontColor(AppColors.TEXT)
            Text('结果按相似度从高到低排列')
              .fontSize(12)
              .fontColor(AppColors.SUBTEXT)
            Button('清除图片')
              .height(28)
              .fontSize(12)
              .backgroundColor(AppColors.SURFACE)
              .fontColor(AppColors.SUBTEXT)
              .onClick(() => this.clearImageSearch())
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.voiceHint.length > 0) {
        Text(this.voiceHint)
          .fontSize(12)
          .fontColor(AppColors.SUBTEXT)
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.loading) {
        LoadingProgress().margin({ top: 24 })
      } else if (this.searched && this.flatItems.length === 0) {
        Text(this.imageSearchMode ? '未找到相似瓷器' : '未找到相关瓷器')
          .fontColor(AppColors.SUBTEXT)
          .margin({ top: 32 })
      } else if (this.searched) {
        Scroll() {
          Column() {
            Text(this.imageSearchMode ?
              `共找到 ${this.total} 件相似文物` : `共找到 ${this.total} 件`)
              .fontSize(13)
              .fontColor(AppColors.SUBTEXT)
              .width('100%')
              .padding({ left: 16, top: 8, bottom: 4 })

            Grid() {
              ForEach(this.flatItems, (item: ArtifactItem) => {
                GridItem() {
                  ArtifactCard({
                    item: item,
                    showSimilarity: this.imageSearchMode,
                    onTap: () => this.openDetail(item)
                  })
                }
              }, (item: ArtifactItem) => `s_${item.museumId}_${item.objectId}_p${this.page}`)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .padding({ left: 16, right: 16 })

            PaginationBar({
              page: this.page,
              totalPages: this.totalPages(),
              onPrev: () => this.goPrevPage(),
              onNext: () => this.goNextPage()
            })
          }
        }
        .layoutWeight(1)
      } else {
        Column({ space: 12 }) {
          Text('🏺')
            .fontSize(40)
            .opacity(0.6)
          Text('支持文字、语音或以图搜图，可按博物馆、朝代筛选')
            .fontSize(13)
            .fontColor(AppColors.SUBTEXT)
            .textAlign(TextAlign.Center)
        }
        .padding(32)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[AppColors.BG, 0], ['#EBE3D6', 1]]
    })
  }
}
