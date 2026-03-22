import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

/// Prints current speech recognition and microphone permission status.
///
/// Returns an exit code for the CLI: `0` on success, `2` when not macOS.
Future<int> runPermissionStatusSample() async {
  if (!Platform.isMacOS) {
    return 2;
  }

  const kit = SpeechKit();
  final speech = await kit.speechRecognitionAuthorizationStatus();
  final mic = await kit.microphonePermissionStatus();
  stdout.writeln('Speech recognition: $speech');
  stdout.writeln('Microphone: $mic');
  return 0;
}
