import '../models/models.dart';
import '../readers/html_text_extractor.dart';
import 'sentence_segmenter.dart';
import 'speech_normalizer.dart';

/// Preprocesses raw HTML or plain text into normalized TTS chunks for speech synthesis.
///
/// Performs:
/// 1. HTML tag removal and footnote isolation (if HTML).
/// 2. Unicode NFKC normalization and zero-width character stripping.
/// 3. Sentence boundary segmentation with abbreviation disambiguation.
/// 4. Spoken text expansion ($42.50 -> forty-two dollars and fifty cents, Dr. -> Doctor).
/// 5. Phonetic transliteration with diacritics removal for Latin text.
/// 6. Duration estimation and character offset tracking.
class TtsChunker {
  static const int defaultMaxParagraphChunkChars = 450;

  const TtsChunker._();

  /// Preprocesses [text] into normalized [TtsChunk]s.
  static List<TtsChunk> preprocessText({
    required String text,
    int sectionIndex = 0,
    String? language,
    bool isHtml = false,
    int maxParagraphChunkChars = defaultMaxParagraphChunkChars,
  }) {
    final cleanText = isHtml ? HtmlTextExtractor.extractSpeechText(text) : text;
    final lang = (language != null && language.isNotEmpty) ? language : 'en';

    // Split into paragraph blocks by newlines
    final paragraphs = cleanText
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return const [];
    }

    final chunks = <TtsChunk>[];
    var globalChunkIdx = 0;
    var searchCursor = 0;
    for (var paraIdx = 0; paraIdx < paragraphs.length; paraIdx++) {
      final para = paragraphs[paraIdx];
      final paraLen = para.length;

      final paraStart = cleanText.indexOf(para, searchCursor);
      final effectiveStart = paraStart != -1 ? paraStart : searchCursor;
      searchCursor = effectiveStart + paraLen;

      if (paraLen <= maxParagraphChunkChars) {
        // Whole paragraph fits in a single cohesive natural chunk
        final spoken = SpeechNormalizer.normalizeForSpeech(para);
        final duration = SpeechNormalizer.estimateDurationMs(spoken);
        final start = effectiveStart;
        final end = effectiveStart + paraLen;
        final id = '$sectionIndex:$globalChunkIdx:$start';

        chunks.add(
          TtsChunk(
            id: id,
            sectionIndex: sectionIndex,
            sentenceIndex: globalChunkIdx,
            text: para,
            spokenText: spoken,
            startOffset: start,
            endOffset: end,
            estimatedDurationMs: duration,
            isParagraphEnd: true,
            paragraphIndex: paraIdx,
            words: extractWordSpans(para, start),
            language: lang,
          ),
        );
        globalChunkIdx++;
      } else {
        // Paragraph is oversized: split into sentences and group up to maxParagraphChunkChars
        final spans = SentenceSegmenter.segmentSentences(para, lang);
        if (spans.isEmpty) {
          final spoken = SpeechNormalizer.normalizeForSpeech(para);
          final duration = SpeechNormalizer.estimateDurationMs(spoken);
          final start = effectiveStart;
          final end = effectiveStart + paraLen;
          final id = '$sectionIndex:$globalChunkIdx:$start';

          chunks.add(
            TtsChunk(
              id: id,
              sectionIndex: sectionIndex,
              sentenceIndex: globalChunkIdx,
              text: para,
              spokenText: spoken,
              startOffset: start,
              endOffset: end,
              estimatedDurationMs: duration,
              isParagraphEnd: true,
              paragraphIndex: paraIdx,
              words: extractWordSpans(para, start),
              language: lang,
            ),
          );
          globalChunkIdx++;
        } else {
          final subSpans = <SentenceSpan>[];
          var currentLen = 0;

          for (var sIdx = 0; sIdx < spans.length; sIdx++) {
            final span = spans[sIdx];
            final spanLen = span.text.length;

            if (currentLen + spanLen > maxParagraphChunkChars &&
                subSpans.isNotEmpty) {
              final firstSpan = subSpans.first;
              final lastSpan = subSpans.last;
              final combinedText = para.substring(
                firstSpan.charStart,
                lastSpan.charEnd,
              );
              final spoken = SpeechNormalizer.normalizeForSpeech(combinedText);
              final duration = SpeechNormalizer.estimateDurationMs(spoken);
              final start = effectiveStart + firstSpan.charStart;
              final end = effectiveStart + lastSpan.charEnd;
              final id = '$sectionIndex:$globalChunkIdx:$start';

              chunks.add(
                TtsChunk(
                  id: id,
                  sectionIndex: sectionIndex,
                  sentenceIndex: globalChunkIdx,
                  text: combinedText,
                  spokenText: spoken,
                  startOffset: start,
                  endOffset: end,
                  estimatedDurationMs: duration,
                  isParagraphEnd: false,
                  paragraphIndex: paraIdx,
                  words: extractWordSpans(combinedText, start),
                  language: lang,
                ),
              );
              globalChunkIdx++;
              subSpans.clear();
              currentLen = 0;
            }

            subSpans.add(span);
            currentLen += spanLen + 1;

            if (sIdx == spans.length - 1 && subSpans.isNotEmpty) {
              final firstSpan = subSpans.first;
              final lastSpan = subSpans.last;
              final combinedText = para.substring(
                firstSpan.charStart,
                lastSpan.charEnd,
              );
              final spoken = SpeechNormalizer.normalizeForSpeech(combinedText);
              final duration = SpeechNormalizer.estimateDurationMs(spoken);
              final start = effectiveStart + firstSpan.charStart;
              final end = effectiveStart + lastSpan.charEnd;
              final id = '$sectionIndex:$globalChunkIdx:$start';

              chunks.add(
                TtsChunk(
                  id: id,
                  sectionIndex: sectionIndex,
                  sentenceIndex: globalChunkIdx,
                  text: combinedText,
                  spokenText: spoken,
                  startOffset: start,
                  endOffset: end,
                  estimatedDurationMs: duration,
                  isParagraphEnd: true,
                  paragraphIndex: paraIdx,
                  words: extractWordSpans(combinedText, start),
                  language: lang,
                ),
              );
              globalChunkIdx++;
            }
          }
        }
      }
    }

    return chunks;
  }

  static final RegExp _wordTokenRe = RegExp(
    r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]|[\w\u00C0-\u024F\u1E00-\u1EFF\u0400-\u04FF\u0370-\u03FF\u0600-\u06FF\u0900-\u097F\x27\-]+',
    unicode: true,
  );

  /// Extracts word-level spans with speech coordinates.
  static List<TtsWordSpan> extractWordSpans(String text, int baseOffset) {
    if (text.isEmpty) return const [];
    final spans = <TtsWordSpan>[];
    for (final match in _wordTokenRe.allMatches(text)) {
      final word = match.group(0)!;
      final trimmed = word.trim();
      if (trimmed.isEmpty) continue;
      spans.add(
        TtsWordSpan(
          word: trimmed,
          startOffset: baseOffset + match.start,
          endOffset: baseOffset + match.end,
        ),
      );
    }
    return spans;
  }
}
