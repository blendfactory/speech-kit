# Speech framework — implementation reference

Structured notes for mapping Apple’s Speech APIs to `speech_kit`. Update as the Dart surface grows.

## Scope

**In scope:** the **module-based** pipeline only (`SpeechAnalyzer`, `SpeechTranscriber`, `AssetInventory`, related `SpeechModule` types, `AnalyzerInput`, etc.).

**Out of scope:** **`SFSpeechRecognizer`** and the rest of the legacy `SFSpeech*` / `SFTranscription` task API. This repository does not bind or document that path.

## Platform (macOS SDK)

| Surface | Primary types | Availability (MacOSX 26.2.sdk `Speech.swiftinterface`) |
|---------|---------------|--------------------------------------------------------|
| Module-based (this package) | `SpeechAnalyzer`, `SpeechTranscriber`, `AssetInventory`, `AnalyzerInput`, `AssetInstallationRequest` | **`macOS 26.0+`, `iOS 26.0+`, `visionOS 26.0+`** (`@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)`) |

---

## Pipeline (Apple’s documented flow)

Flow matches Apple’s [`SpeechAnalyzer`](https://developer.apple.com/documentation/speech/speechanalyzer) documentation.

| Step | Apple API | Role |
|------|-----------|------|
| 1 | `SpeechTranscriber` (or another `SpeechModule`) | Configure locale, presets/options |
| 2 | `AssetInventory.assetInstallationRequest(supporting:)` | Ensure models/assets; download/install if needed |
| 3 | Input | `AsyncStream` / `AsyncSequence` of `AnalyzerInput` (buffers), or file-based APIs on `SpeechAnalyzer` |
| 4 | `SpeechAnalyzer` | Session: `analyzeSequence(_:)`, `finalizeAndFinish(through:)`, cancellation helpers |
| 5 | Module results | e.g. `transcriber.results` — `AsyncSequence` of `SpeechTranscriber.Result` (`AttributedString` text, time ranges, etc.) |

### Related types (non-exhaustive)

| Apple type | Role |
|------------|------|
| `DictationTranscriber` | Dictation-style module (parallel to `SpeechTranscriber`); exposed via `DictationTranscriberConfiguration` in Dart |
| `SpeechDetector` | Voice-activity style analysis module |
| `AnalysisContext` | Shared context / custom vocabulary hooks |
| `SFSpeechLanguageModel` | Custom language model configuration (see framework docs; name retains `SF` prefix in Apple API) |

---

## Errors and edge cases

- Handle unavailable locale, missing assets, cancelled sessions, and analyzer finish rules.
- Respect app state (backgrounding) and audio session rules on iOS.
- Follow Apple’s **finish / finalize** semantics (`finalizeAndFinish`, `cancelAndFinishNow`, etc.) — finishing the input `AsyncStream` alone does not always end the session.

## Documentation source

Primary: https://developer.apple.com/documentation/speech
