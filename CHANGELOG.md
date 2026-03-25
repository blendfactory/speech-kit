# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2026-03-24

First pub.dev release: native Dart bindings for Apple Speech (SpeechAnalyzer pipeline) on **macOS** via Dart Build Hooks and FFI.

### Added

- **`SpeechKit` façade** — speech and microphone permission status/requests; `AssetInventory` status and `ensureAssetsInstalled`; `bestAvailableAudioFormat`; `analyzeFile` / `analyzePcm` / `analyzePcmStream` with optional `AnalysisContext` and `SpeechAnalyzerOptions`; `SpeechAnalysisSession` with `TranscriptionSegment` streaming; `endSpeechModelRetention`.
- **Custom language model** — `exportCustomLanguageModelData` (phrase counts, custom pronunciations, optional `PhraseCountsFromTemplatesConfig`), `prepareCustomLanguageModel`, `supportedCustomLanguagePhonemes`, `SpeechLanguageModelPaths` for dictation.
- **Repository layout** — `lib/`, `test/`, `native/` Swift bridge, architecture rule `.cursor/rules/architecture-ddd-layered.mdc`, and `doc/domain-model.md`.
- **Example package (`example/`)** — CLI samples: `permission_status`, `asset_inventory`, `best_audio_format` (with `--install` to fetch on-device models when needed), `supported_phonemes`, `export_custom_lm`, `end_model_retention`, `analyze_file` (optional `--bias`, `--task-priority`, `--model-retention`); shared `lib/example_common.dart`; `example/README.md` with overview table and `tree`-style layout.

### Changed

- Static analysis aligned with `screen-capture-kit` (`all_lint_rules.yaml` + shared `analysis_options.yaml` pattern; drop `package:lints`).
- **Documentation** — README (structure aligned with `screen-capture-kit`), `CONTRIBUTING.md`, and `doc/domain-model.md` updated for the implemented API and macOS-only native path.
- **`pubspec.yaml`** — `platforms` limited to **macOS** until iOS FFI is supported.

[Unreleased]: https://github.com/blendfactory/speech-kit/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/blendfactory/speech-kit/releases/tag/v0.0.1
