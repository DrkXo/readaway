// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real E-Book Files Verification', () {
    const cbzPath = '/home/drkxo/Documents/Ebooks/example.cbz';
    const pdfPath = '/home/drkxo/Documents/Ebooks/The-Collected-Works-of-HP-Lovecraft.pdf';
    const protectedPdfPath = '/home/drkxo/Documents/Ebooks/The-Collected-Works-of-HP-Lovecraft_protected.pdf';

    test('Verify example.cbz directly and via IsolateDocumentSession', () async {
      final file = File(cbzPath);
      expect(file.existsSync(), isTrue, reason: 'File does not exist: $cbzPath');

      print('Testing CBZ: $cbzPath (Size: ${file.lengthSync()} bytes)');

      // 1. Direct Reader
      final reader = await ComicBookDocumentReader.open(cbzPath);
      print('  Direct CBZ opened:');
      print('  - Title: ${reader.title}');
      print('  - Format: ${reader.format}');
      print('  - Page count: ${reader.pageCount}');
      print('  - Metadata author: ${reader.metadata?.author}');
      print('  - Outline items: ${reader.outline.length}');

      expect(reader.format, 'cbz');
      expect(reader.pageCount, greaterThan(0));

      final size0 = reader.getPageSize(0);
      print('  - Page 0 dimensions: ${size0?.width}x${size0?.height}');
      expect(size0, isNotNull);

      final img0 = await reader.loadPageImage(0);
      print('  - Page 0 image bytes: ${img0.length}');
      expect(img0.isNotEmpty, isTrue);

      reader.dispose();

      // 2. Isolate Session
      final session = await IsolateDocumentSession.open(cbzPath);
      print('  Isolate CBZ session opened:');
      print('  - Session title: ${session.title}');
      print('  - Session page count: ${session.pageCount}');
      expect(session.pageCount, greaterThan(0));

      final isolateSize0 = await session.getPageSize(0);
      print('  - Isolate Page 0 dimensions: ${isolateSize0?.width}x${isolateSize0?.height}');
      expect(isolateSize0, isNotNull);

      final isolateImg0 = await session.loadPageImage(0);
      print('  - Isolate Page 0 image bytes: ${isolateImg0.length}');
      expect(isolateImg0.isNotEmpty, isTrue);

      session.dispose();
      print('CBZ verification completed successfully!\n');
    });

    test('Verify The-Collected-Works-of-HP-Lovecraft.pdf directly and via IsolateDocumentSession', () async {
      final file = File(pdfPath);
      expect(file.existsSync(), isTrue, reason: 'File does not exist: $pdfPath');

      print('Testing PDF: $pdfPath (Size: ${file.lengthSync()} bytes)');

      // 1. Direct Reader
      final reader = await PdfDocumentReader.open(pdfPath);
      print('  Direct PDF opened:');
      print('  - Title: ${reader.title}');
      print('  - Format: ${reader.format}');
      print('  - Page count: ${reader.pageCount}');
      print('  - Outline items: ${reader.outline.length}');

      expect(reader.format, 'pdf');
      expect(reader.pageCount, greaterThan(0));

      final size0 = reader.getPageSize(0);
      print('  - Page 0 dimensions: ${size0?.width}x${size0?.height}');
      expect(size0, isNotNull);

      final img0 = await reader.loadPageImage(0);
      print('  - Page 0 rendered image pixels: ${img0.length}');
      expect(img0.isNotEmpty, isTrue);

      reader.dispose();
      print('PDF verification completed successfully!\n');
    });

    test('Verify The-Collected-Works-of-HP-Lovecraft_protected.pdf password handling and unlocking', () async {
      final file = File(protectedPdfPath);
      expect(file.existsSync(), isTrue, reason: 'File does not exist: $protectedPdfPath');

      print('Testing Protected PDF: $protectedPdfPath (Size: ${file.lengthSync()} bytes)');

      // 1. Open without password -> Expect DocumentEncryptedException with isInvalidPassword: false
      try {
        await PdfDocumentReader.open(protectedPdfPath);
        fail('Should have thrown DocumentEncryptedException when opening without password');
      } on DocumentEncryptedException catch (e) {
        print('  Correctly caught password requirement without password: ${e.message} (isInvalidPassword: ${e.isInvalidPassword})');
        expect(e.isInvalidPassword, isFalse);
      }

      // 2. Open with wrong password -> Expect DocumentEncryptedException with isInvalidPassword: true
      try {
        await PdfDocumentReader.open(protectedPdfPath, password: 'definitely_wrong_password_123');
        fail('Should have thrown DocumentEncryptedException when opening with wrong password');
      } on DocumentEncryptedException catch (e) {
        print('  Correctly caught invalid password error: ${e.message} (isInvalidPassword: ${e.isInvalidPassword})');
        expect(e.isInvalidPassword, isTrue);
      }

      // 3. Open with correct password '1234'
      final unlockedReader = await PdfDocumentReader.open(protectedPdfPath, password: '1234');
      print('  Successfully unlocked protected PDF with password: "1234"!');
      print('  - Unlocked title: ${unlockedReader.title}');
      print('  - Unlocked page count: ${unlockedReader.pageCount}');
      expect(unlockedReader.pageCount, 1374);

      final size0 = unlockedReader.getPageSize(0);
      print('  - Page 0 dimensions: ${size0?.width}x${size0?.height}');
      expect(size0, isNotNull);

      final img0 = await unlockedReader.loadPageImage(0);
      print('  - Page 0 rendered image pixels: ${img0.length}');
      expect(img0.isNotEmpty, isTrue);
      unlockedReader.dispose();

      print('Protected PDF verification completed successfully!\n');
    });
  });
}
