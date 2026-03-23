import 'package:meta/meta.dart';

/// Optional vocabulary bias for `SpeechAnalyzer` (Apple `AnalysisContext`).
///
/// Maps each [contextualStringsByTag] key to phrases the recognizer should
/// prefer. Use the `general` tag when you do not need multiple groups.
///
/// Ref: `AnalysisContext.contextualStrings` in Apple’s Speech framework.
@immutable
final class AnalysisContext {
  /// Creates context with optional per-tag phrase lists.
  const AnalysisContext({this.contextualStringsByTag = const {}});

  /// Tag name (e.g. `general`) to short phrases for bias recognition.
  final Map<String, List<String>> contextualStringsByTag;
}
