import 'dart:math' as math;

/// Exponent governing how aggressively pauses compress as narration speeds up.
///
/// Dividing a pause by the raw rate shrinks it faster than the speech itself
/// compresses, gluing sentences together at 2×. Raising the rate to this power
/// instead yields a gentle curve: a 180 ms base gap lasts 164 ms at 1.5× and
/// 137 ms at 2×.
const double kRateCompressionExponent = 0.6;

/// Floor applied to every estimated utterance duration, in seconds.
///
/// Even a single-word sentence occupies measurable time once the engine's
/// attack and release envelopes are accounted for.
const double kMinUtteranceSeconds = 0.3;

/// Cold-start speaking rate for CJK scripts, in countable characters/second.
const double kCjkDefaultCharsPerSecond = 4.5;

/// Cold-start speaking rate for alphabetic scripts, in countable
/// characters/second.
const double kLatinDefaultCharsPerSecond = 15;

/// Nominal pause between sentences at 1× playback, in seconds.
const double kDefaultSentenceGapSec = 0.15;

/// Nominal pause between paragraphs at 1× playback, in seconds.
const double kDefaultParagraphGapSec = 0.3;

/// Scales a nominal pause of [baseGapSec] for a playback [rate].
///
/// This is the sole authority for pause compression: consumers treat the
/// returned value as wall-clock silence and must not rescale it, or the two
/// stages compound into `base / rate^1.6`.
///
/// Rates that are zero, negative, or NaN leave [baseGapSec] untouched. Results
/// are quantised to hundredths of a second — flooring to whole seconds would
/// erase every pause outright.
double scaleGapForRate(double baseGapSec, double rate) {
  if (!(rate > 0)) return baseGapSec;
  return (baseGapSec / math.pow(rate, kRateCompressionExponent) * 100).round() /
      100;
}

/// Returns the seconds of silence to bake into synthesized audio so that,
/// when played back at [rate], the pause lasts [scaleGapForRate] wall-clock
/// seconds.
///
/// Baked silence is audio, so the player's speed stretches it: `S` seconds of
/// silence plays in `S / rate` wall-clock seconds. Compensating with `* rate`
/// yields the wall-clock pause [scaleGapForRate] specifies. Rates that are
/// zero, negative, or NaN leave [baseGapSec] untouched.
double bakedGapForRate(double baseGapSec, double rate) {
  if (!(rate > 0)) return baseGapSec;
  return scaleGapForRate(baseGapSec, rate) * rate;
}

/// Reports whether [languageTag] denotes a CJK script.
///
/// Matching is case-insensitive and considers regional/variant suffixes, so
/// `zh`, `ZH-Hans`, `ja-JP`, and `ko-KR` all qualify.
bool isCjkLanguage(String languageTag) {
  final tag = languageTag.toLowerCase();
  return tag.startsWith('zh') || tag.startsWith('ja') || tag.startsWith('ko');
}

/// Reduces [text] to comparable lexical content for rate measurements.
///
/// Punctuation and casing are discarded because the spoken markup handed to the
/// engine and the raw range text tracked by the timeline differ only in those
/// dimensions. Separating runs collapse to a single space, which contributes to
/// the resulting length exactly as it did when calibrating persisted voices.
String normalizeForCounting(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

/// Estimates how long uttering [text] will take, in seconds.
///
/// Preference order: an explicit [calibratedCharsPerSecond] observed for the
/// active voice, otherwise the per-script default for [language]. Blank or
/// purely punctuational input measures zero; everything else observes
/// [kMinUtteranceSeconds].
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
