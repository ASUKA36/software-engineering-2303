import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AppColors } from '../common/Constants';
import { AppTheme, OrnamentLine } from '../common/AppTheme';
import { ArtifactItem, CommentItem, FavoriteFolder, UserPhotoItem, WriteResult } from '../model/Models';
import { MuseumService } from '../service/MuseumService';
import { UserSession } from '../store/UserSession';

import { ArtifactRouteParams } from '../common/RouteParams';
import { ImagePickerUtil } from '../common/ImagePickerUtil';
import { SpeechGuideService } from '../service/SpeechGuideService';

@Entry
@Component
struct ArtifactDetailPage {
  @State artifact: ArtifactItem | null = null;
  @State comments: CommentItem[] = [];
  @State userPhotos: UserPhotoItem[] = [];
  @State liked: boolean = false;
  @State favorited: boolean = false;
  @State commentInput: string = '';
  @State replyToCommentId: number = 0;
  @State replyToNickname: string = '';
  @State photoDescription: string = '';
  @State photoLocation: string = '';
  @State pickedImageUri: string = '';
  @State pickedImageBase64: string = '';
  @State photoSubmitting: boolean = false;
  @State interactionTab: number = 0;
  @State loading: boolean = true;
  @State imageList: string[] = [];
  @State currentImageIndex: number = 0;
  @State fullscreenMode: boolean = false;
  @State fullscreenIndex: number = 0;
  @State fsScale: number = 1;
  @State fsOffsetX: number = 0;
  @State fsOffsetY: number = 0;
  @State fsViewWidth: number = 360;
  @State fsViewHeight: number = 640;
  @State showFsInfo: boolean = false;
  private readonly fsDblTapScale: number = 2.5;
  @State guideSpeaking: boolean = false;
  @State folders: FavoriteFolder[] = [];
  @State showFolderPicker: boolean = false;
  @State showNewFolder: boolean = false;
  @State newFolderName: string = '';
  private museumId: number = 0;
  private objectId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as ArtifactRouteParams;
    this.museumId = Number(params.museumId ?? '0');
    this.objectId = params.objectId ?? '';
    this.loadAll();
    SpeechGuideService.setStateListener((speaking: boolean) => {
      this.guideSpeaking = speaking;
    });
  }

  aboutToDisappear(): void {
    SpeechGuideService.stop();
    SpeechGuideService.setStateListener(null);
  }

  async toggleGuide(): Promise<void> {
    if (this.artifact === null) {
      return;
    }
    if (SpeechGuideService.isSpeaking()) {
      SpeechGuideService.stop();
      return;
    }
    const ok = await SpeechGuideService.speakArtifact(this.artifact);
    if (!ok) {
      promptAction.showToast({ message: '语音讲解不可用，请确认设备已安装中文语音包' });
    }
  }

  async loadAll(): Promise<void> {
    this.loading = true;
    this.artifact = await MuseumService.getArtifact(this.museumId, this.objectId);
    if (this.artifact !== null) {
      this.imageList = MuseumService.getImageList(this.artifact);
      this.currentImageIndex = 0;
      this.fullscreenIndex = 0;
      this.resetFsZoom();
    }
    this.comments = await MuseumService.getComments(this.museumId, this.objectId);
    this.userPhotos = await MuseumService.getArtifactPhotos(this.museumId, this.objectId);
    if (this.artifact !== null) {
      MuseumService.recordBrowse(this.artifact);
    }
    if (UserSession.isLoggedIn()) {
      const st = await MuseumService.getInteractionStatus(this.museumId, this.objectId);
      this.liked = st.liked;
      this.favorited = st.favorited;
    }
    this.loading = false;
  }

  async requireLogin(hint: string = '登录后即可收藏、点赞和评论'): Promise<boolean> {
    if (UserSession.isLoggedIn()) {
      return true;
    }
    const result = await promptAction.showDialog({
      title: '需要登录',
      message: hint,
      buttons: [
        { text: '稍后再说', color: '#666666' },
        { text: '前往登录', color: AppColors.PRIMARY }
      ]
    });
    if (result.index === 1) {
      router.pushUrl({ url: 'pages/LoginPage' });
    }
    return false;
  }

  startReply(comment: CommentItem): void {
    this.replyToCommentId = comment.commentId;
    this.replyToNickname = comment.nickname;
  }

  cancelReply(): void {
    this.replyToCommentId = 0;
    this.replyToNickname = '';
  }

  isReplyComment(comment: CommentItem): boolean {
    return comment.parentId !== undefined && comment.parentId !== null && comment.parentId > 0;
  }

  isMyComment(comment: CommentItem): boolean {
    const user = UserSession.getUser();
    return user !== null && comment.userId === user.userId;
  }

  async confirmDeleteComment(comment: CommentItem): Promise<void> {
    if (!await this.requireLogin('登录后即可管理评论')) {
      return;
    }
    const result = await promptAction.showDialog({
      title: '删除评论',
      message: '删除后将从公开展示中移除，确定删除吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#C44E4E' }
      ]
    });
    if (result.index !== 1) {
      return;
    }
    const wr = await MuseumService.deleteComment(comment.commentId);
    promptAction.showToast({ message: wr.message });
    if (wr.success) {
      if (this.replyToCommentId === comment.commentId) {
        this.cancelReply();
      }
      this.comments = await MuseumService.getComments(this.museumId, this.objectId);
    }
  }

  async openFavoritePicker(): Promise<void> {
    if (!await this.requireLogin('登录后即可收藏文物并选择收藏夹')) {
      return;
    }
    this.folders = await MuseumService.getFavoriteFolders();
    if (this.folders.length === 0) {
      const wr = await MuseumService.toggleFavorite(this.museumId, this.objectId, true);
      if (wr.success) {
        this.favorited = true;
        promptAction.showToast({ message: '已收藏（已保存）' });
      } else {
        promptAction.showToast({ message: wr.message });
      }
      return;
    }
    this.showNewFolder = false;
    this.newFolderName = '';
    this.showFolderPicker = true;
  }

  closeFolderPicker(): void {
    this.showFolderPicker = false;
    this.showNewFolder = false;
    this.newFolderName = '';
  }

  async confirmFavoriteToFolder(folder: FavoriteFolder): Promise<void> {
    let wr: WriteResult;
    if (this.favorited) {
      wr = await MuseumService.moveFavoriteToFolder(this.museumId, this.objectId, folder.folderId);
    } else {
      wr = await MuseumService.toggleFavorite(this.museumId, this.objectId, true, folder.folderId);
      if (wr.success) {
        this.favorited = true;
      }
    }
    this.closeFolderPicker();
    if (wr.success) {
      promptAction.showToast({ message: `已收藏至「${folder.name}」` });
    } else {
      promptAction.showToast({ message: wr.message.length > 0 ? wr.message : '操作失败' });
    }
  }

  async confirmUnfavorite(): Promise<void> {
    const wr = await MuseumService.toggleFavorite(this.museumId, this.objectId, false);
    this.closeFolderPicker();
    if (wr.success) {
      this.favorited = false;
      promptAction.showToast({ message: '已取消收藏' });
    } else {
      promptAction.showToast({ message: wr.message.length > 0 ? wr.message : '取消收藏失败' });
    }
  }

  async createFolderAndFavorite(): Promise<void> {
    const name = this.newFolderName.trim();
    if (name.length === 0) {
      promptAction.showToast({ message: '请输入收藏夹名称' });
      return;
    }
    const wr = await MuseumService.createFavoriteFolder(name);
    if (!wr.success) {
      promptAction.showToast({ message: wr.message.length > 0 ? wr.message : '创建失败' });
      return;
    }
    this.folders = await MuseumService.getFavoriteFolders();
    for (let i = 0; i < this.folders.length; i++) {
      if (this.folders[i].name === name && this.folders[i].folderId > 0) {
        await this.confirmFavoriteToFolder(this.folders[i]);
        return;
      }
    }
    this.showNewFolder = false;
    this.newFolderName = '';
    promptAction.showToast({ message: '收藏夹已创建，请选择' });
  }

  resetFsZoom(): void {
    this.fsScale = 1;
    this.fsOffsetX = 0;
    this.fsOffsetY = 0;
  }

  getEraLabel(): string {
    if (this.artifact === null) {
      return '';
    }
    const dynasty = this.artifact.dynasty;
    const period = this.artifact.period;
    if (dynasty.length > 0 && period.length > 0) {
      return `${dynasty} · ${period}`;
    }
    if (dynasty.length > 0) {
      return dynasty;
    }
    return period;
  }

  openFullscreen(): void {
    if (this.imageList.length === 0) {
      return;
    }
    this.fullscreenIndex = this.currentImageIndex;
    this.showFsInfo = false;
    this.resetFsZoom();
    this.fullscreenMode = true;
  }

  closeFullscreen(): void {
    this.currentImageIndex = this.fullscreenIndex;
    this.fullscreenMode = false;
    this.showFsInfo = false;
    this.resetFsZoom();
  }

  toggleFsInfo(): void {
    this.showFsInfo = !this.showFsInfo;
  }

  handleFsDoubleTap(event: GestureEvent): void {
    if (this.fsScale > 1.05) {
      this.resetFsZoom();
      return;
    }
    const finger = event.fingerList[0];
    const tapX = finger.localX;
    const tapY = finger.localY;
    const cx = this.fsViewWidth / 2;
    const cy = this.fsViewHeight / 2;
    this.fsScale = this.fsDblTapScale;
    this.fsOffsetX = (cx - tapX) * (this.fsDblTapScale - 1);
    this.fsOffsetY = (cy - tapY) * (this.fsDblTapScale - 1);
  }

  updateFsViewSize(width: number, height: number): void {
    if (width > 0 && height > 0) {
      this.fsViewWidth = width;
      this.fsViewHeight = height;
    }
  }

  async pickPhoto(): Promise<void> {
    const base64 = await ImagePickerUtil.pickImageBase64();
    if (base64.length === 0) {
      promptAction.showToast({ message: '未选择图片' });
      return;
    }
    this.pickedImageBase64 = base64;
    this.pickedImageUri = `data:image/jpeg;base64,${base64}`;
    promptAction.showToast({ message: '已选择图片' });
  }

  async submitPhoto(): Promise<void> {
    if (this.photoSubmitting) {
      return;
    }
    if (!await this.requireLogin('登录后即可上传图片')) {
      return;
    }
    if (this.pickedImageBase64.length === 0) {
      promptAction.showToast({ message: '请先选择图片' });
      return;
    }
    if (!this.photoDescription.trim()) {
      promptAction.showToast({ message: '请填写照片说明' });
      return;
    }
    this.photoSubmitting = true;
    const wr = await MuseumService.uploadPhoto(
      this.photoDescription.trim(),
      this.photoLocation.trim(),
      this.museumId,
      this.objectId,
      this.pickedImageBase64
    );
    this.photoSubmitting = false;
    if (wr.rejectReason.length > 0 && !wr.success) {
      promptAction.showDialog({
        title: '图片未通过审核',
        message: wr.rejectReason,
        buttons: [{ text: '知道了', color: AppColors.PRIMARY }]
      });
    } else {
      promptAction.showToast({ message: wr.message });
    }
    if (wr.success) {
      this.photoDescription = '';
      this.photoLocation = '';
      this.pickedImageUri = '';
      this.pickedImageBase64 = '';
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('← 返回')
            .fontSize(15)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(AppColors.SURFACE)
            .borderRadius(16)
            .border({ width: 1, color: AppColors.BORDER })
            .onClick(() => router.back())
          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 4 })

        if (this.loading || !this.artifact) {
          LoadingProgress().layoutWeight(1)
        } else {
          Scroll() {
            Column({ space: 12 }) {
              this.artifactImagePreview()

              Text(this.artifact.title)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT)
                .padding({ left: 16, right: 16 })

              Button(this.guideSpeaking ? '⏸ 停止讲解' : '🎧 语音讲解')
                .width('92%')
                .height(42)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .borderRadius(21)
                .backgroundColor(this.guideSpeaking ? AppColors.ACCENT : '#8B7355')
                .shadow(AppTheme.softShadow())
                .onClick(() => this.toggleGuide())

              Row({ space: 12 }) {
                Button(this.liked ? '👍 已赞' : '👍 点赞')
                  .layoutWeight(1)
                  .height(42)
                  .borderRadius(21)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(this.liked ? AppColors.ACCENT : AppColors.PRIMARY)
                  .shadow(this.liked ? AppTheme.softShadow() : AppTheme.primaryBtnShadow())
                  .onClick(async () => {
                    if (!await this.requireLogin('登录后即可点赞')) {
                      return;
                    }
                    const next = !this.liked;
                    const wr = await MuseumService.toggleLike(this.museumId, this.objectId, next);
                    if (wr.success) {
                      this.liked = next;
                      promptAction.showToast({ message: next ? '已点赞（已保存）' : '已取消点赞' });
                    } else {
                      promptAction.showToast({ message: wr.message });
                    }
                  })
                Button(this.favorited ? '★ 已藏' : '☆ 收藏')
                  .layoutWeight(1)
                  .height(42)
                  .borderRadius(21)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(this.favorited ? '#5D4E37' : '#8B7355')
                  .shadow(AppTheme.softShadow())
                  .onClick(() => this.openFavoritePicker())
              }
              .padding({ left: 16, right: 16 })

              this.attrRow('朝代', this.artifact.dynasty)
              this.attrRow('年代', this.artifact.period)
              this.attrRow('类型', this.artifact.type)
              this.attrRow('材质', this.artifact.material)
              this.attrRow('尺寸', this.artifact.dimensions)
              this.attrRow('馆藏', `${this.artifact.museum} · ${this.artifact.location}`)

              Text('详细介绍')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.PRIMARY)
                .padding({ left: 16, top: 8, right: 16 })
              OrnamentLine()
                .padding({ left: 16, right: 16, bottom: 6 })
              Text(this.artifact.description)
                .fontSize(14)
                .fontColor(AppColors.TEXT)
                .lineHeight(22)
                .padding({ left: 16, right: 16 })

              Row({ space: 6 }) {
                Text('💬')
                  .fontSize(16)
                Text('互动')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.PRIMARY)
              }
              .padding({ left: 16, top: 12, right: 16 })
              OrnamentLine()
                .padding({ left: 16, right: 16, bottom: 4 })

              Row({ space: 12 }) {
                this.interactionTabBtn(`评论 (${this.comments.length})`, 0)
                this.interactionTabBtn(`用户图片 (${this.userPhotos.length})`, 1)
              }
              .padding({ left: 16, right: 16 })

              if (this.interactionTab === 0) {
                this.commentSection()
              } else {
                this.userPhotoSection()
              }
            }
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG)

      if (this.showFolderPicker) {
        this.folderPickerOverlay()
      }

      if (this.fullscreenMode) {
        this.fullscreenViewer()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  artifactImagePreview() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.imageList.length > 0) {
        Swiper() {
          ForEach(this.imageList, (src: string, index: number) => {
            Image(src)
              .width('100%')
              .height(280)
              .objectFit(ImageFit.Contain)
              .backgroundColor('#F0EBE3')
          }, (src: string, index: number) => `preview_${index}_${src}`)
        }
        .width('100%')
        .height(280)
        .indicator(this.imageList.length > 1)
        .loop(false)
        .index(this.currentImageIndex)
        .onChange((index: number) => {
          this.currentImageIndex = index;
        })
      } else {
        Column() {
          Text('暂无图片')
            .fontSize(14)
            .fontColor(AppColors.SUBTEXT)
        }
        .width('100%')
        .height(280)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F0EBE3')
      }

      Row() {
        if (this.imageList.length > 1) {
          Text(`${this.currentImageIndex + 1} / ${this.imageList.length}`)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#66000000')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(12)
        }
        Blank()
        if (this.imageList.length > 0) {
          Text('⛶')
            .fontSize(18)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(36)
            .height(36)
            .backgroundColor('#99000000')
            .borderRadius(18)
            .onClick(() => this.openFullscreen())
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 10 })
    }
    .width('100%')
    .height(280)
  }

  @Builder
  fullscreenViewer() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')

      Swiper() {
        ForEach(this.imageList, (src: string, index: number) => {
          Stack() {
            Image(src)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .scale({
                x: this.fullscreenIndex === index ? this.fsScale : 1,
                y: this.fullscreenIndex === index ? this.fsScale : 1
              })
              .translate({
                x: this.fullscreenIndex === index ? this.fsOffsetX : 0,
                y: this.fullscreenIndex === index ? this.fsOffsetY : 0
              })
          }
          .width('100%')
          .height('100%')
          .onAreaChange((_old: Area, area: Area) => {
            if (this.fullscreenIndex === index) {
              this.updateFsViewSize(Number(area.width), Number(area.height));
            }
          })
          .gesture(
            GestureGroup(GestureMode.Parallel,
              GestureGroup(GestureMode.Exclusive,
                TapGesture({ count: 2 })
                  .onAction((event: GestureEvent) => {
                    if (this.fullscreenIndex === index) {
                      this.handleFsDoubleTap(event);
                    }
                  }),
                TapGesture({ count: 1 })
                  .onAction(() => {
                    if (this.fullscreenIndex === index) {
                      this.toggleFsInfo();
                    }
                  })
              ),
              PinchGesture({ fingers: 2 })
                .onActionUpdate((event: GestureEvent) => {
                  if (this.fullscreenIndex === index) {
                    this.fsScale = Math.min(5, Math.max(1, event.scale));
                  }
                }),
              PanGesture()
                .onActionUpdate((event: GestureEvent) => {
                  if (this.fullscreenIndex === index && this.fsScale > 1) {
                    this.fsOffsetX = this.fsOffsetX + event.offsetX;
                    this.fsOffsetY = this.fsOffsetY + event.offsetY;
                  }
                })
            )
          )
        }, (src: string, index: number) => `fs_${index}_${src}`)
      }
      .width('100%')
      .height('100%')
      .index(this.fullscreenIndex)
      .indicator(this.imageList.length > 1)
      .loop(false)
      .disableSwipe(this.fsScale > 1)
      .onChange((index: number) => {
        this.fullscreenIndex = index;
        this.showFsInfo = false;
        this.resetFsZoom();
      })

      Column() {
        Row() {
          if (this.imageList.length > 1) {
            Text(`${this.fullscreenIndex + 1} / ${this.imageList.length}`)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor('#66000000')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(14)
          }
          Blank()
          Button('退出')
            .fontSize(14)
            .height(36)
            .backgroundColor('#66000000')
            .fontColor(Color.White)
            .onClick(() => this.closeFullscreen())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 44 })

        Blank()

        if (this.showFsInfo && this.artifact !== null) {
          Column({ space: 8 }) {
            Text(this.artifact.title)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.getEraLabel())
              .fontSize(14)
              .fontColor('#DDDDDD')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 32 })
          .backgroundColor('#99000000')
        }
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  folderPickerOverlay() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => this.closeFolderPicker())

      Column({ space: 12 }) {
        Text(this.favorited ? '调整收藏分组' : '选择收藏夹')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
        Text(this.artifact?.title ?? '')
          .fontSize(13)
          .fontColor(AppColors.SUBTEXT)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.folders.length > 0) {
          Scroll() {
            Column({ space: 8 }) {
              ForEach(this.folders, (folder: FavoriteFolder) => {
                Button(`${folder.name} (${folder.itemCount})`)
                  .width('100%')
                  .height(40)
                  .fontSize(14)
                  .backgroundColor('#F7F2EA')
                  .fontColor(AppColors.TEXT)
                  .onClick(() => {
                    this.confirmFavoriteToFolder(folder);
                  })
              }, (folder: FavoriteFolder) => `${folder.folderId}`)
            }
          }
          .height(200)
        }

        if (this.showNewFolder) {
          Row({ space: 8 }) {
            TextInput({ placeholder: '收藏夹名称', text: this.newFolderName })
              .layoutWeight(1)
              .backgroundColor(AppColors.BG)
              .onChange((v: string) => {
                this.newFolderName = v;
              })
            Button('创建并收藏')
              .height(40)
              .backgroundColor(AppColors.PRIMARY)
              .onClick(() => this.createFolderAndFavorite())
          }
        } else {
          Button('+ 新建收藏夹')
            .width('100%')
            .height(40)
            .fontSize(14)
            .backgroundColor('#FFF8EE')
            .fontColor(AppColors.PRIMARY)
            .border({ width: 1, color: AppColors.ACCENT })
            .onClick(() => {
              this.showNewFolder = true;
            })
        }

        if (this.favorited) {
          Button('取消收藏')
            .width('100%')
            .height(40)
            .fontSize(14)
            .backgroundColor('#FFEBEE')
            .fontColor('#B3261E')
            .onClick(() => this.confirmUnfavorite())
        }

        Button('关闭')
          .width('100%')
          .height(40)
          .backgroundColor('#999')
          .onClick(() => this.closeFolderPicker())
      }
      .width('100%')
      .padding(20)
      .backgroundColor(AppColors.CARD)
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  interactionTabBtn(title: string, index: number) {
    Button(title)
      .fontSize(13)
      .height(36)
      .layoutWeight(1)
      .borderRadius(18)
      .fontWeight(this.interactionTab === index ? FontWeight.Medium : FontWeight.Normal)
      .backgroundColor(this.interactionTab === index ? AppColors.PRIMARY : AppColors.CHIP_BG)
      .fontColor(this.interactionTab === index ? Color.White : AppColors.TEXT)
      .border({
        width: 1,
        color: this.interactionTab === index ? AppColors.PRIMARY : AppColors.BORDER
      })
      .shadow(this.interactionTab === index ? AppTheme.primaryBtnShadow() : { radius: 0, color: Color.Transparent, offsetY: 0 })
      .onClick(() => {
        this.interactionTab = index;
      })
  }

  @Builder
  commentSection() {
    Column({ space: 8 }) {
      if (this.comments.length === 0) {
        Text('暂无评论，快来抢沙发')
          .fontSize(13)
          .fontColor(AppColors.SUBTEXT)
          .padding({ left: 16, right: 16, top: 4 })
      }

      ForEach(this.comments, (c: CommentItem) => {
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(c.nickname)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
            if (this.isMyComment(c)) {
              Button('删除')
                .fontSize(11)
                .height(28)
                .padding({ left: 10, right: 10 })
                .backgroundColor('#FCE8E8')
                .fontColor('#C44E4E')
                .onClick(() => {
                  this.confirmDeleteComment(c);
                })
            }
            Button('回复')
              .fontSize(11)
              .height(28)
              .padding({ left: 10, right: 10 })
              .backgroundColor('#F7F2EA')
              .fontColor(AppColors.PRIMARY)
              .onClick(async () => {
                if (!await this.requireLogin('登录后即可回复评论')) {
                  return;
                }
                this.startReply(c);
              })
          }
          .width('100%')

          if (this.isReplyComment(c) && c.replyToNickname !== undefined) {
            Text(`回复 @${c.replyToNickname}`)
              .fontSize(12)
              .fontColor(AppColors.SUBTEXT)
          }

          Text(c.content)
            .fontSize(14)
            .fontColor(AppColors.TEXT)

          Text(c.createdAt)
            .fontSize(11)
            .fontColor(AppColors.SUBTEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(12)
        .margin({
          left: this.isReplyComment(c) ? 32 : 16,
          right: 16
        })
        .backgroundColor(this.isReplyComment(c) ? '#FAFAF8' : AppColors.CARD)
        .borderRadius(8)
      }, (c: CommentItem) => `${c.commentId}`)

      if (this.replyToCommentId > 0) {
        Row({ space: 8 }) {
          Text(`回复 @${this.replyToNickname}`)
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .layoutWeight(1)
          Button('取消')
            .fontSize(11)
            .height(28)
            .backgroundColor('#EDE6D9')
            .onClick(() => this.cancelReply())
        }
        .padding({ left: 16, right: 16, top: 4 })
      }

      Row({ space: 8 }) {
        TextInput({
          placeholder: this.replyToCommentId > 0
            ? `回复 @${this.replyToNickname}…`
            : '发表评论…',
          text: this.commentInput
        })
          .layoutWeight(1)
          .onChange((v: string) => {
            this.commentInput = v;
          })
        Button('发送')
          .onClick(async () => {
            if (!await this.requireLogin('登录后即可发表评论')) {
              return;
            }
            if (!this.commentInput.trim()) {
              promptAction.showToast({ message: '请输入评论内容' });
              return;
            }
            const parentId = this.replyToCommentId > 0 ? this.replyToCommentId : undefined;
            const wr = await MuseumService.addComment(
              this.museumId,
              this.objectId,
              this.commentInput.trim(),
              parentId
            );
            if (wr.rejectReason.length > 0 && !wr.success) {
              promptAction.showDialog({
                title: '评论未通过审核',
                message: wr.rejectReason,
                buttons: [{ text: '知道了', color: AppColors.PRIMARY }]
              });
            } else {
              promptAction.showToast({ message: wr.message });
            }
            if (wr.success) {
              this.commentInput = '';
              this.cancelReply();
              this.comments = await MuseumService.getComments(this.museumId, this.objectId);
            }
          })
      }
      .padding({ left: 16, right: 16, bottom: 24, top: 4 })
    }
  }

  @Builder
  userPhotoSection() {
    Column({ space: 8 }) {
      if (this.userPhotos.length === 0) {
        Text('暂无用户图片，审核通过后将在此展示')
          .fontSize(13)
          .fontColor(AppColors.SUBTEXT)
          .padding({ left: 16, right: 16, top: 4 })
      }

      ForEach(this.userPhotos, (p: UserPhotoItem) => {
        Column({ space: 8 }) {
          if (MuseumService.getPhotoSrc(p.photoUrl).length > 0) {
            Image(MuseumService.getPhotoSrc(p.photoUrl))
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Cover)
              .borderRadius(6)
          } else {
            Row() {
              Text('🖼')
                .fontSize(28)
              Text('文字投稿')
                .fontSize(13)
                .fontColor(AppColors.SUBTEXT)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(80)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#F0EBE3')
            .borderRadius(6)
          }

          Text(p.description || '无说明')
            .fontSize(14)
            .fontColor(AppColors.TEXT)
          if (p.location) {
            Text(`📍 ${p.location}`)
              .fontSize(13)
              .fontColor(AppColors.SUBTEXT)
          }
          Row() {
            Text(p.nickname ?? '用户')
              .fontSize(12)
              .fontColor(AppColors.SUBTEXT)
            Blank()
            Text(p.createdAt)
              .fontSize(11)
              .fontColor(AppColors.SUBTEXT)
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(12)
        .margin({ left: 16, right: 16 })
        .backgroundColor(AppColors.CARD)
        .borderRadius(8)
      }, (p: UserPhotoItem) => `${p.photoId}`)

      Column({ space: 10 }) {
        Text('上传图片')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.PRIMARY)
          .width('100%')

        Text('关联当前文物，选择手机相册图片后提交审核')
          .fontSize(12)
          .fontColor(AppColors.SUBTEXT)
          .width('100%')

        if (this.pickedImageUri.length > 0) {
          Image(this.pickedImageUri)
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
            .borderRadius(6)
        }

        Button('从相册选择图片')
          .width('100%')
          .backgroundColor('#E8E0D5')
          .fontColor(AppColors.TEXT)
          .onClick(() => this.pickPhoto())

        TextInput({ placeholder: '拍摄地点', text: this.photoLocation })
          .width('100%')
          .backgroundColor(AppColors.BG)
          .onChange((v: string) => {
            this.photoLocation = v;
          })

        TextInput({ placeholder: '照片说明（必填）', text: this.photoDescription })
          .width('100%')
          .backgroundColor(AppColors.BG)
          .onChange((v: string) => {
            this.photoDescription = v;
          })

        Button(this.photoSubmitting ? '提交中…' : '提交审核')
          .width('100%')
          .backgroundColor(AppColors.PRIMARY)
          .enabled(!this.photoSubmitting)
          .onClick(() => this.submitPhoto())
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(14)
      .margin({ left: 16, right: 16, bottom: 24 })
      .backgroundColor(AppColors.CARD)
      .borderRadius(8)
    }
  }

  @Builder
  attrRow(label: string, value: string) {
    if (value) {
      Row() {
        Text(`${label}：`)
          .fontSize(13)
          .fontColor(AppColors.SUBTEXT)
          .width(56)
        Text(value)
          .fontSize(13)
          .fontColor(AppColors.TEXT)
          .layoutWeight(1)
      }
      .padding({ left: 16, right: 16 })
      .width('100%')
    }
  }
}
