/// Utility for splitting long texts into manageable chunks for upstream translation
/// APIs that impose request size limits.
class TextChunker {
  const TextChunker();

  /// Splits [text] into chunks of at most [maxLength] code units,
  /// breaking on sentence boundaries, newlines, or spaces whenever possible.
  List<String> splitIntoChunks(String text, int maxLength) {
    if (text.length <= maxLength) return [text];

    final chunks = <String>[];
    var start = 0;

    while (start < text.length) {
      if (text.length - start <= maxLength) {
        chunks.add(text.substring(start));
        break;
      }

      var end = start + maxLength;
      final window = text.substring(start, end);

      // Search for sentence boundaries in the window
      var cut = end;
      final sentenceEnd = _findLastSentenceEnd(window);

      if (sentenceEnd > maxLength ~/ 2) {
        cut = start + sentenceEnd + 1;
      } else {
        // Fall back to space boundary
        final lastSpace = window.lastIndexOf(' ');
        if (lastSpace > maxLength ~/ 2) {
          cut = start + lastSpace + 1;
        }
      }

      chunks.add(text.substring(start, cut));
      start = cut;
    }

    return chunks;
  }

  int _findLastSentenceEnd(String window) {
    final ends = [
      window.lastIndexOf('. '),
      window.lastIndexOf('! '),
      window.lastIndexOf('? '),
      window.lastIndexOf('。\n'),
      window.lastIndexOf('。\r\n'),
      window.lastIndexOf('。'),
      window.lastIndexOf('！'),
      window.lastIndexOf('？'),
      window.lastIndexOf('\n'),
    ];
    return ends.reduce((a, b) => a > b ? a : b);
  }
}
