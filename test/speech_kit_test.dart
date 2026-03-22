import 'dart:io' show Platform;

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
      final status = await kit.assetInventoryStatus([
        const SpeechTranscriberConfiguration(
          localeId: 'en-US',
          preset: SpeechTranscriberPreset.transcription,
        ),
      ]);
      expect(status, isA<AssetInventoryStatus>());
    } else {
      await expectLater(
        kit.speechRecognitionAuthorizationStatus(),
        throwsA(isA<UnsupportedError>()),
      );
    }
  });
}
