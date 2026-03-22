import 'package:meta/meta.dart';

import 'package:speech_kit/src/domain/value_objects/configuration/speech_transcriber_preset.dart';

/// Describes a module configuration used for asset checks and analysis.
///
/// Infrastructure maps these snapshots to native `SpeechModule` instances.
@immutable
sealed class SpeechModuleConfiguration {
  const SpeechModuleConfiguration();
}

/// Configuration for `SpeechTranscriber`.
@immutable
final class SpeechTranscriberConfiguration extends SpeechModuleConfiguration {
  /// Creates a transcriber configuration for asset checks and future sessions.
  const SpeechTranscriberConfiguration({
    required this.localeId,
    required this.preset,
  });

  /// BCP 47 language tag (e.g. `en-US`, `ja-JP`).
  final String localeId;
  final SpeechTranscriberPreset preset;
}
