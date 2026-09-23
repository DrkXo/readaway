import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('PdfEngineManager & PdfFormatHandler Tests', () {
    test('PdfEngineManager reference counting and lifecycle', () async {
      expect(PdfEngineManager.activeCount, 0);
      expect(PdfEngineManager.isInitialized, isFalse);

      await PdfEngineManager.acquire();
      expect(PdfEngineManager.activeCount, 1);
      expect(PdfEngineManager.isInitialized, isTrue);

      await PdfEngineManager.acquire();
      expect(PdfEngineManager.activeCount, 2);

      await PdfEngineManager.release();
      expect(PdfEngineManager.activeCount, 1);
      expect(PdfEngineManager.isInitialized, isTrue);

      await PdfEngineManager.release();
      expect(PdfEngineManager.activeCount, 0);
      expect(PdfEngineManager.isInitialized, isFalse);
    });

    test('PdfFormatHandler supports extension and magic bytes', () {
      const handler = PdfFormatHandler();
      expect(handler.format, 'pdf');
      expect(handler.supports('book.pdf'), isTrue);
      expect(handler.supports('book.PDF'), isTrue);
      expect(handler.supports('book.epub'), isFalse);

      final pdfMagic = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]); // %PDF-1.7
      expect(handler.supports('unknown_file', pdfMagic), isTrue);

      final nonPdf = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]); // PK..
      expect(handler.supports('unknown_file', nonPdf), isFalse);
    });

    test('DocumentEncryptedException properties', () {
      const ex1 = DocumentEncryptedException('Password needed', isInvalidPassword: false);
      expect(ex1.isInvalidPassword, isFalse);
      expect(ex1.message, 'Password needed');

      const ex2 = DocumentEncryptedException('Wrong password', isInvalidPassword: true);
      expect(ex2.isInvalidPassword, isTrue);
      expect(ex2.toString(), contains('Wrong password'));
    });
  });
}
