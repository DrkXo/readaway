import '../models/models.dart';
import 'text_transformer.dart';

/// Repairs Persian and Arabic ebook text shaping.
///
/// Legacy ebooks misuse the Right-to-Left Mark (RLM U+200F) as a compound-word half-space
/// (e.g. mi-ravam, ketab-ha), which breaks cursive Arabic shaping.
/// This transformer replaces runs of RLMs with Zero-Width Non-Joiners (ZWNJ U+200C)
/// when positioned strictly between Arabic-script non-digit characters.
class BidiSanitizerTransformer implements TextTransformer {
  const BidiSanitizerTransformer();

  @override
  String get name => 'bidi_sanitizer';

  // Arabic letters and signs excluding Arabic-Indic digits (0660-0669) and extended digits (06F0-06F9).
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
