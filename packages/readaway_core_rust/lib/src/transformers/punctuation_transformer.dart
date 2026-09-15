import '../models/transform_context.dart';
import 'text_transformer.dart';

/// Adapts quotation marks for vertical reading mode and variant conversions
/// (Simplified Chinese Hans vs Traditional Chinese Hant).
class PunctuationTransformer implements TextTransformer {
  const PunctuationTransformer();

  @override
  String get name => 'punctuation';

  static const Map<String, String> _verticalQuotationsMapHans = {
    '“': '﹃',
    '”': '﹄',
    '‘': '﹁',
    '’': '﹂',
    '「': '﹁',
    '」': '﹂',
    '『': '﹃',
    '』': '﹄',
  };

  static const Map<String, String> _verticalQuotationsMapHant = {
    '“': '﹁',
    '”': '﹂',
    '‘': '﹃',
    '’': '﹄',
    '「': '﹁',
    '」': '﹂',
    '『': '﹃',
    '』': '﹄',
  };

  static const Map<String, String> _quotationsMapHans2Hant = {
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

    final variant = context.convertChineseVariant;
    if (variant != null && variant != 'none') {
      final isToSimplified = variant.contains('2s');
      for (final entry in _quotationsMapHans2Hant.entries) {
        final from = isToSimplified ? entry.value : entry.key;
        final to = isToSimplified ? entry.key : entry.value;
        result = result.replaceAll(from, to);
      }
    }

    if (context.vertical) {
      final isHant = context.language?.toLowerCase().contains('hant') ?? false;
      final verticalMap =
          isHant ? _verticalQuotationsMapHant : _verticalQuotationsMapHans;
      for (final entry in verticalMap.entries) {
        result = result.replaceAll(entry.key, entry.value);
      }
    }

    return result;
  }
}
