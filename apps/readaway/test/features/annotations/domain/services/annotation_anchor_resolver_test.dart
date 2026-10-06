import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/domain/services/annotation_anchor_resolver.dart';
import 'package:readaway_core/readaway_core.dart';

/// The flow text every test anchors into.
///
/// The repeated sentence is deliberate: it is what makes context-based
/// re-finding observable.
const _flow =
    'The quick brown fox jumps over the lazy dog. '
    'The quick brown fox sleeps.';

const _excerpt = 'The quick brown fox';

/// A chapter layout with deterministic glyph geometry: one rect per range,
/// positioned at the range's character offsets.
ChapterTextLayout _layout({String flow = _flow}) => ChapterTextLayout(
  contentHeight: 1000,
  viewportHeight: 500,
  lineBounds: const [(top: 0.0, bottom: 20.0)],
  spans: [
    TextSpanBox(
      charStart: 0,
      charEnd: flow.length,
      rect: Rect.fromLTWH(0, 0, 100, 20),
      nodeTag: 'p',
      type: 'text',
    ),
  ],
  pages: [
    PageSlice(
      index: 0,
      startY: 0,
      endY: 500,
      startChar: 0,
      endChar: flow.length,
    ),
  ],
  flowText: flow,
  totalCharacterCount: flow.length,
  charBoxResolver: (start, end) => [
    Rect.fromLTWH(start.toDouble(), 0, (end - start).toDouble(), 20),
  ],
);

