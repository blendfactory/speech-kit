import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

/// Prints speech recognition and microphone permission status.
///
/// When speech recognition is `SpeechRecognitionPermission.notDetermined`,
/// calls `SpeechKit.requestSpeechRecognitionPermission` so the system can show
/// the permission prompt (requires `NSSpeechRecognitionUsageDescription` in a
/// real app bundle; CLI runs may not show a dialog depending on context).
///
/// When the microphone is `MicrophonePermission.undetermined`, calls
/// `SpeechKit.requestMicrophonePermission` (requires microphone usage strings
/// in a real app; CLI behavior may vary).
///
/// Returns an exit code for the CLI: `0` on success, `2` when not macOS.
Future<int> runPermissionStatusSample() async {
  if (!Platform.isMacOS) {
    return 2;
  }

  const kit = SpeechKit();
  var speech = await kit.speechRecognitionAuthorizationStatus();
  stdout.writeln('Speech recognition (before): $speech');

  if (speech == SpeechRecognitionPermission.notDetermined) {
    stdout.writeln('Requesting speech recognition permission...');
    speech = await kit.requestSpeechRecognitionPermission();
    stdout.writeln('Speech recognition (after request): $speech');
  }

  if (speech == SpeechRecognitionPermission.denied ||
      speech == SpeechRecognitionPermission.restricted) {
    stderr.writeln(
      'Speech recognition is not available. Check System Settings → '
      'Privacy & Security → Speech Recognition.',
    );
  }

  var mic = await kit.microphonePermissionStatus();
  stdout.writeln('Microphone (before): $mic');

  if (mic == MicrophonePermission.undetermined) {
    stdout.writeln('Requesting microphone permission...');
    await kit.requestMicrophonePermission();
    mic = await kit.microphonePermissionStatus();
    stdout.writeln('Microphone (after request): $mic');
  }

  if (mic == MicrophonePermission.denied) {
    stderr.writeln(
      'Microphone access is denied. Check System Settings → '
      'Privacy & Security → Microphone.',
    );
  }

  return 0;
}
