import 'dart:io';

import 'package:speech_kit_example/end_model_retention_sample.dart';

/// CLI for `SpeechKit.endSpeechModelRetention`.
Future<void> main(List<String> args) async {
  if (args.any((a) => a == '--help' || a == '-h')) {
    stdout.writeln(
      'Usage: dart run bin/end_model_retention.dart\n'
      '\n'
      '  Calls SpeechModels.endRetention() via SpeechKit. Use after analysis\n'
      '  when you no longer need models kept with lingering / process-lifetime\n'
      '  retention (macOS 26+).\n',
    );
    return;
  }
  if (args.isNotEmpty) {
    stderr.writeln('Unknown argument (try --help)');
    exitCode = 64;
    return;
  }

  exitCode = await runEndModelRetentionSample();
}
