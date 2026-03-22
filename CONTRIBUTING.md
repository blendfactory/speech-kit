# Contributing

Thank you for helping improve `speech_kit` and this repository.

## Development setup

As the package layout is established, the following will apply:

- **Dart SDK** — version constraint will be declared in `pubspec.yaml`.
- **Apple platforms** — Xcode and devices or simulators for iOS/macOS when working on the native bridge or integration tests.
- **Permissions** — Speech recognition and microphone usage require appropriate entitlements and Info.plist / usage descriptions; examples will live under `example/` when added.

From the package root:

```bash
dart pub get
dart analyze
dart test
```

To run the placeholder example:

```bash
dart run example/speech_kit_example.dart
```

## Pull requests

- Keep changes focused; prefer small PRs for reviewability.
- Run `dart format .`, `dart analyze`, and `dart test` before submitting when those commands are available.
- Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages (see `.cursor/rules/commit-message-standards.mdc` in this repo).
- Document public API changes in `CHANGELOG.md` under `[Unreleased]` when behavior or surface changes.

## Architecture and Apple API coverage

- Follow `.cursor/rules/dart-standards.mdc` for Dart code.
- Use `.cursor/skills/speech-kit-spec` and `.cursor/skills/speech-kit-api-coverage` when mapping Apple’s Speech APIs to Dart.
- Use `.cursor/skills/speech-kit-native-bridge` when implementing or extending the native layer.
- **Do not** add the legacy **`SFSpeechRecognizer`** pipeline; stick to **`SpeechAnalyzer` / `SpeechTranscriber` / `AssetInventory`** (see `speech-kit-spec`).

## Reporting issues

Use [GitHub Issues](https://github.com/blendfactory/speech-kit/issues). Include OS version, Dart SDK version, and minimal reproduction steps where possible.
