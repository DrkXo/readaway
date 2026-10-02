import 'package:flutter/widgets.dart';
import 'package:hyper_render/hyper_render.dart' show RenderHyperBox;
import 'package:readaway_core/readaway_core.dart';

/// Builds a [ChapterTextLayout] from a laid-out [RenderHyperBox].
///
/// Two different render-object APIs are read, and the distinction is the whole
/// point:
///
/// - [RenderHyperBox.debugFragments] reports the *tokenizer* output. When a text
///   node wraps, the layout splits it into new fragments, positions those, and
///   never adds them back to that list — so the tokenizer fragment is reported
///   unpositioned for text that was in fact laid out and painted. It is still
///   the only complete description of the chapter's character space, because the
///   renderer counts text that never reaches a line (hidden content, replaced
///   elements), so it is used to reconstruct [ChapterTextLayout.flowText] and to
///   validate the total.
/// - [RenderHyperBox.debugLineFragments] reports the fragments of the lines
///   that were actually produced, each with the position it was painted at and
///   the renderer's own `globalOffset`. This is the only source of geometry, and
///   therefore the only source of [TextSpanBox].
///
/// The two must agree. The character offsets are cross-checked against
/// [ChapterTextLayout.flowText] so that a change in the renderer's accounting
/// surfaces as a refusal to build a mapping rather than as silently wrong
/// highlight positions.
class ChapterTextLayoutBuilder {
  const ChapterTextLayoutBuilder();

  /// Matches whitespace runs, so the offset cross-check can ignore differences
  /// in how much of it sits at a wrap without becoming insensitive to drift.
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Reads the laid-out geometry out of [hyperBox].
  ///
  /// [contentHeight] and [viewportHeight] describe the slice geometry.
  ChapterTextLayout build({
    required RenderHyperBox hyperBox,
    required double contentHeight,
    required double viewportHeight,
  }) {
    return buildFromLayout(
      fragments: _readFragments(hyperBox) ?? const <LayoutFragment>[],
      lineFragments:
          _readLineFragments(hyperBox) ?? const <LayoutLineFragment>[],
      lineBounds: _readLineBounds(hyperBox),
      totalCharacterCount: hyperBox.totalCharacterCount,
      contentHeight: contentHeight,
      viewportHeight: viewportHeight,
      charBoxResolver: hyperBox.getBoxesForCharRange,
    );
  }

  /// Builds a layout from already-extracted fragment data.
  ///
  /// Separated from [build] so the character accounting and the offset
  /// cross-check can be exercised without a live render object.
  ///
  /// [totalCharacterCount] must be the character total the render object
  /// reports, and [fragments] must be its tokenizer output. When the
  /// reconstructed total disagrees with it, the upstream accounting rule has
  /// changed; when a line fragment's text does not match the flow text at its
  /// reported offset, the offsets have drifted. Either way the character
  /// mapping would be untrustworthy, so an unavailable layout is returned and
  /// callers fall back to proportional geometry.
  ChapterTextLayout buildFromLayout({
    required List<LayoutFragment> fragments,
    required List<LayoutLineFragment> lineFragments,
    required List<({double top, double bottom})>? lineBounds,
    required int totalCharacterCount,
    required double contentHeight,
    required double viewportHeight,
    List<Rect> Function(int start, int end)? charBoxResolver,

    /// Suppresses the debug assertions raised when the reconstructed character
    /// total disagrees with [totalCharacterCount], or when a line fragment's
    /// text does not match the flow text at its reported offset. Only for tests
    /// that need to observe the unavailable layout the assertions guard.
    bool suppressCharacterTotalAssertion = false,
  }) {
    final lines = lineBounds;

    final fallback = ChapterTextLayout.unavailable(
      contentHeight: contentHeight,
      viewportHeight: viewportHeight,
      lineBounds: lines ?? const <({double top, double bottom})>[],
    );

    if (fragments.isEmpty) return fallback;

    // ---------------------------------------------------------------------
    // 1. Reconstruct the chapter's flow text in the renderer's character
    //    space. This is what the reader sees and what text selection copies,
    //    and every offset in this layout indexes into it.
    //
    //    Mirrors the upstream accounting rule in
    //    `RenderHyperBox._ensureFragments`: text and ruby contribute their
    //    length, a line break contributes exactly one character, and every
    //    other type (atomic boxes, block boundaries) contributes none. Block
    //    and inline boundaries are reported as type 'text' with empty text, so
    //    they are covered by the empty-text case.
    // ---------------------------------------------------------------------
    final flowText = StringBuffer();
    var charCursor = 0;

    for (final fragment in fragments) {
      final type = fragment.type ?? '';
      final text = fragment.text;

      if (type == 'lineBreak') {
        flowText.write('\n');
        charCursor += 1;
        continue;
      }
      if (text == null || text.isEmpty) continue;
      if (type != 'text' && type != 'ruby') continue;
      flowText.write(text);
      charCursor += text.length;
    }

    final flow = flowText.toString();

    if (charCursor != totalCharacterCount) {
      assert(
        suppressCharacterTotalAssertion,
        'ChapterTextLayoutBuilder: reconstructed $charCursor characters but '
        'RenderHyperBox reports $totalCharacterCount. The upstream fragment '
        'accounting rule has changed; character offsets are unreliable.',
      );
      return fallback;
    }

    // ---------------------------------------------------------------------
    // 2. Spans come from the positioned line fragments, using the renderer's
    //    own offsets. A wrapped text node contributes one span per line it
    //    occupies, which is what makes sentence-level highlighting possible:
    //    a range resolves to the glyph runs it covers, not to a whole paragraph.
    // ---------------------------------------------------------------------
    final spans = <TextSpanBox>[];
    for (final fragment in lineFragments) {
      spans.add(
        TextSpanBox(
          charStart: fragment.charStart,
          // Truncated text was never painted past the clamp, so it must not be
          // highlighted as though it were.
          charEnd: fragment.visibleCharEnd,
          rect: fragment.rect,
          nodeId: fragment.nodeId,
          nodeTag: fragment.nodeTag ?? '',
          type: fragment.type ?? '',
        ),
      );
    }

    // ---------------------------------------------------------------------
    // 3. Cross-check the renderer's offsets against the reconstructed text.
    //    Ranges must be in bounds, ascending and non-overlapping, and each
    //    fragment's text must be the flow text at the offset it claims. Gaps
    //    are expected and correct — whitespace trimmed at a wrap belongs to no
    //    fragment — so coverage is deliberately not required.
    // ---------------------------------------------------------------------
    if (!_offsetsAgree(lineFragments, flow, totalCharacterCount)) {
      assert(
        suppressCharacterTotalAssertion,
        'ChapterTextLayoutBuilder: a line fragment reports text that does not '
        'match the flow text at its character offset, or its ranges overlap or '
        'run past the chapter total. The renderer\'s character accounting has '
        'changed; character offsets are unreliable.',
      );
      return fallback;
    }

    final offsets = const PageSlicer().computePageOffsets(
      contentHeight: contentHeight,
      viewportHeight: viewportHeight,
      lineBounds: (lines == null || lines.isEmpty) ? null : lines,
    );

    return ChapterTextLayout(
      contentHeight: contentHeight,
      viewportHeight: viewportHeight,
      lineBounds: lines ?? const <({double top, double bottom})>[],
      spans: spans,
      pages: buildPages(offsets, spans, contentHeight, totalCharacterCount),
      flowText: flow,
      totalCharacterCount: totalCharacterCount,
      charBoxResolver: charBoxResolver,
    );
  }

