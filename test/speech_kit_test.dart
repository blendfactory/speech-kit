import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:speech_kit/speech_kit.dart';
import 'package:test/test.dart';

void main() {
  test('SpeechKit can be constructed', () {
    const kit = SpeechKit();
    expect(kit, isA<SpeechKit>());
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
    } else {
      await expectLater(
        kit.speechRecognitionAuthorizationStatus(),
        throwsA(isA<UnsupportedError>()),
      );
    }
  });
}
