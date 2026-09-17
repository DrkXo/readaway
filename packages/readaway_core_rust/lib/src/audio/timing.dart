import 'dart:math' as math;

/// Exponent governing how aggressively pauses compress as narration speeds up.
const double kRateCompressionExponent = 0.6;

/// Floor applied to every estimated utterance duration, in seconds.
const double kMinUtteranceSeconds = 0.3;

/// Cold-start speaking rate for CJK scripts, in countable characters/second.
const double kCjkDefaultCharsPerSecond = 4.5;

/// Cold-start speaking rate for alphabetic scripts, in countable characters/second.
const double kLatinDefaultCharsPerSecond = 15;

/// Nominal pause between sentences at 1× playback, in seconds.
const double kDefaultSentenceGapSec = 0.15;

/// Nominal pause between paragraphs at 1× playback, in seconds.
const double kDefaultParagraphGapSec = 0.3;

/// Scales a nominal pause of [baseGapSec] for a playback [rate].
double scaleGapForRate(double baseGapSec, double rate) {
  if (!(rate > 0)) return baseGapSec;
  return (baseGapSec / math.pow(rate, kRateCompressionExponent) * 100).round() /
      100;
}

/// Returns the seconds of silence to bake into synthesized audio.
double bakedGapForRate(double baseGapSec, double rate) {
  if (!(rate > 0)) return baseGapSec;
  return scaleGapForRate(baseGapSec, rate) * rate;
}

/// Reports whether [languageTag] denotes a CJK script.
bool isCjkLanguage(String languageTag) {
  final tag = languageTag.toLowerCase();
  return tag.startsWith('zh') || tag.startsWith('ja') || tag.startsWith('ko');
}

/// Reduces [text] to comparable lexical content for rate measurements.
String normalizeForCounting(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

/// Estimates how long uttering [text] will take, in seconds.
double estimateUtteranceSeconds({
  required String text,
  required String language,
  double? calibratedCharsPerSecond,
}) {
  final chars = normalizeForCounting(text).length;
  if (chars == 0) return 0;

  final cps =
      calibratedCharsPerSecond ??
      (isCjkLanguage(language)
          ? kCjkDefaultCharsPerSecond
          : kLatinDefaultCharsPerSecond);
  if (!(cps > 0)) return kMinUtteranceSeconds;

  final seconds = chars / cps;
  return seconds < kMinUtteranceSeconds ? kMinUtteranceSeconds : seconds;
}
