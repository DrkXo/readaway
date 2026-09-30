import 'chapter_text_layout.dart';

/// A monotone correspondence between positions in a chapter's speech text and
/// positions in the same chapter's rendered flow text.
///
/// The two strings describe the same source but are not the same string. The
/// renderer shows the kanji base of a ruby annotation, adds list markers and
/// shows footnote containers; the speech side speaks the kana reading, omits
/// the markers and skips the footnotes. Character counts therefore differ, and
/// no fixed offset relates them.
///
/// This class recovers the relationship by matching the two strings against
/// each other rather than assuming one. Where characters line up the mapping
/// is exact. Where they genuinely differ — a ruby annotation, a list marker —
/// the difference is isolated into a single span, and only inside that span is
/// the answer an estimate. [isExact] reports which case a given offset is in,
/// so a caller can prefer a different strategy for the rare fuzzy region
/// instead of trusting an interpolated number.
///
/// The mapping is monotone: render positions never decrease as speech
/// positions advance, so a result can be used for page lookups without
/// re-checking ordering.
///
/// Two builders produce one, and they are not interchangeable:
///
/// * [SpeechCharMap.fromSpans] uses a layout's fragment geometry and is the
///   one to use whenever the layout has spans. Each span is a render range the
///   renderer already measured, so a span that is found in the speech text is a
///   *verified* correspondence rather than one recovered by inference. Text the
///   speech side does not speak — a footnote, a list marker — cannot drag the
///   mapping off course, because the next span that does place re-establishes
///   position by construction.
/// * [SpeechCharMap.build] diffs two strings and recovers their relationship
///   by resynchronising. It needs no geometry, which makes it the fallback for
///   a layout measured without spans, but it can only resynchronise within a
///   fixed lookahead. Past that it walks the two strings in step through text
///   that has no counterpart, and reports the result as exact.
///
/// [fromSpans] is preferred because it cannot lose its place.
class SpeechCharMap {
  /// How many matching characters may pass between anchors in an unbroken run.
  ///
  /// Every anchor inside such a run is a verified correspondence, so the run
  /// stays exact rather than being covered by one long interpolation. The
  /// interval only trades anchor-list size against how often a verified point
  /// is recorded; a smaller value costs more memory and fixes nothing further.
  static const _runAnchorInterval = 32;

  // The anchors and fuzzy spans are private, so they are positional rather than
  // named: Dart does not allow a named parameter to initialise a private field.
  const SpeechCharMap._(
    this._anchors,
    this._fuzzySpans, {
    required this.speechLength,
    required this.renderLength,
  });

  /// Length of the speech text this map was built from.
  final int speechLength;

  /// Length of the rendered flow text this map was built from.
  final int renderLength;

  final List<_Anchor> _anchors;

  /// Speech ranges whose mapping is interpolated rather than matched.
  ///
  /// Sorted, non-overlapping, and never touching. Their interiors are the only
  /// places a result is an estimate.
  final List<_Span> _fuzzySpans;

