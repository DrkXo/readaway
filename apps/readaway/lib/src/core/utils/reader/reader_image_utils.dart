import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Decodes a MuPDF `renderPage` result map into a Flutter [ui.Image].
///
/// MuPDF renders pixels as RGB(A); Flutter's [ui.Image] wants RGBA. This
/// reorders the channels one pixel at a time, writing alpha to 255 when the
/// source was 3-component (no alpha).
Future<ui.Image> decodeRenderedPage(Map<String, dynamic> rendered) {
  final w = rendered['width'] as int;
  final h = rendered['height'] as int;
  final stride = rendered['stride'] as int;
  final comps = rendered['components'] as int;
  final src = rendered['pixels'] as Uint8List;

  // mupdf renders RGB(A); Flutter needs RGBA.
  final rgba = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    var s = y * stride;
    var d = y * w * 4;
    for (var x = 0; x < w; x++) {
      rgba[d++] = src[s];
      rgba[d++] = src[s + 1];
      rgba[d++] = src[s + 2];
      rgba[d++] = comps == 4 ? src[s + 3] : 255;
      s += comps;
    }
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    w,
    h,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}
