import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Encodes raw 32-bit BGRA pixel buffers rendered by PDFium into standard lossless PNG bytes.
///
/// Pure-Dart encoding avoids invoking engine-side `dart:ui` codecs or GPU textures
/// inside background isolates, ensuring crash-free rendering across isolates.
Uint8List encodeBgraToPng(
  Uint8List bgraPixels, {
  required int width,
  required int height,
}) {
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: bgraPixels.buffer,
    bytesOffset: bgraPixels.offsetInBytes,
    format: img.Format.uint8,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );

  return Uint8List.fromList(img.encodePng(image));
}
