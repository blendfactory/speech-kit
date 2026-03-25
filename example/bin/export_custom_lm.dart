import 'dart:io';

import 'package:speech_kit_example/export_custom_lm_sample.dart';

/// CLI for `SpeechKit.exportCustomLanguageModelData` (minimal phrase list).
Future<void> main(List<String> args) async {
  var localeId = 'en-US';
  String? outputPath;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      stdout.writeln(
        'Usage: dart run bin/export_custom_lm.dart --output|-o <path> '
        '[--locale|-l BCP47]\n'
        '\n'
        '  Writes a small custom language model training file '
        '(phrase counts only).\n'
        '  macOS 26+.\n'
        '\n'
        '  --output, -o   Output file path (required)\n'
        '  --locale, -l   BCP 47 tag (default: en-US)\n',
      );
      return;
    }
    if ((a == '--output' || a == '-o') && i + 1 < args.length) {
      outputPath = args[++i];
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

  if (outputPath == null || outputPath.isEmpty) {
    stderr.writeln('Missing --output <path> (try --help)');
    exitCode = 64;
    return;
  }

  exitCode = await runExportCustomLmSample(
    localeId: localeId,
    outputPath: outputPath,
  );
}