  /// Whether [speechChar] maps to a trustworthy render position.
  ///
  /// False strictly inside a span where the two texts differ, such as a ruby
  /// annotation. The closing boundary of such a span is exact: it is a point the
  /// matcher resynchronised on, so the offset there is known. The opening
  /// boundary is exact too, unless the span runs from the start of the speech
  /// text and nothing had been placed there — see [fromSpans], where the first
  /// position of a chapter has no anchor behind it to be exact relative to.
  ///
  /// The result is still monotone and close when this is false — it is an
  /// interpolation across the differing text, not a guess.
  bool isExact(int speechChar) {
    if (speechChar < 0 || speechChar > speechLength) return false;
    var low = 0;
    var high = _fuzzySpans.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final span = _fuzzySpans[mid];
      if (span.start < speechChar) {
        if (speechChar < span.end) return false;
        low = mid + 1;
      } else if (speechChar == span.start) {
        // The opening boundary of a span is an anchor, and so exact — unless the
        // span runs from the very start of the speech text and nothing had been
        // placed there yet, in which case the boundary is the seed anchor and
        // nothing has verified it.
        return span.startIsVerified;
      } else {
        high = mid - 1;
      }
    }
    return true;
  }

  /// Number of speech characters whose mapping is established by matching.
  int get exactSpeechChars {
    var fuzzy = 0;
    for (final span in _fuzzySpans) {
      fuzzy += span.end - span.start;
    }
    final exact = speechLength - fuzzy;
    return exact < 0 ? 0 : exact;
  }

  /// Fraction of the speech text whose mapping is exact, in `0.0..1.0`.
  ///
  /// Useful for deciding whether to use this map at all, and for surfacing
  /// alignment quality in tests and diagnostics.
  double get exactFraction =>
      speechLength == 0 ? 1.0 : exactSpeechChars / speechLength;

  /// Builds a map between [speech] and [render].
  ///
  /// [lookahead] bounds how far ahead the matcher will search for a point to
  /// resynchronise. Larger values recover from longer divergences, at a cost
  /// proportional to the number of characters examined.
  factory SpeechCharMap.build(
    String speech,
    String render, {
    int lookahead = 48,
  }) {
    final n = speech.length;
    final m = render.length;

    // The two strings often do not start alike — a list marker precedes the
    // first word, for instance. Seeding a (0, 0) anchor regardless would
    // assert that speech offset 0 sits at render offset 0, which is false.
    // The first anchor is therefore only hard when the opening characters
    // actually match; otherwise the first resynchronisation establishes it.
    final anchors = <_Anchor>[];
    if (n > 0 && m > 0 && speech.codeUnitAt(0) == render.codeUnitAt(0)) {
      anchors.add(const _Anchor(0, 0, hard: true));
    }

    final fuzzySpans = <_Span>[];
    var fuzzyStart = -1;
    void openFuzzy(int at) => fuzzyStart < 0 ? fuzzyStart = at : null;
    void closeFuzzy(int at) {
      if (fuzzyStart < 0) return;
      if (at > fuzzyStart) fuzzySpans.add(_Span(fuzzyStart, at));
      fuzzyStart = -1;
    }

    var i = 0;
    var j = 0;
    var lastAnchorSpeech = 0;
    var matchedSinceAnchor = false;
    while (i < n || j < m) {
      if (i < n && j < m && speech.codeUnitAt(i) == render.codeUnitAt(j)) {
        i++;
        j++;
        closeFuzzy(i - 1);
        matchedSinceAnchor = true;

        // Anchor a long run of matching text. Without this the only anchors in
        // a run are the one before it and the divergence after it, so a
        // thousand characters of identical text would be covered by a single
        // straight line. That line cannot track the run: a one-character
        // disagreement anywhere makes every position before it wrong by up to
        // that much, and [isExact] would still report the run as matched.
        //
        // Both sides advanced together to get here, so this is a verified
        // correspondence and the anchor is hard. The interval bounds the
        // memory an anchor list costs while keeping any residual interpolation
        // error to a single character.
        if (i - lastAnchorSpeech >= _runAnchorInterval) {
          anchors.add(_Anchor(i, j, hard: true));
          lastAnchorSpeech = i;
          matchedSinceAnchor = false;
        }
        continue;
      }

      // Close the run of matching text where it actually ends. The resync below
      // is placed after the characters that caused the divergence, and anything
      // between this point and it was verified to match, so stretching the last
      // run anchor all the way there would interpolate across text that never
      // needed interpolating.
      if (matchedSinceAnchor) {
        anchors.add(_Anchor(i, j, hard: true));
        lastAnchorSpeech = i;
        matchedSinceAnchor = false;
      }

      openFuzzy(i);

      // Look for the cheaper way back into step: either the speech text has
      // run ahead (extra characters the renderer does not show) or the
      // renderer has (characters the speech side does not speak).
      final skipSpeech = j < m
          ? _distance(speech, i, render.codeUnitAt(j), lookahead)
          : -1;
      final skipRender = i < n
          ? _distance(render, j, speech.codeUnitAt(i), lookahead)
          : -1;

      if (skipSpeech > 0 && (skipRender <= 0 || skipSpeech <= skipRender)) {
        i += skipSpeech;
        anchors.add(_Anchor(i, j, hard: false));
      } else if (skipRender > 0) {
        j += skipRender;
        anchors.add(_Anchor(i, j, hard: false));
      } else if (i < n && j < m) {
        // No resynchronisation point nearby. Advance both sides; this is a
        // genuine character substitution.
        i++;
        j++;
      } else if (i < n) {
        i++;
      } else {
        j++;
      }
    }

    closeFuzzy(n);
    anchors.add(_Anchor(n, m, hard: false));

    return SpeechCharMap._(
      anchors,
      fuzzySpans,
      speechLength: n,
      renderLength: m,
    );
  }

  /// Builds a map from [speech] to [layout]'s flow text using the layout's
  /// fragment geometry, rather than by comparing the two strings.
  ///
  /// Each span in [layout] names a render range the renderer actually measured.
  /// The text of that range is looked for in [speech], forward from where the
  /// previous span ended, and a hit is a correspondence established by
  /// identity: the same characters in the same order, so the offsets inside the
  /// span correspond one for one and [isExact] holds throughout it.
  ///
  /// A span that is not found is *left unplaced* rather than guessed at. Its
  /// text is one the speech side does not speak — a ruby base, a list marker, a
  /// footnote — or one that differs in whitespace. The run of unplaced spans
  /// between the last placed span and the next becomes a single gap bounded by
  /// two anchors that were both verified, and every offset inside it is reported
  /// as approximate. A footnote the speech side skips entirely places the *next*
  /// span at the cursor unchanged, leaving no gap at all and no drift in anything
  /// after it.
  ///
  /// A gap's *shape* is left to interpolate evenly between its bounds, which is
  /// wrong in one predictable way: it assumes whatever the gap covers is spread
  /// evenly across it, and what it covers is normally one contiguous run at one
  /// end. Where the whole of one side of a gap is a copy of the end of the
  /// other, two string tests say so and an anchor pins the offset — see
  /// [_fillGap]. Everywhere else the gap stays approximate, because the shape
  /// cannot be recovered without guessing, and a guess that looks like a
  /// measurement is worse than an admitted estimate. [build] is not used here
  /// for the same reason: it can report a correspondence it has not verified.
  ///
  /// [maxSearchRun] bounds how far past the cursor a span may be found. It
  /// costs nothing in the ordinary case, where a span is found immediately after
  /// the text preceding it, and caps the work spent on a layout whose speech
  /// text bears no relation to it. A span that cannot be placed within the bound
  /// is treated as unplaced, which is honest rather than slow.
  ///
  /// The result reports the same [speechLength] and [renderLength] as
  /// [SpeechCharMap.build] on the same two strings, so the two are
  /// interchangeable to a caller.
  factory SpeechCharMap.fromSpans({
    required String speech,
    required ChapterTextLayout layout,
    // maxSearchRun removed to allow recovering from arbitrarily large gaps
  }) {
    final flow = layout.flowText;
    final anchors = <_Anchor>[];

    // Seeded unconditionally. When the speech text opens with something the
    // renderer does not show, the first span is placed further along and this
    // anchor is what the speech before it interpolates from; without it that
    // interpolation would run backwards off the front of the render text.
    anchors.add(const _Anchor(0, 0, hard: false));

    final fuzzySpans = <_Span>[];

    // Start of the run of unplaced spans, if one is open. Its end is not known
    // until a span after it places, which is what tells us how far the speech
    // side ran on without placing anything.
    var gapSpeech = 0;
    var gapRender = 0;
    var cursor = 0;
    var renderEnd = 0;

    for (final span in layout.spans) {
      if (!span.isFlowText) continue;
      // Spans arrive in layout order, so this only rejects a caller that hands
      // over spans out of order. Honouring one would put the anchor list out of
      // step with itself and break monotonicity for every offset after it.
      if (span.charStart < renderEnd) continue;
      if (span.charStart < 0 || span.charEnd > flow.length) continue;

      final text = flow.substring(span.charStart, span.charEnd);

      final offset = speech.indexOf(text, cursor);
      if (offset < 0) continue;

      final found = offset;

      if (found > cursor) {
        _fillGap(
          speech: speech,
          flow: flow,
          speechStart: gapSpeech,
          speechEnd: found,
          renderStart: gapRender,
          renderEnd: span.charStart,
          anchors: anchors,
          fuzzySpans: fuzzySpans,
        );
      }
      anchors.add(_Anchor(found, span.charStart, hard: true));
      anchors.add(_Anchor(found + text.length, span.charEnd, hard: true));
      cursor = found + text.length;
      renderEnd = span.charEnd;
      gapSpeech = cursor;
      gapRender = renderEnd;
    }

    // Speech past the last placed span, and render text no span accounted for,
    // have no verified correspondence to each other.
    if (cursor < speech.length || renderEnd < flow.length) {
      _fillGap(
        speech: speech,
        flow: flow,
        speechStart: gapSpeech,
        speechEnd: speech.length,
        renderStart: gapRender,
        renderEnd: flow.length,
        anchors: anchors,
        fuzzySpans: fuzzySpans,
      );
    }

    // A gap with no placement after it has no anchor to close it, and an anchor
    // list that stops short of the end leaves every offset past its last anchor
    // with no segment to interpolate in.
    if (anchors.last.speech != speech.length ||
        anchors.last.render != flow.length) {
      anchors.add(_Anchor(speech.length, flow.length, hard: false));
    }

    return SpeechCharMap._(
      anchors,
      fuzzySpans,
      speechLength: speech.length,
      renderLength: flow.length,
    );
  }

  /// Returns the render position corresponding to [speechChar].
  ///
  /// Offsets outside the speech text clamp to the ends. Inside a differing span
  /// the result is interpolated between the surrounding anchors; check
  /// [isExact] when that distinction matters.
  int renderCharFor(int speechChar) {
    if (speechChar < 0) return 0;
    if (speechChar >= speechLength) return renderLength;
    if (_anchors.length < 2) return speechChar;

    // Clamped because a caller reaching here with an offset past the last
    // anchor would otherwise index off the end rather than report a position.
    final index = _anchorIndexForSpeech(speechChar);
    final a = _anchors[index];
    final b = _anchors[index < _anchors.length - 1 ? index + 1 : index];
    if (speechChar == a.speech) return a.render;

    final speechSpan = b.speech - a.speech;
    if (speechSpan <= 0) return a.render;
    final renderSpan = b.render - a.render;

    if (a.hard && b.hard && speechSpan == renderSpan) {
      // Identical text on both sides: the offsets themselves correspond.
      return a.render + (speechChar - a.speech);
    }
    if (renderSpan <= 0) return a.render;

    return a.render + ((speechChar - a.speech) * renderSpan ~/ speechSpan);
  }

  /// Returns the speech position corresponding to [renderChar].
  ///
  /// The inverse of [renderCharFor], used to find which spoken text is
  /// currently on screen.
  int speechCharFor(int renderChar) {
    if (renderChar < 0) return 0;
    if (renderChar >= renderLength) return speechLength;
    if (_anchors.length < 2) return renderChar;

    final index = _anchorIndexForRender(renderChar);
    final a = _anchors[index];
    final b = _anchors[index < _anchors.length - 1 ? index + 1 : index];
    if (renderChar == a.render) return a.speech;

    final renderSpan = b.render - a.render;
    if (renderSpan <= 0) return a.speech;
    final speechSpan = b.speech - a.speech;

    if (a.hard && b.hard && speechSpan == renderSpan) {
      return a.speech + (renderChar - a.render);
    }
    if (speechSpan <= 0) return a.speech;

    return a.speech + ((renderChar - a.render) * speechSpan ~/ renderSpan);
  }

  /// Index of the last anchor at or before [speechChar].
  int _anchorIndexForSpeech(int speechChar) {
    var low = 0;
    var high = _anchors.length - 1;
    var index = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (_anchors[mid].speech <= speechChar) {
        index = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return index;
  }

  /// Index of the last anchor at or before [renderChar].
  int _anchorIndexForRender(int renderChar) {
    var low = 0;
    var high = _anchors.length - 1;
    var index = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (_anchors[mid].render <= renderChar) {
        index = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return index;
  }
}

/// Appends the anchors and fuzzy span for a run of spans that could not be
/// placed, between two verified anchors.
///
/// The gap runs from [speechStart]/[renderStart] to [speechEnd]/[renderEnd] on
/// the two axes, both of which are already anchored by the placements on either
/// side, so the gap is bounded and its interior is the only thing unverified.
///
/// Left alone, a gap is interpolated evenly between its two anchors, which
/// assumes the divergence it covers is spread evenly. It never is: it is
/// normally one contiguous run at one end, and where the renderer leads with
/// something unspoken that is recoverable exactly by asking whether the whole of
/// the speech side is the tail of the render side.
///
/// Nothing else is guessed. The mirror case — the render side being the head of
/// the speech side — is not reachable, because a fragment whose text began the
/// speech side of its own gap would have been placed rather than skipped.
void _fillGap({
  required String speech,
  required String flow,
  required int speechStart,
  required int speechEnd,
  required int renderStart,
  required int renderEnd,
  required List<_Anchor> anchors,
  required List<_Span> fuzzySpans,
}) {
  final speechText = speech.substring(speechStart, speechEnd);
  final renderText = flow.substring(renderStart, renderEnd);

  // A gap opening at the very start of the speech text has no anchor behind it:
  // speech 0 is a position nothing has confirmed.
  var startsVerified = renderStart > 0;

  if (speechText == renderText) {
    // The same text on both sides, so every offset in the gap is the offset it
    // reports and there is nothing uncertain about any of them. Only reachable
    // when there is no fragment to place at all, which means the whole chapter
    // is being mapped without one.
    return;
  } else if (renderText.length > speechText.length &&
      renderText.endsWith(speechText)) {
    // The renderer leads with something unpronounced — a list marker, an image,
    // a heading — and the whole of the speech side is the tail of the render
    // side. Anchoring speech 0 at the render offset it starts matching makes
    // every offset in the gap exact, and a chapter opening with a marker stops
    // placing its first spoken character at render zero.
    final shift = renderText.length - speechText.length;
    startsVerified = true;
    anchors.add(_Anchor(speechStart, renderStart + shift, hard: true));
  }

  if (speechEnd > speechStart) {
    fuzzySpans.add(
      _Span(speechStart, speechEnd, startIsVerified: startsVerified),
    );
  }
}

/// Distance from [start] to the next occurrence of [unit], within [limit].
int _distance(String text, int start, int unit, int limit) {
  final max = text.length - 1;
  final end = (start + limit) < max ? start + limit : max;
  for (var k = start + 1; k <= end; k++) {
    if (text.codeUnitAt(k) == unit) return k - start;
  }
  return -1;
}

/// A point where the speech and render positions are known to be in step.
///
/// [hard] anchors were reached by matching the same character on both sides, so
/// positions either side of them correspond one-for-one. Soft anchors were
/// reached by resynchronising after a divergence, and bound a span whose
/// interior is interpolated.
class _Anchor {
  final int speech;
  final int render;
  final bool hard;

  const _Anchor(this.speech, this.render, {required this.hard});
}

/// A half-open speech range whose mapping is interpolated.
///
/// [end] is always anchored, so only the interior is uncertain. [start] is an
/// anchor too, except when the range opens at the very beginning of the speech
/// text and no fragment had been placed there; [startIsVerified] records that
/// distinction, which [isExact] needs in order to avoid reporting a position as
/// exact on the strength of an anchor that verified nothing.
class _Span {
  final int start;
  final int end;

  /// Whether [start] corresponds to [SpeechCharMap] positions on both sides.
  final bool startIsVerified;

  const _Span(this.start, this.end, {this.startIsVerified = true});
}
