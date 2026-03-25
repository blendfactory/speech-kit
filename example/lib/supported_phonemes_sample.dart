import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

import 'package:speech_kit_example/example_common.dart';

/// Prints custom-language-model phonemes for a locale
/// (`SpeechKit.supportedCustomLanguagePhonemes`).
///
/// Returns `0` success, `1` on error, `2` when not macOS.
Future<int> runSupportedPhonemesSample({required String localeId}) async {
  if (!isMacOsSpeechKitHost) {
    printMacOsOnlyHint('supported_phonemes');
    return 2;
  }

  const kit = SpeechKit();
  stdout.writeln('supportedCustomLanguagePhonemes(locale: $localeId)');

  try {
    final list = await kit.supportedCustomLanguagePhonemes(localeId);
    if (list.isEmpty) {
      stdout.writeln('(empty list — check locale or OS support)');
    } else {
      list.forEach(stdout.writeln);
    }
    return 0;
  } on SpeechKitException catch (e) {
    stderr.writeln('$e');
    return 1;
  }
}
