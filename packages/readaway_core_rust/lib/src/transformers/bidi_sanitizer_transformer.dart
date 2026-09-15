import '../models/transform_context.dart';
import 'text_transformer.dart';

/// Repairs Persian and Arabic ebook text shaping.
class BidiSanitizerTransformer implements TextTransformer {
  const BidiSanitizerTransformer();

  @override
  String get name => 'bidi_sanitizer';

  static final RegExp _rlmHalfSpaceRegex = RegExp(
    r'([\u0600-\u065F\u066A-\u06EF\u06FA-\u06FF\uFB50-\uFDFF\uFE70-\uFEFC])(\u200F+)(?=[\u0600-\u065F\u066A-\u06EF\u06FA-\u06FF\uFB50-\uFDFF\uFE70-\uFEFC])',
    unicode: true,
  );

  @override
  String transform(TransformContext context) {
    if (!context.content.contains('\u200F')) {
      return context.content;
    }

    return context.content.replaceAllMapped(_rlmHalfSpaceRegex, (m) {
      final precedingChar = m.group(1)!;
      final rlms = m.group(2)!;
      return '$precedingChar${'\u200C' * rlms.length}';
    });
  }
}
