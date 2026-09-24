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
    var currentCharOffset = 0;

    for (var paraIdx = 0; paraIdx < paragraphs.length; paraIdx++) {
      final para = paragraphs[paraIdx];
      final paraLen = para.length;

      if (paraLen <= maxParagraphChunkChars) {
        // Whole paragraph fits in a single cohesive natural chunk
        final spoken = SpeechNormalizer.normalizeForSpeech(para);
        final duration = SpeechNormalizer.estimateDurationMs(spoken);
        final start = currentCharOffset;
        final end = currentCharOffset + paraLen;
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
          final start = currentCharOffset;
          final end = currentCharOffset + paraLen;
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
              final combinedText = subSpans.map((s) => s.text).join(' ');
              final spoken = SpeechNormalizer.normalizeForSpeech(combinedText);
              final duration = SpeechNormalizer.estimateDurationMs(spoken);
              final start = currentCharOffset + subSpans.first.charStart;
              final end = currentCharOffset + subSpans.last.charEnd;
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
              final combinedText = subSpans.map((s) => s.text).join(' ');
              final spoken = SpeechNormalizer.normalizeForSpeech(combinedText);
              final duration = SpeechNormalizer.estimateDurationMs(spoken);
              final start = currentCharOffset + subSpans.first.charStart;
              final end = currentCharOffset + subSpans.last.charEnd;
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
                  language: lang,
                ),
              );
              globalChunkIdx++;
            }
          }
        }
      }

      currentCharOffset += paraLen + 1;
    }

    return chunks;
  }
}
