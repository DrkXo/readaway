import 'dart:math' as math;

import '../models/models.dart';
import 'timing.dart';

/// Base pause durations in seconds for various punctuation marks at 1× playback.
class PunctuationPauses {
  const PunctuationPauses._();

  /// Comma and caesura pauses (Latin comma, CJK fullwidth comma, ideographic comma, Arabic comma).
  static const double commaSec = 0.18;

  /// Mid-sentence clause breaks (semicolon, colon, CJK fullwidth counterparts, em/en dashes).
  static const double clauseBreakSec = 0.22;

  /// Exclamation and question marks (standard and fullwidth, Arabic question mark).
  static const double exclamationQuestionSec = 0.28;

  /// Standard sentence terminators (period, CJK full stop, Indic danda / double danda).
  static const double sentenceTerminalSec = 0.35;

  /// Ellipsis and prolonged pauses.
  static const double ellipsisSec = 0.50;

  /// Default paragraph transition gap.
  static const double paragraphGapSec = 0.80;
}

/// Represents a segmented speech phrase with its trailing prosodic pause.
class SpeechProsodySpan {
  /// The text phrase to synthesize.
  final String text;

  /// The trailing pause in seconds to insert after this speech span.
  final double pauseAfterSec;

  const SpeechProsodySpan({required this.text, this.pauseAfterSec = 0.0});

  @override
  String toString() =>
      'SpeechProsodySpan(text: "$text", pauseAfterSec: ${pauseAfterSec.toStringAsFixed(3)}s)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeechProsodySpan &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          pauseAfterSec == other.pauseAfterSec;

  @override
  int get hashCode => Object.hash(text, pauseAfterSec);
}

/// Computes graded pause duration based on the trailing punctuation of [text].
///
/// Supports Latin, CJK, Arabic, and Indic punctuation characters:
/// - Ellipsis (`...`, `…`, `……`): 500ms
/// - Sentence terminals (`.`, `。`, `।`, `॥`): 350ms
/// - Exclamations / Questions (`!`, `?`, `！`, `？`, `؟`): 280ms
/// - Clause breaks (`;`, `:`, `；`, `：`, `—`, `–`, `؛`): 220ms
/// - Commas / Caesura (`,`, `，`, `、`, `،`): 180ms
double punctuationBasePauseSec(String text) {
  final trimmed = text.trimRight();
  if (trimmed.isEmpty) return PunctuationPauses.commaSec;

  var clean = trimmed;
  // Strip trailing closing quotes and brackets to inspect the terminating punctuation
  while (clean.isNotEmpty &&
      (clean.endsWith('"') ||
          clean.endsWith("'") ||
          clean.endsWith('”') ||
          clean.endsWith('’') ||
          clean.endsWith('»') ||
          clean.endsWith(')') ||
          clean.endsWith('）') ||
          clean.endsWith(']') ||
          clean.endsWith('}') ||
          clean.endsWith('」') ||
          clean.endsWith('』') ||
          clean.endsWith('】'))) {
    clean = clean.substring(0, clean.length - 1).trimRight();
  }

  if (clean.isEmpty) return PunctuationPauses.commaSec;

  if (clean.endsWith('...') || clean.endsWith('…') || clean.endsWith('……')) {
    return PunctuationPauses.ellipsisSec;
  }

  final lastChar = clean[clean.length - 1];
  switch (lastChar) {
    case '.':
    case '。':
    case '।':
    case '॥':
      return PunctuationPauses.sentenceTerminalSec;

    case '!':
    case '?':
    case '！':
    case '？':
    case '؟':
      return PunctuationPauses.exclamationQuestionSec;

    case ';':
    case ':':
    case '；':
    case '：':
    case '—':
    case '–':
    case '؛':
      return PunctuationPauses.clauseBreakSec;

    case ',':
    case '，':
    case '、':
    case '،':
      return PunctuationPauses.commaSec;

    default:
      return PunctuationPauses.sentenceTerminalSec;
  }
}

