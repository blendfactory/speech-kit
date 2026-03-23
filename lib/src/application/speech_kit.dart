/// @docImport 'package:speech_kit/src/domain/errors/speech_kit_exception.dart';
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:speech_kit/src/application/speech_analysis_session.dart';
import 'package:speech_kit/src/domain/value_objects/analysis/analysis_context.dart';
import 'package:speech_kit/src/domain/value_objects/assets/asset_inventory_status.dart';
import 'package:speech_kit/src/domain/value_objects/audio/compatible_audio_format.dart';
import 'package:speech_kit/src/domain/value_objects/configuration/speech_analyzer_options.dart';
import 'package:speech_kit/src/domain/value_objects/configuration/speech_module_configuration.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/microphone_permission.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/speech_recognition_permission.dart';
import 'package:speech_kit/src/infrastructure/speech_kit_no_io.dart'
    if (dart.library.io) 'package:speech_kit/src/infrastructure/speech_kit_io.dart';

/// Entry point for Apple Speech (SpeechAnalyzer pipeline) from Dart.
///
/// Speech recognition authorization uses Apple’s `SFSpeechRecognizer` APIs
/// inside the native library only; the Dart surface stays free of legacy
/// recognizer types.
///
/// **Minimum OS** for module APIs such as [assetInventoryStatus] and future
/// session methods: **macOS 26+ / iOS 26+ / visionOS 26+** (see package docs).
@immutable
class SpeechKit {
  /// Creates a [SpeechKit] facade.
  const SpeechKit();

  /// Current speech recognition authorization for this app.
  Future<SpeechRecognitionPermission> speechRecognitionAuthorizationStatus() {
    return speechRecognitionAuthorizationStatusImpl();
  }

  /// Prompts for speech recognition permission when status is not determined.
  Future<SpeechRecognitionPermission> requestSpeechRecognitionPermission() {
    return requestSpeechRecognitionPermissionImpl();
  }

  /// Current microphone record permission (`AVAudioApplication`).
  Future<MicrophonePermission> microphonePermissionStatus() {
    return microphonePermissionStatusImpl();
  }

  /// Requests microphone access when permission is undetermined.
  ///
  /// Returns whether recording is allowed after the request completes.
  Future<bool> requestMicrophonePermission() {
    return requestMicrophonePermissionImpl();
  }

  /// Asset readiness for the given modules (maps to `AssetInventory.status`).
  ///
  /// **macOS 26+** with native dylib. `SpeechTranscriberConfiguration`,
  /// `DictationTranscriberConfiguration`, and optional
  /// `SpeechDetectorConfiguration` entries are supported in this release.
  Future<AssetInventoryStatus> assetInventoryStatus(
    List<SpeechModuleConfiguration> modules,
  ) {
    return assetInventoryStatusImpl(modules);
  }

  /// Ensures assets are installed (`assetInstallationRequest` +
  /// `downloadAndInstall` when needed).
  ///
  /// **macOS 26+** with native dylib. May perform network I/O while downloading
  /// models. `SpeechTranscriberConfiguration`,
  /// `DictationTranscriberConfiguration`, and optional
  /// `SpeechDetectorConfiguration` entries are supported.
  Future<void> ensureAssetsInstalled(List<SpeechModuleConfiguration> modules) {
    return ensureAssetsInstalledImpl(modules);
  }

  /// Best audio format for the given modules (`SpeechAnalyzer`
  /// `bestAvailableAudioFormat(compatibleWith:)`).
  ///
  /// Returns `null` from Apple when assets are missing; this method throws
  /// [SpeechKitException] with a descriptive message in that case.
  Future<CompatibleAudioFormat> bestAvailableAudioFormat(
    List<SpeechModuleConfiguration> modules,
  ) {
    return bestAvailableAudioFormatImpl(modules);
  }

  /// Ends retained on-device speech models (`SpeechModels.endRetention()`).
  ///
  /// Call when your app no longer needs models kept after analysis (for example
  /// after using [SpeechAnalyzerModelRetention.lingering] or
  /// [SpeechAnalyzerModelRetention.processLifetime]).
  ///
  /// **macOS 26+** with native dylib.
  Future<void> endSpeechModelRetention() {
    return endSpeechModelRetentionImpl();
  }

