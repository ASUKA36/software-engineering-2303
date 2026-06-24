import { textToSpeech } from '@kit.CoreSpeechKit';
import { ArtifactItem } from '../model/Models';

export class SpeechGuideService {
  private static engine: textToSpeech.TextToSpeechEngine | null = null;
  private static speaking: boolean = false;
  private static stateListener: ((speaking: boolean) => void) | null = null;

  static setStateListener(listener: ((speaking: boolean) => void) | null): void {
    SpeechGuideService.stateListener = listener;
  }

  private static notifyState(speaking: boolean): void {
    SpeechGuideService.speaking = speaking;
    if (SpeechGuideService.stateListener !== null) {
      SpeechGuideService.stateListener(speaking);
    }
  }

  static isSpeaking(): boolean {
    return SpeechGuideService.speaking;
  }

  static buildGuideText(artifact: ArtifactItem): string {
    let text = `${artifact.title}。`;
    if (artifact.dynasty.length > 0) {
      text += `朝代${artifact.dynasty}。`;
    }
    if (artifact.period.length > 0) {
      text += `年代${artifact.period}。`;
    }
    if (artifact.type.length > 0) {
      text += `类型${artifact.type}。`;
    }
    if (artifact.material.length > 0) {
      text += `材质${artifact.material}。`;
    }
    if (artifact.dimensions.length > 0) {
      text += `尺寸${artifact.dimensions}。`;
    }
    if (artifact.museum.length > 0) {
      text += `馆藏${artifact.museum}。`;
    }
    text += artifact.description;
    if (text.length > 2000) {
      return text.substring(0, 2000);
    }
    return text;
  }

  private static async ensureEngine(): Promise<boolean> {
    if (SpeechGuideService.engine !== null) {
      return true;
    }
    try {
      const engine = await textToSpeech.createEngine({
        language: 'zh-CN',
        person: 0,
        online: 1
      });
      engine.setListener({
        onStart: () => {
          SpeechGuideService.notifyState(true);
        },
        onComplete: () => {
          SpeechGuideService.notifyState(false);
        },
        onStop: () => {
          SpeechGuideService.notifyState(false);
        },
        onError: () => {
          SpeechGuideService.notifyState(false);
        }
      });
      SpeechGuideService.engine = engine;
      return true;
    } catch (e) {
      try {
        const engine = await textToSpeech.createEngine({
          language: 'zh-CN',
          person: 0,
          online: 0
        });
        engine.setListener({
          onStart: () => {
            SpeechGuideService.notifyState(true);
          },
          onComplete: () => {
            SpeechGuideService.notifyState(false);
          },
          onStop: () => {
            SpeechGuideService.notifyState(false);
          },
          onError: () => {
            SpeechGuideService.notifyState(false);
          }
        });
        SpeechGuideService.engine = engine;
        return true;
      } catch (err) {
        return false;
      }
    }
  }

  static async speakArtifact(artifact: ArtifactItem): Promise<boolean> {
    const ready = await SpeechGuideService.ensureEngine();
    if (!ready || SpeechGuideService.engine === null) {
      return false;
    }
    const content = SpeechGuideService.buildGuideText(artifact);
    if (content.length === 0) {
      return false;
    }
    if (SpeechGuideService.engine.isBusy()) {
      SpeechGuideService.engine.stop();
    }
    try {
      SpeechGuideService.engine.speak(content, {
        requestId: `guide_${Date.now()}`
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static stop(): void {
    if (SpeechGuideService.engine !== null && SpeechGuideService.engine.isBusy()) {
      SpeechGuideService.engine.stop();
    }
    SpeechGuideService.notifyState(false);
  }

  static shutdown(): void {
    SpeechGuideService.stop();
    if (SpeechGuideService.engine !== null) {
      SpeechGuideService.engine.shutdown();
      SpeechGuideService.engine = null;
    }
  }
}
