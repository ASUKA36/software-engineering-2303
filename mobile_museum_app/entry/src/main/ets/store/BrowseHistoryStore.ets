import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ArtifactItem, UserArtifactRef } from '../model/Models';

interface BrowseHistoryEntry {
  museumId: number;
  objectId: string;
  title: string;
  dynasty: string;
  type: string;
  imageUrl: string;
  imagePath: string;
  imgWeb?: string;
  viewedAt: string;
}

/** 浏览记录仅存本机 Preferences，不上传服务器。 */
export class BrowseHistoryStore {
  private static readonly PREF_NAME: string = 'browse_history';
  private static readonly KEY_ITEMS: string = 'items';
  private static readonly MAX_ITEMS: number = 100;
  private static pref: preferences.Preferences | null = null;
  private static context: common.UIAbilityContext | null = null;

  static init(context: common.UIAbilityContext): void {
    BrowseHistoryStore.context = context;
  }

  private static async ensurePref(): Promise<preferences.Preferences | null> {
    if (BrowseHistoryStore.pref !== null) {
      return BrowseHistoryStore.pref;
    }
    if (BrowseHistoryStore.context === null) {
      return null;
    }
    try {
      BrowseHistoryStore.pref =
        await preferences.getPreferences(BrowseHistoryStore.context, BrowseHistoryStore.PREF_NAME);
      return BrowseHistoryStore.pref;
    } catch (e) {
      return null;
    }
  }

  private static entryFromArtifact(artifact: ArtifactItem): BrowseHistoryEntry {
    return {
      museumId: artifact.museumId,
      objectId: artifact.objectId,
      title: artifact.title,
      dynasty: artifact.dynasty,
      type: artifact.type,
      imageUrl: artifact.imageUrl,
      imagePath: artifact.imagePath,
      imgWeb: artifact.imgWeb,
      viewedAt: new Date().toISOString()
    };
  }

  private static entryToRef(entry: BrowseHistoryEntry): UserArtifactRef {
    return {
      museumId: entry.museumId,
      objectId: entry.objectId,
      title: entry.title,
      dynasty: entry.dynasty,
      type: entry.type,
      imageUrl: entry.imageUrl,
      imagePath: entry.imagePath,
      imgWeb: entry.imgWeb,
      createdAt: entry.viewedAt
    };
  }

  private static async readEntries(): Promise<BrowseHistoryEntry[]> {
    const pref = await BrowseHistoryStore.ensurePref();
    if (pref === null) {
      return [];
    }
    try {
      const raw = await pref.get(BrowseHistoryStore.KEY_ITEMS, '[]') as string;
      const parsed = JSON.parse(raw) as BrowseHistoryEntry[];
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed;
    } catch (e) {
      return [];
    }
  }

  private static async writeEntries(entries: BrowseHistoryEntry[]): Promise<boolean> {
    const pref = await BrowseHistoryStore.ensurePref();
    if (pref === null) {
      return false;
    }
    try {
      await pref.put(BrowseHistoryStore.KEY_ITEMS, JSON.stringify(entries));
      await pref.flush();
      return true;
    } catch (e) {
      return false;
    }
  }

  static async add(artifact: ArtifactItem): Promise<boolean> {
    const key = `${artifact.museumId}_${artifact.objectId}`;
    let entries = await BrowseHistoryStore.readEntries();
    entries = entries.filter((e) => `${e.museumId}_${e.objectId}` !== key);
    entries.unshift(BrowseHistoryStore.entryFromArtifact(artifact));
    if (entries.length > BrowseHistoryStore.MAX_ITEMS) {
      entries = entries.slice(0, BrowseHistoryStore.MAX_ITEMS);
    }
    return BrowseHistoryStore.writeEntries(entries);
  }

  static async list(): Promise<UserArtifactRef[]> {
    const entries = await BrowseHistoryStore.readEntries();
    const refs: UserArtifactRef[] = [];
    for (let i = 0; i < entries.length; i++) {
      refs.push(BrowseHistoryStore.entryToRef(entries[i]));
    }
    return refs;
  }

  static async clear(): Promise<boolean> {
    return BrowseHistoryStore.writeEntries([]);
  }
}
