import '../models/models.dart';
import 'text_transformer.dart';

/// Adapts quotation marks for vertical reading mode and variant conversions
/// (Simplified Chinese Hans vs Traditional Chinese Hant).
class PunctuationTransformer implements TextTransformer {
  const PunctuationTransformer();

  @override
  String get name => 'punctuation';

  Map<String, String> get _verticalQuotationsMapHans => {
    '“': '﹃',
    '”': '﹄',
    '‘': '﹁',
    '’': '﹂',
    '「': '﹁',
    '」': '﹂',
    '『': '﹃',
    '』': '﹄',
  };

  Map<String, String> get _verticalQuotationsMapHant => {
    '“': '﹁',
    '”': '﹂',
    '‘': '﹃',
    '’': '﹄',
    '「': '﹁',
    '」': '﹂',
    '『': '﹃',
    '』': '﹄',
  };

  Map<String, String> get _quotationsMapHans2Hant => {
    '“': '「',
    '”': '」',
    '‘': '『',
    '’': '』',
    '﹃': '﹁',
    '﹄': '﹂',
    '﹁': '﹃',
    '﹂': '﹄',
  };

  @override
  String transform(TransformContext context) {
    if (!context.replaceQuotationMarks && !context.vertical) {
      return context.content;
    }

    var result = context.content;

    // 1. Chinese Hans/Hant variant quotation conversion
    final variant = context.convertChineseVariant;
    if (variant != null && variant != 'none') {
      final isToSimplified = variant.contains('2s');
      for (final entry in _quotationsMapHans2Hant.entries) {
        final from = isToSimplified ? entry.value : entry.key;
        final to = isToSimplified ? entry.key : entry.value;
        result = result.replaceAll(from, to);
      }
    }

    // 2. Vertical reading quotation rotation
    if (context.vertical) {
      final lang = context.language ?? '';
      final isTraditional =
          lang.contains('Hant') || lang.contains('TW') || lang.contains('HK');
      final map = isTraditional
          ? _verticalQuotationsMapHant
          : _verticalQuotationsMapHans;

      for (final entry in map.entries) {
        result = result.replaceAll(entry.key, entry.value);
      }
    }

    return result;
  }
}
