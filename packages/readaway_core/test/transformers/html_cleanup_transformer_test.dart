import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('HtmlCleanupTransformer', () {
    const transformer = HtmlCleanupTransformer();

    test('strips malformed CSS declarations and leading semicolons', () {
      const input =
          '<p style="; font-style: normal; font-weight: 400; text-align: center; text-decoration-; color: #ff0000">Text</p>';
      final result = transformer.transform(
        const TransformContext(content: input),
      );

      expect(result, isNot(contains('text-decoration-')));
      expect(result, isNot(contains('style=";')));
      expect(result, contains('font-style: normal'));
      expect(result, contains('font-weight: 400'));
      expect(result, contains('text-align: center'));
      expect(result, contains('color: #ff0000'));
    });

    test('strips browser clipboard noise properties (ligatures, orphans, widows)', () {
      const input =
          '<span style="font-variant-ligatures: normal; font-variant-caps: normal; orphans: 2; widows: 2; font-size: 14px">Span</span>';
      final result = transformer.transform(
        const TransformContext(content: input),
      );

      expect(result, isNot(contains('font-variant-ligatures')));
      expect(result, isNot(contains('font-variant-caps')));
      expect(result, isNot(contains('orphans')));
      expect(result, isNot(contains('widows')));
      expect(result, contains('font-size: 14px'));
    });

    test('removes Apple-tab-span class names', () {
      const input = '<span class="Apple-tab-span custom-class">Tabbed</span>';
      final result = transformer.transform(
        const TransformContext(content: input),
      );

      expect(result, isNot(contains('Apple-tab-span')));
      expect(result, contains('custom-class'));
    });

    test('removes empty style attributes', () {
      const input = '<p style="; text-decoration-; ">Empty style</p>';
      final result = transformer.transform(
        const TransformContext(content: input),
      );

      expect(result, equals('<p >Empty style</p>'));
    });

    test('integrates with TextTransformPipeline.defaultPipeline', () {
      const input =
          '<p style="; font-weight: bold; text-decoration-;">Hello  World</p>';
      final output = TextTransformPipeline.defaultPipeline.transform(
        const TransformContext(content: input),
      );

      expect(output, isNot(contains('text-decoration-')));
      expect(output, contains('font-weight: bold'));
    });
  });
}
