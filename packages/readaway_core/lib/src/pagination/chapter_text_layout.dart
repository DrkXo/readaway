import 'dart:ui' show Rect;

/// One laid-out fragment as reported by a render object's debug API.
///
/// A structural stand-in for the upstream `Fragment` type, which is not
/// exported by `hyper_render_core`. All fields are nullable because the debug
/// API reports unmeasured fragments with null geometry.
class LayoutFragment {
  /// Fragment type name: `text`, `atomic`, `lineBreak` or `ruby`.
  final String? type;

  /// The fragment's characters, or null/empty for structural fragments such as
  /// block boundaries and atomic boxes.
  final String? text;

  /// Left edge in chapter-local coordinates.
  final double? offsetX;

  /// Top edge in chapter-local coordinates.
  final double? offsetY;

  /// Measured width, or null before layout.
  final double? width;

  /// Measured height, or null before layout.
  final double? height;

  /// Tag name of the source node.
  final String? nodeTag;

  const LayoutFragment({
    this.type,
    this.text,
    this.offsetX,
    this.offsetY,
    this.width,
    this.height,
    this.nodeTag,
  });

  /// Reads the shape produced by `RenderHyperBox.debugFragments`.
  factory LayoutFragment.fromDebugMap(Map<String, dynamic> map) {
    double? num2double(Object? v) => v is num ? v.toDouble() : null;
    return LayoutFragment(
      type: map['type'] as String?,
      text: map['text'] as String?,
      offsetX: num2double(map['offsetX']),
      offsetY: num2double(map['offsetY']),
      width: num2double(map['width']),
      height: num2double(map['height']),
      nodeTag: map['nodeTag'] as String?,
    );
  }
}

/// A line box as reported by a render object's debug API.
class LayoutLine {
  /// Top edge in chapter-local coordinates.
  final double top;

  /// Measured height.
  final double height;

  const LayoutLine({required this.top, required this.height});

  /// Bottom edge in chapter-local coordinates.
  double get bottom => top + height;

  /// Reads the shape produced by `RenderHyperBox.debugLines`.
  factory LayoutLine.fromDebugMap(Map<String, dynamic> map) {
    double num2double(Object? v) =>
        v is num ? v.toDouble() : (v == null ? 0.0 : double.nan);
    return LayoutLine(
      top: num2double(map['top']),
      height: num2double(map['height']),
    );
  }
}

/// One positioned fragment of a laid-out line, as reported by
/// `RenderHyperBox.debugLineFragments`.
///
/// Unlike [LayoutFragment], which mirrors the renderer's *tokenizer* output and
/// so reports null geometry for a text node that wrapped, this mirrors the
/// lines the layout actually produced. Every instance is positioned, and
/// [charStart] is the renderer's own `globalOffset` rather than a value
/// re-derived here by prefix sum.
class LayoutLineFragment {
  /// Render fragment type name: `text`, `atomic`, `lineBreak` or `ruby`.
  final String? type;

  /// The fragment's characters, or null/empty for structural fragments.
  final String? text;

  /// The reading drawn above [text] for a ruby fragment, or null.
  ///
  /// This is a different string from [text] in both content and length, so a
  /// consumer relating drawn text to spoken or translated text needs both.
  final String? rubyText;

  /// Character offset of the first character, in the renderer's own space.
  final int charStart;

  /// One past the last character, as the renderer accounts for it.
  final int charEnd;

  /// How much of [text] actually reached the screen when the fragment was
  /// truncated, or null when it was not.
  final int? ellipsisVisibleLength;

  /// Index of the line this fragment was placed on.
  final int lineIndex;

  /// Left edge in chapter-local coordinates.
  final double offsetX;

  /// Top edge in chapter-local coordinates.
  final double offsetY;

  /// Measured width.
  final double width;

  /// Measured height.
  final double height;

  /// Id of the source node.
  final String? nodeId;

  /// Tag name of the source node.
  final String? nodeTag;

  const LayoutLineFragment({
    required this.charStart,
    required this.charEnd,
    required this.offsetX,
    required this.offsetY,
    required this.width,
    required this.height,
    required this.lineIndex,
    this.type,
    this.text,
    this.rubyText,
    this.ellipsisVisibleLength,
    this.nodeId,
    this.nodeTag,
  });

