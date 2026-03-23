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
| `SpeechDetector` | Voice-activity (VAD) module; Dart: `SpeechDetectorConfiguration` |
| `AnalysisContext` | Shared context / `contextualStrings` bias; Dart: `AnalysisContext` → `SpeechKit.analyzeFile` / `SpeechKit.analyzePcm` |
| `SFSpeechLanguageModel` | Custom language model configuration (see framework docs; name retains `SF` prefix in Apple API) |

---

## Dart bridge mapping (analyzer input)

| Path | Dart | Native |
|------|------|--------|
| File | `SpeechKit.analyzeFile` | `SpeechAnalyzer.analyzeSequence(from:)` on an audio file URL |
| Single PCM buffer | `SpeechKit.analyzePcm` (`Uint8List` + `CompatibleAudioFormat`) | Builds one `AVAudioPCMBuffer`, wraps in `AnalyzerInput(buffer:)`, `analyzeSequence(_:)` |
| PCM stream (multi-chunk) | `SpeechKit.analyzePcmStream` (`Stream<Uint8List>` + `CompatibleAudioFormat`) | FFI push per chunk → `AnalyzerInput(buffer:)` per chunk; `finish_pcm_input` when the Dart stream completes |

Each chunk must be frame-aligned; empty chunks are skipped.

### `prepareToAnalyze`

| Dart | Native |
|------|--------|
| `prepareAudioFormat` (optional) + `onPrepareProgress` on `analyzeFile` / `analyzePcm` / `analyzePcmStream` | `prepareToAnalyze(in:withProgressReadyHandler:)`; progress uses KVO on `Progress.fractionCompleted`, forwarded as analyzer callback event type `2` (`{"fractionCompleted": …}`) |

If `prepareAudioFormat` is omitted, the file’s `processingFormat` or the PCM `format` argument is used for preparation (matches Apple’s default).

---

## Errors and edge cases

- Handle unavailable locale, missing assets, cancelled sessions, and analyzer finish rules.
- Respect app state (backgrounding) and audio session rules on iOS.
- Follow Apple’s **finish / finalize** semantics (`finalizeAndFinish`, `cancelAndFinishNow`, etc.) — finishing the input `AsyncStream` alone does not always end the session.

## Documentation source

Primary: https://developer.apple.com/documentation/speech
