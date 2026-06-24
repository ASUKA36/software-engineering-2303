import { ApiClient } from './ApiClient';
import { AppConfig } from '../common/Constants';
import {
  ArtifactListJson,
  ArtifactDetailJson,
  CommentListJson,
  CommentRecordListJson,
  LoginJson,
  LoginBody,
  MessageJson,
  MuseumListJson,
  PhotoListJson,
  FolderJson,
  FolderListJson,
  FolderMoveBody,
  RefListJson,
  RegisterBody,
  SearchJson,
  ImageSearchBody,
  ImageSearchJson,
  StatusJson,
  StringListJson,
  UploadPhotoBody,
} from './ApiTypes';
import {
  ArtifactItem,
  ArtifactPageResult,
  CommentItem,
  CommentPayload,
  EmptyPayload,
  FavoriteFolder,
  InteractionStatus,
  LoginResult,
  MuseumOption,
  SearchResult,
  UserArtifactRef,
  UserCommentRecord,
  UserCommentListMeta,
  UserPhotoItem,
  UserRefListMeta,
  WriteResult,
  HttpRawResponse,
  AuthResult
} from '../model/Models';
import { BrowseHistoryStore } from '../store/BrowseHistoryStore';
import { UserSession } from '../store/UserSession';

const OFFLINE_MSG: string = '无法连接服务器，请确认 server 已启动且 Constants.ets 中 API_BASE 正确';

