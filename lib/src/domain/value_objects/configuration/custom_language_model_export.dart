import 'package:meta/meta.dart';
import 'package:speech_kit/speech_kit.dart' show SpeechKit;
import 'package:speech_kit/src/application/speech_kit.dart' show SpeechKit;

import 'package:speech_kit/src/domain/value_objects/configuration/template_language_model_training.dart';

/// One phrase and repetition count for `SFCustomLanguageModelData.PhraseCount`.
@immutable
final class CustomLanguageModelPhraseCount {
  /// Creates a phrase count entry.
  const CustomLanguageModelPhraseCount({
    required this.phrase,
    required this.count,
  });

  /// Phrase text.
  final String phrase;

  /// Non-negative occurrence count.
  final int count;
}

/// Grapheme and ARPAbet-style phoneme strings for custom pronunciation.
@immutable
final class CustomLanguageModelPronunciation {
  /// Creates a pronunciation entry.
  const CustomLanguageModelPronunciation({
    required this.grapheme,
    required this.phonemes,
  });

  /// Surface form (word or token).
  final String grapheme;

  /// Phoneme strings (validate with supported-custom-language phonemes for the
  /// locale via the SpeechKit API).
  final List<String> phonemes;
}

/// Payload for [SpeechKit.exportCustomLanguageModelData] / `export(to:)`.
///
/// At least one of [phraseCounts], [pronunciations], or
/// [phraseCountsFromTemplates] should be non-empty for a useful model; empty
/// exports are allowed and may fail at runtime on Apple’s side.
@immutable
final class CustomLanguageModelExportRequest {
  /// Creates an export request.
  const CustomLanguageModelExportRequest({
    required this.localeId,
    required this.identifier,
    required this.version,
    required this.exportPath,
    this.phraseCounts = const [],
    this.pronunciations = const [],
    this.phraseCountsFromTemplates,
  });

  /// BCP 47 tag (e.g. `en-US`).
  final String localeId;

  /// Stable model identifier (e.g. bundle id + feature name).
  final String identifier;

  /// Version string for the custom model artifact.
  final String version;

  /// Filesystem path where the training data file is written (see Apple docs).
  final String exportPath;

  /// Phrase / count pairs.
  final List<CustomLanguageModelPhraseCount> phraseCounts;

  /// Custom pronunciation entries.
  final List<CustomLanguageModelPronunciation> pronunciations;

  /// Optional `PhraseCountsFromTemplates` / `CompoundTemplate` tree.
  final PhraseCountsFromTemplatesConfig? phraseCountsFromTemplates;

  /// JSON for the native bridge.
  Map<String, Object?> toJson() => {
    'locale': localeId,
    'identifier': identifier,
    'version': version,
    'exportPath': exportPath,
    'phraseCounts': [
      for (final p in phraseCounts)
        <String, Object?>{
          'phrase': p.phrase,
          'count': p.count,
        },
    ],
    'customPronunciations': [
      for (final t in pronunciations)
        <String, Object?>{
          'grapheme': t.grapheme,
          'phonemes': t.phonemes,
        },
    ],
    if (phraseCountsFromTemplates != null)
      'phraseCountsFromTemplates': phraseCountsFromTemplates!.toJson(),
  };
}
