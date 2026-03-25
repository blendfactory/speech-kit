import 'dart:io';

import 'package:speech_kit_example/supported_phonemes_sample.dart';

/// CLI for `SpeechKit.supportedCustomLanguagePhonemes`.
Future<void> main(List<String> args) async {
  var localeId = 'en-US';

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      stdout.writeln(
        'Usage: dart run bin/supported_phonemes.dart [--locale|-l BCP47]\n'
        '\n'
        '  Lists ARPAbet-style phoneme strings valid for custom\n'
        '  pronunciations in the given locale (macOS 26+).\n'
        '\n'
        '  --locale, -l   BCP 47 tag (default: en-US)\n',
      );
      return;
    }
    if ((a == '--locale' || a == '-l') && i + 1 < args.length) {
      localeId = args[++i];
      continue;
    }
    stderr.writeln('Unknown argument: $a (try --help)');
    exitCode = 64;
    return;
  }

  exitCode = await runSupportedPhonemesSample(localeId: localeId);
}
