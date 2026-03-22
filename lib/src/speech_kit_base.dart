import 'package:meta/meta.dart';

/// Entry point for the public API of this package.
///
/// Native integration with [SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer)
/// will be added in a future release.
@immutable
class SpeechKit {
  /// Creates a [SpeechKit] facade.
  const SpeechKit();

  @override
  String toString() => 'SpeechKit()';
}
