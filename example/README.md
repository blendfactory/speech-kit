# speech_kit example

Sample command-line app demonstrating speech recognition and microphone
permission queries with `speech_kit`.

## Requirements

- macOS with **Dart SDK 3.10+** (aligned with the main package)
- **Speech recognition** and **microphone** usage strings in the app bundle
  when embedding in a real app (`NSSpeechRecognitionUsageDescription`, etc.);
  this CLI may still prompt or reflect TCC state depending on context
- Native dylib from the parent package’s Dart build hooks (run `dart pub get`
  in the repo root or here so hooks can compile)

## Run

From this directory:

```bash
dart pub get
dart run bin/permission_status.dart
```

On non-macOS hosts the tool exits with code `2` and prints a short message.

## Layout

| Path | Role |
|------|------|
| `bin/permission_status.dart` | CLI entry |
| `lib/permission_status_sample.dart` | Shared sample logic |
