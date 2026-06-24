import { router, promptAction } from '@kit.ArkUI';
import { AppColors } from '../common/Constants';
import { AppTheme } from '../common/AppTheme';
import { buildArtifactRouteParams } from '../common/RouteParams';
import { InteractionRefCard } from '../components/InteractionRefCard';
import { ProfileAccountPanel } from '../components/ProfileAccountPanel';
import {
  FavoriteFolder,
  UserArtifactRef,
  UserCommentRecord,
  UserInfo,
  UserPhotoItem,
  UserRefListMeta
} from '../model/Models';
import { MuseumService } from '../service/MuseumService';
import { UserSession } from '../store/UserSession';

@Component
export struct ProfilePage {
  @StorageLink('profileRefreshKey') @Watch('onProfileRefreshKeyChange') profileRefreshKey: number = 0;
  @State user: UserInfo | null = null;
  @State tab: number = 0;
  @State contentTab: number = 0;
  @State favorites: UserArtifactRef[] = [];
  @State likes: UserArtifactRef[] = [];
  @State browseHistory: UserArtifactRef[] = [];
  @State folders: FavoriteFolder[] = [];
  @State selectedFolderId: number = -1;
  @State myComments: UserCommentRecord[] = [];
  @State myPhotos: UserPhotoItem[] = [];
  @State showNewFolder: boolean = false;
  @State newFolderName: string = '';
  @State pendingComments: number = 0;
  @State pendingPhotos: number = 0;
  @State foldersEnabled: boolean = true;
  @State showFolderPicker: boolean = false;
  @State moveMuseumId: number = 0;
  @State moveObjectId: string = '';
  @State moveTitle: string = '';
  /** 全量收藏元数据，切换收藏夹时使用 */
  private allFavoritesMeta: UserRefListMeta | null = null;

  aboutToAppear(): void {
    if (!UserSession.isLoggedIn()) {
      this.tab = 2;
    }
    this.refresh();
  }

  onProfileRefreshKeyChange(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    this.user = UserSession.getUser();
    const browseMeta = await MuseumService.getBrowseHistory();
    this.browseHistory = browseMeta.items;
    if (UserSession.isLoggedIn()) {
      const foldersTask = MuseumService.getFavoriteFolders();
      const likesTask = MuseumService.getLikes();
      const commentsTask = MuseumService.getMyComments();
      const photosTask = MuseumService.getMyPhotos();
      const allFavoritesTask = MuseumService.getFavorites();

      this.folders = await foldersTask;
      this.foldersEnabled = this.folders.length > 0;
      const likesMeta = await likesTask;
      this.likes = likesMeta.items;
      const commentsMeta = await commentsTask;
      this.myComments = commentsMeta.items;
      this.myPhotos = await photosTask;
      this.updatePendingCounts();
      const allFavoritesMeta = await allFavoritesTask;
      this.allFavoritesMeta = allFavoritesMeta;

      let favMeta = allFavoritesMeta;
      if (this.selectedFolderId >= 0) {
        favMeta = await MuseumService.getFavorites(this.selectedFolderId);
        this.favorites = favMeta.items;
      } else {
        this.favorites = allFavoritesMeta.items;
      }
    } else {
      this.favorites = [];
      this.likes = [];
      this.browseHistory = [];
      this.folders = [];
      this.myComments = [];
      this.myPhotos = [];
      this.pendingComments = 0;
      this.pendingPhotos = 0;
      this.allFavoritesMeta = null;
    }
  }

  private updatePendingCounts(): void {
    let comments = 0;
    for (let i = 0; i < this.myComments.length; i++) {
      if (this.myComments[i].auditStatus === 0) {
        comments++;
      }
    }
    let photos = 0;
    for (let i = 0; i < this.myPhotos.length; i++) {
      if (this.myPhotos[i].status === 0) {
        photos++;
      }
    }
    this.pendingComments = comments;
    this.pendingPhotos = photos;
  }

  openPendingAudit(): void {
    this.tab = 3;
    this.contentTab = this.pendingComments > 0 ? 0 : 1;
  }

  async loadFavoritesForFolder(): Promise<void> {
    const favMeta = this.selectedFolderId >= 0
      ? await MuseumService.getFavorites(this.selectedFolderId)
      : await MuseumService.getFavorites();
    this.favorites = favMeta.items;
    if (this.selectedFolderId < 0) {
      this.allFavoritesMeta = favMeta;
    }
  }