  /// Bounding box in chapter-local coordinates.
  Rect get rect => Rect.fromLTWH(offsetX, offsetY, width, height);

  /// One past the last character that reached the screen.
  ///
  /// Equal to [charEnd] unless the fragment was truncated, in which case the
  /// characters past this point were never painted and must not be highlighted.
  int get visibleCharEnd => ellipsisVisibleLength == null
      ? charEnd
      : charStart + ellipsisVisibleLength!;

  /// Reads the shape produced by `RenderHyperBox.debugLineFragments`.
  factory LayoutLineFragment.fromDebugMap(Map<String, dynamic> map) {
    double num2double(Object? v) => v is num ? v.toDouble() : double.nan;
    return LayoutLineFragment(
      type: map['type'] as String?,
      text: map['text'] as String?,
      rubyText: map['rubyText'] as String?,
      charStart: map['charStart'] as int? ?? 0,
      charEnd: map['charEnd'] as int? ?? 0,
      ellipsisVisibleLength: map['ellipsisVisibleLength'] as int?,
      lineIndex: map['lineIndex'] as int? ?? 0,
      offsetX: num2double(map['offsetX']),
      offsetY: num2double(map['offsetY']),
      width: num2double(map['width']),
      height: num2double(map['height']),
      nodeId: map['nodeId'] as String?,
      nodeTag: map['nodeTag'] as String?,
    );
  }

  @override
  String toString() =>
      'LayoutLineFragment(line $lineIndex, $charStart..$charEnd, '
      '$nodeTag/$type, $rect)';
}

/// A single laid-out text fragment in a chapter's canonical character space.
///
/// Character offsets are *not* indices into any string the app holds. They are
/// the offsets used by `RenderHyperBox` for text selection and IME, where the
/// chapter's flow text is the concatenation of every text fragment in layout
/// order, a line break contributes one character, and every other fragment type
/// contributes none.
class TextSpanBox {
  /// Character offset of the first character in [rect].
  final int charStart;

  /// Character offset one past the last character in [rect].
  final int charEnd;

  /// Bounding box in chapter-local coordinates, before any page-slice
  /// translation is applied.
  final Rect rect;

  /// Tag name of the source node, e.g. `p`, `a`, `span`.
  final String nodeTag;

  /// Render fragment type, e.g. `text`, `ruby`, `atomic`, `lineBreak`.
  final String type;

  const TextSpanBox({
    required this.charStart,
    required this.charEnd,
    required this.rect,
    required this.nodeTag,
    required this.type,
  });

  /// Whether this span contributes characters to the chapter's flow text.
  bool get isFlowText => charEnd > charStart;

  @override
  String toString() =>
      'TextSpanBox($charStart..$charEnd, $nodeTag/$type, $rect)';
}

/// One screen page of a chapter, expressed in both geometric and character
/// terms so that either can be converted to the other exactly.
class PageSlice {
  /// 0-based page index within the chapter.
  final int index;

  /// Top of the page in chapter-local coordinates.
  final double startY;

  /// Bottom of the page in chapter-local coordinates.
  final double endY;

  /// Character offset where the page's content begins.
  final int startChar;

  /// Character offset one past where the page's content ends.
  final int endChar;

  const PageSlice({
    required this.index,
    required this.startY,
    required this.endY,
    required this.startChar,
    required this.endChar,
  });

  @override
  String toString() =>
      'PageSlice($index, y $startY..$endY, c $startChar..$endChar)';
}

/// An immutable snapshot of one chapter's laid-out geometry.
///
/// This is the shared coordinate space between what the reader draws and what
/// the TTS engine speaks. Every position, character offset and page boundary
/// here refers to the same space, so mapping between a character offset and a
/// page is an exact binary search rather than an estimate.
class ChapterTextLayout {
  /// Total height of the chapter's content box.
  final double contentHeight;

  /// Height of the viewport used to slice pages.
  final double viewportHeight;

  /// Line boxes of the chapter, used by [PageSlicer] to snap page breaks.
  final List<({double top, double bottom})> lineBounds;

  /// Every positioned fragment, in layout order. Ordered by
  /// [TextSpanBox.charStart], one entry per fragment per line, so a range
  /// covering a sentence resolves to the exact runs of glyphs it covers rather
  /// than to whole style runs.
  final List<TextSpanBox> spans;

