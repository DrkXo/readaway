import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('PunctuationTransformer', () {
    const transformer = PunctuationTransformer();

    test('rotates quotations in vertical mode for Simplified Chinese', () {
      const input = '他说：“你好，世界！”';
      final ctx = TransformContext(
        content: input,
        language: 'zh-CN',
        vertical: true,
      );

      final result = transformer.transform(ctx);
      expect(result, contains('﹃你好，世界！﹄'));
    });

    test('rotates quotations in vertical mode for Traditional Chinese', () {
      const input = '他說：“你好，世界！”';
      final ctx = TransformContext(
        content: input,
        language: 'zh-Hant',
        vertical: true,
      );

      final result = transformer.transform(ctx);
      expect(result, contains('﹁你好，世界！﹂'));
    });

    test('converts Hans quotes to Hant quotes', () {
      const input = '他说：“‘你好’，世界！”';
      final ctx = TransformContext(
        content: input,
        replaceQuotationMarks: true,
        convertChineseVariant: 's2t',
      );

      final result = transformer.transform(ctx);
      expect(result, contains('「『你好』，世界！」'));
    });

    test('converts Hant quotes to Hans quotes', () {
      const input = '他說：「『你好』，世界！」';
      final ctx = TransformContext(
        content: input,
        replaceQuotationMarks: true,
        convertChineseVariant: 't2s',
      );

      final result = transformer.transform(ctx);
      expect(result, contains('“‘你好’，世界！”'));
    });
  });
}
