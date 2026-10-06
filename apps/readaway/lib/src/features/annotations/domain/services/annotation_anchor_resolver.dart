import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:readaway_core/readaway_core.dart'
    show ChapterTextLayout, PaginationCoordinator;

import '../entity/reader_note.dart';

/// How well a stored anchor still matches the chapter it points into.
enum AnchorResolution {
  /// The chapter has not been measured yet, so nothing can be said about the
  /// anchor. Distinct from [orphaned]: this state resolves itself once the
  /// chapter is laid out.
  pending,

  /// The stored offsets still address the stored excerpt.
  exact,

  /// The offsets had drifted but the excerpt was re-found, and the repaired
  /// anchor should be written back.
  repaired,

  /// The excerpt is no longer in the chapter. The note stays listed but is not
  /// painted, so the reader is never shown a highlight in the wrong place.
  orphaned,

  /// The note is not painted by design — a bookmark, or a note with no
  /// highlight.
  notPainted,
}

/// A note together with the geometry it currently occupies.
class ResolvedNote {
  const ResolvedNote({
    required this.note,
    required this.rects,
    required this.resolution,
    this.anchor,
  });

  /// The note that was resolved.
  final ReaderNote note;

  /// Chapter-local rectangles to paint, empty when nothing should be drawn.
  final List<Rect> rects;

  /// What happened while resolving.
  final AnchorResolution resolution;

  /// The repaired anchor, present only when [resolution] is
  /// [AnchorResolution.repaired].
  final ReaderNoteAnchor? anchor;

  /// Whether anything should be drawn for this note.
  bool get isPaintable => rects.isNotEmpty;
}

/// Turns a note's stored anchor into geometry, and records new anchors from
/// reader selections.
///
/// Anchors are character ranges in the chapter's flow-text space, which is
/// stable across font, margin and theme changes because it is derived from
/// characters rather than geometry. What is *not* stable is the text itself: a
/// future preference could change how a chapter is transformed, which would
/// shift every offset after it. Each anchor therefore carries the excerpt it
/// covered, and this resolver treats that excerpt as the anchor's self-check —
/// re-finding the range rather than trusting a stale number.
///
/// Nothing is cached. A chapter holds few notes, and a rect lookup is only
/// performed for the chapter on screen, so caching would add invalidation
/// machinery to save work that is not being spent.
class AnnotationAnchorResolver {
  const AnnotationAnchorResolver(this._coordinator);

  final PaginationCoordinator _coordinator;

  /// How many characters of surrounding context an anchor records, on each
  /// side. Enough to disambiguate a repeated fragment, short enough to survive
  /// a small edit nearby.
  static const int contextLength = 40;

  /// Resolves [note] against its chapter's current geometry.
  ResolvedNote resolve(ReaderNote note) {
    if (!note.isPainted) {
      return ResolvedNote(
        note: note,
        rects: const [],
        resolution: AnchorResolution.notPainted,
      );
    }

    final anchor = note.anchor;
    final layout = _coordinator.getChapterLayout(anchor.chapterIndex);
    if (layout == null || !layout.hasCharacterMapping) {
      return ResolvedNote(
        note: note,
        rects: const [],
        resolution: AnchorResolution.pending,
      );
    }

    final flow = layout.flowText;
    if (_excerptAt(flow, anchor.startChar, anchor.endChar) == anchor.text) {
      return ResolvedNote(
        note: note,
        rects: _rectsFor(layout, anchor.startChar, anchor.endChar),
        resolution: AnchorResolution.exact,
      );
    }

    final found = _findExcerpt(flow, anchor);
    if (found == null) {
      return ResolvedNote(
        note: note,
        rects: const [],
        resolution: AnchorResolution.orphaned,
      );
    }

    return ResolvedNote(
      note: note,
      rects: _rectsFor(layout, found.$1, found.$2),
      resolution: AnchorResolution.repaired,
      anchor: anchor.copyWith(startChar: found.$1, endChar: found.$2),
    );
  }

  /// Records a new range anchor for a reader selection.
  ///
  /// Returns null when the chapter has no usable character mapping or the range
  /// is not addressable, so the caller can tell the reader the selection could
  /// not be anchored instead of saving an anchor that would never resolve.
  ReaderNoteAnchor? anchorForSelection({
    required int chapterIndex,
    required int startChar,
    required int endChar,
  }) {
    final layout = _coordinator.getChapterLayout(chapterIndex);
    if (layout == null || !layout.hasCharacterMapping) return null;

    final flow = layout.flowText;
    final start = startChar.clamp(0, flow.length);
    final end = endChar.clamp(0, flow.length);
    if (end <= start) return null;

    return ReaderNoteAnchor(
      chapterIndex: chapterIndex,
      startChar: start,
      endChar: end,
      pageIndex: _coordinator.pageForChar(chapterIndex, start),
      text: flow.substring(start, end),
      prefix: flow.substring(math.max(0, start - contextLength), start),
      suffix: flow.substring(end, math.min(flow.length, end + contextLength)),
    );
  }

