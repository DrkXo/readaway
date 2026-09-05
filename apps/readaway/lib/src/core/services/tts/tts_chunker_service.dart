import 'dart:async';
import 'dart:isolate';

import 'package:injectable/injectable.dart';

import '../isolate_service.dart';
import '../logging_service.dart';
import 'text_sanitizer.dart';
import 'tts_chunk_model.dart';

export 'text_sanitizer.dart';
export 'tts_chunk_model.dart';

/// Top-level entry point executed inside the worker isolate.
void _textChunkerIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();

  // 1. Handshake: Send worker's SendPort back to the host process
  mainSendPort.send(receivePort.sendPort);

  final chunker = TextChunker();

  // 2. Listen for incoming chunking commands
  receivePort.listen((message) {
    if (message is Map && message['id'] != null) {
      final Object id = message['id'];
      final text = message['text'] as String;
      final maxChunkChars = message['maxChunkChars'] as int? ?? 350;
      final sanitizeForSpeech = message['sanitizeForSpeech'] as bool? ?? true;

      try {
        final chunks = chunker.chunkSentences(
          text,
          maxChunkChars: maxChunkChars,
          sanitizeForSpeech: sanitizeForSpeech,
        );

        // Convert TtsChunk objects into primitive Maps for SendPort transfer
        final rawChunks = chunks.map((c) => c.toMap()).toList(growable: false);

        mainSendPort.send({'id': id, 'result': rawChunks});
      } catch (e, st) {
        mainSendPort.send({'id': id, 'error': '$e\n$st'});
      }
    }
  });
}

/// Facade service managing background isolate text chunking for TTS.
@lazySingleton
class TtsChunkingService {
  final IsolateService _isolateService;
  static const String _isolateName = 'text_chunker_worker';

  int _nextCommandId = 0;

  TtsChunkingService(this._isolateService);

  /// Spawns the worker isolate on demand. Idempotent.
  Future<void> start() async {
    if (_isolateService.isSpawned(_isolateName)) return;

    await _isolateService.spawn(
      name: _isolateName,
      entryPoint: _textChunkerIsolateEntryPoint,
    );
  }

  /// Kills the worker isolate.
  Future<void> stop() => dispose();

  /// Fully tears down the isolate.
  @disposeMethod
  Future<void> dispose() async {
    await _isolateService.disposeIsolate(_isolateName);
  }

  /// Offloads text chunking to the background worker isolate.
  ///
  /// Returns a list of [TtsChunk]s enriched with exact offsets, paragraph metadata,
  /// speech sanitization, and word boundaries.
  Future<List<TtsChunk>> chunkText(
    String text, {
    int maxChunkChars = 350,
    bool sanitizeForSpeech = true,
  }) async {
    if (text.trim().isEmpty) return const [];

    try {
      await start();

      final commandId = _nextCommandId++;
      final response = await _isolateService.sendCommand<List<dynamic>>(
        _isolateName,
        {
          'id': commandId,
          'text': text,
          'maxChunkChars': maxChunkChars,
          'sanitizeForSpeech': sanitizeForSpeech,
        },
      );

      return response
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => TtsChunk.fromMap(map))
          .toList(growable: false);
    } catch (e, st) {
      logger.w(
        'Worker isolate chunking failed, falling back to sync chunker',
        e,
        st,
      );
      final fallbackChunker = TextChunker();
      return fallbackChunker.chunkSentences(
        text,
        maxChunkChars: maxChunkChars,
        sanitizeForSpeech: sanitizeForSpeech,
      );
    }
  }
}

/// High-performance multi-script text chunking engine.
///
/// Features:
/// - Multi-script sentence boundary detection (Latin, CJK, Cyrillic, etc.)
/// - Trailing quotation mark and bracket attachment
/// - Extensive abbreviation, title, decimal, and initial protection
/// - Hierarchical clause breakpoint search for long utterances (Readest style)
/// - Unspeakable noise filtering (ornamental dividers, bullet symbols)
/// - Exact 1:1 character offset tracking
/// - Paragraph boundary identification
@LazySingleton()
class TextChunker {
  /// Matches two or more linebreaks indicating a paragraph division.
  static final RegExp _paragraphSplit = RegExp(r'\r?\n\s*\r?\n');

  /// Closing punctuation (quotes, brackets) that attach to preceding sentence.
  static const String _closingQuotesAndBrackets = '"\'”’」』）］】»›\\]\\)';

