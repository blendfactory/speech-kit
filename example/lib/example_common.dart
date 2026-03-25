import 'dart:io';

/// Whether this process can run macOS-only `speech_kit` native samples.
bool get isMacOsSpeechKitHost => Platform.isMacOS;

/// Prints a standard message when [isMacOsSpeechKitHost] is false.
void printMacOsOnlyHint(String sampleName) {
  stderr.writeln(
    '$sampleName requires macOS (speech_kit native FFI in this release).',
  );
}
