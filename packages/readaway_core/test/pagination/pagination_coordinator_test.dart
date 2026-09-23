import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('PaginationCoordinator.registerChapterHeight', () {
    test('skips recompute when contentHeight is unchanged', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 2000,
      );

      final offsets = coordinator.getChapterPageOffsets(0);
      expect(coordinator.currentState.totalPages, 2);

      // Re-registering the same measurement (a page turn re-measures the
      // whole chapter) must not recompute offsets.
      coordinator.registerChapterHeight(chapterIndex: 0, contentHeight: 2000);
      expect(identical(coordinator.getChapterPageOffsets(0), offsets), isTrue);

      coordinator.registerChapterHeight(chapterIndex: 0, contentHeight: 1500);
      expect(identical(coordinator.getChapterPageOffsets(0), offsets), isFalse);
      expect(coordinator.getChapterHeight(0), 1500);
    });

    test('skips recompute when lineBounds are unchanged', () {
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 1,
        viewportHeight: 1000,
        contentHeight: 2000,
      );

      final bounds = [(top: 0.0, bottom: 80.0), (top: 80.0, bottom: 160.0)];
      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: 2000,
        lineBounds: bounds,
      );
      final offsets = coordinator.getChapterPageOffsets(0);

      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: 2000,
        lineBounds: List.of(bounds),
      );
      expect(identical(coordinator.getChapterPageOffsets(0), offsets), isTrue);

      coordinator.registerChapterHeight(
        chapterIndex: 0,
        contentHeight: 2000,
        lineBounds: const [
          (top: 0.0, bottom: 90.0),
          (top: 90.0, bottom: 180.0),
        ],
      );
      expect(identical(coordinator.getChapterPageOffsets(0), offsets), isFalse);
    });
  });
}
