import 'package:meta/meta.dart';

/// One transcription result chunk (conceptually maps from module `Result`).
///
/// Plain text is used at the Dart boundary; attributed metadata can be added
/// when the native bridge exposes it.
@immutable
final class TranscriptionSegment {
  const TranscriptionSegment({
    required this.text,
    required this.rangeStart,
    required this.rangeDuration,
    required this.resultsFinalizationOffset,
    this.alternativeTexts = const [],
  });

  final String text;
  final Duration rangeStart;
  final Duration rangeDuration;
  final Duration resultsFinalizationOffset;
  final List<String> alternativeTexts;
}
