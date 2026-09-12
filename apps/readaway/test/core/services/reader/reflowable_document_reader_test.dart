import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/reader/reflowable_document_reader.dart';
import 'package:readaway/src/core/services/reader/single_html_document_reader.dart';
import 'package:readaway/src/core/services/reader/plain_text_document_reader.dart';
import 'package:readaway/src/core/services/reader/epub_document_reader.dart';

void main() {
  group('ReflowableDocumentReader - PlainTextDocumentReader', () {
    late Directory tempDir;
    late File textFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('plain_text_test_');
      textFile = File('${tempDir.path}/sample.txt');
      await textFile.writeAsString('''
First paragraph of the story.
With a second line.

Second paragraph after double newline.

Third paragraph.
''');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('parses plain text into single section with semantic paragraphs', () async {
      final reader = await PlainTextDocumentReader.fromFile(textFile.path);
      expect(reader.sectionCount, equals(1));
      expect(reader.sections.first.mediaType, equals('text/plain'));

      final html = reader.loadSectionHtml(0);
      expect(html, contains('<p>First paragraph of the story.<br/>With a second line.</p>'));
      expect(html, contains('<p>Second paragraph after double newline.</p>'));
      expect(html, contains('<p>Third paragraph.</p>'));
      expect(reader.title, equals('First paragraph of the story.'));
      expect(reader.outline.length, equals(1));
      expect(reader.outline.first.title, equals('First paragraph of the story.'));

      reader.dispose();
    });

    test('auto-detects .txt format via ReflowableDocumentReader.fromFile', () async {
      final reader = await ReflowableDocumentReader.fromFile(textFile.path);
      expect(reader, isA<PlainTextDocumentReader>());
      expect(reader.sectionCount, equals(1));
      expect(reader.title, equals('First paragraph of the story.'));
      reader.dispose();
    });
  });

  group('ReflowableDocumentReader - SingleHtmlDocumentReader', () {
    late Directory tempDir;
    late File htmlFile;
    late File imageFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('single_html_test_');
      htmlFile = File('${tempDir.path}/article.html');
      await htmlFile.writeAsString('''
<!DOCTYPE html>
<html>
<head><title>My Test Article</title></head>
<body>
  <h1>Article Title</h1>
  <img src="images/photo.png" />
  <p>Article body.</p>
</body>
</html>
''');

      final imgDir = Directory('${tempDir.path}/images');
      await imgDir.create();
      imageFile = File('${imgDir.path}/photo.png');
      await imageFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]); // PNG signature
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('loads HTML content and resolves local filesystem assets', () async {
      final reader = await SingleHtmlDocumentReader.fromFile(htmlFile.path);
      expect(reader.sectionCount, equals(1));
      expect(reader.title, equals('My Test Article'));
      expect(reader.outline.length, equals(1));
      expect(reader.outline.first.title, equals('My Test Article'));

      final html = reader.loadSectionHtml(0);
      expect(html, contains('Article Title'));
      expect(html, contains('photo.png'));

      final assetBytes = reader.loadAssetBytes('images/photo.png');
      expect(assetBytes, isNotNull);
      expect(assetBytes!.length, equals(4));
      expect(assetBytes[0], equals(0x89));

      reader.dispose();
    });

    test('auto-detects .html format via ReflowableDocumentReader.fromFile', () async {
      final reader = await ReflowableDocumentReader.fromFile(htmlFile.path);
      expect(reader, isA<SingleHtmlDocumentReader>());
      expect(reader.sectionCount, equals(1));
      expect(reader.title, equals('My Test Article'));
      reader.dispose();
    });
  });

  group('ReflowableDocumentReader - EpubDocumentReader', () {
    const epubPath = '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

    test('loads Reverend Insanity EPUB, extracts chapters and assets', () async {
      final file = File(epubPath);
      if (!await file.exists()) {
        // Skip if test document is not present on machine
        return;
      }

      final reader = await EpubDocumentReader.fromFile(epubPath);
      expect(reader.sectionCount, equals(504));
      expect(reader.title, equals('Reverend Insanity'));
      expect(reader.outline.length, greaterThan(400));
      expect(reader.outline.first.title, isNotEmpty);

      // Read Chapter 1 (index 3, usually title / prologue / c1)
      final ch0 = reader.loadSectionHtml(0);
      expect(ch0, isNotEmpty);
      expect(ch0, contains('<html'));

      final ch3 = reader.loadSectionHtml(3);
      expect(ch3, isNotEmpty);
      expect(ch3, contains('<html'));

      // Test resolveSectionIndex
      final resolved = reader.resolveSectionIndex(reader.sections[5].href);
      expect(resolved, equals(5));

      // Test asset loading
      final mimeBytes = reader.loadAssetBytes('mimetype');
      expect(mimeBytes, isNotNull);
      expect(String.fromCharCodes(mimeBytes!), contains('application/epub+zip'));

      reader.dispose();
    });
  });
}
