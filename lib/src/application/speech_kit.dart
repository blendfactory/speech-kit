/// @docImport 'package:speech_kit/src/domain/errors/speech_kit_exception.dart';
library;

import 'package:meta/meta.dart';
import 'package:speech_kit/src/application/speech_analysis_session.dart';
import 'package:speech_kit/src/domain/value_objects/analysis/analysis_context.dart';
import 'package:speech_kit/src/domain/value_objects/assets/asset_inventory_status.dart';
import 'package:speech_kit/src/domain/value_objects/audio/compatible_audio_format.dart';
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

  /// Starts a file-based `SpeechAnalyzer` session and streams transcription
  /// results as [SpeechAnalysisSession.results].
  ///
  /// Notes:
  /// - This first release focuses on file input
  ///   (`SpeechAnalyzer.analyzeSequence(from:)`).
  /// - Optional [analysisContext] maps to Apple
  ///   `AnalysisContext.contextualStrings` (bias vocabulary) via native
  ///   `setContext` before analysis.
  /// - Call [SpeechAnalysisSession.finalizeAndFinish] or
  ///   [SpeechAnalysisSession.cancelAndFinishNow] to end the native session
  ///   explicitly when needed.
  SpeechAnalysisSession analyzeFile(
    String audioFilePath, {
    required List<SpeechModuleConfiguration> modules,
    AnalysisContext? analysisContext,
  }) {
    return analyzeFileImpl(
      audioFilePath,
      modules: modules,
      analysisContext: analysisContext,
    );
  }

  @override
  String toString() => 'SpeechKit()';
}
