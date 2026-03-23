import 'package:meta/meta.dart';

/// One line in a template expansion (`TemplatePhraseCountGenerator.Template`).
///
/// [body] may use `{className}` placeholders matching keys in
/// [PhraseCountsFromTemplatesConfig.classes] (Apple `SFCustomLanguageModelData`
/// conventions).
@immutable
final class TemplateLineNode {
  /// Creates a template line with repetition [count].
  const TemplateLineNode({
    required this.body,
    required this.count,
  });

  /// Template string (may include `{placeholder}` segments).
  final String body;

  /// Non-negative repetition count for this template.
  final int count;
}

/// Recursive template tree for `PhraseCountsFromTemplates` / `CompoundTemplate`.
sealed class TemplateInsertableNode {
  const TemplateInsertableNode._();
}

/// A single `TemplatePhraseCountGenerator.Template` line.
final class TemplateLeafNode extends TemplateInsertableNode {
  /// Creates a leaf template node.
  const TemplateLeafNode(this.line) : super._();

  /// Line and count passed to Apple’s `Template` type.
  final TemplateLineNode line;
}

/// Multiple [TemplateInsertableNode] values combined with `CompoundTemplate`.
final class TemplateCompoundNode extends TemplateInsertableNode {
  /// Creates a compound node (at least one child required).
  const TemplateCompoundNode({required this.components}) : super._();

  /// Child template pieces (Apple `CompoundTemplate`).
  final List<TemplateInsertableNode> components;
}

/// Maps to `PhraseCountsFromTemplates` (`classes` + template tree).
@immutable
final class PhraseCountsFromTemplatesConfig {
  /// Creates template-based phrase count data.
  ///
  /// [classes] maps placeholder class names to replacement word lists.
  /// [root] is the template tree inserted into `PhraseCountsFromTemplates`.
  const PhraseCountsFromTemplatesConfig({
    required this.classes,
    required this.root,
  });

  /// Class name → vocabulary entries (e.g. `city` → `Tokyo`, `Osaka`).
  final Map<String, List<String>> classes;

  /// Root `TemplateInsertable` (template line or compound).
  final TemplateInsertableNode root;

  /// JSON for the native export bridge.
  Map<String, Object?> toJson() => {
    'classes': classes,
    'root': _nodeToJson(root),
  };
}

Map<String, Object?> _nodeToJson(TemplateInsertableNode node) {
  switch (node) {
    case TemplateLeafNode(:final line):
      return {
        'kind': 'template',
        'body': line.body,
        'count': line.count,
      };
    case TemplateCompoundNode(:final components):
      return {
        'kind': 'compound',
        'components': [for (final c in components) _nodeToJson(c)],
      };
  }
}

/// Max nesting depth for [PhraseCountsFromTemplatesConfig.root] (native limit).
const kPhraseCountsFromTemplatesMaxDepth = 32;

/// Returns `null` if valid; otherwise a message suitable for [FormatException].
String? phraseCountsFromTemplatesValidationError(
  PhraseCountsFromTemplatesConfig config,
) {
  return _templateNodeValidationError(config.root, 0);
}

/// Validates [PhraseCountsFromTemplatesConfig] before native export.
///
/// Throws [FormatException] when counts are negative, a compound has no
/// children, or depth exceeds [kPhraseCountsFromTemplatesMaxDepth].
void validatePhraseCountsFromTemplatesConfig(
  PhraseCountsFromTemplatesConfig config,
) {
  final message = phraseCountsFromTemplatesValidationError(config);
  if (message != null) {
    throw FormatException(message);
  }
}

String? _templateNodeValidationError(TemplateInsertableNode node, int depth) {
  if (depth > kPhraseCountsFromTemplatesMaxDepth) {
    return 'Template tree exceeds max depth '
        '$kPhraseCountsFromTemplatesMaxDepth';
  }
  switch (node) {
    case TemplateLeafNode(:final line):
      if (line.count < 0) {
        return 'Template count must be non-negative';
      }
      return null;
    case TemplateCompoundNode(:final components):
      if (components.isEmpty) {
        return 'Compound template must have at least one component';
      }
      for (final c in components) {
        final nested = _templateNodeValidationError(c, depth + 1);
        if (nested != null) {
          return nested;
        }
      }
      return null;
  }
}
