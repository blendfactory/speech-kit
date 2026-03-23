import 'dart:io';

import 'package:speech_kit_example/analyze_file_sample.dart';

/// CLI sample for `SpeechKit.analyzeFile` (local audio file path).
///
/// Place a supported audio file yourself under `example/assets/` (or anywhere)
/// and pass its path. Nothing is downloaded by this tool.
Future<void> main(List<String> args) async {
  var localeId = 'ja-JP';
  var install = false;
  String? audioPath;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      stdout.writeln(
        'Usage: dart run bin/analyze_file.dart <audio-file-path> [options]\n'
        '   or: dart run bin/analyze_file.dart --audio|-a <path> [options]\n'
        '\n'
        '  <audio-file-path>  Path to a local audio file (WAV, OGG, etc.)\n'
        '  --audio, -a        Same as positional path\n'
        '  --locale, -l       BCP 47 tag (default: ja-JP)\n'
        '  --install, -i      Run ensureAssetsInstalled before analysis\n',
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
    if ((a == '--audio' || a == '-a') && i + 1 < args.length) {
      audioPath = args[++i];
      continue;
    }
    if (!a.startsWith('-')) {
      if (audioPath != null) {
        stderr.writeln('Unexpected extra argument: $a (try --help)');
        exitCode = 64;
        return;
      }
      audioPath = a;
      continue;
    }
    stderr.writeln('Unknown argument: $a (try --help)');
    exitCode = 64;
    return;
  }

  if (audioPath == null || audioPath.isEmpty) {
    stderr.writeln('Missing audio file path. (try --help)');
    exitCode = 64;
    return;
  }

  final code = await runAnalyzeFileSample(
    audioFilePath: audioPath,
    localeId: localeId,
    installAssetsIfNeeded: install,
  );
  exitCode = code;
}
