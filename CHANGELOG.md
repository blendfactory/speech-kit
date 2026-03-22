# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Architecture rule `.cursor/rules/architecture-ddd-layered.mdc` and `doc/domain-model.md` (DDD + layered design for the SpeechAnalyzer pipeline).

### Changed

- Align static analysis with `screen-capture-kit` (`all_lint_rules.yaml` + shared `analysis_options.yaml` pattern; drop `package:lints`).

## [0.0.1] - 2026-03-22

### Added

- Initial `speech_kit` package scaffold (`pubspec.yaml`, `lib/`, `test/`, `example/`).

[Unreleased]: https://github.com/blendfactory/speech-kit/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/blendfactory/speech-kit/releases/tag/v0.0.1
