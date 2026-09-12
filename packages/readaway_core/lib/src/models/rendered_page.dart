part of 'models.dart';

/// Raw rendered page pixels (RGBA, premultiplied alpha).
///
/// This is a transient, memory-heavy value — it is intentionally **not**
/// JSON-serializable.
@freezed
abstract class RenderedPage with _$RenderedPage {
  const factory RenderedPage({
    /// Pixel width of the rendered image.
    required int width,

    /// Pixel height of the rendered image.
    required int height,

    /// Bytes per row (may exceed `width * components` due to padding).
    required int stride,

    /// Number of color components per pixel (4 = RGBA).
    required int components,

    /// Raw pixel data, `stride * height` bytes.
    required Uint8List pixels,
  }) = _RenderedPage;
}
