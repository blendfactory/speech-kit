import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

import 'package:speech_kit_example/example_common.dart';

/// Prints [SpeechKit.bestAvailableAudioFormat] for a transcriber module list.
///
/// Returns `0` success, `1` on error, `2` when not macOS.
///
/// When [installIfNeeded] is true, calls `SpeechKit.ensureAssetsInstalled`
/// first for the transcriber module list built below.
Future<int> runBestAudioFormatSample({
  required String localeId,
  required bool installIfNeeded,
}) async {
  if (!isMacOsSpeechKitHost) {
    printMacOsOnlyHint('best_audio_format');
    return 2;
  }

  const kit = SpeechKit();
  final modules = <SpeechModuleConfiguration>[
    SpeechTranscriberConfiguration(
      localeId: localeId,
      preset: SpeechTranscriberPreset.transcription,
    ),
  ];

  stdout.writeln(
    'bestAvailableAudioFormat for locale=$localeId (transcription)',
  );

  try {
    if (installIfNeeded) {
      stdout.writeln('Ensuring on-device assets (may download)…');
      await kit.ensureAssetsInstalled(modules);
    }

    final format = await kit.bestAvailableAudioFormat(modules);
    stdout.writeln('Sample rate: ${format.sampleRate} Hz');
    stdout.writeln('Channels: ${format.channelCount}');
    stdout.writeln('Common format raw value: ${format.commonFormatRawValue}');
    stdout.writeln('Interleaved: ${format.isInterleaved}');
    return 0;
  } on SpeechKitException catch (e) {
    stderr.writeln('$e');
    return 1;
  }
}