  /// Starts a file-based `SpeechAnalyzer` session and streams transcription
  /// results as [SpeechAnalysisSession.results].
  ///
  /// Notes:
  /// - This first release focuses on file input
  ///   (`SpeechAnalyzer.analyzeSequence(from:)`).
  /// - Optional [analysisContext] maps to Apple
  ///   `AnalysisContext.contextualStrings` (bias vocabulary) via native
  ///   `setContext` before analysis.
  /// - [prepareAudioFormat] and [onPrepareProgress] map to
  ///   `prepareToAnalyze(in:withProgressReadyHandler:)` (expected input format
  ///   and `Progress.fractionCompleted`). If [prepareAudioFormat] is null, the
  ///   file’s `processingFormat` is used for preparation.
  /// - Optional [analyzerOptions] maps to `SpeechAnalyzer.Options` (task
  ///   priority and model retention). If null, the system default options are
  ///   used.
  /// - Call [SpeechAnalysisSession.finalizeAndFinish] or
  ///   [SpeechAnalysisSession.cancelAndFinishNow] to end the native session
  ///   explicitly when needed.
  SpeechAnalysisSession analyzeFile(
    String audioFilePath, {
    required List<SpeechModuleConfiguration> modules,
    AnalysisContext? analysisContext,
    SpeechAnalyzerOptions? analyzerOptions,
    CompatibleAudioFormat? prepareAudioFormat,
    void Function(double fractionCompleted)? onPrepareProgress,
  }) {
    return analyzeFileImpl(
      audioFilePath,
      modules: modules,
      analysisContext: analysisContext,
      analyzerOptions: analyzerOptions,
      prepareAudioFormat: prepareAudioFormat,
      onPrepareProgress: onPrepareProgress,
    );
  }

  /// Starts a `SpeechAnalyzer` session from raw PCM in memory (`AnalyzerInput`
  /// + `analyzeSequence(_:)`).
  ///
  /// [pcmBytes] must match [format] (frame-aligned interleaved PCM as produced
  /// for that `AVAudioFormat`). Prefer [bestAvailableAudioFormat] for a
  /// compatible layout.
  ///
  /// This passes a **single buffer** as one `AnalyzerInput`. For multiple
  /// chunks over time, use [analyzePcmStream].
  ///
  /// [prepareAudioFormat] / [onPrepareProgress] follow the same rules as
  /// [analyzeFile] (`prepareToAnalyze`). If [prepareAudioFormat] is null,
  /// [format] is used for preparation.
  ///
  /// [analyzerOptions] is the same as for [analyzeFile].
  SpeechAnalysisSession analyzePcm(
    Uint8List pcmBytes, {
    required CompatibleAudioFormat format,
    required List<SpeechModuleConfiguration> modules,
    AnalysisContext? analysisContext,
    SpeechAnalyzerOptions? analyzerOptions,
    CompatibleAudioFormat? prepareAudioFormat,
    void Function(double fractionCompleted)? onPrepareProgress,
  }) {
    return analyzePcmImpl(
      pcmBytes,
      format: format,
      modules: modules,
      analysisContext: analysisContext,
      analyzerOptions: analyzerOptions,
      prepareAudioFormat: prepareAudioFormat,
      onPrepareProgress: onPrepareProgress,
    );
  }

  /// Starts a `SpeechAnalyzer` session from a **stream** of PCM chunks
  /// (`AsyncSequence` of `AnalyzerInput` + `analyzeSequence(_:)`).
  ///
  /// Each emitted [Uint8List] must be **frame-aligned** for [format] (same
  /// rules as [analyzePcm]). Empty chunks are skipped. Use a **single-listen**
  /// stream; the implementation subscribes once.
  ///
  /// When the stream completes without error, native input is finished and the
  /// analyzer can finalize. Errors during iteration cancel the session.
  ///
  /// [prepareAudioFormat] / [onPrepareProgress] follow the same rules as
  /// [analyzePcm]. PCM payloads still use [format] for buffer layout.
  ///
  /// [analyzerOptions] is the same as for [analyzeFile].
  SpeechAnalysisSession analyzePcmStream(
    Stream<Uint8List> pcmChunks, {
    required CompatibleAudioFormat format,
    required List<SpeechModuleConfiguration> modules,
    AnalysisContext? analysisContext,
    SpeechAnalyzerOptions? analyzerOptions,
    CompatibleAudioFormat? prepareAudioFormat,
    void Function(double fractionCompleted)? onPrepareProgress,
  }) {
    return analyzePcmStreamImpl(
      pcmChunks,
      format: format,
      modules: modules,
      analysisContext: analysisContext,
      analyzerOptions: analyzerOptions,
      prepareAudioFormat: prepareAudioFormat,
      onPrepareProgress: onPrepareProgress,
    );
  }

  @override
  String toString() => 'SpeechKit()';
}
