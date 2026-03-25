import 'dart:io';

import 'package:speech_kit/speech_kit.dart';
import 'package:speech_kit_example/analyze_file_sample.dart';

/// CLI sample for `SpeechKit.analyzeFile` (local audio file path).
///
/// Place a supported audio file yourself under `example/assets/` (or anywhere)
/// and pass its path. Nothing is downloaded by this tool.
Future<void> main(List<String> args) async {
  var localeId = 'ja-JP';
  var install = false;
  String? audioPath;
  String? biasWordsCsv;
  SpeechAnalyzerTaskPriority? taskPriority;
  SpeechAnalyzerModelRetention? modelRetention;

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
        '  --install, -i      Run ensureAssetsInstalled before analysis\n'
        '  --bias, -b         Comma-separated bias words for tag "general"\n'
        '                     (AnalysisContext)\n'
        '  --task-priority    high | medium | low | background '
        '(SpeechAnalyzer)\n'
        '  --model-retention  whileInUse | lingering | '
        'processLifetime\n',
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
    if ((a == '--bias' || a == '-b') && i + 1 < args.length) {
      biasWordsCsv = args[++i];
      continue;
    }
    if (a == '--task-priority' && i + 1 < args.length) {
      taskPriority = _parseTaskPriority(args[++i]);
      if (taskPriority == null) {
        stderr.writeln('Invalid --task-priority (use --help)');
        exitCode = 64;
        return;
      }
      continue;
    }
    if (a == '--model-retention' && i + 1 < args.length) {
      modelRetention = _parseModelRetention(args[++i]);
      if (modelRetention == null) {
        stderr.writeln('Invalid --model-retention (use --help)');
        exitCode = 64;
        return;
      }
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

  AnalysisContext? analysisContext;
  if (biasWordsCsv != null && biasWordsCsv.isNotEmpty) {
    final words = biasWordsCsv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (words.isNotEmpty) {
      analysisContext = AnalysisContext(
        contextualStringsByTag: {'general': words},
      );
    }
  }

  SpeechAnalyzerOptions? analyzerOptions;
  if (taskPriority != null || modelRetention != null) {
    analyzerOptions = SpeechAnalyzerOptions(
      taskPriority: taskPriority ?? SpeechAnalyzerTaskPriority.medium,
      modelRetention: modelRetention ?? SpeechAnalyzerModelRetention.whileInUse,
    );
  }

  final code = await runAnalyzeFileSample(
    audioFilePath: audioPath,
    localeId: localeId,
    installAssetsIfNeeded: install,
    analyzerOptions: analyzerOptions,
    analysisContext: analysisContext,
  );
  exitCode = code;
}

SpeechAnalyzerTaskPriority? _parseTaskPriority(String raw) {
  for (final v in SpeechAnalyzerTaskPriority.values) {
    if (v.name == raw) {
      return v;
    }
  }
  return null;
}

SpeechAnalyzerModelRetention? _parseModelRetention(String raw) {
  for (final v in SpeechAnalyzerModelRetention.values) {
    if (v.name == raw) {
      return v;
    }
  }
  return null;
}
