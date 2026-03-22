import 'package:speech_kit/speech_kit.dart';
import 'package:test/test.dart';

void main() {
  test('SpeechKit can be constructed', () {
    const kit = SpeechKit();
    expect(kit, isA<SpeechKit>());
  });
}
