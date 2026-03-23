/// Preset for dictation transcriber configuration (maps to
/// `DictationTranscriber.Preset`).
///
/// Order matches Apple’s standard presets table
/// (phrase through timeIndexedLongDictation).
enum DictationTranscriberPreset {
  phrase,
  shortDictation,
  progressiveShortDictation,
  longDictation,
  progressiveLongDictation,
  timeIndexedLongDictation,
}
