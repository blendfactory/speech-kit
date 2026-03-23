/// Opaque identifier for one native `SpeechAnalyzer` analysis session.
///
/// The underlying native handle is managed in infrastructure and is only
/// exposed to support cancellation/finalization calls.
extension type SpeechAnalysisSessionId(int value) {
  /// Native handles are expected to be positive.
  bool get isValid => value > 0;
}
