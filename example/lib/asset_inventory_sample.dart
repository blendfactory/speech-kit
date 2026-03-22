import 'dart:io';

import 'package:speech_kit/speech_kit.dart';

/// Demonstrates `SpeechKit.assetInventoryStatus` and optional
/// `ensureAssetsInstalled` for a single `SpeechTranscriberConfiguration`.
///
/// Returns `0` on success, `2` when not macOS (or unsupported host), `1` on
/// `SpeechKitException`.
Future<int> runAssetInventorySample({
  required String localeId,
  required bool installIfNeeded,
}) async {
  if (!Platform.isMacOS) {
    return 2;
  }

  const kit = SpeechKit();
  final modules = [
    SpeechTranscriberConfiguration(
      localeId: localeId,
      preset: SpeechTranscriberPreset.transcription,
    ),
  ];

  stdout.writeln('AssetInventory for locale=$localeId (transcription preset)');

  try {
    final status = await kit.assetInventoryStatus(modules);
    stdout.writeln('Status: $status');

    if (installIfNeeded) {
      if (status == AssetInventoryStatus.installed) {
        stdout.writeln('No install step needed (already installed).');
      } else {
        stdout.writeln(
          'Calling ensureAssetsInstalled (may download on-device models)...',
        );
        await kit.ensureAssetsInstalled(modules);
        final after = await kit.assetInventoryStatus(modules);
        stdout.writeln('Status after ensureAssetsInstalled: $after');
      }
    }
  } on SpeechKitException catch (e) {
    stderr.writeln('$e');
    return 1;
  }

  return 0;
}
