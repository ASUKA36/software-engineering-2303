import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

export class ImagePickerUtil {
  /** 打开系统相册，返回 JPEG 的 Base64（无 data: 前缀） */
  static async pickImageBase64(): Promise<string> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select(options);
      if (result === null || result.photoUris === undefined || result.photoUris.length === 0) {
        return '';
      }
      return await ImagePickerUtil.uriToBase64(result.photoUris[0]);
    } catch (e) {
      return '';
    }
  }

  static async uriToBase64(uri: string): Promise<string> {
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buf);
      const helper = new util.Base64Helper();
      return helper.encodeToString(new Uint8Array(buf));
    } catch (e) {
      return '';
    } finally {
      if (file !== undefined) {
        fileIo.closeSync(file);
      }
    }
  }
}
