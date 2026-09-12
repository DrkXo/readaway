part of 'models.dart';

/// An axis-aligned rectangle in page coordinates.
@freezed
abstract class PageRect with _$PageRect {
  const factory PageRect({
    /// Left edge.
    required double x0,

    /// Top edge.
    required double y0,

    /// Right edge.
    required double x1,

    /// Bottom edge.
    required double y1,
  }) = _PageRect;

  const PageRect._();

  double get width => x1 - x0;
  double get height => y1 - y0;
}