  /// Sentence terminators:
  /// Group 1: Latin/European [.!?\u2026]
  /// Group 2: CJK terminators [。！？\u3002\uff01\uff1f]
  static final RegExp _sentenceEndPattern = RegExp(
    '(?:([.!?\u2026]+)|([。！？\u3002\uff01\uff1f]))([$_closingQuotesAndBrackets]*)',
    unicode: true,
  );

  /// Standard abbreviations where a trailing period does not mark the end of a sentence.
  static const Set<String> _abbreviations = {
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
    'capt.',
    'col.',
    'gen.',
    'gov.',
    'lt.',
    'maj.',
    'rev.',
    'sgt.',
    'sen.',
    'rep.',
    'dept.',
    'univ.',
    'est.',
    'inc.',
    'ltd.',
    'corp.',
    'co.',
    'vol.',
    'pp.',
    'p.',
    'jan.',
    'feb.',
    'mar.',
    'apr.',
    'aug.',
    'sept.',
    'oct.',
    'nov.',
    'dec.',
    'a.m.',
    'p.m.',
    'al.',
  };

  /// Single-letter initials like "J." in "J. K. Rowling".
  static final RegExp _singleInitialPattern = RegExp(r'^[A-Za-z]\.$');

  /// Multi-letter acronyms like "U.S." or "U.S.A.".
  static final RegExp _acronymPattern = RegExp(r'^(?:[A-Za-z]\.){2,}$');

  /// Splits [text] into speech-ready, display-aligned [TtsChunk]s.
  List<TtsChunk> chunkSentences(
    String text, {
    int maxChunkChars = 350,
    bool sanitizeForSpeech = true,
  }) {
    if (text.trim().isEmpty) return const [];

    final chunks = <TtsChunk>[];

    // 1. Enumerate paragraph spans
    final paragraphSpans = _findParagraphSpans(text);

    for (var pIdx = 0; pIdx < paragraphSpans.length; pIdx++) {
      final pSpan = paragraphSpans[pIdx];
      final pRawText = text.substring(pSpan.start, pSpan.end);
      if (pRawText.trim().isEmpty) continue;

      // 2. Segment sentences within this paragraph
      final sentenceSpans = _segmentParagraphSentences(
        text,
        pSpan.start,
        pSpan.end,
      );

      final pChunks = <TtsChunk>[];

      for (final sSpan in sentenceSpans) {
        // Trim bounds accurately relative to source text
        final trimmed = _trimSpan(text, sSpan.start, sSpan.end);
        if (trimmed == null) continue;

        final trimmedText = text.substring(trimmed.start, trimmed.end);
        if (!TextSanitizer.isSpeakable(trimmedText)) continue;

        // 3. Handle utterance length
        if (trimmedText.length <= maxChunkChars) {
          final spoken = sanitizeForSpeech
              ? TextSanitizer.sanitizeForSpeech(trimmedText)
              : trimmedText;

          pChunks.add(
            TtsChunk(
              text: trimmedText,
              spokenText: spoken,
              startOffset: trimmed.start,
              endOffset: trimmed.end,
              rawStartOffset: sSpan.start,
              rawEndOffset: sSpan.end,
              paragraphIndex: pIdx,
              words: _computeWordSpans(trimmedText, trimmed.start),
            ),
          );
        } else {
          // Hierarchical sub-sentence clause wrapping
          final subChunks = _hierarchicalClauseWrap(
            text,
            trimmed.start,
            trimmed.end,
            maxChunkChars,
            pIdx,
            sanitizeForSpeech: sanitizeForSpeech,
          );
          pChunks.addAll(subChunks);
        }
      }

      // Mark the last chunk of this paragraph as paragraph-end
      if (pChunks.isNotEmpty) {
        final last = pChunks.removeLast();
        pChunks.add(last.copyWith(isParagraphEnd: true));
        chunks.addAll(pChunks);
      }
    }

    return chunks;
  }

  /// Locates non-empty paragraph text spans separated by blank lines.
  List<_RawSpan> _findParagraphSpans(String text) {
    final spans = <_RawSpan>[];
    var start = 0;

    for (final match in _paragraphSplit.allMatches(text)) {
      if (match.start > start) {
        spans.add(_RawSpan(start, match.start));
      }
      start = match.end;
    }

    if (start < text.length) {
      spans.add(_RawSpan(start, text.length));
    }

    return spans;
  }

