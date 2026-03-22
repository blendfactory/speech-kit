---
name: speech-kit-native-bridge
description: >-
  Patterns for bridging Apple Speech framework (SpeechAnalyzer pipeline) to Dart.
  Use when implementing native Swift code, streaming audio or results, or designing
  the native–Dart interface layer.
---

# Speech Framework Native Bridge

Patterns for bridging Apple **Speech** (`Speech.framework`) **module API** to Dart: **`SpeechAnalyzer`**, **`SpeechTranscriber`** (and related modules), **`AssetInventory`**.

**Out of scope:** **`SFSpeechRecognizer`**, **`SFSpeechRecognitionRequest`**, **`SFSpeechRecognitionTask`**, and callback-based legacy recognition. Do not implement fallbacks using those types.

The bridge will almost certainly require **Swift** (structured concurrency, `AsyncSequence`). FFI, a small helper executable, or embedding Swift from Dart Build Hooks are implementation choices for this repo—pick one consistent approach.

## When to use

- Implementing `AssetInventory` download/install from Dart-triggered native code
- Driving `SpeechAnalyzer` sessions and feeding `AnalyzerInput`
- Draining module `results` `AsyncSequence` into Dart `Stream` or chunks
- Passing audio buffers or file paths safely across the boundary
- Designing async native → Dart communication

## Architecture (template)

```
Dart API (Future, Stream, facades)
    │
    │  FFI / embed Swift / helper process (TBD per repo decision)
    ▼
Swift — SpeechAnalyzer, SpeechTranscriber, AssetInventory
    │
    │  Speech.framework
    ▼
AnalyzerInput streams, module AsyncSequence results
```

## Bridging patterns

### 1. Asset installation → Dart `Future`

- `AssetInventory.assetInstallationRequest(supporting:)` is `async throws`.
- Expose progress (e.g. `Foundation.Progress`) to Dart if users need UI feedback.

### 2. Module results → Dart `Stream`

- Iterate `for try await result in transcriber.results` (or equivalent) on a Swift task; forward each `SpeechTranscriber.Result` to Dart.
- Map `AttributedString` / time ranges to plain Dart types at the boundary.

### 3. Audio input

- Use `SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith:)` (or module-specific formats) and convert incoming audio to that format before wrapping in `AnalyzerInput`.
- Define ownership of **AVAudioSession** (iOS) or capture path (macOS) in one place.

### 4. File-based analysis

- Prefer Apple’s file-oriented `SpeechAnalyzer` APIs where they fit; validate sandbox-readable URLs on macOS.

### 5. Error handling

- Map analyzer and module errors to typed Dart exceptions; end the Dart stream on session failure.
- Respect Apple’s rule that errors finish the analysis session.

### 6. Lifecycle

- On Dart cancel: call `cancelAndFinishNow()` or the appropriate finalize path; tear down Swift tasks cleanly.
- Avoid touching deallocated analyzer/module objects across isolation boundaries.

## Platform notes

- **iOS:** `NSSpeechRecognitionUsageDescription` and microphone usage strings are required.
- **macOS:** Follow current Apple guidance for sandboxed file and microphone access.
- **Minimum OS:** match **macOS 26+ / iOS 26+ / visionOS 26+** for the module API (see `speech-kit-spec`).

## References

- https://developer.apple.com/documentation/speech
- Skill: `speech-kit-spec` and `reference.md`
