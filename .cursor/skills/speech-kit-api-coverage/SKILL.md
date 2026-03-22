---
name: speech-kit-api-coverage
description: >-
  Tracks Apple Speech framework API coverage in the speech_kit package. Use when
  planning features, identifying implementation gaps, or updating the roadmap.
---

# Speech Framework API Coverage

Checklist for tracking which Speech APIs are implemented in the Dart package.

**Scope:** **`SpeechAnalyzer` + `SpeechTranscriber` (and related modules) + `AssetInventory` only.** Legacy `SFSpeechRecognizer` / `SFSpeechRecognitionTask` / `SFTranscription` are **not** tracked here and must not be added.

**Minimum OS:** align with Swift availability (**macOS 26+ / iOS 26+ / visionOS 26+** per MacOSX 26.2.sdk `Speech.swiftinterface`).

## When to use

- Before adding a new feature (check what is missing)
- When updating README roadmap or feature lists
- During release planning
- When reviewing PRs for completeness

## Status legend

Use: ✅ Done | 🚧 In progress | ❌ Not started

## Coverage checklist

Update rows as implementation progresses.

### Permissions and setup

| API / capability | Status | Notes |
|------------------|--------|-------|
| Speech + microphone consent (`Info.plist` usage strings + runtime authorization per Apple docs) | 🚧 | **macOS:** native dylib calls `+[SFSpeechRecognizer requestAuthorization:]` + `AVAudioApplication` record permission; Dart exposes `SpeechRecognitionPermission` / `MicrophonePermission` only. **iOS:** hook builds macOS asset only—add iOS build + embedder testing. Callers must still ship `NSSpeechRecognitionUsageDescription` / microphone usage strings. |

### Asset inventory

| API / capability | Status | Notes |
|------------------|--------|-------|
| `AssetInventory.status(forModules:)` | 🚧 | Dart: `SpeechKit.assetInventoryStatus` + `SpeechTranscriberConfiguration`; native Swift bridge **not** wired—throws `SpeechKitFailure.notImplemented`. |
| `AssetInventory.assetInstallationRequest(supporting:)` + install | 🚧 | Dart: `SpeechKit.ensureAssetsInstalled`; native **not** wired—throws `notImplemented`. |

### Transcription module

| API / capability | Status | Notes |
|------------------|--------|-------|
| `SpeechTranscriber` (locale, presets/options) | 🚧 | Dart: `SpeechTranscriberConfiguration`, `SpeechTranscriberPreset`; no native module construction yet. |
| `DictationTranscriber` (optional) | ❌ | |
| `SpeechDetector` (optional) | ❌ | |

### Analyzer session

| API / capability | Status | Notes |
|------------------|--------|-------|
| `SpeechAnalyzer` init with modules | ❌ | |
| `SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith:)` | ❌ | |
| `AnalyzerInput` / buffer or file input | ❌ | |
| `analyzeSequence(_:)` or `start(inputSequence:)` | ❌ | |
| Result consumption (`SpeechTranscriber.results` / `AsyncSequence`) | ❌ | Map to Dart `Stream` or similar |
| Finish / cancel (`finalizeAndFinish`, `cancelAndFinishNow`, …) | ❌ | |
| `prepareToAnalyze`, model retention / priority options (if exposed) | ❌ | |

### Custom language model (optional)

| API / capability | Status | Notes |
|------------------|--------|-------|
| `SFSpeechLanguageModel` / `AnalysisContext` hooks | ❌ | Apple types may retain `SF` prefix; still part of module API, not legacy recognizer |

## README alignment

When the package publishes a roadmap or feature list in `README.md`, link bullets to the rows above and state **minimum macOS / iOS / visionOS** explicitly.
