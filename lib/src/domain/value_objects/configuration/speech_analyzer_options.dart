import 'package:meta/meta.dart';

/// Maps to Apple `SpeechAnalyzer.Options` (`TaskPriority` + model retention).
///
/// Ref: `SpeechAnalyzer.init(modules:options:)` in the Speech framework
/// (macOS 26+).
@immutable
final class SpeechAnalyzerOptions {
  /// Creates analyzer options for a session.
  ///
  /// Defaults match typical interactive use:
  /// [SpeechAnalyzerTaskPriority.medium] and
  /// [SpeechAnalyzerModelRetention.whileInUse].
  const SpeechAnalyzerOptions({
    this.taskPriority = SpeechAnalyzerTaskPriority.medium,
    this.modelRetention = SpeechAnalyzerModelRetention.whileInUse,
  });

  /// Swift `TaskPriority` (scheduling priority for analyzer work).
  final SpeechAnalyzerTaskPriority taskPriority;

  /// How long speech models may stay resident after the session.
  final SpeechAnalyzerModelRetention modelRetention;

  /// JSON for the native bridge (`taskPriority` / `modelRetention` keys).
  Map<String, Object?> toJson() => {
    'taskPriority': taskPriority.name,
    'modelRetention': modelRetention.name,
  };
}

/// Subset of Swift `TaskPriority` exposed to Dart (names match enum cases).
enum SpeechAnalyzerTaskPriority {
  high,
  medium,
  low,
  background,
}

/// Swift `SpeechAnalyzer.Options.ModelRetention`.
enum SpeechAnalyzerModelRetention {
  whileInUse,
  lingering,
  processLifetime,
}
