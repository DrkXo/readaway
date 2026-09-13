import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('WhitespaceTransformer', () {
    const transformer = WhitespaceTransformer();

    test('collapses excessive spaces and converts NBSP when overrideLayout is true', () {
      const input = '<p>Multiple    spaces   and &nbsp; tabs \u00A0 here.</p>';
      final ctx = TransformContext(
        content: input,
        overrideLayout: true,
      );

      final result = transformer.transform(ctx);
      expect(result, equals('<p>Multiple spaces and tabs here.</p>'));
    });

    test('preserves pre and code indentation', () {
      const input = '<p>Normal   spaces</p><pre>  void   main() {\n    return;\n  }</pre>';
      final ctx = TransformContext(
        content: input,
        overrideLayout: true,
      );

      final result = transformer.transform(ctx);
      expect(result, contains('<p>Normal spaces</p>'));
      expect(result, contains('<pre>  void   main() {\n    return;\n  }</pre>'));
    });

    test('leaves content untouched when overrideLayout is false', () {
      const input = '<p>Multiple    spaces</p>';
      final ctx = TransformContext(
        content: input,
        overrideLayout: false,
      );

      expect(transformer.transform(ctx), equals(input));
    });
  });

  group('BidiSanitizerTransformer', () {
    const transformer = BidiSanitizerTransformer();

    test('replaces RLM half-space with ZWNJ between Arabic letters', () {
      // Persian: می\u200Fروم (mi-ravam)
      const input = 'می\u200Fروم';
      final ctx = TransformContext(content: input);

      final result = transformer.transform(ctx);
      expect(result, equals('می\u200Cروم'));
    });
  });
}
