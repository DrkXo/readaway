import 'dart:convert';
import 'dart:typed_data';

import '../../models/models.dart';

/// Detects character encodings of text files and decodes them into Dart [String]s.
class EncodingDetector {
  const EncodingDetector._();

  static const int _headSampleSize = 64 * 1024;
  static const int _midSampleSize = 8192;

  /// Inspects [bytes] and detects the most probable character encoding.
  static DetectedEncoding detect(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const DetectedEncoding(
        name: 'utf-8',
        confidence: 1.0,
        hasBom: false,
      );
    }

    // 1. Check for explicit Byte Order Marks (BOM)
    if (bytes.length >= 3 &&
        bytes[0] == 0xef &&
        bytes[1] == 0xbb &&
        bytes[2] == 0xbf) {
      return const DetectedEncoding(
        name: 'utf-8',
        confidence: 1.0,
        hasBom: true,
      );
    }

    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
      return const DetectedEncoding(
        name: 'utf-16le',
        confidence: 1.0,
        hasBom: true,
      );
    }

    if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
      return const DetectedEncoding(
        name: 'utf-16be',
        confidence: 1.0,
        hasBom: true,
      );
    }

    // 2. Strict UTF-8 validation on head and mid samples
    final headLen = bytes.length < _headSampleSize ? bytes.length : _headSampleSize;
    final headSample = Uint8List.sublistView(bytes, 0, headLen);

    bool isStrictUtf8 = true;
    try {
      utf8.decode(headSample);
      if (bytes.length > _headSampleSize * 2) {
        final midStart = (bytes.length - _midSampleSize) ~/ 2;
        final midSample = Uint8List.sublistView(
          bytes,
          midStart,
          midStart + _midSampleSize,
        );
        utf8.decode(midSample);
      }
    } catch (_) {
      isStrictUtf8 = false;
    }

    if (isStrictUtf8) {
      return const DetectedEncoding(
        name: 'utf-8',
        confidence: 0.99,
        hasBom: false,
      );
    }

    // 3. Heuristic byte analysis when strict UTF-8 fails
    int highByteCount = 0;
    final sampleSize = headSample.length < 4096 ? headSample.length : 4096;
    for (int i = 0; i < sampleSize; i++) {
      if (headSample[i] >= 0x80) {
        highByteCount++;
      }
    }
    final highByteRatio = sampleSize > 0 ? highByteCount / sampleSize : 0.0;

    // Detect Shift-JIS pattern
    if (highByteRatio > 0.1) {
      bool sjisPattern = false;
      for (int i = 0; i < sampleSize - 1; i++) {
        final b1 = headSample[i];
        final b2 = headSample[i + 1];
        if (((b1 >= 0x81 && b1 <= 0x9f) || (b1 >= 0xe0 && b1 <= 0xfc)) &&
            ((b2 >= 0x40 && b2 <= 0x7e) || (b2 >= 0x80 && b2 <= 0xfc))) {
          sjisPattern = true;
          break;
        }
      }

      if (sjisPattern) {
        return const DetectedEncoding(
          name: 'shift-jis',
          confidence: 0.85,
          hasBom: false,
        );
      }

      if (highByteRatio > 0.3) {
        return const DetectedEncoding(
          name: 'gbk',
          confidence: 0.88,
          hasBom: false,
        );
      }
    }

    // Default to lenient UTF-8
    return const DetectedEncoding(
      name: 'utf-8',
      confidence: 0.75,
      hasBom: false,
    );
  }

  /// Decodes [bytes] into a [String] using the detected or specified encoding.
  static String decode(Uint8List bytes, {DetectedEncoding? detected}) {
    final encoding = detected ?? detect(bytes);

    switch (encoding.name.toLowerCase()) {
      case 'utf-16le':
        final skip = encoding.hasBom ? 2 : 0;
        final actualBytes = bytes.sublist(skip);
        final charCodes = <int>[];
        for (int i = 0; i + 1 < actualBytes.length; i += 2) {
          charCodes.add(actualBytes[i] | (actualBytes[i + 1] << 8));
        }
        return String.fromCharCodes(charCodes);

      case 'utf-16be':
        final skip = encoding.hasBom ? 2 : 0;
        final actualBytes = bytes.sublist(skip);
        final charCodes = <int>[];
        for (int i = 0; i + 1 < actualBytes.length; i += 2) {
          charCodes.add((actualBytes[i] << 8) | actualBytes[i + 1]);
        }
        return String.fromCharCodes(charCodes);

      case 'utf-8':
      default:
        final skip = encoding.hasBom && bytes.length >= 3 ? 3 : 0;
        final actualBytes = skip > 0 ? bytes.sublist(skip) : bytes;
        return utf8.decode(actualBytes, allowMalformed: true);
    }
  }
}
