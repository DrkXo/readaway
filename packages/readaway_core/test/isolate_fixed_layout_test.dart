import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('IsolateDocumentSession Fixed-Layout (CBZ/Comic)', () {
    late Directory tempDir;
    late String cbzPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isolate_fixed_test_');

      final archive = Archive();
      // PNG 1 (800x1200)
      final p1 = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x03, 0x20, // 800
        0x00, 0x00, 0x04, 0xB0, // 1200
        0x08, 0x06, 0x00, 0x00, 0x00,
      ]);
      // PNG 2 (400x600)
      final p2 = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x01, 0x90, // 400
        0x00, 0x00, 0x02, 0x58, // 600
        0x08, 0x06, 0x00, 0x00, 0x00,
      ]);

      archive.addFile(ArchiveFile('page_01.png', p1.length, p1));
      archive.addFile(ArchiveFile('page_02.png', p2.length, p2));

      final zipBytes = ZipEncoder().encode(archive);
      cbzPath = p.join(tempDir.path, 'sample.cbz');
      await File(cbzPath).writeAsBytes(zipBytes);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('IsolateDocumentSession opens CBZ, gets page count, dimensions, and loads page images across isolates', () async {
      final session = await IsolateDocumentSession.open(cbzPath);

      expect(session.format, 'cbz');
      expect(session.isReflowable, isFalse);
      expect(session.pageCount, 2);
      expect(session.title, 'sample');

      final size0 = await session.getPageSize(0);
      expect(size0, isNotNull);
      expect(size0!.width, 800.0);
      expect(size0.height, 1200.0);

      final size1 = await session.getPageSize(1);
      expect(size1, isNotNull);
      expect(size1!.width, 400.0);
      expect(size1.height, 600.0);

      final img0 = await session.loadPageImage(0);
      expect(img0.isNotEmpty, isTrue);

      final img1 = await session.loadPageImage(1);
      expect(img1.isNotEmpty, isTrue);

      session.dispose();
    });
  });
}