  async confirmClearBrowseHistory(): Promise<void> {
    const result = await promptAction.showDialog({
      title: '清空浏览记录',
      message: '确定清空全部浏览记录吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '清空', color: '#C44E4E' }
      ]
    });
    if (result.index !== 1) {
      return;
    }
    const wr = await MuseumService.clearBrowseHistory();
    promptAction.showToast({ message: wr.message });
    if (wr.success) {
      await this.refresh();
    }
  }

  openArtifact(museumId: number, objectId: string): void {
    router.pushUrl({
      url: 'pages/ArtifactDetailPage',
      params: buildArtifactRouteParams(museumId, objectId)
    });
  }

  showAuditDetail(title: string, reason: string): void {
    promptAction.showDialog({
      title: title,
      message: reason.length > 0 ? reason : '暂无详细说明',
      buttons: [{ text: '知道了', color: AppColors.PRIMARY }]
    });
  }

  onCommentTap(item: UserCommentRecord): void {
    if (item.auditStatus === 1) {
      this.openArtifact(item.museumId, item.objectId);
      return;
    }
    this.showAuditDetail(`评论 · ${item.statusText}`, item.rejectReason);
  }

  async confirmDeleteComment(item: UserCommentRecord): Promise<void> {
    const result = await promptAction.showDialog({
      title: '删除评论',
      message: '删除后将从列表与公开展示中移除，确定删除吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#C44E4E' }
      ]
    });
    if (result.index !== 1) {
      return;
    }
    const wr = await MuseumService.deleteComment(item.commentId);
    promptAction.showToast({ message: wr.message });
    if (wr.success) {
      await this.refresh();
    }
  }

  onPhotoTap(item: UserPhotoItem): void {
    if (item.status === 1 && item.museumId !== undefined && item.objectId !== undefined) {
      this.openArtifact(item.museumId, item.objectId);
      return;
    }
    this.showAuditDetail(`图片 · ${item.statusText}`, item.rejectReason ?? '暂无详细说明');
  }

  async createFolder(): Promise<void> {
    const name = this.newFolderName.trim();
    if (name.length === 0) {
      promptAction.showToast({ message: '请输入收藏夹名称' });
      return;
    }
    const wr = await MuseumService.createFavoriteFolder(name);
    if (wr.success) {
      this.newFolderName = '';
      this.showNewFolder = false;
      promptAction.showToast({ message: '收藏夹已创建' });
      await this.refresh();
    } else {
      promptAction.showToast({ message: wr.message.length > 0 ? wr.message : '创建失败' });
    }
  }

  openFavoriteSettings(ref: UserArtifactRef): void {
    this.moveMuseumId = ref.museumId;
    this.moveObjectId = ref.objectId;
    this.moveTitle = ref.title;
    this.showFolderPicker = true;
  }

  async confirmMoveToFolder(folder: FavoriteFolder): Promise<void> {
    const wr = await MuseumService.moveFavoriteToFolder(
      this.moveMuseumId,
      this.moveObjectId,
      folder.folderId
    );
    this.showFolderPicker = false;
    if (wr.success) {
      promptAction.showToast({ message: `已移至「${folder.name}」` });
      await this.refresh();
    } else {
      promptAction.showToast({ message: wr.message.length > 0 ? wr.message : '移动失败' });
    }
  }

  async confirmUnfavorite(): Promise<void> {
    const wr = await MuseumService.toggleFavorite(this.moveMuseumId, this.moveObjectId, false);
    this.showFolderPicker = false;
    if (wr.success) {
      promptAction.showToast({ message: '已取消收藏' });
      await this.refresh();
    } else {
      promptAction.showToast({ message: wr.message.length > 0 ? wr.message : '取消收藏失败' });
    }
  }

  closeFolderPicker(): void {
    this.showFolderPicker = false;
  }

  statusColor(approved: boolean, pending: boolean): string {
    if (approved) {
      return '#2E7D32';
    }
    if (pending) {
      return '#C9A227';
    }
    return '#B3261E';
  }

  onProfileTabClick(index: number): void {
    if (!UserSession.isLoggedIn() && index !== 2) {
      promptAction.showToast({ message: '请先登录后查看' });
      return;
    }
    this.tab = index;
  }

  @Builder
  loginRequiredHint(hint: string) {
    Column({ space: 12 }) {
      Text(hint)
        .fontSize(14)
        .fontColor(AppColors.SUBTEXT)
      Button('前往登录')
        .height(40)
        .backgroundColor(AppColors.PRIMARY)
        .onClick(() => router.pushUrl({ url: 'pages/LoginPage' }))
    }
    .width('100%')
    .padding({ top: 48, bottom: 48 })
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack() {
      Column() {
        if (!this.user) {
          Column({ space: 12 }) {
            Text('👤')
              .fontSize(40)
              .opacity(0.85)
            Text('个人中心')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
            Text('浏览记录保存在本机；登录后可同步收藏、点赞与评论')
              .fontSize(13)
              .fontColor(AppColors.SUBTEXT)
              .textAlign(TextAlign.Center)
            Button('✦ 登录 / 注册')
              .width('70%')
              .height(40)
              .borderRadius(20)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(AppColors.PRIMARY)
              .shadow(AppTheme.primaryBtnShadow())
              .onClick(() => router.pushUrl({ url: 'pages/LoginPage' }))
          }
          .width('100%')
          .padding(20)
          .margin({ left: 16, right: 16, top: 8, bottom: 4 })
          .backgroundColor(AppColors.CARD)
          .borderRadius(12)
          .border({ width: 1, color: AppColors.BORDER })
          .shadow(AppTheme.cardShadow())
        } else {
          Column({ space: 12 }) {
            this.profileGreeting()
            if (this.user !== null) {
              ProfileAccountPanel({
                user: this.user,
                pendingComments: this.pendingComments,
                pendingPhotos: this.pendingPhotos,
                onPendingTap: () => this.openPendingAudit()
              })
            }
          }
          .padding(16)
          .margin({ left: 16, right: 16, top: 8, bottom: 4 })
          .backgroundColor(AppColors.CARD)
          .borderRadius(12)
          .border({ width: 1, color: AppColors.BORDER })
          .shadow(AppTheme.cardShadow())
        }

        this.profileTabs()

        if (this.user && this.tab === 3) {
          Row({ space: 12 }) {
            this.contentSubTab('评论', 0)
            this.contentSubTab('图片', 1)
          }
          .padding({ left: 16, right: 16, bottom: 8 })
        }

        if (this.user && this.tab === 0) {
          this.folderBar()
        }

        if (this.tab === 2 && this.browseHistory.length > 0) {
          Row() {
            Blank()
            Button('清空记录')
              .fontSize(12)
              .height(32)
              .backgroundColor('#FFEBEE')
              .fontColor('#B3261E')
              .onClick(() => this.confirmClearBrowseHistory())
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 4 })
        }

        Scroll() {
          if (!this.user) {
            if (this.tab === 0) {
              this.loginRequiredHint('登录后可查看收藏')
            } else if (this.tab === 1) {
              this.loginRequiredHint('登录后可查看点赞')
            } else if (this.tab === 2) {
              this.browseGrid()
            } else if (this.contentTab === 0) {
              this.loginRequiredHint('登录后可查看评论')
            } else {
              this.loginRequiredHint('登录后可查看上传图片')
            }
          } else if (this.tab === 0) {
            this.favoriteGrid()
          } else if (this.tab === 1) {
            this.likeGrid()
          } else if (this.tab === 2) {
            this.browseGrid()
          } else if (this.contentTab === 0) {
            this.listMyComments()
          } else {
            this.listMyPhotos()
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .backgroundColor(AppColors.BG)
      .onAppear(() => {
        this.refresh();
      })

      if (this.showFolderPicker) {
        this.folderPickerOverlay()
      }
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
        Text('设置分组')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
        Text(this.moveTitle)
          .fontSize(13)
          .fontColor(AppColors.SUBTEXT)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.foldersEnabled && this.folders.length > 0) {
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
                    this.confirmMoveToFolder(folder);
                  })
              }, (folder: FavoriteFolder) => `${folder.folderId}`)
            }
          }
          .height(220)
        }

        Button('取消收藏')
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#FFEBEE')
          .fontColor('#B3261E')
          .onClick(() => {
            this.confirmUnfavorite();
          })

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
  profileGreeting() {
    Row() {
      Text('我的文物足迹')
        .fontSize(14)
        .fontColor(AppColors.SUBTEXT)
        .layoutWeight(1)

      Button('退出')
        .fontSize(12)
        .height(32)
        .backgroundColor('#999')
        .onClick(async () => {
          UserSession.logout();
          await this.refresh();
        })
    }
    .width('100%')
  }

  @Builder
  profileTabs() {
    Scroll() {
      Row({ space: 0 }) {
        this.profileTab('收藏', 0)
        this.profileTab('点赞', 1)
        this.profileTab('浏览', 2)
        this.profileTab('评论', 3)
      }
      .padding({ left: 8, right: 8 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  profileTab(title: string, index: number) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(13)
        .fontColor(this.tab === index ? AppColors.PRIMARY : AppColors.SUBTEXT)
        .fontWeight(this.tab === index ? FontWeight.Bold : FontWeight.Normal)
        .maxLines(1)
      Divider()
        .width(20)
        .height(2)
        .color(this.tab === index ? AppColors.PRIMARY : Color.Transparent)
    }
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .onClick(() => {
      this.onProfileTabClick(index);
    })
  }

  @Builder
  contentSubTab(title: string, index: number) {
    Button(title)
      .fontSize(13)
      .height(32)
      .layoutWeight(1)
      .backgroundColor(this.contentTab === index ? AppColors.PRIMARY : '#E8E0D5')
      .fontColor(this.contentTab === index ? Color.White : AppColors.TEXT)
      .onClick(() => {
        this.contentTab = index;
      })
  }

  @Builder
  folderBar() {
    Column({ space: 8 }) {
      Scroll() {
        Row({ space: 8 }) {
          Text('全部')
            .fontSize(12)
            .fontColor(this.selectedFolderId === -1 ? Color.White : AppColors.TEXT)
            .backgroundColor(this.selectedFolderId === -1 ? AppColors.PRIMARY : '#EDE6D9')
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .borderRadius(16)
            .onClick(async () => {
              this.selectedFolderId = -1;
              await this.loadFavoritesForFolder();
            })

          ForEach(this.folders, (folder: FavoriteFolder) => {
            Text(`${folder.name} (${folder.itemCount})`)
              .fontSize(12)
              .fontColor(this.selectedFolderId === folder.folderId ? Color.White : AppColors.TEXT)
              .backgroundColor(this.selectedFolderId === folder.folderId ? AppColors.PRIMARY : '#EDE6D9')
              .padding({ left: 14, right: 14, top: 7, bottom: 7 })
              .borderRadius(16)
              .onClick(async () => {
                this.selectedFolderId = folder.folderId;
                await this.loadFavoritesForFolder();
              })
          }, (folder: FavoriteFolder) => `${folder.folderId}`)

          Text('+ 新建')
            .fontSize(12)
            .fontColor(AppColors.PRIMARY)
            .backgroundColor('#FFF8EE')
            .border({ width: 1, color: AppColors.ACCENT })
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .borderRadius(16)
            .onClick(() => {
              this.showNewFolder = !this.showNewFolder;
            })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      if (this.showNewFolder) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '收藏夹名称', text: this.newFolderName })
            .layoutWeight(1)
            .backgroundColor(AppColors.CARD)
            .onChange((v: string) => {
              this.newFolderName = v;
            })
          Button('创建')
            .height(40)
            .backgroundColor(AppColors.PRIMARY)
            .onClick(() => this.createFolder())
        }
        .padding({ left: 16, right: 16, bottom: 4 })
      }

      Text('点击卡片右下角「设置分组」可调整收藏夹或取消收藏')
        .fontSize(11)
        .fontColor(AppColors.SUBTEXT)
        .padding({ left: 16, bottom: 4 })
    }
  }

  @Builder
  favoriteGrid() {
    if (this.favorites.length === 0) {
      Column({ space: 8 }) {
        Text('暂无收藏')
          .fontSize(16)
          .fontColor(AppColors.SUBTEXT)
        Text('去文物详情页点击「收藏」添加')
          .fontSize(12)
          .fontColor(AppColors.SUBTEXT)
      }
      .width('100%')
      .padding({ top: 48, bottom: 48 })
      .alignItems(HorizontalAlign.Center)
    } else {
      Grid() {
        ForEach(this.favorites, (ref: UserArtifactRef) => {
          GridItem() {
            InteractionRefCard({
              ref: ref,
              badge: '收藏',
              badgeColor: AppColors.PRIMARY,
              showGroupButton: true,
              onTap: () => this.openArtifact(ref.museumId, ref.objectId),
              onGroupTap: () => this.openFavoriteSettings(ref)
            })
          }
        }, (ref: UserArtifactRef) => `${ref.museumId}_${ref.objectId}`)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .width('100%')
    }
  }

  @Builder
  browseGrid() {
    if (this.browseHistory.length === 0) {
      Column({ space: 8 }) {
        Text('暂无浏览记录')
          .fontSize(16)
          .fontColor(AppColors.SUBTEXT)
        Text('打开文物详情页后会自动记录在本机')
          .fontSize(12)
          .fontColor(AppColors.SUBTEXT)
      }
      .width('100%')
      .padding({ top: 48, bottom: 48 })
      .alignItems(HorizontalAlign.Center)
    } else {
      Grid() {
        ForEach(this.browseHistory, (ref: UserArtifactRef) => {
          GridItem() {
            InteractionRefCard({
              ref: ref,
              badge: '浏览',
              badgeColor: '#5C6BC0',
              onTap: () => this.openArtifact(ref.museumId, ref.objectId)
            })
          }
        }, (ref: UserArtifactRef) => `browse_${ref.museumId}_${ref.objectId}`)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .width('100%')
    }
  }

  @Builder
  likeGrid() {
    if (this.likes.length === 0) {
      Column({ space: 8 }) {
        Text('暂无点赞')
          .fontSize(16)
          .fontColor(AppColors.SUBTEXT)
        Text('在文物详情页为喜欢的瓷器点赞')
          .fontSize(12)
          .fontColor(AppColors.SUBTEXT)
      }
      .width('100%')
      .padding({ top: 48, bottom: 48 })
      .alignItems(HorizontalAlign.Center)
    } else {
      Grid() {
        ForEach(this.likes, (ref: UserArtifactRef) => {
          GridItem() {
            InteractionRefCard({
              ref: ref,
              badge: '已赞',
              badgeColor: AppColors.ACCENT,
              onTap: () => this.openArtifact(ref.museumId, ref.objectId)
            })
          }
        }, (ref: UserArtifactRef) => `like_${ref.museumId}_${ref.objectId}`)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .width('100%')
    }
  }

  @Builder
  listMyComments() {
    if (this.myComments.length === 0) {
      Text('暂无评论，去文物详情页发表吧')
        .fontColor(AppColors.SUBTEXT)
        .margin(24)
    } else {
      Column() {
        ForEach(this.myComments, (c: UserCommentRecord) => {
          Column({ space: 6 }) {
            Row() {
              Text(c.artifactTitle)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text(c.statusText)
                .fontSize(12)
                .fontColor(this.statusColor(c.auditStatus === 1, c.auditStatus === 0))
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
            .width('100%')
            if (c.parentId !== undefined && c.parentId !== null && c.parentId > 0 && c.replyToNickname !== undefined) {
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
            Text(c.auditStatus === 1 ? '点击查看文物详情' : '点击查看审核说明')
              .fontSize(11)
              .fontColor(AppColors.PRIMARY)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .margin({ left: 16, right: 16, bottom: 8 })
          .borderRadius(10)
          .shadow({ radius: 6, color: '#10000000', offsetY: 2 })
          .onClick(() => this.onCommentTap(c))
        }, (c: UserCommentRecord) => `${c.commentId}`)
      }
      .padding({ top: 8, bottom: 24 })
    }
  }

  @Builder
  listMyPhotos() {
    if (this.myPhotos.length === 0) {
      Text('暂无图片，去文物详情页「用户图片」上传')
        .fontColor(AppColors.SUBTEXT)
        .margin(24)
    } else {
      Column() {
        ForEach(this.myPhotos, (p: UserPhotoItem) => {
          Column({ space: 6 }) {
            if (MuseumService.getPhotoSrc(p.photoUrl).length > 0) {
              Image(MuseumService.getPhotoSrc(p.photoUrl))
                .width('100%')
                .height(120)
                .objectFit(ImageFit.Cover)
                .borderRadius(6)
            }
            Row() {
              Text(p.artifactTitle ?? '未知文物')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text(p.statusText)
                .fontSize(12)
                .fontColor(this.statusColor(p.status === 1, p.status === 0))
            }
            .width('100%')
            Text(p.description || '无说明')
              .fontSize(13)
              .fontColor(AppColors.TEXT)
            if (p.location) {
              Text(`地点：${p.location}`)
                .fontSize(12)
                .fontColor(AppColors.SUBTEXT)
            }
            Text(p.createdAt)
              .fontSize(11)
              .fontColor(AppColors.SUBTEXT)
            Text(p.status === 1 ? '点击查看文物详情' : '点击查看审核说明')
              .fontSize(11)
              .fontColor(AppColors.PRIMARY)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(14)
          .backgroundColor(AppColors.CARD)
          .margin({ left: 16, right: 16, bottom: 8 })
          .borderRadius(10)
          .shadow({ radius: 6, color: '#10000000', offsetY: 2 })
          .onClick(() => this.onPhotoTap(p))
        }, (p: UserPhotoItem) => `${p.photoId}`)
      }
      .padding({ top: 8, bottom: 24 })
    }
  }
}