  /// Segments a paragraph range into sentence spans.
  List<_RawSpan> _segmentParagraphSentences(String text, int pStart, int pEnd) {
    final paragraphText = text.substring(pStart, pEnd);
    final spans = <_RawSpan>[];
    var cursor = 0;

    final matches = _sentenceEndPattern.allMatches(paragraphText).toList();

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final latinTerminator = match.group(1);
      final cjkTerminator = match.group(2);
      final matchEnd = match.end;

      if (latinTerminator != null) {
        // Decimal check: e.g. "3.14" -> skip
        if (latinTerminator == '.' && _isDecimalNumber(paragraphText, match.start)) {
          continue;
        }

        final isAtEnd = matchEnd >= paragraphText.length;
        final hasFollowingWhitespace = !isAtEnd &&
            RegExp(r'\s').hasMatch(paragraphText[matchEnd]);

        if (!isAtEnd && !hasFollowingWhitespace) {
          // e.g. web address, file extension, or email
          continue;
        }

        // Dialogue tag check: If punctuation is enclosed in quotation marks (e.g. "Wait!" he said)
        // and followed by a lowercase word (dialogue attribution), keep as single utterance.
        final closingQuote = match.group(3);
        if (closingQuote != null && closingQuote.isNotEmpty && !isAtEnd) {
          final remainder = paragraphText.substring(matchEnd).trimLeft();
          if (remainder.isNotEmpty && RegExp(r'^[a-z]').hasMatch(remainder)) {
            continue;
          }
        }

        // Abbreviation / Initial / Acronym check
        if (latinTerminator == '.' &&
            _isAbbreviationOrInitial(paragraphText, match.start)) {
          continue;
        }
      } else if (cjkTerminator != null) {
        // CJK terminators (。！？) are unambiguous and require no following space
      }

      if (matchEnd > cursor) {
        spans.add(_RawSpan(pStart + cursor, pStart + matchEnd));
        cursor = matchEnd;
      }
    }

    if (cursor < paragraphText.length) {
      spans.add(_RawSpan(pStart + cursor, pStart + paragraphText.length));
    }

