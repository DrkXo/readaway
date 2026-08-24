part of '../services.dart';

/// Splits ebook text into sentence-sized chunks for TTS.
///
/// Neural TTS engines (and even OS engines) do better — lower latency to
/// first audio, more natural pausing, easier to pause/resume/highlight —
/// when fed one sentence or clause at a time rather than a whole chapter
/// in one call. This also lets [ReaderTtsController] track which sentence
/// is currently playing for read-along highlighting.
class TtsChunk {
  const TtsChunk({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });

  /// The sentence/clause text, trimmed.
  final String text;

  /// Character offsets into the original source string, so the UI can
  /// map a chunk back to a highlightable range.
  final int startOffset;
  final int endOffset;
}

@lazySingleton
class TextChunker {
  final RegExp _sentenceBoundary = RegExp(
    r'(?<=[.!?\u2026])(?=\s|$)|(?<=\n)\s*\n',
  );

  /// Splits [text] into sentence-ish chunks. Consecutive very short
  /// fragments (e.g. "Mr." followed by a name) are merged back together
  /// using a short list of common abbreviations, since naive splitting on
  /// `.` breaks badly on those.
  List<TtsChunk> chunkSentences(
    String text, {
    int maxChunkChars = 400,
  }) {
    if (text.trim().isEmpty) return const [];

    final rawParts = <_RawSpan>[];
    var start = 0;
    for (final match in _sentenceBoundary.allMatches(text)) {
      final end = match.end;
      if (end > start) {
        rawParts.add(_RawSpan(start, end));
      }
      start = end;
    }
    if (start < text.length) {
      rawParts.add(_RawSpan(start, text.length));
    }

    final merged = _mergeAbbreviations(text, rawParts);
    final chunks = <TtsChunk>[];

    for (final span in merged) {
      final piece = text.substring(span.start, span.end).trim();
      if (piece.isEmpty) continue;

      if (piece.length <= maxChunkChars) {
        chunks.add(
          TtsChunk(text: piece, startOffset: span.start, endOffset: span.end),
        );
      } else {
        // Extremely long "sentence" (e.g. no punctuation for a while) —
        // hard-wrap on word boundaries so no single TTS call gets an
        // unbounded amount of text.
        chunks.addAll(_hardWrap(text, span.start, span.end, maxChunkChars));
      }
    }
    return chunks;
  }

  final _abbreviations = {
    'mr.',
    'mrs.',
    'ms.',
    'dr.',
    'prof.',
    'sr.',
    'jr.',
    'st.',
    'vs.',
    'etc.',
    'e.g.',
    'i.e.',
    'no.',
    'fig.',
    'approx.',
  };

  List<_RawSpan> _mergeAbbreviations(String text, List<_RawSpan> spans) {
    final result = <_RawSpan>[];
    for (final span in spans) {
      if (result.isNotEmpty) {
        final prevText = text
            .substring(result.last.start, result.last.end)
            .trimRight()
            .toLowerCase();
        final lastWord = prevText.split(RegExp(r'\s+')).lastOrNull ?? '';
        if (_abbreviations.contains(lastWord)) {
          result[result.length - 1] = _RawSpan(result.last.start, span.end);
          continue;
        }
      }
      result.add(span);
    }
    return result;
  }

  static List<TtsChunk> _hardWrap(
    String text,
    int start,
    int end,
    int maxChars,
  ) {
    final chunks = <TtsChunk>[];
    var cursor = start;
    while (cursor < end) {
      var sliceEnd = (cursor + maxChars).clamp(cursor, end);
      if (sliceEnd < end) {
        final lastSpace = text.lastIndexOf(RegExp(r'\s'), sliceEnd);
        if (lastSpace > cursor) sliceEnd = lastSpace;
      }
      final piece = text.substring(cursor, sliceEnd).trim();
      if (piece.isNotEmpty) {
        chunks.add(
          TtsChunk(text: piece, startOffset: cursor, endOffset: sliceEnd),
        );
      }
      cursor = sliceEnd;
    }
    return chunks;
  }
}

class _RawSpan {
  const _RawSpan(this.start, this.end);
  final int start;
  final int end;
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
