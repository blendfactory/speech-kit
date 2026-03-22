import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:speech_kit/speech_kit.dart';

Future<void> main() async {
  const kit = SpeechKit();
  developer.log('$kit', name: 'speech_kit.example');

  if (!Platform.isMacOS) {
    developer.log(
      'Native permission sample runs on macOS only.',
      name: 'speech_kit.example',
    );
    return;
  }

  final speech = await kit.speechRecognitionAuthorizationStatus();
  final mic = await kit.microphonePermissionStatus();
  developer.log(
    'Speech: $speech, microphone: $mic',
    name: 'speech_kit.example',
  );
}
