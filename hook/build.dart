import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }
    if (input.config.code.targetOS != OS.macOS) {
      return;
    }

    final packageRoot = input.packageRoot.toFilePath();
    final outDir = input.outputDirectory;
    output.dependencies.add(
      input.packageRoot.resolve('native/speech_kit_permissions.m'),
    );
    output.dependencies.add(
      input.packageRoot.resolve('native/speech_kit_assets.swift'),
    );
    await Directory.fromUri(outDir).create(recursive: true);

    final permObject = outDir.resolve('speech_kit_permissions.o');
    final dylibOut = outDir.resolve(
      OS.macOS.dylibFileName(input.packageName),
    );

    final sdkResult = await Process.run(
      'xcrun',
      ['--sdk', 'macosx', '--show-sdk-path'],
    );
    if (sdkResult.exitCode != 0) {
      throw StateError('xcrun macosx sdk: ${sdkResult.stderr}');
    }
    final sdk = (sdkResult.stdout as String).trim();

    final arch = input.config.code.targetArchitecture.name;
    final swiftTripleArch = arch == 'x64' ? 'x86_64' : arch;
    final swiftTarget = '$swiftTripleArch-apple-macosx26.0';

    final clang = await Process.run('clang', [
      '-c',
      '-fobjc-arc',
      '-o',
      permObject.toFilePath(),
      '$packageRoot/native/speech_kit_permissions.m',
      '-isysroot',
      sdk,
    ]);
    if (clang.exitCode != 0) {
      throw StateError(
        'clang speech_kit_permissions.m failed:\n'
        '${clang.stdout}\n${clang.stderr}',
      );
    }

    final swiftc = await Process.run('swiftc', [
      '-emit-library',
      '-o',
      dylibOut.toFilePath(),
      '-module-name',
      'SpeechKitNative',
      permObject.toFilePath(),
      '$packageRoot/native/speech_kit_assets.swift',
      '-target',
      swiftTarget,
      '-sdk',
      sdk,
      '-framework',
      'Foundation',
      '-framework',
      'Speech',
      '-framework',
      'AVFAudio',
      '-O',
    ]);
    if (swiftc.exitCode != 0) {
      throw StateError(
        'swiftc link failed:\n${swiftc.stdout}\n${swiftc.stderr}',
      );
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: '${input.packageName}.dart',
        linkMode: DynamicLoadingBundled(),
        file: dylibOut,
      ),
    );
  });
}
