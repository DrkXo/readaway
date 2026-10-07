import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  const slicer = PageSlicer();

  group('PageSlicer', () {
    test(
      'returns [0.0] for non-positive dimensions or single-page content',
      () {
        expect(
          slicer.computePageOffsets(contentHeight: 0, viewportHeight: 500),
          [0.0],
        );
        expect(
          slicer.computePageOffsets(contentHeight: 500, viewportHeight: 0),
          [0.0],
        );
        expect(
          slicer.computePageOffsets(contentHeight: 400, viewportHeight: 500),
          [0.0],
        );
      },
    );

    test('slices text lines cleanly at line boundaries', () {
      // 3 lines of 100px each, viewport 250px
      final lines = <({double top, double bottom})>[
        (top: 0.0, bottom: 100.0),
        (top: 100.0, bottom: 200.0),
        (top: 200.0, bottom: 300.0),
        (top: 300.0, bottom: 400.0),
      ];

      final offsets = slicer.computePageOffsets(
        contentHeight: 400.0,
        viewportHeight: 250.0,
        lineBounds: lines,
      );

      // Page 0 holds line 0 & 1 (0 to 200). Page 1 starts at line 2 (200.0).
      expect(offsets, [0.0, 200.0]);
    });

    test('keeps an image on a new page without slicing when it fits within viewportHeight', () {
      // Paragraph text 0..200, followed by an image 200..650 (height 450)
      // Viewport height = 500.
      final lines = <({double top, double bottom})>[
        (top: 0.0, bottom: 100.0),
        (top: 100.0, bottom: 200.0),
        (top: 200.0, bottom: 650.0), // image height 450 <= 500
        (top: 650.0, bottom: 750.0),
      ];

      final offsets = slicer.computePageOffsets(
        contentHeight: 750.0,
        viewportHeight: 500.0,
        lineBounds: lines,
      );

      // Page 0: Lines 0 and 1 fit (0..200). Image (200..650) exceeds targetBottom 500.
      // So Page 0 ends at 200.0.
      // Page 1: starts at 200.0. TargetBottom is 200 + 500 = 700.
      // Image (200..650) fits completely on Page 1!
      // Line 3 (650..750) exceeds 700, so Page 2 starts at 650.0.
      expect(offsets, [0.0, 200.0, 650.0]);
    });

    test('reproduces bug: an unconstrained image taller than viewportHeight slices across pages', () {
      // Paragraph text 0..100, followed by an unconstrained image 100..800 (height 700)
      // Viewport height = 500.
      final lines = <({double top, double bottom})>[
        (top: 0.0, bottom: 100.0),
        (top: 100.0, bottom: 800.0), // Image height 700 > viewport 500!
        (top: 800.0, bottom: 900.0),
      ];

      final offsets = slicer.computePageOffsets(
        contentHeight: 900.0,
        viewportHeight: 500.0,
        lineBounds: lines,
      );

      // Page 0: Line 0 (0..100) fits. Next is image at 100.0.
      // Page 1: Starts at 100.0. TargetBottom is 100 + 500 = 600.
      // The image ends at 800.0 > 600.0. It CANNOT fit!
      // PageSlicer falls back to nextTop = targetBottom (600.0).
      // Page 2 starts at 600.0, slicing the image (100..600 on page 1, 600..800 on page 2)!
      expect(offsets, [0.0, 100.0, 600.0]);
      // Sliced directly inside the image bounds (100 < 600 < 800)
      expect(offsets.contains(600.0), isTrue);
    });

    test('when image is scaled to fit within viewportHeight, it is never sliced across pages', () {
      // With image height constrained to fit viewport (e.g. height 480 <= 500)
      final lines = <({double top, double bottom})>[
        (top: 0.0, bottom: 100.0),
        (top: 100.0, bottom: 580.0), // Constrained image height 480 <= 500
        (top: 580.0, bottom: 680.0),
      ];

      final offsets = slicer.computePageOffsets(
        contentHeight: 680.0,
        viewportHeight: 500.0,
        lineBounds: lines,
      );

      // Page 0: 0..100.
      // Page 1: starts at 100. Image ends at 580 <= 600. Entire image is on Page 1!
      // Page 2: starts at 580.
      expect(offsets, [0.0, 100.0, 580.0]);
      // Verify no slice cuts through the image between 100 and 580!
      expect(offsets.contains(600.0), isFalse);
    });
  });
}