/// Splits [text] into prosodic sub-phrases delimited by punctuation marks,
/// computing natural silence durations for each span.
///
/// Delimiters include:
/// - Commas / Caesuras: `,`, `，`, `、`, `،`
/// - Clause breaks: `;`, `:`, `；`, `：`, `—`, `–`, `؛`
/// - Exclamations & Questions: `!`, `?`, `！`, `？`, `؟`
/// - Sentence terminals: `.`, `。`, `।`, `॥`
/// - Ellipses: `...`, `…`, `……`
List<SpeechProsodySpan> splitProsodySpans(
  String text, {
  int sentenceGapMs = 0,
  double silenceScaleMultiplier = 1.0,
  bool enableJitter = true,
  math.Random? random,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];

  // Match punctuation marks (and any trailing quotes/brackets), ignoring decimals and thousand separators.
  final pattern = RegExp(
    r"""(\.\.\.+|[…]+|[。!\?！？؟;:；：—–\u0964\u0965\uFF0C\u3001\u060C\u061B]|\.(?!\d)|,(?!\d))[’”"'»\)\]\}」』】]*""",
  );

  final matches = pattern.allMatches(trimmed).toList();
  if (matches.isEmpty) {
    return [SpeechProsodySpan(text: trimmed, pauseAfterSec: 0.0)];
  }

  final spans = <SpeechProsodySpan>[];
  var lastIndex = 0;

  for (final match in matches) {
    final segment = trimmed.substring(lastIndex, match.end).trim();
    if (segment.isNotEmpty) {
      final puncBase = punctuationBasePauseSec(segment);
      double pauseSec;
      if (sentenceGapMs > 0) {
        final ratio =
            (sentenceGapMs / 1000.0) / PunctuationPauses.sentenceTerminalSec;
        pauseSec = puncBase * ratio;
      } else {
        pauseSec = puncBase;
      }

      if (silenceScaleMultiplier > 0) {
        pauseSec *= silenceScaleMultiplier;
      }
      if (enableJitter && pauseSec > 0) {
        pauseSec = applyNaturalJitter(pauseSec, random: random);
      }
      spans.add(SpeechProsodySpan(text: segment, pauseAfterSec: pauseSec));
    }
    lastIndex = match.end;
  }

  if (lastIndex < trimmed.length) {
    final remainder = trimmed.substring(lastIndex).trim();
    if (remainder.isNotEmpty) {
      spans.add(SpeechProsodySpan(text: remainder, pauseAfterSec: 0.0));
    }
  }

  return spans;
}

/// Applies a natural non-metronomic jitter ($\pm 10\%$) to [baseSec].
///
/// A custom [random] instance can be provided for deterministic unit testing.
double applyNaturalJitter(
  double baseSec, {
  double jitterPercent = 0.10,
  math.Random? random,
}) {
  if (baseSec <= 0 || jitterPercent <= 0) return baseSec;
  final rng = random ?? math.Random();
  // Random factor between -jitterPercent and +jitterPercent
  final factor = (rng.nextDouble() * 2.0 * jitterPercent) - jitterPercent;
  final result = baseSec * (1.0 + factor);
  return result < 0 ? 0.0 : result;
}

/// Resolves the final seconds of silence to bake after [chunk].
///
/// - If [isLastChunk] is true, returns `0.0` (the final chunk carries no trailing pause).
/// - If [chunk.isParagraphEnd] is true, uses [paragraphGapMs].
/// - Otherwise, resolves pause between [sentenceGapMs] or punctuation-graded pause.
/// - Scales by [silenceScaleMultiplier] and applies jitter if [enableJitter] is true.
/// - Compresses for playback [rate] using [bakedGapForRate].
double computeChunkGapSec(
  TtsChunk chunk, {
  required int sentenceGapMs,
  required int paragraphGapMs,
  double silenceScaleMultiplier = 1.0,
  double rate = 1.0,
  bool isLastChunk = false,
  bool enableJitter = true,
  math.Random? random,
}) {
  if (isLastChunk) return 0.0;

  double baseSec;
  if (chunk.isParagraphEnd) {
    baseSec = paragraphGapMs > 0
        ? (paragraphGapMs / 1000.0)
        : PunctuationPauses.paragraphGapSec;
  } else {
    // If custom sentence gap is provided and different from default, use it as baseline
    final puncBase = punctuationBasePauseSec(chunk.text);
    if (sentenceGapMs > 0) {
      // Scale standard punctuation according to custom sentence gap baseline
      final ratio =
          (sentenceGapMs / 1000.0) / PunctuationPauses.sentenceTerminalSec;
      baseSec = puncBase * ratio;
    } else {
      baseSec = puncBase;
    }
  }

  // Scale by silence multiplier
  var scaledSec =
      baseSec * (silenceScaleMultiplier > 0 ? silenceScaleMultiplier : 1.0);

  // Apply ±10% jitter to prevent robotic metronome effect
  if (enableJitter && scaledSec > 0) {
    scaledSec = applyNaturalJitter(scaledSec, random: random);
  }

  // Bake for playback rate compression
  return bakedGapForRate(scaledSec, rate <= 0 ? 1.0 : rate);
}
