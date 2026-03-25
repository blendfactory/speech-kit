import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

import 'package:speech_kit_example/example_common.dart';

/// Writes minimal `SFCustomLanguageModelData` training data using
/// [SpeechKit.exportCustomLanguageModelData].
///
/// Returns `0` success, `1` on error, `2` when not macOS.
Future<int> runExportCustomLmSample({
  required String localeId,
  required String outputPath,
}) async {
  if (!isMacOsSpeechKitHost) {
    printMacOsOnlyHint('export_custom_lm');
    return 2;
  }

  final out = File(outputPath);
  await out.parent.create(recursive: true);

  const kit = SpeechKit();
  final request = CustomLanguageModelExportRequest(
    localeId: localeId,
    identifier: 'com.example.speech_kit_example.custom_lm',
    version: '1',
    exportPath: out.absolute.path,
    phraseCounts: const [
      CustomLanguageModelPhraseCount(phrase: 'speech kit example', count: 10),
    ],
  );

  stdout.writeln('Exporting training data to: ${out.absolute.path}');

  try {
    await kit.exportCustomLanguageModelData(request);
    stdout.writeln(
      'Export finished. Pass this path to prepareCustomLanguageModel.',
    );
    return 0;
  } on SpeechKitException catch (e) {
    stderr.writeln('$e');
    return 1;
  }
}