  /// Whether every line fragment is in bounds, ascending and non-overlapping,
  /// and carries the text the flow text actually has at its reported offset.
  ///
  /// Gaps are not a failure. Whitespace trimmed at a wrap is counted by the
  /// renderer but belongs to no fragment, so a range landing in a gap correctly
  /// has no rect, and a fragment's own range may begin or end inside that
  /// trimmed whitespace. Completeness is therefore not required — only that what
  /// *is* reported is consistent — and the text comparison ignores whitespace
  /// for the same reason.
  ///
  /// This is the tripwire for a bad merge of the fork: a change to how the
  /// renderer derives `globalOffset` would show up here as text that does not
  /// match at the offset it claims, which is a refusal to build a mapping rather
  /// than a highlight in the wrong place.
  static bool _offsetsAgree(
    List<LayoutLineFragment> fragments,
    String flow,
    int totalCharacters,
  ) {
    String strip(String s) => s.replaceAll(_whitespace, '');
    var previousEnd = 0;

    for (final fragment in fragments) {
      if (fragment.charStart < 0) return false;
      if (fragment.charEnd > totalCharacters) return false;
      if (fragment.charStart < previousEnd) return false;
      if (fragment.charEnd > previousEnd) previousEnd = fragment.charEnd;

      // Only text and ruby carry characters; atomic boxes and line breaks are
      // positioned but contribute none, and their offsets are structural.
      final type = fragment.type ?? '';
      if (type != 'text' && type != 'ruby') continue;
      final text = fragment.text;
      if (text == null || text.isEmpty) continue;
      if (fragment.charEnd <= fragment.charStart) return false;

      final at = flow.substring(fragment.charStart, fragment.charEnd);
      if (strip(at) != strip(text)) return false;
    }
    return true;
  }

  /// Converts page-break Y offsets into character ranges.
  ///
  /// A page starts at the first character rendered at or after its break Y,
  /// which is the character after the last span ending above that Y.
  ///
  /// Public for testing; not part of the intended call surface.
  @visibleForTesting
  static List<PageSlice> buildPages(
    List<double> offsets,
    List<TextSpanBox> spans,
    double contentHeight,
    int totalCharacters,
  ) {
    final starts = <int>[];
    var spanCursor = 0;

    for (final startY in offsets) {
      while (spanCursor < spans.length &&
          spans[spanCursor].rect.bottom <= startY) {
        spanCursor++;
      }
      starts.add(
        spanCursor < spans.length
            ? spans[spanCursor].charStart
            : totalCharacters,
      );
    }

    return [
      for (var i = 0; i < offsets.length; i++)
        PageSlice(
          index: i,
          startY: offsets[i],
          endY: i + 1 < offsets.length ? offsets[i + 1] : contentHeight,
          startChar: starts[i],
          endChar: i + 1 < starts.length ? starts[i + 1] : totalCharacters,
        ),
    ];
  }

  List<({double top, double bottom})>? _readLineBounds(
    RenderHyperBox hyperBox,
  ) {
    try {
      final lines = hyperBox.debugLines();
      if (lines.isEmpty) return null;
      return lines.map((l) {
        final line = LayoutLine.fromDebugMap(l);
        return (top: line.top, bottom: line.bottom);
      }).toList();
    } catch (_) {
      return null;
    }
  }

  List<LayoutFragment>? _readFragments(RenderHyperBox hyperBox) {
    try {
      return hyperBox
          .debugFragments()
          .map(LayoutFragment.fromDebugMap)
          .toList();
    } catch (_) {
      return null;
    }
  }

  List<LayoutLineFragment>? _readLineFragments(RenderHyperBox hyperBox) {
    try {
      return hyperBox
          .debugLineFragments()
          .map(LayoutLineFragment.fromDebugMap)
          .toList();
    } catch (_) {
      return null;
    }
  }
}
