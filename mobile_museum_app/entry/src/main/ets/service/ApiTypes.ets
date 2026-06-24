import { ArtifactItem, CommentItem, FavoriteFolder, MuseumOption, SearchGroup, UserArtifactRef, UserCommentRecord, UserInfo, UserPhotoItem } from '../model/Models';

export interface ArtifactListJson {
  code: number;
  data: ArtifactItem[];
  total?: number;
  page?: number;
  size?: number;
}

export interface ArtifactDetailJson {
  code: number;
  data: ArtifactItem;
}

export interface SearchJson {
  code: number;
  data: ArtifactItem[];
  groups?: SearchGroup[];
  total?: number;
  page?: number;
  size?: number;
}

export interface StringListJson {
  code: number;
  data: string[];
}

export interface MuseumListJson {
  code: number;
  data: MuseumOption[];
}

export interface LoginJson {
  code: number;
  token: string;
  user: UserInfo;
  message?: string;
}

export interface RegisterBody {
  username: string;
  password: string;
  email: string;
  phone: string;
}

export interface LoginBody {
  account: string;
  password: string;
}

export interface ApiEnvelope {
  code?: number;
  message?: string;
}

export interface StatusJson {
  code: number;
  liked: boolean;
  favorited: boolean;
}

export interface MessageJson {
  code: number;
  message: string;
  rejectReason?: string;
}

export interface CommentListJson {
  code: number;
  data: CommentItem[];
}

export interface RefListJson {
  code: number;
  data: UserArtifactRef[];
  total?: number;
  foldersEnabled?: boolean;
}

export interface FolderListJson {
  code: number;
  data: FavoriteFolder[];
  foldersEnabled?: boolean;
}

export interface FolderJson {
  code: number;
  data: FavoriteFolder;
}

export interface FolderMoveBody {
  folderId: number;
}

export interface PhotoListJson {
  code: number;
  data: UserPhotoItem[];
}

export interface CommentRecordListJson {
  code: number;
  data: UserCommentRecord[];
  total?: number;
}

export interface UploadPhotoBody {
  description: string;
  location: string;
  museumId?: number;
  objectId?: string;
  imageBase64: string;
}

export interface ImageSearchBody {
  imageBase64: string;
  page?: number;
  size?: number;
  museum_id?: number[];
  dynasty?: string[];
}

export interface ImageSearchJson {
  code: number;
  data: ArtifactItem[];
  total?: number;
  page?: number;
  size?: number;
  message?: string;
}
