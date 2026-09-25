import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/share_service.dart';
import 'package:share_plus/share_plus.dart';

import '../../helpers/test_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('share_service_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ShareService Tests', () {
    test('shareDocumentFile fails when file does not exist', () async {
      final service = ShareService.withHandler(
        shareHandler: (params) async {
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await service.shareDocumentFile(
        filePath: '/path/does/not/exist.pdf',
      );
      expect(result, isFalse);
    });

    test('shareDocumentFile shares existing file successfully', () async {
      final testFile = File('${tempDir.path}/test_book.pdf');
      await testFile.writeAsString('sample content');

      ShareParams? capturedParams;

      final service = ShareService.withHandler(
        shareHandler: (params) async {
          capturedParams = params;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await service.shareDocumentFile(
        filePath: testFile.path,
        title: 'Sample Book',
      );

      expect(result, isTrue);
      expect(capturedParams, isNotNull);
      expect(capturedParams!.files, isNotNull);
      expect(capturedParams!.files!.length, 1);
      expect(capturedParams!.files!.first.path, testFile.path);
      expect(capturedParams!.subject, 'Sample Book');
      expect(capturedParams!.text, 'Sample Book');
    });

    test('sharePageImage writes imageBytes to temp and shares successfully', () async {
      final testDoc = File('${tempDir.path}/comic.cbz');
      await testDoc.writeAsString('dummy cbz content');

      final dummyImageBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]); // PNG header

      ShareParams? capturedParams;

      final service = ShareService.withHandler(
        tempDirectoryProvider: () async => tempDir,
        shareHandler: (params) async {
          capturedParams = params;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await service.sharePageImage(
        filePath: testDoc.path,
        pageIndex: 2,
        totalPages: 24,
        imageBytes: dummyImageBytes,
        title: 'Awesome Comic',
      );

      expect(result, isTrue);
      expect(capturedParams, isNotNull);
      expect(capturedParams!.files, isNotNull);
      expect(capturedParams!.files!.length, 1);
      expect(capturedParams!.files!.first.mimeType, 'image/png');
      expect(capturedParams!.files!.first.path.endsWith('_page_3.png'), isTrue);
      expect(capturedParams!.subject, 'Awesome Comic - Page 3');
      expect(capturedParams!.text, 'Page 3 of 24 from "Awesome Comic"');

      // Verify the generated file exists and contains the bytes
      final generatedFile = File(capturedParams!.files!.first.path);
      expect(generatedFile.existsSync(), isTrue);
      expect(generatedFile.readAsBytesSync(), dummyImageBytes);
      await generatedFile.delete();
    });

    test('sharePageImage returns false when imageBytes is empty', () async {
      final testDoc = File('${tempDir.path}/comic.cbz');
      await testDoc.writeAsString('dummy cbz content');

      final service = ShareService.withHandler(
        shareHandler: (params) async =>
            const ShareResult('success', ShareResultStatus.success),
      );

      final result = await service.sharePageImage(
        filePath: testDoc.path,
        pageIndex: 0,
        totalPages: 10,
        imageBytes: Uint8List(0),
      );

      expect(result, isFalse);
    });

    test('shareImageBytes writes custom image bytes and shares successfully', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      ShareParams? capturedParams;

      final service = ShareService.withHandler(
        tempDirectoryProvider: () async => tempDir,
        shareHandler: (params) async {
          capturedParams = params;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await service.shareImageBytes(
        imageBytes: dummyBytes,
        fileName: 'screenshot.png',
        subject: 'Screenshot Subject',
        text: 'Screenshot Text',
      );

      expect(result, isTrue);
      expect(capturedParams, isNotNull);
      expect(capturedParams!.files, isNotNull);
      expect(capturedParams!.files!.length, 1);
      expect(capturedParams!.files!.first.name, 'screenshot.png');
      expect(capturedParams!.subject, 'Screenshot Subject');
      expect(capturedParams!.text, 'Screenshot Text');

      final generatedFile = File(capturedParams!.files!.first.path);
      expect(generatedFile.existsSync(), isTrue);
      expect(generatedFile.readAsBytesSync(), dummyBytes);
      await generatedFile.delete();
    });

    test('shareText shares plain text snippet successfully', () async {
      ShareParams? capturedParams;

      final service = ShareService.withHandler(
        shareHandler: (params) async {
          capturedParams = params;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await service.shareText(
        'Quote from chapter 1',
        subject: 'Memorable Quote',
      );

      expect(result, isTrue);
      expect(capturedParams, isNotNull);
      expect(capturedParams!.text, 'Quote from chapter 1');
      expect(capturedParams!.subject, 'Memorable Quote');
    });
  });
}
