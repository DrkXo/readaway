import 'dart:typed_data';

import '../../models/models.dart';

/// Lightweight, zero-overhead parser that extracts image dimensions from headers
/// (JPEG, PNG, WebP, GIF, BMP) without decompressing pixel bitmaps.
class ImageHeaderParser {
  const ImageHeaderParser._();

  /// Sniffs the image format and extracts [PageSize] from raw bytes.
  /// Returns null if the format is unknown or the header is truncated.
  static PageSize? parseDimensions(Uint8List bytes) {
    if (bytes.length < 8) return null;

    // 1. PNG check: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return _parsePng(bytes);
    }

    // 2. JPEG check: FF D8
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return _parseJpeg(bytes);
    }

    // 3. GIF check: GIF87a or GIF89a
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return _parseGif(bytes);
    }

    // 4. WebP / RIFF check: 52 49 46 46 (RIFF) ... 57 45 42 50 (WEBP)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return _parseWebp(bytes);
    }

    // 5. BMP check: 42 4D (BM)
    if (bytes[0] == 0x42 && bytes[1] == 0x4D && bytes.length >= 26) {
      return _parseBmp(bytes);
    }

    return null;
  }

  static PageSize? _parsePng(Uint8List bytes) {
    if (bytes.length < 24) return null;
    final view = ByteData.sublistView(bytes);
    final width = view.getUint32(16, Endian.big).toDouble();
    final height = view.getUint32(20, Endian.big).toDouble();
    if (width <= 0 || height <= 0) return null;
    return PageSize(width: width, height: height);
  }

  static PageSize? _parseJpeg(Uint8List bytes) {
    var offset = 2;
    final view = ByteData.sublistView(bytes);
    final len = bytes.length;

    while (offset < len - 8) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }
      final marker = bytes[offset + 1];
      // Skip padding FF bytes
      if (marker == 0xFF || marker == 0x00) {
        offset++;
        continue;
      }

      // SOF0 to SOF15 (except DHT 0xC4, JPG 0xC8, DAC 0xCC)
      final isSof =
          (marker >= 0xC0 && marker <= 0xC3) ||
          (marker >= 0xC5 && marker <= 0xC7) ||
          (marker >= 0xC9 && marker <= 0xCB) ||
          (marker >= 0xCD && marker <= 0xCF);

      if (isSof && offset + 8 < len) {
        final height = view.getUint16(offset + 5, Endian.big).toDouble();
        final width = view.getUint16(offset + 7, Endian.big).toDouble();
        if (width > 0 && height > 0) {
          return PageSize(width: width, height: height);
        }
      }

      // Read chunk length and advance
      if (offset + 3 < len) {
        final chunkLen = view.getUint16(offset + 2, Endian.big);
        offset += 2 + chunkLen;
      } else {
        break;
      }
    }
    return null;
  }

  static PageSize? _parseGif(Uint8List bytes) {
    if (bytes.length < 10) return null;
    final view = ByteData.sublistView(bytes);
    final width = view.getUint16(6, Endian.little).toDouble();
    final height = view.getUint16(8, Endian.little).toDouble();
    if (width <= 0 || height <= 0) return null;
    return PageSize(width: width, height: height);
  }

  static PageSize? _parseWebp(Uint8List bytes) {
    if (bytes.length < 30) return null;
    final view = ByteData.sublistView(bytes);

    // Check chunk type at offset 12
    final tag = String.fromCharCodes(bytes.sublist(12, 16));
    if (tag == 'VP8X' && bytes.length >= 30) {
      // Extended WebP: 24-bit canvas width at offset 24, canvas height at offset 27
      final width = 1 + bytes[24] + (bytes[25] << 8) + (bytes[26] << 16);
      final height = 1 + bytes[27] + (bytes[28] << 8) + (bytes[29] << 16);
      return PageSize(width: width.toDouble(), height: height.toDouble());
    } else if (tag == 'VP8 ' && bytes.length >= 30) {
      // Lossy VP8: check startcode 9d 01 2a at offset 23
      if (bytes[23] == 0x9D && bytes[24] == 0x01 && bytes[25] == 0x2A) {
        final width = (view.getUint16(26, Endian.little) & 0x3FFF).toDouble();
        final height = (view.getUint16(28, Endian.little) & 0x3FFF).toDouble();
        if (width > 0 && height > 0) {
          return PageSize(width: width, height: height);
        }
      }
    } else if (tag == 'VP8L' && bytes.length >= 25) {
      // Lossless VP8L: signature 0x2f at offset 20
      if (bytes[20] == 0x2F) {
        final b1 = bytes[21];
        final b2 = bytes[22];
        final b3 = bytes[23];
        final b4 = bytes[24];
        final width = 1 + (b1 | ((b2 & 0x3F) << 8));
        final height = 1 + (((b2 >> 6) | (b3 << 2) | ((b4 & 0x0F) << 10)));
        return PageSize(width: width.toDouble(), height: height.toDouble());
      }
    }
    return null;
  }

  static PageSize? _parseBmp(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    final width = view.getInt32(18, Endian.little).abs().toDouble();
    final height = view.getInt32(22, Endian.little).abs().toDouble();
    if (width <= 0 || height <= 0) return null;
    return PageSize(width: width, height: height);
  }
}
