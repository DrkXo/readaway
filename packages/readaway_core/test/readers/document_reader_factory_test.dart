import 'dart:io';
import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

import '../fixtures/cbz_fixture.dart';
import '../fixtures/epub_fixture.dart';

void main() {
  group('DocumentReaderFactory', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('readaway_core_factory_');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('registers built-in handlers by default', () {
      final factory = DocumentReaderFactory();
      expect(
        factory.handlers.map((h) => h.format),
        containsAll(['epub', 'cbz', 'html', 'txt']),
      );
    });

    test('opens an EPUB file by extension', () async {
      final epubPath = '${tempDir.path}/book.epub';
      File(epubPath).writeAsBytesSync(EpubFixture.build());

      final factory = DocumentReaderFactory();
      final reader = await factory.open(epubPath);

      expect(reader, isA<EpubDocumentReader>());
      expect(reader.format, 'epub');
      expect(reader.title, 'Test Book');
      reader.dispose();
    });

    test('sniffs ZIP magic bytes for unknown extensions', () async {
      final epubPath = '${tempDir.path}/book.data';
      File(epubPath).writeAsBytesSync(EpubFixture.build());

      final factory = DocumentReaderFactory();
      final reader = await factory.open(epubPath);

      expect(reader, isA<EpubDocumentReader>());
      reader.dispose();
    });

    test('opens a CBZ file by extension', () async {
      final cbzPath = '${tempDir.path}/comic.cbz';
      File(cbzPath).writeAsBytesSync(CbzFixture.build());

      final factory = DocumentReaderFactory();
      final reader = await factory.open(cbzPath);

      expect(reader, isA<CbzDocumentReader>());
      expect(reader.format, 'cbz');
      expect((reader as CbzDocumentReader).pageCount, 3);
      reader.dispose();
    });

    test('sniffs CBZ from an unknown-extension ZIP with images', () async {
      final cbzPath = '${tempDir.path}/comic.data';
      File(cbzPath).writeAsBytesSync(CbzFixture.build());

      final factory = DocumentReaderFactory();
      final reader = await factory.open(cbzPath);

      expect(reader, isA<CbzDocumentReader>());
      reader.dispose();
    });

    test('EPUB handler does not claim CBZ bytes', () {
      const handler = EpubFormatHandler();
      expect(handler.supports('comic.data', CbzFixture.build()), isFalse);
    });

    test('CBZ handler does not claim EPUB bytes', () {
      const handler = CbzFormatHandler();
      expect(handler.supports('book.data', EpubFixture.build()), isFalse);
    });

    test('throws UnsupportedFormatException for unknown files', () async {
      final unknownPath = '${tempDir.path}/file.xyz';
      File(unknownPath).writeAsBytesSync(Uint8List.fromList([1, 2, 3]));

      final factory = DocumentReaderFactory();
      expect(
        () => factory.open(unknownPath),
        throwsA(isA<UnsupportedFormatException>()),
      );
    });

    test('supports registering and unregistering custom handlers', () async {
      final factory = DocumentReaderFactory();
      factory.unregister('txt');
      expect(factory.handlers.map((h) => h.format), isNot(contains('txt')));

      final custom = _FakeHandler();
      factory.register(custom);
      expect(factory.handlers, contains(custom));

      final reader = await factory.open('${tempDir.path}/custom.fake');
      expect(reader, isA<_FakeReader>());
      reader.dispose();
    });
  });
}

class _FakeHandler implements DocumentFormatHandler {
  @override
  String get format => 'fake';

  @override
  bool supports(String filePath, [Uint8List? bytes]) =>
      filePath.endsWith('.fake');

  @override
  Future<DocumentReader> open(String filePath) async => _FakeReader();
}

class _FakeReader implements DocumentReader {
  @override
  String get format => 'fake';

  @override
  bool get isReflowable => true;

  @override
  String? get title => 'Fake';

  @override
  DocumentMetadata? get metadata => null;

  @override
  List<OutlineItem> get outline => const [];

  @override
  String? get coverImagePath => null;

  @override
  Uint8List? loadAsset(String assetPath) => null;

  @override
  void dispose() {}
}
