import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { audio } from '@kit.AudioKit';

const SESSION_ID: string = 'museum_voice_search';
const READ_SIZE: number = 1280;
const LISTEN_MS: number = 8000;

export class SpeechSearchService {
  private static asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private static capturer: audio.AudioCapturer | null = null;
  private static listening: boolean = false;
  private static resultHandler: ((text: string, isFinal: boolean) => void) | null = null;
  private static stopTimer: number = -1;
  private static finalReceived: boolean = false;

  static isListening(): boolean {
    return SpeechSearchService.listening;
  }

  static async ensureMicPermission(context: common.UIAbilityContext): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Permissions[] = ['ohos.permission.MICROPHONE'];
    const result = await atManager.requestPermissionsFromUser(context, permissions);
    if (result.authResults.length === 0) {
      return false;
    }
    return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  private static async ensureEngine(): Promise<boolean> {
    if (SpeechSearchService.asrEngine !== null) {
      return true;
    }
    try {
      const engine = await speechRecognizer.createEngine({
        language: 'zh-CN',
        online: 1
      });
      engine.setListener({
        onStart: () => {
        },
        onEvent: () => {
        },
        onResult: (_sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
          if (SpeechSearchService.resultHandler !== null && result.result.length > 0) {
            SpeechSearchService.resultHandler(result.result, result.isFinal || result.isLast);
          }
          if (result.isFinal || result.isLast) {
            SpeechSearchService.finalReceived = true;
          }
        },
        onComplete: () => {
          SpeechSearchService.listening = false;
          if (!SpeechSearchService.finalReceived && SpeechSearchService.resultHandler !== null) {
            SpeechSearchService.resultHandler('', true);
          }
          SpeechSearchService.finalReceived = false;
        },
        onError: () => {
          SpeechSearchService.listening = false;
          if (SpeechSearchService.resultHandler !== null) {
            SpeechSearchService.resultHandler('', true);
          }
          SpeechSearchService.finalReceived = false;
        }
      });
      SpeechSearchService.asrEngine = engine;
      return true;
    } catch (e) {
      try {
        const engine = await speechRecognizer.createEngine({
          language: 'zh-CN',
          online: 0
        });
        engine.setListener({
          onStart: () => {
          },
          onEvent: () => {
          },
          onResult: (_sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
            if (SpeechSearchService.resultHandler !== null && result.result.length > 0) {
              SpeechSearchService.resultHandler(result.result, result.isFinal || result.isLast);
            }
            if (result.isFinal || result.isLast) {
              SpeechSearchService.finalReceived = true;
            }
          },
          onComplete: () => {
            SpeechSearchService.listening = false;
            if (!SpeechSearchService.finalReceived && SpeechSearchService.resultHandler !== null) {
              SpeechSearchService.resultHandler('', true);
            }
            SpeechSearchService.finalReceived = false;
          },
          onError: () => {
            SpeechSearchService.listening = false;
            if (SpeechSearchService.resultHandler !== null) {
              SpeechSearchService.resultHandler('', true);
            }
            SpeechSearchService.finalReceived = false;
          }
        });
        SpeechSearchService.asrEngine = engine;
        return true;
      } catch (err) {
        return false;
      }
    }
  }

  private static async ensureCapturer(): Promise<boolean> {
    if (SpeechSearchService.capturer !== null) {
      return true;
    }
    try {
      const streamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };
      const capturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      };
      SpeechSearchService.capturer = await audio.createAudioCapturer({
        streamInfo: streamInfo,
        capturerInfo: capturerInfo
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  private static async pumpAudio(): Promise<void> {
    while (SpeechSearchService.listening && SpeechSearchService.capturer !== null &&
      SpeechSearchService.asrEngine !== null) {
      try {
        const buffer = await SpeechSearchService.capturer.read(READ_SIZE, true);
        if (buffer.byteLength > 0) {
          SpeechSearchService.asrEngine.writeAudio(SESSION_ID, new Uint8Array(buffer));
        }
      } catch (e) {
        break;
      }
    }
  }

  static async startListen(onResult: (text: string, isFinal: boolean) => void): Promise<boolean> {
    if (SpeechSearchService.listening) {
      return true;
    }
    const engineReady = await SpeechSearchService.ensureEngine();
    const capturerReady = await SpeechSearchService.ensureCapturer();
    if (!engineReady || !capturerReady || SpeechSearchService.asrEngine === null ||
      SpeechSearchService.capturer === null) {
      return false;
    }
    SpeechSearchService.resultHandler = onResult;
    SpeechSearchService.finalReceived = false;
    SpeechSearchService.listening = true;
    try {
      SpeechSearchService.asrEngine.startListening({
        sessionId: SESSION_ID,
        audioInfo: {
          audioType: 'pcm',
          sampleRate: 16000,
          soundChannel: 1,
          sampleBit: 16
        }
      });
      await SpeechSearchService.capturer.start();
      SpeechSearchService.pumpAudio();
      SpeechSearchService.stopTimer = setTimeout(() => {
        SpeechSearchService.stopListen();
      }, LISTEN_MS);
      return true;
    } catch (e) {
      SpeechSearchService.listening = false;
      return false;
    }
  }

  static async stopListen(): Promise<void> {
    if (SpeechSearchService.stopTimer >= 0) {
      clearTimeout(SpeechSearchService.stopTimer);
      SpeechSearchService.stopTimer = -1;
    }
    SpeechSearchService.listening = false;
    if (SpeechSearchService.capturer !== null) {
      try {
        await SpeechSearchService.capturer.stop();
      } catch (e) {
      }
    }
    if (SpeechSearchService.asrEngine !== null) {
      try {
        SpeechSearchService.asrEngine.finish(SESSION_ID);
      } catch (e) {
      }
    }
  }

  static shutdown(): void {
    SpeechSearchService.stopListen();
    if (SpeechSearchService.capturer !== null) {
      SpeechSearchService.capturer.release();
      SpeechSearchService.capturer = null;
    }
    if (SpeechSearchService.asrEngine !== null) {
      SpeechSearchService.asrEngine.shutdown();
      SpeechSearchService.asrEngine = null;
    }
    SpeechSearchService.resultHandler = null;
  }
}
