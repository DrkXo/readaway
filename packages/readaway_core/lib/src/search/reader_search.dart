import 'dart:math';

import '../abstracts/reflowable_document_reader.dart';
import '../readers/html_text_extractor.dart';

/// One occurrence of a search term inside one section of a reflowable document.
class ReaderSearchMatch {
  const ReaderSearchMatch({
    required this.sectionIndex,
    required this.start,
    required this.end,
    required this.snippet,
  });

  /// Section (chapter) that contains the match.
  final int sectionIndex;

  /// Character offset of the match within that section's plain-text rendering.
  final int start;

  /// One past the last character of the match.
  final int end;

  /// A short window of surrounding text used by results UI and highlighting.
  final String snippet;

  int get length => end - start;
}

/// A tiny, stateless search service over reflowable document sections.
///
/// Search is performed against the plain-text rendering of each section, so it
/// matches the words the reader actually sees rather than markup. Matches are
/// returned in reading order. The implementation is deliberately synchronous and
/// allocation-light enough to be run on an isolate later without changes.
class ReaderSearchService {
  const ReaderSearchService();

  /// All non-overlapping matches of [query] in [reader].
  ///
  /// Returns an empty list for an empty or whitespace-only query. Results are
  /// capped at [maxResults] to keep large books (or common words) usable.
  List<ReaderSearchMatch> search(
    ReflowableDocumentReader reader,
    String query, {
    int maxResults = 2000,
    int contextChars = 60,
  }) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty || maxResults <= 0) return const [];

    final pattern = RegExp(RegExp.escape(needle), caseSensitive: false);
    final results = <ReaderSearchMatch>[];
    for (var section = 0; section < reader.sectionCount; section++) {
      if (results.length >= maxResults) break;

      final text = reader.extractSectionText(section);
      final lower = text.toLowerCase();
      var cursor = 0;
      while (true) {
        if (results.length >= maxResults) break;
        final match = pattern.firstMatch(lower.substring(cursor));
        if (match == null) break;

        final start = cursor + match.start;
        final end = start + match.group(0)!.length;
        results.add(
          ReaderSearchMatch(
            sectionIndex: section,
            start: start,
            end: end,
            snippet: _snippet(text, start, end, contextChars),
          ),
        );

        cursor = end;
        if (cursor == text.length) break;
      }
    }
    return results;
  }

  static String _snippet(String text, int start, int end, int context) {
    final excerptStart = max(0, start - context);
    final excerptEnd = min(text.length, end + context);
    final raw = text.substring(excerptStart, excerptEnd).replaceAll('\n', ' ');
    if (excerptStart > 0) return '…$raw';
    if (excerptEnd < text.length) return '$raw…';
    return raw;
  }
}
