# Contributing

Thank you for helping improve `speech_kit` and this repository.

## Development setup

- **Dart SDK** — see the `environment.sdk` constraint in [`pubspec.yaml`](pubspec.yaml).
- **Host OS** — the native FFI implementation in this release targets **macOS** (`dart:io` + `Platform.isMacOS`). Use a **Mac with Xcode** when building or debugging the Swift bridge under [`native/`](native/).
- **Permissions** — speech recognition and microphone flows need appropriate **Info.plist** usage strings (`NSSpeechRecognitionUsageDescription`, `NSMicrophoneUsageDescription`) in the **host app** bundle. CLI `dart run` is limited; see [`example/README.md`](example/README.md) for bundle notes and the helper script.

From the package root:

```bash
dart pub get
dart analyze
dart test
```

Optional formatting:

```bash
dart format .
```

### Example CLI

Samples live under [`example/`](example/). From the package root:

```bash
cd example
dart pub get
dart run bin/permission_status.dart
```

See [`example/README.md`](example/README.md) for CLI entry points (`permission_status`,
`asset_inventory`, `analyze_file`, `best_audio_format`, etc.).

## Pull requests

- Keep changes focused; prefer small PRs for reviewability.
- Run `dart format .`, `dart analyze`, and `dart test` before submitting.
- Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages (see `.cursor/rules/commit-message-standards.mdc` in this repo).
- Document public API changes in `CHANGELOG.md` under `[Unreleased]` when behavior or surface changes.

## Architecture and Apple API coverage

- Follow `.cursor/rules/dart-standards.mdc` for Dart code.
- Follow `.cursor/rules/architecture-ddd-layered.mdc` for layer boundaries (DDD + layered layout aligned with `screen-capture-kit`).
- See `doc/domain-model.md` for the bounded context, aggregate (**`SpeechAnalysisSession`**), and value object conventions.
- Use `.cursor/skills/speech-kit-spec` and `.cursor/skills/speech-kit-api-coverage` when mapping Apple’s Speech APIs to Dart.
- Use `.cursor/skills/speech-kit-native-bridge` when implementing or extending the native layer.
- **Do not** add the legacy **`SFSpeechRecognizer`** pipeline; stick to **`SpeechAnalyzer` / `SpeechTranscriber` / `AssetInventory`** (see `speech-kit-spec`).

## Reporting issues

Use [GitHub Issues](https://github.com/blendfactory/speech-kit/issues). Include OS version, Dart SDK version, and minimal reproduction steps where possible.
