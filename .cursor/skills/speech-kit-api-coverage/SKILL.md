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
| Speech + microphone consent (`Info.plist` usage strings + runtime authorization per Apple docs) | ✅ | **macOS:** native dylib calls `+[SFSpeechRecognizer requestAuthorization:]` + `AVAudioApplication` record permission; Dart exposes `SpeechRecognitionPermission` / `MicrophonePermission` only. Callers must still ship `NSSpeechRecognitionUsageDescription` / microphone usage strings. |

### Asset inventory

| API / capability | Status | Notes |
|------------------|--------|-------|
| `AssetInventory.status(forModules:)` | ✅ | Dart: `SpeechKit.assetInventoryStatus` + `SpeechTranscriberConfiguration`; Swift bridge maps `SpeechTranscriber` modules → `AssetInventory.status`. |
| `AssetInventory.assetInstallationRequest(supporting:)` + install | ✅ | Dart: `SpeechKit.ensureAssetsInstalled`; Swift bridge maps modules → `assetInstallationRequest` → `downloadAndInstall`. |

### Transcription module

| API / capability | Status | Notes |
|------------------|--------|-------|
| `SpeechTranscriber` (locale, presets/options) | ✅ | Dart: `SpeechTranscriberConfiguration`, `SpeechTranscriberPreset`; Swift constructs `SpeechTranscriber(locale:preset:)` for both asset inventory and file-based analysis. |
| `DictationTranscriber` (optional) | ❌ | |
| `SpeechDetector` (optional) | ❌ | |

### Analyzer session

| API / capability | Status | Notes |
|------------------|--------|-------|
| `SpeechAnalyzer` init with modules | ✅ | Swift uses `SpeechAnalyzer(modules:)` |
| `SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith:)` | ✅ | Dart: `SpeechKit.bestAvailableAudioFormat` → `CompatibleAudioFormat` (JSON from Swift `AVAudioFormat`). |
| `AnalyzerInput` / buffer or file input | 🚧 | File input supported via `SpeechAnalyzer.analyzeSequence(from:)`. Buffer input (`AnalyzerInput` + `AsyncSequence`) not yet. |
| `analyzeSequence(_:)` or `start(inputSequence:)` | ✅ | File-based `analyzeSequence(from:)` supported. |
| Result consumption (`SpeechTranscriber.results` / `AsyncSequence`) | ✅ | Swift drains `transcriber.results` and forwards each phrase to Dart `Stream<TranscriptionSegment>`. |
| Finish / cancel (`finalizeAndFinish`, `cancelAndFinishNow`, …) | ✅ | Uses `finalizeAndFinish(through:)` or `cancelAndFinishNow()` depending on input. Stream cancel maps to native cancel. |
| `prepareToAnalyze`, model retention / priority options (if exposed) | ❌ | |

### Custom language model (optional)

| API / capability | Status | Notes |
|------------------|--------|-------|
| `SFSpeechLanguageModel` / `AnalysisContext` hooks | ❌ | Apple types may retain `SF` prefix; still part of module API, not legacy recognizer |

## README alignment

When the package publishes a roadmap or feature list in `README.md`, link bullets to the rows above and state **minimum macOS / iOS / visionOS** explicitly.
