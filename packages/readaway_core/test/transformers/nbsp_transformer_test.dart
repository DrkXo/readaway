import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('NbspTransformer', () {
    const transformer = NbspTransformer();

    test('glues Russian short prepositions and particles with NBSP', () {
      const input = 'Мы гуляли и в парке, а не около дома.';
      final ctx = TransformContext(
        content: input,
        language: 'ru',
      );

      final result = transformer.transform(ctx);
      // 'и', 'в', 'а', 'не', 'около' should be followed by \u00A0
      expect(result, contains('и\u00A0в\u00A0парке'));
      expect(result, contains('а\u00A0не\u00A0около\u00A0дома'));
      // Length in UTF-16 code units must remain identical to original!
      expect(result.length, equals(input.length));
    });

    test('glues English short function words with NBSP', () {
      const input = 'This is a test in the dark.';
      final ctx = TransformContext(
        content: input,
        language: 'en',
      );

      final result = transformer.transform(ctx);
      expect(result, contains('a\u00A0test'));
      expect(result, contains('in\u00A0the\u00A0dark'));
      expect(result.length, equals(input.length));
    });

    test('preserves style and script blocks untouched', () {
      const html = '<html><head><style>p { color: red; }</style></head>'
          '<body><p>This is a book in a library.</p>'
          '<script>var a = 1; if (a < 2) {}</script></body></html>';
      final ctx = TransformContext(
        content: html,
        language: 'en',
      );

      final result = transformer.transform(ctx);
      expect(result, contains('<style>p { color: red; }</style>'));
      expect(result, contains('<script>var a = 1; if (a < 2) {}</script>'));
      expect(result, contains('a\u00A0book'));
      expect(result, contains('in\u00A0a\u00A0library'));
    });
  });
}
