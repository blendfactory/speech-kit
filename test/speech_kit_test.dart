import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:speech_kit/speech_kit.dart';
import 'package:test/test.dart';

void main() {
  test('SpeechKit can be constructed', () {
    const kit = SpeechKit();
    expect(kit, isA<SpeechKit>());
  });

  test('SpeechLanguageModelPaths maps to bridge JSON keys', () {
    const o = SpeechLanguageModelPaths(
      languageModelPath: '/tmp/model',
      vocabularyPath: '/tmp/vocab',
      weight: 0.5,
    );
    expect(o.toJson(), {
      'languageModelPath': '/tmp/model',
      'vocabularyPath': '/tmp/vocab',
      'weight': 0.5,
    });
  });

  test('SpeechAnalyzerOptions maps to bridge JSON keys', () {
    const o = SpeechAnalyzerOptions(
      taskPriority: SpeechAnalyzerTaskPriority.low,
      modelRetention: SpeechAnalyzerModelRetention.lingering,
    );
    expect(o.toJson(), {
      'taskPriority': 'low',
      'modelRetention': 'lingering',
    });
  });

  test('asset and platform guard behavior', () async {
    const kit = SpeechKit();
    if (Platform.isMacOS) {
      await expectLater(
        kit.assetInventoryStatus(const []),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );
      await expectLater(
        kit.bestAvailableAudioFormat(const []),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );
      final status = await kit.assetInventoryStatus([
        const SpeechTranscriberConfiguration(
          localeId: 'en-US',
          preset: SpeechTranscriberPreset.transcription,
        ),
      ]);
      expect(status, isA<AssetInventoryStatus>());

      final dictationStatus = await kit.assetInventoryStatus([
        const DictationTranscriberConfiguration(
          localeId: 'en-US',
          preset: DictationTranscriberPreset.shortDictation,
        ),
      ]);
      expect(dictationStatus, isA<AssetInventoryStatus>());

      final vadStatus = await kit.assetInventoryStatus([
        const SpeechDetectorConfiguration(),
        const SpeechTranscriberConfiguration(
          localeId: 'en-US',
          preset: SpeechTranscriberPreset.transcription,
        ),
      ]);
      expect(vadStatus, isA<AssetInventoryStatus>());

      await expectLater(kit.endSpeechModelRetention(), completes);

      await expectLater(
        kit.prepareCustomLanguageModel(
          trainingDataAssetPath: '',
          outputLanguageModelPath: '/tmp/out',
        ),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );

      await expectLater(
        kit.prepareCustomLanguageModel(
          trainingDataAssetPath: '/tmp/in',
          outputLanguageModelPath: '/tmp/out',
          weight: 2,
        ),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );

      // Analyzer session argument validation (native analysis requires a
      // real audio file + installed assets, which we don't do in unit tests).
      expect(
        () => kit.analyzeFile(
          '',
          modules: const [],
        ),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );

      const fmt = CompatibleAudioFormat(
        sampleRate: 48000,
        channelCount: 1,
        commonFormatRawValue: 1,
        isInterleaved: true,
      );
      expect(
        () => kit.analyzePcm(
          Uint8List(0),
          format: fmt,
          modules: const [
            SpeechTranscriberConfiguration(
              localeId: 'en-US',
              preset: SpeechTranscriberPreset.transcription,
            ),
          ],
        ),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );
      expect(
        () => kit.analyzePcm(
          Uint8List(4),
          format: fmt,
          modules: const [],
        ),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );
      expect(
        () => kit.analyzePcmStream(
          const Stream.empty(),
          format: fmt,
          modules: const [],
        ),
        throwsA(
          predicate(
            (e) =>
                e is SpeechKitException &&
                e.failure == SpeechKitFailure.operationFailed,
          ),
        ),
      );
    } else {
      await expectLater(
        kit.speechRecognitionAuthorizationStatus(),
        throwsA(isA<UnsupportedError>()),
      );
    }
  });
}
