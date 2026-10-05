import 'tts_timeline.dart';

/// Builds LRC (`.lrc`) lyric text from a [TtsTimeline] and the chunks it
/// describes.
///
/// LRC is a line-oriented format: one line per utterance, each prefixed with
/// the wall-clock time at which it begins. That is exactly the shape a
/// [TtsTimeline] already has, so this is a projection rather than a
/// computation — every timestamp here is a measured audio boundary, not an
/// estimate.
///
/// ## Interoperability
///
/// The output is deliberately written to the strictest reading of the format,
/// because consumers vary in how forgiving their parsers are:
///
/// * **Three fractional digits, always.** `[mm:ss.xx]` and `[mm:ss.xxx]` are
///   both widely accepted, but a consumer that assumes a fixed two digits will
///   misread `.5` as 50 ms rather than 500 ms. Emitting exactly three leaves
///   no ambiguity for anyone.
/// * **A leading metadata tag.** `[ti:...]`, `[ar:...]` and `[al:...]` are
///   conventional and are ignored by parsers that do not understand them.
///   The offset tag is written as `0` because the timeline is already exact;
///   it exists so a player has an explicit hook rather than assuming one.
/// * **No line breaks inside a line.** LRC is newline-delimited, so a stray
///   newline in the source would split one utterance into two entries and
///   desynchronise the reader from the timeline. Newlines are collapsed to
///   spaces by [sanitizeLrcText].
///
/// A chunk whose text is empty after sanitising is skipped rather than given a
/// fabricated timestamp. It still occupied time on the timeline, so the
/// surviving lines keep their own measured positions — the hole is visible as a
/// gap, which is the truth.
///
/// ## Lossy by necessity
///
/// LRC has no escaping mechanism, so a line body cannot literally begin with
/// something that looks like a timestamp. Left in place it would be read as a
/// second time anchor and render the line twice — once at its real position and
/// once at the embedded one. [sanitizeLrcText] therefore drops a leading
/// timestamp. Text of the form `[00:45] he sang` loses those five characters;
/// this is a property of the format, not a rounding error, and it is the only
/// choice that leaves the timeline intact.
String buildLrc({
  required TtsTimeline timeline,
  required List<String> texts,
  String title = '',
  String artist = '',
  String album = '',
}) {
  assert(
    texts.length <= timeline.length,
    'got ${texts.length} texts for ${timeline.length} chunks',
  );

  final buffer = StringBuffer();
  if (title.isNotEmpty) buffer.writeln('[ti:$title]');
  if (artist.isNotEmpty) buffer.writeln('[ar:$artist]');
  if (album.isNotEmpty) buffer.writeln('[al:$album]');
  buffer.writeln('[offset:0]');

  for (var i = 0; i < texts.length; i++) {
    final text = sanitizeLrcText(texts[i]);
    if (text.isEmpty) continue;
    buffer
      ..write(formatLrcTimestamp(timeline.startOf(i)))
      ..write(text)
      ..writeln();
  }

  return buffer.toString();
}

/// Formats [position] as an LRC timestamp of the form `[mm:ss.xxx]`.
///
/// Minutes are not wrapped at 60. LRC consumers read the field as a running
/// total, so an hour-long narration reaching `mm = 75` is correct where a
/// wrapped `[15:00.000]` would be ambiguous against a 15-minute mark. Centis
/// and millis are always three digits: the leading zeros are what make `.5`
/// unambiguous, and dropping them is the single most common way a generated
/// LRC ends up off by a factor of ten.
String formatLrcTimestamp(Duration position) {
  final totalMs = position.inMilliseconds;
  final minutes = totalMs ~/ 60000;
  final seconds = (totalMs % 60000) ~/ 1000;
  final millis = totalMs % 1000;
  return '[${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}.'
      '${millis.toString().padLeft(3, '0')}]';
}

/// Prepares [text] for use as an LRC line body.
///
/// Three transformations, each required rather than cosmetic:
///
/// 1. **Newlines become spaces.** LRC is a line-delimited format, so an
///    embedded newline would silently split one utterance into two entries and
///    the second would appear at the next timestamp.
/// 2. **A leading timestamp is stripped.** Text that is itself a timestamp —
///    or a timestamp followed by more text — would be read by a parser as an
///    additional time anchor for this line, causing the line to be rendered
///    twice.
/// 3. **A BOM and zero-width marks are dropped.** These survive copying
///    through editors and document pipelines often enough that a stray BOM at
///    the start of a line makes some parsers treat the whole file as untimed.
String sanitizeLrcText(String text) {
  return text
      .replaceAll('\r\n', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      // BOM, ZWSP, ZWNJ, ZWJ and the word-joiner. Matched as a class rather
      // than written literally: an invisible character in source survives
      // review unnoticed and is lost to the first copy-paste or rebase.
      .replaceAll(RegExp('[\uFEFF\u200B\u200C\u200D\u2060]'), '')
      .replaceFirst(RegExp(r'^\[\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?\]'), '')
      .trim();
}

/// Parses an LRC timestamp back into a [Duration].
///
/// The inverse of [formatLrcTimestamp], provided so a generated file can be
/// verified without depending on a third-party parser. Accepts one to three
/// fractional digits, and a missing fraction, because real-world LRC uses all
/// three forms.
Duration? parseLrcTimestamp(String line) {
  final match = RegExp(r'^\[(\d{1,4}):(\d{1,2})(?:[.:](\d{1,3}))?\]')
      .firstMatch(line.trim());
  if (match == null) return null;

  final minutes = int.parse(match.group(1)!);
  final seconds = int.parse(match.group(2)!);
  final fraction = match.group(3);
  // A bare `.5` is 500 ms, not 50: the fraction is a decimal, so pad on the
  // right to three places before reading it.
  final millis = fraction == null || fraction.isEmpty
      ? 0
      : int.parse(fraction.padRight(3, '0'));
  return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
}

/// Extracts every `(timestamp, text)` pair from [lrc].
///
/// Lines that carry no timestamp are skipped, and a line carrying several
/// timestamps — the repeated-line convention for a chorus — yields one entry
/// per timestamp. Round-trips [buildLrc] so generated output can be checked
/// against the timeline that produced it.
List<({Duration start, String text})> parseLrc(String lrc) {
  final entries = <({Duration start, String text})>[];

  for (final rawLine in lrc.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    // An ID tag such as [ti:...] or [offset:0] is metadata, not an entry.
    if (RegExp(r'^\[[a-zA-Z]+:').hasMatch(line)) continue;

    final timestamps = RegExp(r'\[(\d{1,4}):(\d{1,2})(?:[.:](\d{1,3}))?\]')
        .allMatches(line);
    if (timestamps.isEmpty) continue;

    // Everything after the last timestamp is the text; a timestamp appearing
    // mid-line is an extra anchor for the same body.
    final text = line
        .replaceAllMapped(
          RegExp(r'\[\d{1,4}:\d{1,2}(?:[.:]\d{1,3})?\]'),
          (_) => '',
        )
        .trim();

    for (final match in timestamps) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final fraction = match.group(3);
      // The fraction is a decimal, so `.5` is half a second. Pad on the right
      // before reading it, which is the same rule the emitter relies on.
      final millis = fraction == null || fraction.isEmpty
          ? 0
          : int.parse(fraction.padRight(3, '0'));
      entries.add((
        start: Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        ),
        text: text,
      ));
    }
  }

  entries.sort((a, b) => a.start.compareTo(b.start));
  return entries;
}
