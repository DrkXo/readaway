import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextTransformPipeline', () {
    test('defaultPipeline executes all transformers sequentially', () {
      // Combines RLM, double spaces, quotes, and orphan prepositions
      const input = '<p>“می\u200Fروم”   и в доме.</p>';
      final ctx = TransformContext(
        content: input,
        language: 'ru',
        vertical: true,
        overrideLayout: true,
      );

      final result = TextTransformPipeline.defaultPipeline.transform(ctx);

      // BiDi: \u200F replaced with \u200C
      expect(result, contains('می\u200Cروم'));
      // Whitespace: triple space collapsed
      expect(result, isNot(contains('   ')));
      // Punctuation: vertical quotes rotated
      expect(result, contains('﹃'));
      expect(result, contains('﹄'));
      // NBSP: 'и' and 'в' glued with \u00A0
      expect(result, contains('и\u00A0в\u00A0доме'));
    });

    test('recovers gracefully from a throwing transformer', () {
      final errorLog = <String>[];
      final badTransformer = _ThrowingTransformer();
      final pipeline = TextTransformPipeline(
        transformers: [
          const WhitespaceTransformer(),
          badTransformer,
          const NbspTransformer(),
        ],
        onError: (t, err, st) {
          errorLog.add('${t.name}: $err');
        },
      );

      final ctx = TransformContext(
        content: '<p>Two  spaces and a book.</p>',
        overrideLayout: true,
        language: 'en',
      );

      final result = pipeline.transform(ctx);

      // Whitespace transformer ran
      expect(result, isNot(contains('  ')));
      // Nbsp transformer ran after error
      expect(result, contains('a\u00A0book'));
      // Error was caught and logged
      expect(errorLog.length, equals(1));
      expect(errorLog.first, contains('broken_step'));
    });
  });
}

class _ThrowingTransformer implements TextTransformer {
  @override
  String get name => 'broken_step';

  @override
  String transform(TransformContext context) {
    throw StateError('Simulated transformer explosion');
  }
}
