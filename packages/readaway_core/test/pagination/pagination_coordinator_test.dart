import 'dart:async';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('PaginationCoordinator', () {
    late PaginationCoordinator coordinator;

    setUp(() {
      coordinator = PaginationCoordinator();
    });

    tearDown(() => coordinator.dispose());

    test('initializes with a single chapter', () {
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 800,
        contentHeight: 2500,
      );

      final state = coordinator.currentState;
      expect(state.totalPages, 4);
      expect(state.chapterPageCounts[0], 4);
      expect(state.chapterIndex, 0);
      expect(state.pageInChapter, 0);
      expect(state.globalPage, 0);
    });

    test('registers multiple chapter heights and computes totals', () {
      coordinator.initialize(
        chapterCount: 2,
        viewportHeight: 800,
        contentHeight: 1600,
      );
      coordinator.registerChapterHeight(chapterIndex: 1, contentHeight: 800);

      final state = coordinator.currentState;
      expect(state.chapterPageCounts[0], 2);
      expect(state.chapterPageCounts[1], 1);
      expect(state.totalPages, 3);
    });

    test('maps global pages to coordinates and back', () {
      coordinator.initialize(
        chapterCount: 2,
        viewportHeight: 800,
        contentHeight: 1600,
      );
      coordinator.registerChapterHeight(chapterIndex: 1, contentHeight: 800);

      final coord = coordinator.coordinateFromGlobalPage(2);
      expect(coord.chapterIndex, 1);
      expect(coord.pageInChapter, 0);
      expect(coord.totalPagesInChapter, 1);

      expect(coordinator.globalPageFromCoordinate(coord), 2);
    });

    test('clamps out-of-range global pages to the last page', () {
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 800,
        contentHeight: 1600,
      );

      final coord = coordinator.coordinateFromGlobalPage(999);
      expect(coord.chapterIndex, 0);
      expect(coord.pageInChapter, 1);
      expect(coord.globalPage, 1);
    });

    test('creates and restores stable anchors', () {
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 800,
        contentHeight: 1600,
      );

      final coord = coordinator.coordinateFromGlobalPage(1);
      final anchor = coordinator.createAnchor(coord);
      expect(anchor.chapterIndex, 0);
      expect(anchor.progressionInChapter, closeTo(1.0, 0.001));

      final restored = coordinator.restoreFromAnchor(anchor);
      expect(restored.pageInChapter, 1);
      expect(restored.globalPage, 1);
    });

    test('emits state through the stream', () async {
      final states = <PaginationState>[];
      final sub = coordinator.state.listen(states.add);

      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 800,
        contentHeight: 1600,
      );

      // rxdart 0.28 subjects emit asynchronously (after a microtask).
      await Future<void>.delayed(Duration.zero);
      expect(states, isNotEmpty);
      expect(states.last.totalPages, 2);
      sub.cancel();
    });

    test('recomputes page counts when the viewport changes', () {
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 800,
        contentHeight: 1600,
      );
      expect(coordinator.currentState.totalPages, 2);

      coordinator.updateViewport(viewportHeight: 400, contentHeight: 1600);
      expect(coordinator.currentState.totalPages, 4);
    });

    test('reset clears all state', () {
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 800,
        contentHeight: 1600,
      );
      coordinator.reset();

      final state = coordinator.currentState;
      expect(state.totalPages, 0);
      expect(state.chapterHeights, isEmpty);
    });

    test('getChapterPageOffsets returns cached slice offsets', () {
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 800,
        contentHeight: 2500,
      );

      final offsets = coordinator.getChapterPageOffsets(0);
      expect(offsets, hasLength(4));
      expect(offsets.first, 0.0);

      // Unmeasured chapters fall back to a single page starting at 0.
      expect(coordinator.getChapterPageOffsets(5), [0.0]);
    });

    test('getGlobalPageForChapter returns the first global page', () {
      coordinator.initialize(
        chapterCount: 2,
        viewportHeight: 800,
        contentHeight: 1600,
      );
      coordinator.registerChapterHeight(chapterIndex: 1, contentHeight: 800);

      expect(coordinator.getGlobalPageForChapter(0), 0);
      expect(coordinator.getGlobalPageForChapter(1), 2);
    });

    test('registerChapterHeight snaps pages to line bounds', () {
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 850,
        contentHeight: 2500,
      );

      // Without line bounds: [0, 850, 1700] (3 pages).
      expect(coordinator.getChapterPageOffsets(0), [0.0, 850.0, 1700.0]);

      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: 2500,
        lineBounds: [
          for (var i = 0; i < 25; i++)
            (top: i * 100.0, bottom: (i + 1) * 100.0),
        ],
      );

      // With line bounds, slices snap to line tops (multiples of 100).
      expect(coordinator.getChapterPageOffsets(0), [
        0.0,
        800.0,
        1600.0,
        2400.0,
      ]);
    });
  });
}
