import 'dart:typed_data';

/// Encodes raw 32-bit BGRA (or RGBA) pixel buffers into a valid uncompressed BMP image stream.
///
/// This pure-Dart encoding avoids invoking engine-side `dart:ui` codecs or GPU textures
/// inside background isolates, preventing native thread crashes while producing standard
/// image bytes decodable by Flutter's `Image.memory`.
Uint8List encodeBgraToBmp(
  Uint8List bgraPixels, {
  required int width,
  required int height,
}) {
  final pixelDataSize = width * height * 4;
  final fileSize = 54 + pixelDataSize;
  final result = Uint8List(fileSize);
  final byteData = ByteData.sublistView(result);

  // --- BMP File Header (14 bytes) ---
  // Signature 'BM'
  byteData.setUint8(0, 0x42); // 'B'
  byteData.setUint8(1, 0x4D); // 'M'
  // Total file size
  byteData.setUint32(2, fileSize, Endian.little);
  // Reserved (4 bytes = 0)
  byteData.setUint32(6, 0, Endian.little);
  // Offset to start of pixel data (54 bytes)
  byteData.setUint32(10, 54, Endian.little);

  // --- DIB Header: BITMAPINFOHEADER (40 bytes) ---
  // Header size
  byteData.setUint32(14, 40, Endian.little);
  // Image width in pixels
  byteData.setInt32(18, width, Endian.little);
  // Image height in pixels (negative value specifies top-down bitmap row order)
  byteData.setInt32(22, -height, Endian.little);
  // Number of color planes (must be 1)
  byteData.setUint16(26, 1, Endian.little);
  // Bits per pixel (32 = 8 bits each for B, G, R, A)
  byteData.setUint16(28, 32, Endian.little);
  // Compression method (0 = BI_RGB, uncompressed)
  byteData.setUint32(30, 0, Endian.little);
  // Image data size in bytes
  byteData.setUint32(34, pixelDataSize, Endian.little);
  // Horizontal resolution (pixels per meter, 2835 ppm ≈ 72 DPI)
  byteData.setInt32(38, 2835, Endian.little);
  // Vertical resolution (pixels per meter, 2835 ppm ≈ 72 DPI)
  byteData.setInt32(42, 2835, Endian.little);
  // Number of colors in color palette (0 = default)
  byteData.setUint32(46, 0, Endian.little);
  // Number of important colors (0 = all)
  byteData.setUint32(50, 0, Endian.little);

  // Copy raw pixel bytes immediately after 54-byte header
  final copyLength =
      bgraPixels.length < pixelDataSize ? bgraPixels.length : pixelDataSize;
  result.setRange(54, 54 + copyLength, bgraPixels);

  return result;
}