  /// Screen pages of the chapter, in order. Empty when measurement failed.
  final List<PageSlice> pages;

  /// The chapter's flow text, reconstructed in the same character space the
  /// offsets above use.
  ///
  /// This is what the render object presents to text selection, and it is the
  /// string the reader actually sees. The TTS side produces a *different*
  /// string over the same source (kana instead of kanji for ruby, no footnote
  /// containers, no list markers), so this is also the reference against which
  /// those differences are measured rather than guessed at.
  ///
  /// Empty when [hasCharacterMapping] is false.
  final String flowText;

  /// Total number of characters in [flowText], as reported by the render object.
  /// Used to validate that reconstructed offsets stay in sync.
  final int totalCharacterCount;

  const ChapterTextLayout({
    required this.contentHeight,
    required this.viewportHeight,
    required this.lineBounds,
    required this.spans,
    required this.pages,
    required this.flowText,
    required this.totalCharacterCount,
  });

  /// A layout carrying no usable geometry, produced when measurement fails or
  /// when reconstructed offsets failed validation.
  ///
  /// Callers must treat an empty [pages] as "no character mapping available"
  /// and fall back to proportional geometry rather than trusting zeros.
  factory ChapterTextLayout.unavailable({
    required double contentHeight,
    required double viewportHeight,
    required List<({double top, double bottom})> lineBounds,
  }) => ChapterTextLayout(
    contentHeight: contentHeight,
    viewportHeight: viewportHeight,
    lineBounds: lineBounds,
    spans: const [],
    pages: const [],
    flowText: '',
    totalCharacterCount: 0,
  );

  /// Whether character-level mapping is usable for this layout.
  bool get hasCharacterMapping => pages.isNotEmpty && spans.isNotEmpty;

  /// Character offsets of each page start, ascending. Parallel to [pages].
  List<int> get pageStartChars =>
      pages.map((p) => p.startChar).toList(growable: false);

  /// Returns the page containing [charOffset].
  ///
  /// Offsets before the first page start clamp to page 0; offsets past the end
  /// clamp to the last page.
  int pageForChar(int charOffset) {
    if (pages.isEmpty) return 0;
    var low = 0;
    var high = pages.length - 1;
    var result = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (pages[mid].startChar <= charOffset) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }

  /// Returns the character offset where [pageIndex] begins, or null when the
  /// page does not exist.
  int? charForPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    return pages[pageIndex].startChar;
  }

  /// Returns the bounding boxes covering `[start, end)` in flow-text
  /// coordinates.
  ///
  /// [start] is inclusive, [end] exclusive. Spans are returned in layout
  /// order. An end equal to [start] yields an empty list.
  List<Rect> rectsForCharRange(int start, int end) {
    if (end <= start || spans.isEmpty) return const [];
    final result = <Rect>[];
    for (final span in spans) {
      if (span.charEnd <= start) continue;
      if (span.charStart >= end) break;
      result.add(span.rect);
    }
    return result;
  }

  /// Whether two layouts describe the same geometry.
  ///
  /// Used to skip redundant re-registration when a page turn re-measures the
  /// same content.
  bool matches(ChapterTextLayout other) {
    if (contentHeight != other.contentHeight) return false;
    if (viewportHeight != other.viewportHeight) return false;
    if (totalCharacterCount != other.totalCharacterCount) return false;
    // The flow text is what any speech correspondence is built against, so two
    // layouts that differ only in their text are not interchangeable even when
    // they paginate identically — which happens when a different chapter is
    // loaded into the same slot, or when an element renders as a list marker at
    // one width and plain text at another.
    if (flowText != other.flowText) return false;
    if (lineBounds.length != other.lineBounds.length) return false;
    for (var i = 0; i < lineBounds.length; i++) {
      final a = lineBounds[i];
      final b = other.lineBounds[i];
      if ((a.top - b.top).abs() > 0.5 || (a.bottom - b.bottom).abs() > 0.5) {
        return false;
      }
    }
    if (pages.length != other.pages.length) return false;
    for (var i = 0; i < pages.length; i++) {
      final a = pages[i];
      final b = other.pages[i];
      if (a.startChar != b.startChar || a.endChar != b.endChar) return false;
      if ((a.startY - b.startY).abs() > 0.5 || (a.endY - b.endY).abs() > 0.5) {
        return false;
      }
    }
    return true;
  }
}