export class MuseumService {
  static async getArtifactsPage(
    sort: string,
    page: number,
    size: number = AppConfig.PAGE_SIZE,
    excludeMuseumIds: number[] = []
  ): Promise<ArtifactPageResult> {
    const result = new ArtifactPageResult();
    result.page = page;
    result.size = size;
    const sortParam = sort === 'hot' ? 'hot' : (sort === 'type' ? 'type' : 'period');
    const params = [`sort=${sortParam}`, `page=${page}`, `size=${size}`];
    for (const id of excludeMuseumIds) {
      params.push(`exclude_museum_id=${id}`);
    }
    const json = await ApiClient.getJson(`/api/artifacts?${params.join('&')}`);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as ArtifactListJson;
      result.items = parsed.data ?? [];
      result.total = parsed.total ?? result.items.length;
      result.page = parsed.page ?? page;
      result.size = parsed.size ?? size;
    }
    return result;
  }

  static async getHotArtifacts(limit: number = 8): Promise<ArtifactItem[]> {
    let json = await ApiClient.getJson(`/api/artifacts/hot?size=${limit}`);
    if (json === null || ApiClient.getCode(json) !== 0) {
      json = await ApiClient.getJson(`/api/artifacts?sort=hot&page=1&size=${limit}`);
    }
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as ArtifactListJson;
      return parsed.data ?? [];
    }
    return [];
  }

  static async getArtifacts(sort: string): Promise<ArtifactItem[]> {
    const page = await MuseumService.getArtifactsPage(sort, 1, AppConfig.PAGE_SIZE);
    return page.items;
  }

  static async getArtifact(museumId: number, objectId: string): Promise<ArtifactItem | null> {
    const json = await ApiClient.getJson(
      `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}`);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as ArtifactDetailJson;
      return parsed.data;
    }
    return null;
  }

  static async search(
    keyword: string,
    dynasties: string[],
    types: string[],
    museumIds: number[],
    page: number = 1,
    size: number = AppConfig.PAGE_SIZE
  ): Promise<SearchResult> {
    const result = new SearchResult();
    result.page = page;
    result.size = size;
    const params = new Array<string>();
    if (keyword.length > 0) {
      params.push(`q=${encodeURIComponent(keyword)}`);
    }
    for (const d of dynasties) {
      params.push(`dynasty=${encodeURIComponent(d)}`);
    }
    for (const t of types) {
      params.push(`type=${encodeURIComponent(t)}`);
    }
    for (const id of museumIds) {
      params.push(`museum_id=${id}`);
    }
    params.push(`page=${page}`);
    params.push(`size=${size}`);
    const path = `/api/artifacts/search?${params.join('&')}`;
    const json = await ApiClient.getJson(path);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as SearchJson;
      result.items = parsed.data ?? [];
      result.groups = parsed.groups ?? [];
      result.total = parsed.total ?? result.items.length;
      result.page = parsed.page ?? page;
      result.size = parsed.size ?? size;
    }
    return result;
  }

  static async searchByImage(
    imageBase64: string,
    dynasties: string[],
    museumIds: number[],
    page: number = 1,
    size: number = AppConfig.PAGE_SIZE
  ): Promise<SearchResult> {
    const result = new SearchResult();
    result.page = page;
    result.size = size;
    if (imageBase64.length === 0) {
      return result;
    }
    await ApiClient.ensureNetwork();
    if (!ApiClient.isOnline()) {
      return result;
    }
    const body: ImageSearchBody = {
      imageBase64: imageBase64,
      page: page,
      size: size
    };
    if (dynasties.length > 0) {
      body.dynasty = dynasties;
    }
    if (museumIds.length > 0) {
      body.museum_id = museumIds;
    }
    const res = await ApiClient.postWrite('/api/artifacts/search-by-image', JSON.stringify(body), false);
    if (res === null) {
      result.errorMessage = OFFLINE_MSG;
      return result;
    }
    try {
      const parsed = JSON.parse(res.body) as ImageSearchJson;
      if (parsed.code === 0) {
        result.items = parsed.data ?? [];
        result.total = parsed.total ?? result.items.length;
        result.page = parsed.page ?? page;
        result.size = parsed.size ?? size;
      } else if (parsed.message !== undefined && parsed.message.length > 0) {
        result.errorMessage = parsed.message;
      }
    } catch (e) {
      result.errorMessage = '服务器返回格式异常';
    }
    return result;
  }

  static async getDynasties(): Promise<string[]> {
    const json = await ApiClient.getJson('/api/dynasties');
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as StringListJson;
      return parsed.data ?? [];
    }
    return [];
  }

  static async getTypes(): Promise<string[]> {
    const json = await ApiClient.getJson('/api/types');
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as StringListJson;
      return parsed.data ?? [];
    }
    return [];
  }

  static async getMuseums(): Promise<MuseumOption[]> {
    const json = await ApiClient.getJson('/api/museums');
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as MuseumListJson;
      return parsed.data ?? [];
    }
    return [];
  }

  private static parseRefListMeta(json: string): UserRefListMeta {
    const meta = new UserRefListMeta();
    const parsed = JSON.parse(json) as RefListJson;
    meta.items = parsed.data ?? [];
    meta.total = parsed.total !== undefined ? parsed.total : meta.items.length;
    return meta;
  }

  private static parseCommentListMeta(json: string): UserCommentListMeta {
    const meta = new UserCommentListMeta();
    const parsed = JSON.parse(json) as CommentRecordListJson;
    meta.items = parsed.data ?? [];
    meta.total = parsed.total !== undefined ? parsed.total : meta.items.length;
    return meta;
  }

  static async getComments(museumId: number, objectId: string): Promise<CommentItem[]> {
    const json = await ApiClient.getJson(
      `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}/comments`);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as CommentListJson;
      return parsed.data;
    }
    return [];
  }

  static async getArtifactPhotos(museumId: number, objectId: string): Promise<UserPhotoItem[]> {
    const json = await ApiClient.getJson(
      `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}/photos`);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as PhotoListJson;
      return parsed.data;
    }
    return [];
  }

  static getPhotoSrc(photoUrl: string): string {
    if (photoUrl.length === 0 || photoUrl.startsWith('text-upload://')) {
      return '';
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }
    if (photoUrl.startsWith('/')) {
      return `${AppConfig.API_BASE}${photoUrl}`;
    }
    return photoUrl;
  }

  static toAbsoluteUrl(path: string): string {
    if (path.length === 0) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      const base = path.startsWith('/api/img') ? AppConfig.IMAGE_API_BASE : AppConfig.API_BASE;
      return `${base}${path}`;
    }
    return path;
  }

  static resolveImageSrc(url: string, path: string, imgWeb?: string): string {
    if (imgWeb !== undefined && imgWeb.length > 0) {
      return MuseumService.toAbsoluteUrl(imgWeb);
    }
    return '';
  }

  static getImageList(item: ArtifactItem): string[] {
    if (item.imgsWeb !== undefined && item.imgsWeb.length > 0) {
      const webList: string[] = [];
      for (let i = 0; i < item.imgsWeb.length; i++) {
        const src = MuseumService.toAbsoluteUrl(item.imgsWeb[i]);
        if (src.length > 0) {
          webList.push(src);
        }
      }
      if (webList.length > 0) {
        return webList;
      }
    }
    if (item.imgWeb !== undefined && item.imgWeb.length > 0) {
      const single = MuseumService.toAbsoluteUrl(item.imgWeb);
      return single.length > 0 ? [single] : [];
    }
    const urls = item.imageUrls ?? [];
    const paths = item.imagePaths ?? [];
    if (urls.length === 0 && paths.length === 0) {
      const one = MuseumService.resolveImageSrc(item.imageUrl, item.imagePath);
      return one.length > 0 ? [one] : [];
    }
    const count = Math.max(urls.length, paths.length, item.imageCount ?? 0);
    const result: string[] = [];
    for (let i = 0; i < count; i++) {
      const url = i < urls.length ? urls[i] : '';
      const path = i < paths.length ? paths[i] : '';
      const src = MuseumService.resolveImageSrc(url, path);
      if (src.length > 0) {
        result.push(src);
      }
    }
    if (result.length === 0) {
      const one = MuseumService.resolveImageSrc(item.imageUrl, item.imagePath);
      if (one.length > 0) {
        result.push(one);
      }
    }
    return result;
  }

  static getRefImageSrc(ref: UserArtifactRef): string {
    if (ref.imgWeb !== undefined && ref.imgWeb.length > 0) {
      return MuseumService.toAbsoluteUrl(ref.imgWeb);
    }
    return MuseumService.resolveImageSrc(ref.imageUrl, ref.imagePath, ref.imgWeb);
  }

  static getImageSrc(item: ArtifactItem): string {
    const list = MuseumService.getImageList(item);
    return list.length > 0 ? list[0] : '';
  }

  static async register(
    username: string,
    password: string,
    email: string,
    phone: string
  ): Promise<AuthResult> {
    const ar = new AuthResult();
    if (username.length === 0 || password.length < 6) {
      ar.errorMessage = '请填写用户名和至少6位密码';
      return ar;
    }
    if (email.length === 0 && phone.length === 0) {
      ar.errorMessage = '请填写邮箱或手机号';
      return ar;
    }
    await ApiClient.ensureNetwork();
    if (!ApiClient.isOnline()) {
      ar.errorMessage = OFFLINE_MSG;
      return ar;
    }
    const body: RegisterBody = {
      username: username,
      password: password,
      email: email,
      phone: phone
    };
    const res = await ApiClient.postWrite('/api/auth/register', JSON.stringify(body), false);
    const wr = ApiClient.parseWriteResult(res, OFFLINE_MSG);
    if (!wr.success) {
      ar.errorMessage = wr.message.length > 0 ? wr.message : '注册失败';
      return ar;
    }
    if (res !== null) {
      try {
        const parsed = JSON.parse(res.body) as LoginJson;
        if (parsed.token !== undefined && parsed.user !== undefined) {
          const out = new LoginResult();
          out.token = parsed.token;
          out.user = parsed.user;
          ar.login = out;
        } else {
          ar.errorMessage = '注册成功但服务器未返回登录信息';
        }
      } catch (e) {
        ar.errorMessage = '服务器返回格式异常';
      }
    }
    return ar;
  }

  static async login(account: string, password: string): Promise<AuthResult> {
    const ar = new AuthResult();
    if (account.length === 0 || password.length === 0) {
      ar.errorMessage = '请输入账号和密码';
      return ar;
    }
    await ApiClient.ensureNetwork();
    if (!ApiClient.isOnline()) {
      ar.errorMessage = OFFLINE_MSG;
      return ar;
    }
    const body: LoginBody = {
      account: account,
      password: password
    };
    const res = await ApiClient.postWrite('/api/auth/login', JSON.stringify(body), false);
    const wr = ApiClient.parseWriteResult(res, OFFLINE_MSG);
    if (!wr.success) {
      ar.errorMessage = wr.message.length > 0 ? wr.message : '登录失败，请检查账号密码';
      return ar;
    }
    if (res !== null) {
      try {
        const parsed = JSON.parse(res.body) as LoginJson;
        if (parsed.token !== undefined && parsed.user !== undefined) {
          const out = new LoginResult();
          out.token = parsed.token;
          out.user = parsed.user;
          ar.login = out;
        } else {
          ar.errorMessage = '登录成功但服务器未返回用户信息';
        }
      } catch (e) {
        ar.errorMessage = '服务器返回格式异常';
      }
    }
    return ar;
  }

  static async getInteractionStatus(museumId: number, objectId: string): Promise<InteractionStatus> {
    const st = new InteractionStatus();
    const json = await ApiClient.getJson(
      `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}/status`, true);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as StatusJson;
      st.liked = parsed.liked;
      st.favorited = parsed.favorited;
    }
    return st;
  }

  static async toggleLike(museumId: number, objectId: string, like: boolean): Promise<WriteResult> {
    if (!ApiClient.isOnline()) {
      const wr = new WriteResult();
      wr.success = false;
      wr.message = OFFLINE_MSG;
      return wr;
    }
    const path = `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}/like`;
    const empty = new EmptyPayload();
    let res: HttpRawResponse | null = null;
    if (like) {
      res = await ApiClient.postWrite(path, JSON.stringify(empty), true);
    } else {
      res = await ApiClient.deleteWrite(path, true);
    }
    const wr = ApiClient.parseWriteResult(res, OFFLINE_MSG);
    if (wr.success) {
      UserSession.bumpProfileRefresh();
    }
    return wr;
  }

  static async toggleFavorite(
    museumId: number,
    objectId: string,
    fav: boolean,
    folderId?: number
  ): Promise<WriteResult> {
    if (!ApiClient.isOnline()) {
      const wr = new WriteResult();
      wr.success = false;
      wr.message = OFFLINE_MSG;
      return wr;
    }
    const path = `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}/favorite`;
    let res: HttpRawResponse | null = null;
    if (fav) {
      const body: FolderMoveBody | EmptyPayload =
        folderId !== undefined ? { folderId: folderId } : new EmptyPayload();
      res = await ApiClient.postWrite(path, JSON.stringify(body), true);
    } else {
      res = await ApiClient.deleteWrite(path, true);
    }
    const wr = ApiClient.parseWriteResult(res, OFFLINE_MSG);
    if (wr.success) {
      UserSession.bumpProfileRefresh();
    }
    return wr;
  }

  static async addComment(
    museumId: number,
    objectId: string,
    content: string,
    parentId?: number
  ): Promise<WriteResult> {
    if (!ApiClient.isOnline()) {
      const wr = new WriteResult();
      wr.success = false;
      wr.message = OFFLINE_MSG;
      return wr;
    }
    const payload = new CommentPayload(content, parentId);
    const res = await ApiClient.postWrite(
      `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}/comments`,
      JSON.stringify(payload), true);
    const wr = ApiClient.parseWriteResult(res, OFFLINE_MSG);
    if (res !== null) {
      try {
        const parsed = JSON.parse(res.body) as MessageJson;
        if (parsed.message !== undefined && parsed.message.length > 0) {
          wr.message = parsed.message;
        }
        if (parsed.rejectReason !== undefined && parsed.rejectReason.length > 0) {
          wr.rejectReason = parsed.rejectReason;
          if (wr.message.length === 0) {
            wr.message = parsed.rejectReason;
          }
        }
      } catch (e) {
        // ignore parse errors
      }
    }
    if (wr.success) {
      UserSession.bumpProfileRefresh();
    }
    return wr;
  }

  static async deleteComment(commentId: number): Promise<WriteResult> {
    if (!ApiClient.isOnline()) {
      const wr = new WriteResult();
      wr.success = false;
      wr.message = OFFLINE_MSG;
      return wr;
    }
    const res = await ApiClient.deleteWrite(`/api/user/comments/${commentId}`, true);
    const wr = ApiClient.parseWriteResult(res, OFFLINE_MSG);
    if (wr.success) {
      UserSession.bumpProfileRefresh();
    }
    return wr;
  }

  static refToArtifact(ref: UserArtifactRef): ArtifactItem {
    return {
      museumId: ref.museumId,
      objectId: ref.objectId,
      title: ref.title,
      artist: '',
      dynasty: ref.dynasty,
      period: '',
      type: ref.type,
      material: '',
      culture: '',
      description: '',
      dimensions: '',
      museum: '',
      location: '',
      imageUrl: ref.imageUrl,
      imagePath: ref.imagePath,
      detailUrl: ''
    };
  }

  static async getFavorites(folderId?: number): Promise<UserRefListMeta> {
    let path = '/api/user/favorites';
    if (folderId !== undefined) {
      path += `?folderId=${folderId}`;
    }
    const json = await ApiClient.getJson(path, true);
    if (json !== null && ApiClient.getCode(json) === 0) {
      return MuseumService.parseRefListMeta(json);
    }
    return new UserRefListMeta();
  }

  static async getFavoriteFolders(): Promise<FavoriteFolder[]> {
    const json = await ApiClient.getJson('/api/user/favorite-folders', true);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as FolderListJson;
      return parsed.data ?? [];
    }
    return [];
  }

  static async createFavoriteFolder(name: string): Promise<WriteResult> {
    const wr = new WriteResult();
    if (!ApiClient.isOnline()) {
      wr.success = false;
      wr.message = OFFLINE_MSG;
      return wr;
    }
    const res = await ApiClient.postWrite(
      '/api/user/favorite-folders',
      JSON.stringify({ name: name }),
      true);
    return ApiClient.parseWriteResult(res, OFFLINE_MSG);
  }

  static async moveFavoriteToFolder(
    museumId: number,
    objectId: string,
    folderId: number
  ): Promise<WriteResult> {
    if (!ApiClient.isOnline()) {
      const wr = new WriteResult();
      wr.success = false;
      wr.message = OFFLINE_MSG;
      return wr;
    }
    const body: FolderMoveBody = { folderId: folderId };
    const res = await ApiClient.putWrite(
      `/api/artifacts/${museumId}/${encodeURIComponent(objectId)}/favorite-folder`,
      JSON.stringify(body),
      true);
    return ApiClient.parseWriteResult(res, OFFLINE_MSG);
  }

  static async getLikes(): Promise<UserRefListMeta> {
    const json = await ApiClient.getJson('/api/user/likes', true);
    if (json !== null && ApiClient.getCode(json) === 0) {
      return MuseumService.parseRefListMeta(json);
    }
    return new UserRefListMeta();
  }

  static async recordBrowse(artifact: ArtifactItem): Promise<void> {
    const ok = await BrowseHistoryStore.add(artifact);
    if (ok) {
      UserSession.bumpProfileRefresh();
    }
  }

  static async getBrowseHistory(): Promise<UserRefListMeta> {
    const meta = new UserRefListMeta();
    meta.items = await BrowseHistoryStore.list();
    meta.total = meta.items.length;
    return meta;
  }

  static async clearBrowseHistory(): Promise<WriteResult> {
    const wr = new WriteResult();
    const ok = await BrowseHistoryStore.clear();
    wr.success = ok;
    wr.message = ok ? '浏览记录已清空' : '清空失败';
    if (ok) {
      UserSession.bumpProfileRefresh();
    }
    return wr;
  }

  static async getMyComments(): Promise<UserCommentListMeta> {
    const json = await ApiClient.getJson('/api/user/comments', true);
    if (json !== null && ApiClient.getCode(json) === 0) {
      return MuseumService.parseCommentListMeta(json);
    }
    return new UserCommentListMeta();
  }

  static async getMyPhotos(): Promise<UserPhotoItem[]> {
    const json = await ApiClient.getJson('/api/user/photos', true);
    if (json !== null && ApiClient.getCode(json) === 0) {
      const parsed = JSON.parse(json) as PhotoListJson;
      return parsed.data;
    }
    return [];
  }

  static async uploadPhoto(
    description: string,
    location: string,
    museumId: number,
    objectId: string,
    imageBase64: string
  ): Promise<WriteResult> {
    if (!ApiClient.isOnline()) {
      const wr = new WriteResult();
      wr.success = false;
      wr.message = OFFLINE_MSG;
      return wr;
    }
    const body: UploadPhotoBody = {
      description: description,
      location: location,
      museumId: museumId,
      objectId: objectId,
      imageBase64: imageBase64
    };
    const res = await ApiClient.postWrite('/api/user/photos', JSON.stringify(body), true);
    const wr = ApiClient.parseWriteResult(res, OFFLINE_MSG);
    if (res !== null) {
      try {
        const parsed = JSON.parse(res.body) as MessageJson;
        if (parsed.message !== undefined && parsed.message.length > 0) {
          wr.message = parsed.message;
        }
        if (parsed.rejectReason !== undefined && parsed.rejectReason.length > 0) {
          wr.rejectReason = parsed.rejectReason;
        }
      } catch (e) {
        // ignore parse errors
      }
    }
    if (wr.success) {
      UserSession.bumpProfileRefresh();
    }
    return wr;
  }
}
