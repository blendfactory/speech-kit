import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

/// Runs [SpeechKit.analyzeFile] on a local audio file (macOS 26+).
///
/// Returns exit code: `0` success, `1` error, `2` unsupported platform.
Future<int> runAnalyzeFileSample({
  required String audioFilePath,
  required String localeId,
  required bool installAssetsIfNeeded,
}) async {
  if (!Platform.isMacOS) {
    stderr.writeln(
      'analyze_file sample requires macOS (SpeechAnalyzer file analysis).',
    );
    return 2;
  }

  final file = File(audioFilePath);
  if (!file.existsSync()) {
    stderr.writeln('Audio file not found: $audioFilePath');
    return 1;
  }

  final absolutePath = file.absolute.path;
  const kit = SpeechKit();

  final modules = <SpeechModuleConfiguration>[
    SpeechTranscriberConfiguration(
      localeId: localeId,
      preset: SpeechTranscriberPreset.transcription,
    ),
  ];

  try {
    if (installAssetsIfNeeded) {
      stdout.writeln('Ensuring on-device assets (may download)…');
      await kit.ensureAssetsInstalled(modules);
    }

    stdout.writeln('Analyzing: $absolutePath');
    final session = kit.analyzeFile(
      absolutePath,
      modules: modules,
      // Optional bias vocabulary:
      // analysisContext: const AnalysisContext(
      //   contextualStringsByTag: {'general': ['AcmeCorp']},
      // ),
    );

    await for (final segment in session.results) {
      final startMs = segment.rangeStart.inMilliseconds;
      final durMs = segment.rangeDuration.inMilliseconds;
      stdout.writeln('[$startMs ms +$durMs ms] ${segment.text}');
    }

    await session.finalizeAndFinish();
    stdout.writeln('Done.');
    return 0;
  } on SpeechKitException catch (e) {
    stderr.writeln('SpeechKitException: $e');
    return 1;
  } on Object catch (e, st) {
    stderr.writeln('Error: $e\n$st');
    return 1;
  }
}
