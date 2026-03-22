# Speech Framework for Dart

Dart bindings and tooling for Apple's **Speech** framework ([Speech](https://developer.apple.com/documentation/speech)), using the **`SpeechAnalyzer` + `SpeechTranscriber` + `AssetInventory`** pipeline only—not the legacy `SFSpeechRecognizer` API.

This repository is under active development. Public API, native bridge layout, and `pub.dev` publication will evolve as features land.

[![license](https://img.shields.io/github/license/blendfactory/speech-kit)](LICENSE)

## Goals

- Expose **speech-to-text** through **`SpeechAnalyzer`**, **`SpeechTranscriber`** (and related modules as needed), and **`AssetInventory`**, with a clear Dart API.
- **Do not** bind or use **`SFSpeechRecognizer`** / **`SFSpeechRecognitionTask`** / the legacy task-based API; minimum OS targets follow Apple’s availability for the module API (see documentation in `.cursor/skills/speech-kit-spec`).
- Prefer **native Apple APIs** with a thin bridge (similar in spirit to other Blendfactory Apple-framework packages).
- Stay **usable without Flutter** where practical (pure Dart + native), subject to platform constraints.

## Official reference

| Resource | URL |
|----------|-----|
| Speech framework | https://developer.apple.com/documentation/speech |
| SpeechAnalyzer | https://developer.apple.com/documentation/speech/speechanalyzer |
| Advanced speech-to-text (sample) | https://developer.apple.com/documentation/speech/bringing-advanced-speech-to-text-capabilities-to-your-app |

## Platform support (target)

| Platform | Target |
|----------|--------|
| iOS | Planned |
| macOS | Planned |
| Windows | Not applicable |
| Linux | Not applicable |
| Android | Not applicable |

The module API this package uses requires **recent Apple OS releases** (e.g. **macOS 26+ / iOS 26+ / visionOS 26+** per current SDK Swift availability); exact minimums will be stated in `pubspec.yaml` and README when the native bridge lands.

## Installation

From pub.dev (when published):

```bash
dart pub add speech_kit
```

From a local clone:

```yaml
dependencies:
  speech_kit:
    path: ../speech-kit
```

## Example

The API is a placeholder until native bindings exist:

```dart
import 'package:speech_kit/speech_kit.dart';

void main() {
  const kit = SpeechKit();
  // ...
}
```

Run the sample:

```bash
dart run example/speech_kit_example.dart
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

BSD 3-Clause License. See [LICENSE](LICENSE).
