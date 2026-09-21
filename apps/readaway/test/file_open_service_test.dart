import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/models/reader/supported_document_formats.dart';
import 'package:readaway/src/core/services/file_open_service.dart';
import 'package:readaway/src/core/services/logging_service.dart';

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('readaway_test'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  group('handleUri', () {
    test('queues a scheme-less absolute path if the file exists', () async {
      final file = File('${tempDir.path}/book.epub')..createSync();
      final service = FileOpenService(loggingService: LoggingService());
      final emitted = <IncomingDocument>[];
      final sub = service.incomingDocuments.listen(emitted.add);

      await service.handleUri(Uri.parse(file.path));

      expect(emitted, hasLength(1));
      expect(emitted.single.path, file.absolute.path);
      expect(emitted.single.fileName, 'book.epub');

      await sub.cancel();
      service.dispose();
    });

    test('handles file:// URI with percent encoding', () async {
      final file = File('${tempDir.path}/my space book.epub')..createSync();
      final service = FileOpenService(loggingService: LoggingService());
      final emitted = <IncomingDocument>[];
      final sub = service.incomingDocuments.listen(emitted.add);

      final fileUri = Uri.file(file.path);
      await service.handleUri(fileUri);

      expect(emitted, hasLength(1));
      expect(emitted.single.path, file.absolute.path);
      expect(emitted.single.fileName, 'my space book.epub');

      await sub.cancel();
      service.dispose();
    });

    test('drops a scheme-less path that does not exist', () async {
      final service = FileOpenService(loggingService: LoggingService());
      final emitted = <IncomingDocument>[];
      final sub = service.incomingDocuments.listen(emitted.add);

      await service.handleUri(Uri.parse('${tempDir.path}/missing.epub'));

      expect(emitted, isEmpty);

      await sub.cancel();
      service.dispose();
    });
  });

  group('startup queuing & CLI args', () {
    test('delivers a document queued before any listener subscribes', () async {
      // Cold-start on desktop: initializeWithArgs runs before the router
      // subscribes (after first frame). The queued document must not be lost.
      final file = File('${tempDir.path}/queued.epub')..createSync();
      final service = FileOpenService(loggingService: LoggingService());

      service.initializeWithArgs([file.absolute.path]);

      final emitted = <IncomingDocument>[];
      final sub = service.incomingDocuments.listen(emitted.add);

      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.single.path, file.absolute.path);

      await sub.cancel();
      service.dispose();
    });

    test('handles double-quoted CLI argument with spaces', () async {
      final file = File('${tempDir.path}/my special book.epub')..createSync();
      final service = FileOpenService(loggingService: LoggingService());

      service.initializeWithArgs(['"${file.absolute.path}"']);

      final emitted = <IncomingDocument>[];
      final sub = service.incomingDocuments.listen(emitted.add);

      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.single.path, file.absolute.path);
      expect(emitted.single.fileName, 'my special book.epub');

      await sub.cancel();
      service.dispose();
    });

    test('handles file:// URI in CLI argument', () async {
      final file = File('${tempDir.path}/uri_book.epub')..createSync();
      final service = FileOpenService(loggingService: LoggingService());

      service.initializeWithArgs([Uri.file(file.path).toString()]);

      final emitted = <IncomingDocument>[];
      final sub = service.incomingDocuments.listen(emitted.add);

      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.single.path, file.absolute.path);

      await sub.cancel();
      service.dispose();
    });
  });

  group('SupportedDocumentFormats', () {
    test('supports standard formats', () {
      expect(SupportedDocumentFormats.isSupported('a.epub'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.EPUB'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.cbz'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.txt'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.md'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.html'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.htm'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.xhtml'), isTrue);
      expect(SupportedDocumentFormats.isSupported('a.pdf'), isFalse);
      expect(SupportedDocumentFormats.isSupported('a.exe'), isFalse);
    });
  });
}