import 'dart:io';

import 'package:speech_kit_example/asset_inventory_sample.dart';

/// CLI sample for `AssetInventory.status` / `ensureAssetsInstalled`.
///
/// Run from the example package root; see `example/README.md`.
Future<void> main(List<String> args) async {
  var localeId = 'en-US';
  var install = false;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      stdout.writeln(
        'Usage: dart run bin/asset_inventory.dart '
        '[--locale|-l BCP47] [--install|-i]\n'
        '\n'
        '  --locale, -l   BCP 47 tag (default: en-US)\n'
        '  --install, -i  Run ensureAssetsInstalled if not already installed\n',
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

  final code = await runAssetInventorySample(
    localeId: localeId,
    installIfNeeded: install,
  );
  if (code == 2) {
    stderr.writeln('This sample requires macOS (AssetInventory is macOS 26+).');
  }
  exitCode = code;
}
