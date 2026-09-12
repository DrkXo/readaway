part of 'models.dart';

/// A single search match described by an 8-corner quad (two triangles).
///
/// Corners are ordered: upper-left, upper-right, lower-right, lower-left.
/// Transient value — not JSON-serializable.
@freezed
abstract class SearchHit with _$SearchHit {
  const factory SearchHit({
    required double ulX,
    required double ulY,
    required double urX,
    required double urY,
    required double lrX,
    required double lrY,
    required double llX,
    required double llY,
  }) = _SearchHit;
}
