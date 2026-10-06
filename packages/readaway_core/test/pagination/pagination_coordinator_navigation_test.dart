import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

/// A viewport one third the height of a 3000px chapter, so registering that
/// chapter yields three pages with no line-boundary data.
const double _viewportHeight = 1000.0;
const double _threePageHeight = 3000.0;

PaginationCoordinator _coordinator({int chapterCount = 2}) {
  final coordinator = PaginationCoordinator();
  coordinator.initialize(
    chapterCount: chapterCount,
    viewportHeight: _viewportHeight,
    contentHeight: 0,
  );
  return coordinator;
}

void main() {
  group('anchor-first navigation', () {
    test('a chapter is unmeasured until it has real geometry', () {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);

      // initialize registers chapter 0 with a zero height, which is a
      // placeholder rather than a measurement.
      expect(coordinator.isChapterMeasured(0), isFalse);
      expect(coordinator.isChapterMeasured(1), isFalse);

      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: _threePageHeight,
      );

      expect(coordinator.isChapterMeasured(0), isTrue);
      expect(coordinator.measuredPageCount(0), 3);
      expect(coordinator.isChapterMeasured(1), isFalse);
      expect(coordinator.measuredPageCount(1), isNull);
    });

    test('forward off a chapter end starts the next chapter', () {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);
      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: _threePageHeight,
      );

      final lastPage = ReadingAnchor(
        chapterIndex: 0,
        progressionInChapter: 1.0,
      );
      expect(
        coordinator.anchorForPageStep(lastPage, forward: true),
        const ReadingAnchor(chapterIndex: 1, progressionInChapter: 0.0),
      );
    });

    test('backward off a chapter start targets the previous chapter end', () {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);
      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: _threePageHeight,
      );

      final firstPage = ReadingAnchor(
        chapterIndex: 1,
        progressionInChapter: 0.0,
      );
      expect(
        coordinator.anchorForPageStep(firstPage, forward: false),
        const ReadingAnchor(chapterIndex: 0, progressionInChapter: 1.0),
      );
    });

    test('within-chapter steps stay on the chapter', () {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);
      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: _threePageHeight,
      );

      // Three pages means page 1 sits at progression 0.5.
      final middle = coordinator.anchorForPageStep(
        const ReadingAnchor(chapterIndex: 0, progressionInChapter: 0.0),
        forward: true,
      );
      expect(
        middle,
        const ReadingAnchor(chapterIndex: 0, progressionInChapter: 0.5),
      );

      expect(
        coordinator.anchorForPageStep(middle, forward: false),
        const ReadingAnchor(chapterIndex: 0, progressionInChapter: 0.0),
      );
    });

    test('the document edges do not step', () {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);

      const first = ReadingAnchor(chapterIndex: 0, progressionInChapter: 0.0);
      expect(coordinator.anchorForPageStep(first, forward: false), first);

      final last = ReadingAnchor(chapterIndex: 1, progressionInChapter: 1.0);
      expect(coordinator.anchorForPageStep(last, forward: true), last);
    });

    test('an end anchor resolves to the last page once measured', () {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);
      coordinator.registerChapterHeight(chapterIndex: 0, contentHeight: 1000.0);

      final chapterOneEnd = ReadingAnchor(
        chapterIndex: 1,
        progressionInChapter: 1.0,
      );

      // Unmeasured: the end anchor provisionally resolves to the chapter's
      // first (placeholder) page.
      expect(
        coordinator.globalPageForAnchor(chapterOneEnd),
        coordinator.getGlobalPageForChapter(1),
      );

      coordinator.registerChapterHeight(
        chapterIndex: 1,
        contentHeight: _threePageHeight,
      );

      // Measured: it now resolves to the chapter's last page.
      expect(
        coordinator.globalPageForAnchor(chapterOneEnd),
        coordinator.getGlobalPageForChapter(1) + 2,
      );
      expect(coordinator.coordinateForAnchor(chapterOneEnd).pageInChapter, 2);
    });
  });

  group('ensureChapterMeasured', () {
    test('completes immediately when the chapter is measured', () async {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);
      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: _threePageHeight,
      );

      await coordinator
          .ensureChapterMeasured(0)
          .timeout(const Duration(milliseconds: 50));
    });

    test('waits for the next measurement of an unmeasured chapter', () async {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);

      var completed = false;
      final future = coordinator.ensureChapterMeasured(1);
      unawaited(future.then((_) => completed = true));

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      coordinator.registerChapterHeight(
        chapterIndex: 1,
        contentHeight: _threePageHeight,
      );

      await future;
      expect(completed, isTrue);
      expect(coordinator.isChapterMeasured(1), isTrue);
    });

    test('is released on reset so a held navigation cannot hang', () async {
      final coordinator = _coordinator();
      addTearDown(coordinator.dispose);

      final future = coordinator.ensureChapterMeasured(1);
      coordinator.reset();

      await future.timeout(const Duration(milliseconds: 50));
      expect(coordinator.isChapterMeasured(1), isFalse);
    });
  });
}
