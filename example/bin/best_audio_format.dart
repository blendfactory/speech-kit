import 'dart:io';

import 'package:speech_kit_example/best_audio_format_sample.dart';

/// CLI for `SpeechKit.bestAvailableAudioFormat`.
Future<void> main(List<String> args) async {
  var localeId = 'en-US';
  var install = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      stdout.writeln(
        'Usage: dart run bin/best_audio_format.dart [--locale|-l BCP47] '
        '[--install|-i]\n'
        '\n'
        '  --locale, -l   BCP 47 tag (default: en-US)\n'
        '  --install, -i  Run ensureAssetsInstalled if models are missing\n',
      );
      return;
    }
    if (a == '--install' || a == '-i') {
      install = true;
      continue;
    }
    if ((a == '--locale' || a == '-l') && i + 1 < args.length) {
      localeId = args[++i];
      continue;
    }
    stderr.writeln('Unknown argument: $a (try --help)');
    exitCode = 64;
    return;
  }

  exitCode = await runBestAudioFormatSample(
    localeId: localeId,
    installIfNeeded: install,
  );
}
