import 'dart:math' as math;
import 'package:injectable/injectable.dart';

/// Computes discrete screen-page slice offsets for reflowable content.
///
/// Ensures that pages snap cleanly between line rows or block elements,
/// preventing text lines or inline images from being sliced in half across
/// horizontal page turns.
@lazySingleton
class ReflowablePageSlicer {
  const ReflowablePageSlicer();

  /// Computes the list of top Y-offsets for each page slice.
  ///
  /// [contentHeight]: Total laid-out height of the chapter content in logical pixels.
  /// [viewportHeight]: Visible height of the reader viewport (excluding margins).
  /// [lineBounds]: Optional list of line or block boundaries `(top, bottom)`
  ///   extracted from layout, used to snap slice points cleanly between lines.
  ///
  /// Returns a non-empty list of vertical offsets: `[0.0, offset1, offset2, ...]`.
  /// The number of pages is `offsets.length`.
  List<double> computePageOffsets({
    required double contentHeight,
    required double viewportHeight,
    List<({double top, double bottom})>? lineBounds,
  }) {
    if (contentHeight <= 0.0 || viewportHeight <= 0.0) {
      return const [0.0];
    }

    if (contentHeight <= viewportHeight) {
      return const [0.0];
    }

    // Fallback: If no line boundaries are provided, slice by viewport height
    if (lineBounds == null || lineBounds.isEmpty) {
      final offsets = <double>[];
      var currentOffset = 0.0;
      while (currentOffset < contentHeight) {
        offsets.add(currentOffset);
        currentOffset += viewportHeight;
      }
      return offsets;
    }

    final offsets = <double>[0.0];
    var currentTop = 0.0;

    while (currentTop + viewportHeight < contentHeight) {
      final targetBottom = currentTop + viewportHeight;

      // Find the last line whose bottom does not exceed targetBottom
      int breakIndex = -1;
      for (var i = 0; i < lineBounds.length; i++) {
        final line = lineBounds[i];
        if (line.top < currentTop - 0.5) continue;

        if (line.bottom <= targetBottom) {
          breakIndex = i;
        } else {
          break;
        }
      }

      if (breakIndex == lineBounds.length - 1) {
        // All lines in the chapter have fit on this page
        break;
      }

      double nextTop;
      if (breakIndex != -1 && breakIndex + 1 < lineBounds.length) {
        final nextLine = lineBounds[breakIndex + 1];
        nextTop = nextLine.top;
      } else {
        // If a single line or element is taller than the viewport, advance by viewportHeight
        nextTop = targetBottom;
      }

      // Guard against infinite loop if nextTop does not advance
      if (nextTop <= currentTop) {
        nextTop = currentTop + viewportHeight;
      }

      offsets.add(nextTop);
      currentTop = nextTop;
    }

    return offsets;
  }

  /// Calculates the slice height for a specific page index.
  double getSliceHeight({
    required List<double> pageOffsets,
    required int pageIndex,
    required double contentHeight,
    required double viewportHeight,
  }) {
    if (pageIndex < 0 || pageIndex >= pageOffsets.length) {
      return viewportHeight;
    }

    final start = pageOffsets[pageIndex];
    final end = (pageIndex + 1 < pageOffsets.length)
        ? pageOffsets[pageIndex + 1]
        : contentHeight;

    return math.max(0.0, end - start);
  }
}
