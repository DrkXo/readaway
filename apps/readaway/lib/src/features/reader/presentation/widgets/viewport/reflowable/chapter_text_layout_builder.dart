import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hyper_render/hyper_render.dart' show RenderHyperBox;
import 'package:readaway_core/readaway_core.dart';

/// Builds a [ChapterTextLayout] from a laid-out [RenderHyperBox].
///
/// The render object maintains a canonical character space for text selection
/// and IME, where the chapter's flow text is the concatenation of every text
/// and ruby fragment in layout order, a line break contributes one character,
/// and every other fragment contributes none. [RenderHyperBox.debugFragments]
/// does not expose those offsets, so they are reconstructed here using the
/// same accounting rule.
///
/// The reconstruction is validated against
/// [RenderHyperBox.totalCharacterCount]. If the two disagree the upstream
/// accounting rule has changed and the result would be silently wrong, so an
/// unavailable layout is returned instead and callers fall back to
/// proportional geometry.
class ChapterTextLayoutBuilder {
  const ChapterTextLayoutBuilder();

  /// Tag names that begin and end a block-level box.
  ///
  /// A fragment with empty text whose source tag is one of these is a block
  /// boundary. Note that [RenderHyperBox.debugFragments] reports block start
  /// and block end fragments as `type: 'text'` with empty text, exactly like
  /// inline boundaries, so the tag is the only available discriminator.
  static const Set<String> blockTags = {
    'address',
    'article',
    'aside',
    'blockquote',
    'caption',
    'dd',
    'details',
    'div',
    'dl',
    'dt',
    'fieldset',
    'figcaption',
    'figure',
    'footer',
    'form',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'header',
    'hgroup',
    'li',
    'main',
    'nav',
    'ol',
    'p',
    'pre',
    'section',
    'summary',
    'table',
    'tbody',
    'td',
    'tfoot',
    'th',
    'thead',
    'tr',
    'ul',
  };

  /// Reads the laid-out geometry out of [hyperBox].
  ///
  /// [contentHeight] and [viewportHeight] describe the slice geometry.
  ChapterTextLayout build({
    required RenderHyperBox hyperBox,
    required double contentHeight,
    required double viewportHeight,
  }) {
    final fragments = _readFragments(hyperBox);
    return buildFromFragments(
      fragments: fragments ?? const <LayoutFragment>[],
      lineBounds: _readLineBounds(hyperBox),
      totalCharacterCount: hyperBox.totalCharacterCount,
      contentHeight: contentHeight,
      viewportHeight: viewportHeight,
    );
  }

