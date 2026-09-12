import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('PageSlicer', () {
    const slicer = PageSlicer();

    test('returns a single page when content fits the viewport', () {
      final offsets = slicer.computePageOffsets(
        contentHeight: 500,
        viewportHeight: 800,
      );
      expect(offsets, [0.0]);
    });

    test('returns a single page for zero or negative dimensions', () {
      expect(slicer.computePageOffsets(contentHeight: 0, viewportHeight: 800), [
        0.0,
      ]);
      expect(slicer.computePageOffsets(contentHeight: 500, viewportHeight: 0), [
        0.0,
      ]);
    });

    test('slices by viewport height when no line bounds are provided', () {
      final offsets = slicer.computePageOffsets(
        contentHeight: 2500,
        viewportHeight: 800,
      );
      expect(offsets, [0.0, 800.0, 1600.0, 2400.0]);
    });

    test('snaps slice points to line tops when bounds are provided', () {
      // Lines at 0-20, 20-40, 40-60, 60-80, 80-100, 100-120, 120-140.
      final lineBounds = [
        for (var i = 0; i < 7; i++) (top: i * 20.0, bottom: i * 20.0 + 20.0),
      ];
      final offsets = slicer.computePageOffsets(
        contentHeight: 140,
        viewportHeight: 50,
        lineBounds: lineBounds,
      );
      // Page 0: 0..50 -> last fully-contained line is line 1 (20-40);
      // next top = line 2 top = 40. Subsequent pages snap to 80 and 120.
      expect(offsets, [0.0, 40.0, 80.0, 120.0]);
    });

    test('advances by viewport when a single element exceeds the viewport', () {
      final lineBounds = [
        (top: 0.0, bottom: 2000.0), // taller than viewport
        (top: 2000.0, bottom: 2100.0),
      ];
      final offsets = slicer.computePageOffsets(
        contentHeight: 2100,
        viewportHeight: 500,
        lineBounds: lineBounds,
      );
      expect(offsets.first, 0.0);
      expect(offsets, contains(500.0));
    });

    test('getSliceHeight computes the height of each slice', () {
      final offsets = [0.0, 800.0, 1600.0, 2400.0];
      expect(
        slicer.getSliceHeight(
          pageOffsets: offsets,
          pageIndex: 0,
          contentHeight: 2500,
          viewportHeight: 800,
        ),
        800.0,
      );
      expect(
        slicer.getSliceHeight(
          pageOffsets: offsets,
          pageIndex: 3,
          contentHeight: 2500,
          viewportHeight: 800,
        ),
        100.0,
      );
      expect(
        slicer.getSliceHeight(
          pageOffsets: offsets,
          pageIndex: 99,
          contentHeight: 2500,
          viewportHeight: 800,
        ),
        800.0,
      );
    });
  });
}
