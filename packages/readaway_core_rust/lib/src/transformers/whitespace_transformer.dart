import '../models/transform_context.dart';
import 'text_transformer.dart';

/// Normalizes redundant whitespace, non-breaking spaces, and runs of spaces
/// while strictly preserving indentation and spacing inside `<pre>` and `<code>` blocks.
class WhitespaceTransformer implements TextTransformer {
  const WhitespaceTransformer();

  @override
  String get name => 'whitespace';

  RegExp get _preservedRegions =>
      RegExp(r'<(pre|code)\b[^>]*>[\s\S]*?<\/\1\s*>', caseSensitive: false);

  RegExp get _multipleSpaces => RegExp(r' {2,}');
  RegExp get _nbspPattern => RegExp(r'(?:&amp;)?&nbsp;', caseSensitive: false);

  @override
  String transform(TransformContext context) {
    if (!context.overrideLayout) return context.content;

    final content = context.content;
    if (!content.contains('<pre') && !content.contains('<code')) {
      return _collapseWhitespace(content);
    }

    final buffer = StringBuffer();
    var lastIndex = 0;

    for (final match in _preservedRegions.allMatches(content)) {
      buffer.write(
        _collapseWhitespace(content.substring(lastIndex, match.start)),
      );
      buffer.write(match.group(0)!);
      lastIndex = match.end;
    }

    buffer.write(_collapseWhitespace(content.substring(lastIndex)));
    return buffer.toString();
  }

  String _collapseWhitespace(String input) {
    return input
        .replaceAllMapped(_nbspPattern, (m) {
          return m.group(0)!.startsWith('&amp;') ? m.group(0)! : ' ';
        })
        .replaceAll('\u00A0', ' ')
        .replaceAll(_multipleSpaces, ' ');
  }
}
