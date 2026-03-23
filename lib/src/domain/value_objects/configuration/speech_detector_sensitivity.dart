/// Sensitivity for voice activity detection (maps to
/// `SpeechDetector.SensitivityLevel`).
enum SpeechDetectorSensitivity {
  /// More forgiving VAD; less aggressive.
  low,

  /// Recommended for most use cases.
  medium,

  /// More aggressive speech detection.
  high,
}