  /// Records a position anchor for the page in a fixed-layout document.
  ///
  /// Fixed-layout documents have no character space to address, so the page
  /// index is the anchor, and `chapterIndex` carries it too because the outline
  /// convention for those formats already equates chapter with page.
  ReaderNoteAnchor pageAnchor({required int pageIndex}) => ReaderNoteAnchor(
    kind: NoteAnchorKind.page,
    chapterIndex: pageIndex,
    pageIndex: pageIndex,
    text: 'Page ${pageIndex + 1}',
  );

  /// Records a position anchor for the place the reader is currently on.
  ///
  /// A fixed-layout document has no character space, so its page is the anchor.
  /// A reflowable one does, so the anchor is the character offset where the
  /// current page begins: a page number would go stale the moment the reader
  /// changed the font size, whereas an offset is re-resolved against the new
  /// layout and still lands on the same words. The excerpt at that offset is
  /// captured as well, so the bookmarks list can show the line the reader
  /// stopped on instead of a number.
  ReaderNoteAnchor anchorForReadingPosition({
    required bool isReflowable,
    required int currentPage,
    required int? currentVirtualPage,
  }) {
    if (!isReflowable) return pageAnchor(pageIndex: currentPage);

    final globalPage = currentVirtualPage ?? 0;
    final coordinate = _coordinator.coordinateFromGlobalPage(globalPage);
    final startChar = _coordinator.charForPage(
      coordinate.chapterIndex,
      coordinate.pageInChapter,
    );

    final flow = _coordinator
        .getChapterLayout(coordinate.chapterIndex)
        ?.flowText;
    final excerpt =
        (flow != null && startChar != null && startChar < flow.length)
        ? flow
              .substring(
                startChar,
                math.min(flow.length, startChar + contextLength),
              )
              .trim()
        : '';

    // A bookmark covers no text, so its range is empty at the offset. Nothing
    // resolves rects for it: it is not painted.
    return ReaderNoteAnchor(
      chapterIndex: coordinate.chapterIndex,
      startChar: startChar ?? 0,
      endChar: startChar ?? 0,
      pageIndex: globalPage,
      text: excerpt.isEmpty ? 'Saved place' : excerpt,
    );
  }

  List<Rect> _rectsFor(ChapterTextLayout layout, int start, int end) =>
      layout.rectsForCharRange(start, end);

  /// The text at `[start, end)`, or null when the range is out of bounds.
  String? _excerptAt(String flow, int start, int end) {
    if (start < 0 || end > flow.length || end < start) return null;
    return flow.substring(start, end);
  }

  /// Re-finds the anchor's excerpt in [flow].
  ///
  /// Every occurrence is scored on how much of the recorded surrounding context
  /// it still has, because the same words can appear many times in a chapter
  /// and context is the only thing that tells those occurrences apart. Ties go
  /// to the occurrence nearest the old offset, on the assumption that text
  /// drifts by less than it moves.
  (int, int)? _findExcerpt(String flow, ReaderNoteAnchor anchor) {
    final text = anchor.text;
    if (text.isEmpty) return null;

    int? bestStart;
    var bestScore = -1;
    var bestDistance = 1 << 62;

    var cursor = flow.indexOf(text);
    while (cursor >= 0) {
      var score = 0;
      if (anchor.prefix.isNotEmpty &&
          cursor >= anchor.prefix.length &&
          _excerptAt(flow, cursor - anchor.prefix.length, cursor) ==
              anchor.prefix) {
        score++;
      }
      final end = cursor + text.length;
      if (anchor.suffix.isNotEmpty &&
          _excerptAt(flow, end, end + anchor.suffix.length) == anchor.suffix) {
        score++;
      }

      final distance = (cursor - anchor.startChar).abs();
      if (score > bestScore ||
          (score == bestScore && distance < bestDistance)) {
        bestStart = cursor;
        bestScore = score;
        bestDistance = distance;
      }

      final next = flow.indexOf(text, cursor + 1);
      if (next == cursor) break;
      cursor = next;
    }

    if (bestStart == null) return null;
    return (bestStart, bestStart + text.length);
  }
}
