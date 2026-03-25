import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

import 'package:speech_kit_example/example_common.dart';

/// Calls [SpeechKit.endSpeechModelRetention] (releases retained on-device
/// models).
///
/// Returns `0` success, `1` on error, `2` when not macOS.
Future<int> runEndModelRetentionSample() async {
  if (!isMacOsSpeechKitHost) {
    printMacOsOnlyHint('end_model_retention');
    return 2;
  }

  const kit = SpeechKit();
  stdout.writeln('Calling endSpeechModelRetention()…');

  try {
    await kit.endSpeechModelRetention();
    stdout.writeln('Done.');
    return 0;
  } on SpeechKitException catch (e) {
    stderr.writeln('$e');
    return 1;
  }
}
