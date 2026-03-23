import 'dart:async';

import 'package:meta/meta.dart';

import 'package:speech_kit/src/domain/value_objects/identifiers/speech_analysis_session_id.dart';
import 'package:speech_kit/src/domain/value_objects/results/transcription_segment.dart';

/// Root for one Apple `SpeechAnalyzer`-backed analysis session.
///
/// The session owns:
/// - a native handle (opaque id)
/// - a results stream of immutable [TranscriptionSegment] chunks
/// - explicit lifecycle operations (finalize/cancel) mapped to Apple
///   `finalizeAndFinish` / `cancelAndFinishNow`.
@immutable
final class SpeechAnalysisSession {
  const SpeechAnalysisSession({
    required this.id,
    required this.results,
    required Future<void> Function() finalizeAndFinish,
    required Future<void> Function() cancelAndFinishNow,
  }) : _finalizeAndFinish = finalizeAndFinish,
       _cancelAndFinishNow = cancelAndFinishNow;

  final SpeechAnalysisSessionId id;
  final Stream<TranscriptionSegment> results;

  final Future<void> Function() _finalizeAndFinish;
  final Future<void> Function() _cancelAndFinishNow;

  /// Waits for the session to reach a finished state.
  ///
  /// For file-based sessions this typically happens automatically after the
  /// file is fully analyzed and results are finalized.
  Future<void> finalizeAndFinish() => _finalizeAndFinish();

  /// Cancels analysis and finishes results immediately.
  ///
  /// This is mapped to Apple `cancelAndFinishNow()`.
  Future<void> cancelAndFinishNow() => _cancelAndFinishNow();
}
