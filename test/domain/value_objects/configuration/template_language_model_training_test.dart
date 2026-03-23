import 'package:speech_kit/speech_kit.dart';
import 'package:test/test.dart';

void main() {
  group('PhraseCountsFromTemplatesConfig', () {
    test('toJson encodes classes and nested template nodes', () {
      const cfg = PhraseCountsFromTemplatesConfig(
        classes: {
          'city': ['Tokyo'],
        },
        root: TemplateCompoundNode(
          components: [
            TemplateLeafNode(
              TemplateLineNode(body: '{city} hello', count: 2),
            ),
          ],
        ),
      );
      final json = cfg.toJson();
      expect(json['classes'], {
        'city': ['Tokyo'],
      });
      final root = json['root']! as Map<String, Object?>;
      expect(root['kind'], 'compound');
      final components = root['components']! as List<Object?>;
      expect(components.length, 1);
      final leaf = components.first! as Map<String, Object?>;
      expect(leaf['kind'], 'template');
      expect(leaf['body'], '{city} hello');
      expect(leaf['count'], 2);
    });

    test('phraseCountsFromTemplatesValidationError rejects bad trees', () {
      expect(
        phraseCountsFromTemplatesValidationError(
          const PhraseCountsFromTemplatesConfig(
            classes: {},
            root: TemplateCompoundNode(components: []),
          ),
        ),
        isNotNull,
      );
      expect(
        phraseCountsFromTemplatesValidationError(
          const PhraseCountsFromTemplatesConfig(
            classes: {},
            root: TemplateLeafNode(
              TemplateLineNode(body: 'x', count: -1),
            ),
          ),
        ),
        isNotNull,
      );
      expect(
        phraseCountsFromTemplatesValidationError(
          const PhraseCountsFromTemplatesConfig(
            classes: {},
            root: TemplateLeafNode(
              TemplateLineNode(body: 'ok', count: 0),
            ),
          ),
        ),
        isNull,
      );
    });

    test(
      'CustomLanguageModelExportRequest includes phraseCountsFromTemplates',
      () {
        const req = CustomLanguageModelExportRequest(
          localeId: 'en-US',
          identifier: 'com.example.m',
          version: '1',
          exportPath: '/tmp/out',
          phraseCountsFromTemplates: PhraseCountsFromTemplatesConfig(
            classes: {
              'n': ['1'],
            },
            root: TemplateLeafNode(
              TemplateLineNode(body: 'n', count: 1),
            ),
          ),
        );
        final map = req.toJson();
        expect(map.containsKey('phraseCountsFromTemplates'), isTrue);
      },
    );
  });
}