  /// Builds a layout from already-extracted fragment data.
  ///
  /// Separated from [build] so the character accounting can be exercised
  /// without a live render object.
  ///
  /// [totalCharacterCount] must be the character total the render object
  /// reports. When the reconstructed total disagrees, the upstream accounting
  /// rule has changed and an unavailable layout is returned: callers then fall
  /// back to proportional geometry instead of trusting wrong offsets.
  ChapterTextLayout buildFromFragments({
    required List<LayoutFragment> fragments,
    required List<({double top, double bottom})>? lineBounds,
    required int totalCharacterCount,
    required double contentHeight,
    required double viewportHeight,

    /// Suppresses the debug assertion raised when the reconstructed character
    /// total disagrees with [totalCharacterCount]. Only for tests that need to
    /// observe the unavailable layout that the assertion otherwise guards.
    bool suppressCharacterTotalAssertion = false,
  }) {
    final lines = lineBounds;

    final fallback = ChapterTextLayout.unavailable(
      contentHeight: contentHeight,
      viewportHeight: viewportHeight,
      lineBounds: lines ?? const <({double top, double bottom})>[],
    );

    if (fragments.isEmpty) return fallback;

    final spans = <TextSpanBox>[];
    final blocks = <TextBlock>[];

    // The chapter's flow text is rebuilt alongside the offsets, so every
    // offset in the layout indexes directly into this string. It is what the
    // reader sees and what text selection copies.
    final flowText = StringBuffer();

    var charCursor = 0;
    var blockStartChar = 0;
    var blockStartY = double.infinity;
    var blockEndY = 0.0;
    var blockTag = '';
    var blockOpen = false;

    void closeBlock() {
      if (!blockOpen) return;
      // Only emit blocks that actually contain flow text. Atomic-only and
      // spacer blocks carry no characters, so they cannot be aligned against
      // extracted speech text and would introduce phantom indices.
      if (charCursor > blockStartChar) {
        blocks.add(
          TextBlock(
            index: blocks.length,
            charStart: blockStartChar,
            charEnd: charCursor,
            startY: blockStartY.isFinite ? blockStartY : 0.0,
            endY: blockEndY,
            tag: blockTag,
          ),
        );
      }
      blockOpen = false;
      blockStartChar = charCursor;
    }

    for (final fragment in fragments) {
      final type = fragment.type ?? '';
      final text = fragment.text;
      final nodeTag = (fragment.nodeTag ?? '').toLowerCase();

      // Mirrors the upstream accounting rule in
      // `RenderHyperBox._ensureFragments`: text and ruby contribute their
      // length, a line break contributes exactly one character, and every
      // other type (atomic boxes, block boundaries) contributes nothing.
      final isLineBreak = type == 'lineBreak';
      // Block and inline boundaries are reported as type 'text' with empty
      // text. Upstream counts them as zero characters, so treating them as
      // boundaries keeps the accounting identical while exposing the tag.
      final isBoundary = (text == null || text.isEmpty) && !isLineBreak;
      // Only text and ruby fragments contribute their length. Atomic boxes
      // (images, replaced elements) contribute nothing regardless of the
      // text the debug API reports for them.
      final isFlowText =
          text != null &&
          text.isNotEmpty &&
          !isLineBreak &&
          (type == 'text' || type == 'ruby');

      if (isBoundary || (!isFlowText && !isLineBreak)) {
        // A boundary or atomic fragment. Block tags close the current block;
        // inline tags (a, em, span, ...) are transparent.
        if (blockTags.contains(nodeTag)) {
          closeBlock();
          blockTag = nodeTag;
          blockStartY = fragment.offsetY ?? double.infinity;
          blockEndY = fragment.offsetY ?? 0.0;
          blockOpen = true;
        }
        continue;
      }

      final charEnd = charCursor + (isLineBreak ? 1 : text!.length);
      flowText.write(isLineBreak ? '\n' : text);

      if (!blockOpen) {
        // Text outside any recognised block (e.g. a bare text node at the
        // root). Open an implicit block so it stays addressable.
        blockOpen = true;
        blockTag = nodeTag;
        blockStartY = fragment.offsetY ?? double.infinity;
        blockStartChar = charCursor;
      }

      final offsetY = fragment.offsetY;
      if (isFlowText && fragment.offsetX != null && offsetY != null) {
        spans.add(
          TextSpanBox(
            charStart: charCursor,
            charEnd: charEnd,
            rect: Rect.fromLTWH(
              fragment.offsetX!,
              offsetY,
              fragment.width ?? 0.0,
              fragment.height ?? 0.0,
            ),
            nodeTag: nodeTag,
            type: type,
          ),
        );
      }

      blockEndY = offsetY ?? blockEndY;
      charCursor = charEnd;

      if (isLineBreak) {
        // A line break separates blocks for speech purposes.
        closeBlock();
        blockStartY = double.infinity;
        blockEndY = 0.0;
      }
    }
    closeBlock();

    // The reconstructed accounting must agree with the render object, otherwise
    // every character offset in this layout is untrustworthy.
    if (charCursor != totalCharacterCount) {
      assert(
        suppressCharacterTotalAssertion,
        'ChapterTextLayoutBuilder: reconstructed $charCursor characters but '
        'RenderHyperBox reports $totalCharacterCount. The upstream fragment '
        'accounting rule has changed; character offsets are unreliable.',
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
      blocks: blocks,
      pages: buildPages(offsets, spans, contentHeight, charCursor),
      flowText: flowText.toString(),
      totalCharacterCount: totalCharacterCount,
    );
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
}
