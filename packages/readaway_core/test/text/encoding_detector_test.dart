import 'dart:convert';
import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('EncodingDetector', () {
    test('detects UTF-8 with BOM and decodes accurately', () {
      final utf8Bytes = Uint8List.fromList([
        0xef, 0xbb, 0xbf, // BOM
        ...utf8.encode('Hello, 世界!'),
      ]);

      final detected = EncodingDetector.detect(utf8Bytes);
      expect(detected.name, equals('utf-8'));
      expect(detected.hasBom, isTrue);

      final decoded = EncodingDetector.decode(utf8Bytes, detected: detected);
      expect(decoded, equals('Hello, 世界!'));
    });

    test('detects UTF-16LE with BOM and decodes accurately', () {
      final text = 'Hello UTF-16LE';
      final bytes = <int>[0xff, 0xfe]; // BOM
      for (final code in text.codeUnits) {
        bytes.add(code & 0xff);
        bytes.add((code >> 8) & 0xff);
      }

      final uint8 = Uint8List.fromList(bytes);
      final detected = EncodingDetector.detect(uint8);
      expect(detected.name, equals('utf-16le'));
      expect(detected.hasBom, isTrue);

      final decoded = EncodingDetector.decode(uint8, detected: detected);
      expect(decoded, equals(text));
    });

    test('detects standard UTF-8 without BOM', () {
      final bytes = Uint8List.fromList(utf8.encode('Plain UTF-8 text.'));
      final detected = EncodingDetector.detect(bytes);
      expect(detected.name, equals('utf-8'));
      expect(detected.hasBom, isFalse);
    });
  });
}
