import 'package:meta/meta.dart';
import 'package:speech_kit/speech_kit.dart' show SpeechKit;
import 'package:speech_kit/src/application/speech_kit.dart' show SpeechKit;

/// Paths to **compiled** custom language model assets for dictation.
///
/// Typically produced by [SpeechKit.prepareCustomLanguageModel] from training
/// data written with [SpeechKit.exportCustomLanguageModelData].
///
/// Maps to `SFSpeechLanguageModel.Configuration` for
/// `DictationTranscriber.ContentHint.customizedLanguage`.
@immutable
final class SpeechLanguageModelPaths {
  /// Creates references to on-disk model files (absolute paths recommended).
  const SpeechLanguageModelPaths({
    required this.languageModelPath,
    this.vocabularyPath,
    this.weight,
  });

  /// Path to the compiled language model file.
  final String languageModelPath;

  /// Optional path to a compiled vocabulary file.
  final String? vocabularyPath;

  /// Optional customization weight (0.0–1.0), macOS 26+ / iOS 26+.
  final double? weight;

  /// JSON for the native dictation module bridge.
  Map<String, Object?> toJson() => {
    'languageModelPath': languageModelPath,
    if (vocabularyPath != null) 'vocabularyPath': vocabularyPath,
    if (weight != null) 'weight': weight,
  };
}