ReaderNote _note({
  required ReaderNoteAnchor anchor,
  ReaderNoteType type = ReaderNoteType.highlight,
  String id = 'n1',
}) {
  final at = DateTime(2026, 1, 1);
  return ReaderNote(
    id: id,
    type: type,
    anchor: anchor,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  late PaginationCoordinator coordinator;
  late AnnotationAnchorResolver resolver;

  final firstStart = _flow.indexOf(_excerpt);
  final secondStart = _flow.indexOf(_excerpt, firstStart + 1);

  setUp(() {
    coordinator = PaginationCoordinator();
    coordinator.initialize(
      chapterCount: 3,
      viewportHeight: 500,
      contentHeight: 1000,
    );
    resolver = AnnotationAnchorResolver(coordinator);
  });

  tearDown(() => coordinator.dispose());

  void registerLayout({int chapterIndex = 0, String flow = _flow}) =>
      coordinator.registerChapterLayout(
        chapterIndex: chapterIndex,
        layout: _layout(flow: flow),
      );

  group('resolve', () {
    test('is pending while the chapter has not been measured', () {
      final anchor = resolver.anchorForSelection(
        chapterIndex: 0,
        startChar: firstStart,
        endChar: firstStart + _excerpt.length,
      );
      // No layout registered yet, so there is nothing to anchor against.
      expect(anchor, isNull);

      final resolved = resolver.resolve(
        _note(
          anchor: const ReaderNoteAnchor(
            chapterIndex: 0,
            startChar: 0,
            endChar: 19,
            text: _excerpt,
          ),
        ),
      );

      expect(resolved.resolution, AnchorResolution.pending);
      expect(resolved.isPaintable, isFalse);
    });

    test('is exact when the stored offsets still address the excerpt', () {
      registerLayout();
      final anchor = resolver.anchorForSelection(
        chapterIndex: 0,
        startChar: firstStart,
        endChar: firstStart + _excerpt.length,
      )!;

      final resolved = resolver.resolve(_note(anchor: anchor));

      expect(resolved.resolution, AnchorResolution.exact);
      expect(resolved.rects.single.left, firstStart.toDouble());
      expect(resolved.rects.single.width, _excerpt.length.toDouble());
      // Nothing to write back when nothing moved.
      expect(resolved.anchor, isNull);
    });

    test('repairs offsets that drifted, and reports the new anchor', () {
      registerLayout();
      final correct = resolver.anchorForSelection(
        chapterIndex: 0,
        startChar: firstStart,
        endChar: firstStart + _excerpt.length,
      )!;
      // The excerpt and its context are intact; only the numbers are wrong.
      final drifted = correct.copyWith(
        startChar: correct.startChar + 7,
        endChar: correct.endChar + 7,
      );

      final resolved = resolver.resolve(_note(anchor: drifted));

      expect(resolved.resolution, AnchorResolution.repaired);
      expect(resolved.anchor!.startChar, firstStart);
      expect(resolved.anchor!.endChar, firstStart + _excerpt.length);
      expect(resolved.rects.single.left, firstStart.toDouble());
    });

    test('re-finds the occurrence its recorded context belongs to', () {
      registerLayout();

      for (final start in [firstStart, secondStart]) {
        final anchor = resolver.anchorForSelection(
          chapterIndex: 0,
          startChar: start,
          endChar: start + _excerpt.length,
        )!;
        // Corrupt the offsets, so only the stored context can decide which of
        // the two identical sentences this note belongs to.
        final resolved = resolver.resolve(
          _note(anchor: anchor.copyWith(startChar: 0, endChar: 0)),
        );

        expect(
          resolved.resolution,
          AnchorResolution.repaired,
          reason: 'occurrence at $start should be re-found',
        );
        expect(
          resolved.anchor!.startChar,
          start,
          reason: 'context should select the occurrence at $start',
        );
      }
    });

    test('is orphaned when the excerpt is no longer in the chapter', () {
      registerLayout();

      final resolved = resolver.resolve(
        _note(
          anchor: const ReaderNoteAnchor(
            chapterIndex: 0,
            startChar: 4,
            endChar: 30,
            text: 'text that was removed from this chapter',
          ),
        ),
      );

      expect(resolved.resolution, AnchorResolution.orphaned);
      expect(resolved.rects, isEmpty);
      expect(resolved.isPaintable, isFalse);
      // The stored anchor is left alone, so the note stays recoverable.
      expect(resolved.anchor, isNull);
    });

    test('never paints a bookmark or an unpainted note', () {
      registerLayout();
      final anchored = resolver.anchorForSelection(
        chapterIndex: 0,
        startChar: firstStart,
        endChar: firstStart + _excerpt.length,
      )!;

      for (final type in [ReaderNoteType.bookmark, ReaderNoteType.note]) {
        final resolved = resolver.resolve(_note(anchor: anchored, type: type));
        expect(resolved.resolution, AnchorResolution.notPainted);
        expect(resolved.rects, isEmpty);
      }
    });
  });

  group('anchorForSelection', () {
    test('captures the excerpt, its context and the containing page', () {
      registerLayout();

      final anchor = resolver.anchorForSelection(
        chapterIndex: 0,
        startChar: firstStart,
        endChar: firstStart + _excerpt.length,
      )!;

      expect(anchor.kind, NoteAnchorKind.reflowable);
      expect(anchor.chapterIndex, 0);
      expect(anchor.startChar, firstStart);
      expect(anchor.endChar, firstStart + _excerpt.length);
      expect(anchor.text, _excerpt);
      expect(anchor.pageIndex, 0);
      expect(anchor.orphaned, isFalse);
      // The first occurrence has nothing before it, so its prefix is empty.
      expect(anchor.prefix, isEmpty);
      expect(anchor.suffix, startsWith(' jumps over the lazy dog'));
    });

    test('clamps an over-long range to the chapter text', () {
      registerLayout();

      final anchor = resolver.anchorForSelection(
        chapterIndex: 0,
        startChar: _flow.length - 3,
        endChar: _flow.length + 100,
      )!;

      expect(anchor.endChar, _flow.length);
      expect(anchor.text, _flow.substring(_flow.length - 3));
    });

    test('gives nothing back for an empty or inverted range', () {
      registerLayout();

      expect(
        resolver.anchorForSelection(chapterIndex: 0, startChar: 5, endChar: 5),
        isNull,
      );
      expect(
        resolver.anchorForSelection(chapterIndex: 0, startChar: 9, endChar: 5),
        isNull,
      );
    });

    test('gives nothing back for a chapter with no character mapping', () {
      // A layout built without a character mapping: pages empty.
      coordinator.registerChapterLayout(
        chapterIndex: 1,
        layout: ChapterTextLayout.unavailable(
          contentHeight: 1000,
          viewportHeight: 500,
          lineBounds: const [(top: 0.0, bottom: 20.0)],
        ),
      );

      expect(
        resolver.anchorForSelection(chapterIndex: 1, startChar: 0, endChar: 5),
        isNull,
      );
    });
  });

  group('pageAnchor', () {
    test('addresses a fixed-layout page and labels it for the list', () {
      final anchor = resolver.pageAnchor(pageIndex: 7);

      expect(anchor.kind, NoteAnchorKind.page);
      expect(anchor.pageIndex, 7);
      // The outline convention for fixed-layout documents equates chapter and
      // page, so the chapter index carries the page too.
      expect(anchor.chapterIndex, 7);
      expect(anchor.text, 'Page 8');
    });
  });
}