    return spans;
  }

  /// Checks whether a period at [periodIndex] is part of a decimal number (e.g. 3.14).
  bool _isDecimalNumber(String text, int periodIndex) {
    if (periodIndex <= 0 || periodIndex >= text.length - 1) return false;
    final prev = text.codeUnitAt(periodIndex - 1);
    final next = text.codeUnitAt(periodIndex + 1);
    const zero = 48; // '0'
    const nine = 57; // '9'
    return prev >= zero && prev <= nine && next >= zero && next <= nine;
  }

  /// Checks whether the word preceding a period at [periodIndex] is an abbreviation or initial.
  bool _isAbbreviationOrInitial(String text, int periodIndex) {
    final prefix = text.substring(0, periodIndex + 1);
    final lastWord = prefix.split(RegExp(r'\s+')).lastOrNull?.toLowerCase() ?? '';
    if (lastWord.isEmpty) return false;

    if (_abbreviations.contains(lastWord)) return true;
    if (_singleInitialPattern.hasMatch(lastWord)) return true;
    if (_acronymPattern.hasMatch(lastWord)) return true;

    return false;
  }

  /// Hierarchically slices a long utterance (> [maxChars]) using natural clause breakpoints.
  ///
  /// Priorities (Readest tiered strategy):
  /// 1. Major clause separators (;, :, —)
  /// 2. Parentheses/brackets
  /// 3. Commas & pauses (,)
  /// 4. Common conjunctions (and, but, or, which, that)
  /// 5. Whitespace
  /// 6. Hard break
  List<TtsChunk> _hierarchicalClauseWrap(
    String text,
    int start,
    int end,
    int maxChars,
    int paragraphIndex, {
    required bool sanitizeForSpeech,
  }) {
    final chunks = <TtsChunk>[];
    var cursor = start;

    while (cursor < end) {
      final remainingLen = end - cursor;
      if (remainingLen <= maxChars) {
        final trimmed = _trimSpan(text, cursor, end);
        if (trimmed != null) {
          final piece = text.substring(trimmed.start, trimmed.end);
          if (TextSanitizer.isSpeakable(piece)) {
            final spoken = sanitizeForSpeech
                ? TextSanitizer.sanitizeForSpeech(piece)
                : piece;
            chunks.add(
              TtsChunk(
                text: piece,
                spokenText: spoken,
                startOffset: trimmed.start,
                endOffset: trimmed.end,
                rawStartOffset: cursor,
                rawEndOffset: end,
                paragraphIndex: paragraphIndex,
                words: _computeWordSpans(piece, trimmed.start),
              ),
            );
          }
        }
        break;
      }

      final targetEnd = cursor + maxChars;
      final breakPoint = _findBreakPoint(text, cursor, targetEnd, end);
      final sliceEnd = (breakPoint > cursor) ? breakPoint : targetEnd;

      final trimmed = _trimSpan(text, cursor, sliceEnd);
      if (trimmed != null) {
        final piece = text.substring(trimmed.start, trimmed.end);
        if (TextSanitizer.isSpeakable(piece)) {
          final spoken = sanitizeForSpeech
              ? TextSanitizer.sanitizeForSpeech(piece)
              : piece;
          chunks.add(
            TtsChunk(
              text: piece,
              spokenText: spoken,
              startOffset: trimmed.start,
              endOffset: trimmed.end,
              rawStartOffset: cursor,
              rawEndOffset: sliceEnd,
              paragraphIndex: paragraphIndex,
              words: _computeWordSpans(piece, trimmed.start),
            ),
          );
        }
      }

      cursor = sliceEnd;
    }

    return chunks;
  }

  /// Searches backwards from [targetEnd] within a search range for the best syntactic boundary.
  int _findBreakPoint(String text, int start, int targetEnd, int totalEnd) {
    const searchRange = 70;
    final searchStart = (targetEnd - searchRange).clamp(start, totalEnd);
    final searchEnd = targetEnd.clamp(searchStart, totalEnd);
    final window = text.substring(searchStart, searchEnd);

    // 1. Major clause separators (;, :, —, –)
    final clauseMatch = RegExp(r'[;:—–；：]\s*').allMatches(window).lastOrNull;
    if (clauseMatch != null && clauseMatch.end > (searchRange * 0.2)) {
      return searchStart + clauseMatch.end;
    }

    // 2. Parentheses / brackets
    final parenMatch = RegExp(r'[\)\]）】]\s*').allMatches(window).lastOrNull;
    if (parenMatch != null && parenMatch.end > (searchRange * 0.2)) {
      return searchStart + parenMatch.end;
    }

    // 3. Commas & pauses (,, ，, 、)
    final commaMatch = RegExp(r'[,，、]\s*').allMatches(window).lastOrNull;
    if (commaMatch != null && commaMatch.end > (searchRange * 0.2)) {
      return searchStart + commaMatch.end;
    }

    // 4. Conjunctions
    final conjMatch = RegExp(r'\s+(?:and|but|or|so|yet|which|that|because|although)\s+', caseSensitive: false)
        .allMatches(window)
        .lastOrNull;
    if (conjMatch != null && conjMatch.start > (searchRange * 0.2)) {
      return searchStart + conjMatch.start + 1; // Break before conjunction
    }

    // 5. Whitespace
    final spaceMatch = RegExp(r'\s+').allMatches(window).lastOrNull;
    if (spaceMatch != null && spaceMatch.end > (searchRange * 0.2)) {
      return searchStart + spaceMatch.end;
    }

    return targetEnd;
  }

  /// Adjusts span start and end to exclude leading and trailing whitespace.
  _RawSpan? _trimSpan(String text, int start, int end) {
    var s = start;
    var e = end;

    while (s < e && RegExp(r'\s').hasMatch(text[s])) {
      s++;
    }
    while (e > s && RegExp(r'\s').hasMatch(text[e - 1])) {
      e--;
    }

    if (s >= e) return null;
    return _RawSpan(s, e);
  }

  /// Decomposes chunk [text] into relative [TtsWordSpan]s.
  List<TtsWordSpan> _computeWordSpans(String text, int chunkStartOffset) {
    final words = <TtsWordSpan>[];
    final wordRegex = RegExp(r'\S+');

    for (final m in wordRegex.allMatches(text)) {
      words.add(
        TtsWordSpan(
          word: m.group(0)!,
          startOffset: m.start,
          endOffset: m.end,
        ),
      );
    }

    return words;
  }
}

class _RawSpan {
  const _RawSpan(this.start, this.end);
  final int start;
  final int end;
}
