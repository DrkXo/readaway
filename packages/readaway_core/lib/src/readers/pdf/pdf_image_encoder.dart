import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Encodes raw 32-bit BGRA pixel buffers rendered by PDFium into an uncompressed BMP format.
///
/// Running pure-Dart PNG/Deflate encoding on multi-megapixel page bitmaps takes
/// 800ms–2500ms of CPU time per page on the main isolate. By contrast, prepending a
/// 54-byte BMP header to raw BGRA pixels takes <0.1ms and is decoded natively by
/// Flutter's C++ Skia/Impeller engine without any software compression overhead.
Uint8List encodeBgraToBmp(
  Uint8List bgraPixels, {
  required int width,
  required int height,
}) {
  final pixelBytesLength = bgraPixels.lengthInBytes;
  final totalSize = 54 + pixelBytesLength;
  final bytes = Uint8List(totalSize);
  final byteData = ByteData.sublistView(bytes);

  // 1. BMP File Header (14 bytes)
  bytes[0] = 0x42; // 'B'
  bytes[1] = 0x4D; // 'M'
  byteData.setUint32(2, totalSize, Endian.little);
  byteData.setUint16(6, 0, Endian.little); // Reserved 1
  byteData.setUint16(8, 0, Endian.little); // Reserved 2
  byteData.setUint32(10, 54, Endian.little); // Pixel data offset

  // 2. DIB Header (BITMAPINFOHEADER - 40 bytes)
  byteData.setUint32(14, 40, Endian.little); // Header size
  byteData.setInt32(18, width, Endian.little); // Image width
  byteData.setInt32(
    22,
    -height,
    Endian.little,
  ); // Image height (negative = top-down)
  byteData.setUint16(26, 1, Endian.little); // Planes
  byteData.setUint16(28, 32, Endian.little); // Bits per pixel (32-bit BGRA)
  byteData.setUint32(
    30,
    0,
    Endian.little,
  ); // Compression (0 = BI_RGB, uncompressed)
  byteData.setUint32(34, pixelBytesLength, Endian.little); // Image size
  byteData.setInt32(38, 2835, Endian.little); // X pixels per meter (~72 DPI)
  byteData.setInt32(42, 2835, Endian.little); // Y pixels per meter (~72 DPI)
  byteData.setUint32(46, 0, Endian.little); // Colors in table
  byteData.setUint32(50, 0, Endian.little); // Important colors

  // 3. Pixel data copy
  bytes.setRange(54, totalSize, bgraPixels);

  return bytes;
}

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
