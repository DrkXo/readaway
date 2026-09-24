// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

String? _resolveTestDocPath(String primaryKey, [String? fallbackKey]) {
  final envVal =
      Platform.environment[primaryKey] ??
      (fallbackKey != null ? Platform.environment[fallbackKey] : null);
  if (envVal != null && envVal.isNotEmpty) return envVal;

  final defineVal = String.fromEnvironment(primaryKey);
  if (defineVal.isNotEmpty) return defineVal;

  if (fallbackKey != null) {
    final fallbackDefine = String.fromEnvironment(fallbackKey);
    if (fallbackDefine.isNotEmpty) return fallbackDefine;
  }

  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real E-Book Files Verification', () {
    final cbzPath = _resolveTestDocPath('TEST_CBZ_PATH', 'CBZ_PATH');
    final pdfPath = _resolveTestDocPath('TEST_PDF_PATH', 'PDF_PATH');
    final protectedPdfPath = _resolveTestDocPath(
      'TEST_PROTECTED_PDF_PATH',
      'PROTECTED_PDF_PATH',
    );
    final protectedPdfPassword =
        _resolveTestDocPath(
          'TEST_PROTECTED_PDF_PASSWORD',
          'PROTECTED_PDF_PASSWORD',
        ) ??
        '1234';

    final hasCbz = cbzPath != null && File(cbzPath).existsSync();
    final hasPdf = pdfPath != null && File(pdfPath).existsSync();
    final hasProtectedPdf =
        protectedPdfPath != null && File(protectedPdfPath).existsSync();

    test(
      'Verify CBZ directly and via IsolateDocumentSession',
      () async {
        final path = cbzPath!;
        final file = File(path);
        print('Testing CBZ: $path (Size: ${file.lengthSync()} bytes)');

        // 1. Direct Reader
        final reader = await ComicBookDocumentReader.open(path);
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
        final session = await IsolateDocumentSession.open(path);
        print('  Isolate CBZ session opened:');
        print('  - Session title: ${session.title}');
        print('  - Session page count: ${session.pageCount}');
        expect(session.pageCount, greaterThan(0));

        final isolateSize0 = await session.getPageSize(0);
        print(
          '  - Isolate Page 0 dimensions: ${isolateSize0?.width}x${isolateSize0?.height}',
        );
        expect(isolateSize0, isNotNull);

        final isolateImg0 = await session.loadPageImage(0);
        print('  - Isolate Page 0 image bytes: ${isolateImg0.length}');
        expect(isolateImg0.isNotEmpty, isTrue);

        session.dispose();
        print('CBZ verification completed successfully!\n');
      },
      skip: !hasCbz
          ? 'CBZ file not provided or not found (set TEST_CBZ_PATH or CBZ_PATH)'
          : null,
    );

    test(
      'Verify PDF directly and via IsolateDocumentSession',
      () async {
        final path = pdfPath!;
        final file = File(path);
        print('Testing PDF: $path (Size: ${file.lengthSync()} bytes)');

        // 1. Direct Reader
        final reader = await PdfDocumentReader.open(path);
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
      },
      skip: !hasPdf
          ? 'PDF file not provided or not found (set TEST_PDF_PATH or PDF_PATH)'
          : null,
    );

    test(
      'Verify protected PDF password handling and unlocking',
      () async {
        final path = protectedPdfPath!;
        final file = File(path);
        print(
          'Testing Protected PDF: $path (Size: ${file.lengthSync()} bytes)',
        );

        // 1. Open without password -> Expect DocumentEncryptedException with isInvalidPassword: false
        try {
          await PdfDocumentReader.open(path);
          fail(
            'Should have thrown DocumentEncryptedException when opening without password',
          );
        } on DocumentEncryptedException catch (e) {
          print(
            '  Correctly caught password requirement without password: ${e.message} (isInvalidPassword: ${e.isInvalidPassword})',
          );
          expect(e.isInvalidPassword, isFalse);
        }

        // 2. Open with wrong password -> Expect DocumentEncryptedException with isInvalidPassword: true
        try {
          await PdfDocumentReader.open(
            path,
            password: 'definitely_wrong_password_123',
          );
          fail(
            'Should have thrown DocumentEncryptedException when opening with wrong password',
          );
        } on DocumentEncryptedException catch (e) {
          print(
            '  Correctly caught invalid password error: ${e.message} (isInvalidPassword: ${e.isInvalidPassword})',
          );
          expect(e.isInvalidPassword, isTrue);
        }

        // 3. Open with correct password
        final unlockedReader = await PdfDocumentReader.open(
          path,
          password: protectedPdfPassword,
        );
        print(
          '  Successfully unlocked protected PDF with password: "$protectedPdfPassword"!',
        );
        print('  - Unlocked title: ${unlockedReader.title}');
        print('  - Unlocked page count: ${unlockedReader.pageCount}');
        expect(unlockedReader.pageCount, greaterThan(0));

        final size0 = unlockedReader.getPageSize(0);
        print('  - Page 0 dimensions: ${size0?.width}x${size0?.height}');
        expect(size0, isNotNull);

        final img0 = await unlockedReader.loadPageImage(0);
        print('  - Page 0 rendered image pixels: ${img0.length}');
        expect(img0.isNotEmpty, isTrue);
        unlockedReader.dispose();

        print('Protected PDF verification completed successfully!\n');
      },
      skip: !hasProtectedPdf
          ? 'Protected PDF file not provided or not found (set TEST_PROTECTED_PDF_PATH or PROTECTED_PDF_PATH)'
          : null,
    );
  });
}
