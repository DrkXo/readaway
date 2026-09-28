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
  /// annotation. The boundaries of such a span are exact: they are points the
  /// matcher resynchronised on, so the offset there is known.
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

  /// Returns the render position corresponding to [speechChar].
  ///
  /// Offsets outside the speech text clamp to the ends. Inside a differing span
  /// the result is interpolated between the surrounding anchors; check
  /// [isExact] when that distinction matters.
  int renderCharFor(int speechChar) {
    if (speechChar < 0) return 0;
    if (speechChar >= speechLength) return renderLength;
    if (_anchors.length < 2) return speechChar;

    final a = _anchors[_anchorIndexForSpeech(speechChar)];
    final b = _anchors[_anchorIndexForSpeech(speechChar) + 1];
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

    final a = _anchors[_anchorIndexForRender(renderChar)];
    final b = _anchors[_anchorIndexForRender(renderChar) + 1];
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
/// [start] and [end] are themselves anchored, so only the interior is
/// uncertain.
class _Span {
  final int start;
  final int end;

  const _Span(this.start, this.end);
}
