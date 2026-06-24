export interface ArtifactItem {
  museumId: number;
  objectId: string;
  title: string;
  artist: string;
  dynasty: string;
  period: string;
  periodStartYear?: number;
  periodEndYear?: number;
  type: string;
  material: string;
  culture: string;
  description: string;
  dimensions: string;
  museum: string;
  location: string;
  imageUrl: string;
  imagePath: string;
  imageUrls?: string[];
  imagePaths?: string[];
  imageCount?: number;
  imgWeb?: string;
  imgsWeb?: string[];
  hasLocalImage?: boolean;
  detailUrl: string;
  provenance?: string;
  bibliography?: string;
  creditLine?: string;
  accessionNumber?: string;
  likeCount?: number;
  hotScore?: number;
  /** 以图搜图相似度 0~1 */
  similarity?: number;
}

export interface UserInfo {
  userId: number;
  username: string;
  nickname: string;
  email?: string;
  phone?: string;
  avatarUrl?: string;
}

export interface CommentItem {
  commentId: number;
  userId: number;
  nickname: string;
  content: string;
  createdAt: string;
  parentId?: number | null;
  replyToNickname?: string;
  replyToUserId?: number;
}

export interface UserArtifactRef {
  favoriteId?: number;
  museumId: number;
  objectId: string;
  title: string;
  dynasty: string;
  type: string;
  imageUrl: string;
  imagePath: string;
  imgWeb?: string;
  imgsWeb?: string[];
  hasLocalImage?: boolean;
  folderId?: number | null;
  createdAt?: string;
}

export interface FavoriteFolder {
  folderId: number;
  name: string;
  itemCount: number;
  sortOrder?: number;
  createdAt?: string;
}

export interface UserCommentRecord {
  commentId: number;
  museumId: number;
  objectId: string;
  artifactTitle: string;
  content: string;
  auditStatus: number;
  statusText: string;
  rejectReason: string;
  createdAt: string;
  parentId?: number | null;
  replyToNickname?: string;
}

export interface UserPhotoItem {
  photoId: number;
  museumId?: number;
  objectId?: string;
  artifactTitle?: string;
  photoUrl: string;
  description: string;
  location: string;
  status: number;
  statusText: string;
  rejectReason?: string;
  nickname?: string;
  createdAt: string;
}

export interface SearchGroup {
  type: string;
  items: ArtifactItem[];
}

export interface MuseumOption {
  museumId: number;
  name: string;
  museum: string;
  count: number;
}

export interface QaSourceInfo {
  museumName: string;
  detailUrl: string;
  objectId: string;
  imageUrl?: string;
  accessionNumber?: string;
}

export interface QaHistoryItem {
  id: number;
  role: string;
  content: string;
  intent?: string;
  entity?: string;
  sources?: QaSourceInfo[];
  createdAt?: string;
}

export class QaRecoveredAnswer {
  content: string = '';
  isFallback: boolean = false;
}

export class QaAskResult {
  success: boolean = false;
  message: string = '';
  answer: string = '';
  answerId: string = '';
  notFound: boolean = false;
  /** 服务端已写入历史但为「暂未检索到」类占位回答 */
  isFallback: boolean = false;
}

export class HttpRawResponse {
  code: number = 0;
  body: string = '';

  constructor(code: number, body: string) {
    this.code = code;
    this.body = body;
  }
}

export class SearchResult {
  items: ArtifactItem[] = [];
  groups: SearchGroup[] = [];
  total: number = 0;
  page: number = 1;
  size: number = 50;
  errorMessage: string = '';
}

export class ArtifactPageResult {
  items: ArtifactItem[] = [];
  total: number = 0;
  page: number = 1;
  size: number = 50;
}

export class LoginResult {
  token: string = '';
  user: UserInfo = { userId: 0, username: '', nickname: '' };
}

export class InteractionStatus {
  liked: boolean = false;
  favorited: boolean = false;
}

export class UserRefListMeta {
  items: UserArtifactRef[] = [];
  total: number = 0;
}

export class UserCommentListMeta {
  items: UserCommentRecord[] = [];
  total: number = 0;
}

/** 写操作结果：注册/点赞/评论/上传等 */
export class WriteResult {
  success: boolean = false;
  message: string = '';
  code: number = -1;
  rejectReason: string = '';
}

/** 登录/注册结果 */
export class AuthResult {
  login: LoginResult | null = null;
  errorMessage: string = '';
}

export class EmptyPayload {
}

export class LoginPayload {
  account: string = '';
  password: string = '';

  constructor(account: string, password: string) {
    this.account = account;
    this.password = password;
  }
}

export class RegisterPayload {
  username: string = '';
  password: string = '';
  email: string = '';
  phone: string = '';

  constructor(username: string, password: string, email: string, phone: string) {
    this.username = username;
    this.password = password;
    this.email = email;
    this.phone = phone;
  }
}

export class CommentPayload {
  content: string = '';
  parentId?: number;

  constructor(content: string, parentId?: number) {
    this.content = content;
    if (parentId !== undefined && parentId > 0) {
      this.parentId = parentId;
    }
  }
}

export class UploadPhotoPayload {
  static buildJson(
    description: string,
    location: string,
    museumId?: number,
    objectId?: string,
    imageBase64?: string
  ): string {
    let json = `{"description":"${UploadPhotoPayload.escape(description)}","location":"${UploadPhotoPayload.escape(location)}"`;
    if (museumId !== undefined && museumId > 0) {
      json += `,"museumId":${museumId}`;
    }
    if (objectId !== undefined && objectId.length > 0) {
      json += `,"objectId":"${UploadPhotoPayload.escape(objectId)}"`;
    }
    if (imageBase64 !== undefined && imageBase64.length > 0) {
      json += `,"imageBase64":"${UploadPhotoPayload.escape(imageBase64)}"`;
    }
    json += '}';
    return json;
  }

  private static escape(s: string): string {
    return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n');
  }
}
