import 'package:meta/meta.dart';

/// Describes an `AVAudioFormat` returned by Apple
/// `SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith:)`.
///
/// [commonFormatRawValue] is `AVAudioCommonFormat.rawValue` (UInt32).
@immutable
final class CompatibleAudioFormat {
  const CompatibleAudioFormat({
    required this.sampleRate,
    required this.channelCount,
    required this.commonFormatRawValue,
    required this.isInterleaved,
  });

  factory CompatibleAudioFormat.fromJson(Map<String, dynamic> json) {
    return CompatibleAudioFormat(
      sampleRate: (json['sampleRate'] as num).toDouble(),
      channelCount: (json['channelCount'] as num).toInt(),
      commonFormatRawValue: (json['commonFormat'] as num).toInt(),
      isInterleaved: json['isInterleaved'] as bool? ?? true,
    );
  }

  final double sampleRate;
  final int channelCount;
  final int commonFormatRawValue;
  final bool isInterleaved;
}
