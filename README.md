# Speech for Dart

Native Dart bindings for Apple Speech (SpeechAnalyzer pipeline) using Dart Build Hooks.

`speech_kit` exposes **`SpeechAnalyzer`**, **`SpeechTranscriber`**, **`DictationTranscriber`**, **`SpeechDetector`**, and **`AssetInventory`** from Dart with a small façade—not the legacy **`SFSpeechRecognizer`** / task-based API. Native code is compiled via hooks and bridged with **FFI**.

[![pub version](https://img.shields.io/pub/v/speech_kit.svg)](https://pub.dev/packages/speech_kit)
[![license](https://img.shields.io/github/license/blendfactory/speech-kit)](LICENSE)

## Features

- **Permissions** — Speech recognition and microphone status / requests (native checks for usage-description keys where applicable)
- **Asset inventory** — `AssetInventory.status`, download/install, and `bestAvailableAudioFormat` for configured modules
- **Analysis sessions** — `analyzeFile`, `analyzePcm`, `analyzePcmStream` with optional `AnalysisContext`, `SpeechAnalyzerOptions`, and `prepareToAnalyze`-style preparation with progress
- **Custom language model (training data)** — `exportCustomLanguageModelData` with phrase counts, custom pronunciations, and optional `PhraseCountsFromTemplatesConfig` (template / compound tree)
- **Custom language model (compile)** — `prepareCustomLanguageModel` from exported training data; `supportedCustomLanguagePhonemes` per locale
- **Dictation integration** — `SpeechLanguageModelPaths` for `SFSpeechLanguageModel.Configuration` on dictation modules
- **Powered by Dart Build Hooks** — No Flutter dependency (pure Dart on supported hosts)

## Platform Support

| Platform | Support |
|----------|---------|
| macOS | ✅ |
| Windows | ❌ |
| Linux | ❌ |
| iOS | ❌ |
| Android | ❌ |

**macOS** is the supported target for the native dylib in this release (`platforms` in `pubspec.yaml` is macOS-only). The module APIs used here require **recent Apple OS releases** (e.g. **macOS 26+** for the current Swift bridge, consistent with **iOS 26+ / visionOS 26+** for the same Speech symbols). Callers need **`dart:io`** (VM or an embedder that provides `dart.library.io`); non-IO configurations use stubs that throw `UnsupportedError`.

## Installation

Add the package:

```bash
dart pub add speech_kit
```

From a local path:

```yaml
dependencies:
  speech_kit:
    path: ../speech-kit
```

## Example

```dart
import 'package:speech_kit/speech_kit.dart';

Future<void> main() async {
  const kit = SpeechKit();
  final speech = await kit.speechRecognitionAuthorizationStatus();
  // Request permission if needed, build SpeechModuleConfiguration list,
  // ensure assets, then analyzeFile / analyzePcm / analyzePcmStream.
}
```

## Usage flow

1. **Check permissions** — `speechRecognitionAuthorizationStatus()` / `requestSpeechRecognitionPermission()` and microphone APIs as needed.
2. **Describe modules** — Build a `List<SpeechModuleConfiguration>` (transcriber, dictation, optional speech detector).
3. **Assets** — `assetInventoryStatus` / `ensureAssetsInstalled`; use `bestAvailableAudioFormat` when preparing audio.
4. **Analyze** — `analyzeFile` (or PCM / stream) with optional `AnalysisContext`, `SpeechAnalyzerOptions`, and preparation callbacks.
5. **Optional: custom LM** — `exportCustomLanguageModelData` → `prepareCustomLanguageModel`; attach compiled paths via dictation configuration when required.
6. **Retention** — Call `endSpeechModelRetention` when you no longer need models kept after analysis (if you used lingering / process-lifetime retention options).

For CLI samples (`permission_status`, `asset_inventory`, `analyze_file`), see [example/README.md](example/README.md).

## Architecture

This package uses Dart Build Hooks to compile native code and bridge Apple’s Speech APIs to Dart.

**Dart layers** (inward dependencies): **domain** (value objects, errors) → **application** (`SpeechKit` façade, `SpeechAnalysisSession`) → **infrastructure** (macOS FFI + `speech_kit_no_io` stub). The public barrel exports domain types and the façade.

```
Dart (barrel + SpeechKit)
 │
 │  FFI
 ▼
Native bridge (Swift)
 │
 ▼
Speech (Apple framework)
```

This keeps the Dart surface small while delegating OS work to the native library.

## Example app

See the `example/` directory for command-line samples and macOS bundle notes. Run instructions: [example/README.md](example/README.md).

## Roadmap

Major capability areas **implemented** today are listed under [Features](#features): permissions, asset inventory, file/PCM/stream analysis with context and analyzer options, custom language model export (including template-based phrase counts), compile step, supported phonemes, and dictation LM paths.

**Partially exposed or not exposed** in the Dart API includes anything not covered in [`.cursor/skills/speech-kit-api-coverage/SKILL.md`](.cursor/skills/speech-kit-api-coverage/SKILL.md). **iOS** FFI is not wired in the current `dart:io` path; **macOS** is the supported desktop target for this release.

## Additional documentation

- [Contributing](CONTRIBUTING.md) — setup, tests, and PR guidelines
- [Domain model](doc/domain-model.md) — layers and value objects
- Apple Speech — [Speech framework](https://developer.apple.com/documentation/speech), [SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer), [SFCustomLanguageModelData](https://developer.apple.com/documentation/speech/sfcustomlanguagemodeldata), [advanced speech-to-text sample](https://developer.apple.com/documentation/speech/bringing-advanced-speech-to-text-capabilities-to-your-app)
