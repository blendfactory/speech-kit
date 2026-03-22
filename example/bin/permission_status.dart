import 'dart:io';

import 'package:speech_kit_example/permission_status_sample.dart';

/// CLI sample that logs speech recognition and microphone authorization.
///
/// Run from the example package root; see `example/README.md`.
Future<void> main(List<String> _) async {
  final code = await runPermissionStatusSample();
  if (code == 2) {
    stderr.writeln('This sample runs on macOS only.');
  }
  exitCode = code;
}
