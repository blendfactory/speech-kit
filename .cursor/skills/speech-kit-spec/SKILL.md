---
name: speech-kit-spec
description: >-
  Reference for Apple Speech framework API specification. Use when implementing
  or extending the speech_kit package, designing Dart APIs, or verifying feature
  coverage against the native framework.
---

# Speech Framework API Specification

Reference for implementing Apple **Speech** framework support in the `speech_kit` Dart package.

## Project scope (non-negotiable)

This package targets **only** Apple’s **module-based** Speech API:

- [`SpeechAnalyzer`](https://developer.apple.com/documentation/speech/speechanalyzer)
- [`SpeechTranscriber`](https://developer.apple.com/documentation/speech/speechtranscriber) (and other `SpeechModule` types as needed)
- [`AssetInventory`](https://developer.apple.com/documentation/speech/assetinventory)

**Do not** add or rely on the legacy Objective-C pipeline (`SFSpeechRecognizer`, `SFSpeechRecognitionRequest`, `SFSpeechRecognitionTask`, `SFTranscription`, etc.). Those APIs are **out of scope** even though they remain in the SDK for older apps.

## When to use

- Implementing authorization, asset install, analyzer sessions, locales, or streaming transcription results
- Designing Dart API that mirrors the **SpeechAnalyzer** model
- Verifying coverage or identifying gaps
- Debugging native bridge issues

## Quick reference

For a structured API outline, see [reference.md](reference.md).

## Official resources

| Resource | URL |
|----------|-----|
| Speech framework | https://developer.apple.com/documentation/speech |
| SpeechAnalyzer (overview + sample flow) | https://developer.apple.com/documentation/speech/speechanalyzer |
| Advanced speech-to-text sample | https://developer.apple.com/documentation/speech/bringing-advanced-speech-to-text-capabilities-to-your-app |
| WWDC25 — SpeechAnalyzer | https://developer.apple.com/videos/play/wwdc2025/277 |

## Minimum platform expectation

**macOS SDK note (verified on MacOSX 26.2.sdk):** Swift types `SpeechAnalyzer`, `AssetInventory`, and `SpeechTranscriber` are annotated **`@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)`** in `Speech.swiftinterface`.

The package should declare a **matching minimum OS** in documentation and build settings once implementation begins. Do not use `SFSpeechRecognizer` as a fallback for older OS versions.

## Privacy and permissions

- Apps must declare usage descriptions (e.g. microphone, speech recognition) and obtain user consent per Apple’s Human Interface Guidelines and `Info.plist` / entitlements requirements.
- If runtime authorization is still exposed only on **`SFSpeechRecognizer`** as a class method, invoke it from **private native code** and surface status to Dart with **neutral types** (e.g. an enum)—do **not** ship a Dart `SFSpeechRecognizer` type or task-based recognition API.
