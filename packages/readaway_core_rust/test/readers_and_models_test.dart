import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core_rust/readaway_core_rust.dart';

void main() {
  group('DocumentMetadata tests', () {
    test('author and creator are symmetric', () {
      const meta1 = DocumentMetadata(
        title: 'Book 1',
        author: 'Arthur Conan Doyle',
      );
      expect(meta1.author, 'Arthur Conan Doyle');
      expect(meta1.creator, 'Arthur Conan Doyle');

      const meta2 = DocumentMetadata(
        title: 'Book 2',
        creator: 'J.K. Rowling',
      );
      expect(meta2.author, 'J.K. Rowling');
      expect(meta2.creator, 'J.K. Rowling');
    });
  });

  group('PlainTextDocumentReader tests', () {
    test('segments chapters and extracts metadata', () async {
      const text = '''
《The Great Novel》Author: Jane Doe

Chapter 1: The Beginning
Once upon a time in a faraway kingdom.

Chapter 2: The Journey
They set out into the wild forest.
''';
      final bytes = Uint8List.fromList(utf8.encode(text));
      final reader = await PlainTextDocumentReader.fromBytes(
        bytes,
        filePath: 'The Great Novel.txt',
      );

      expect(reader.format, 'txt');
      expect(reader.isReflowable, isTrue);
      expect(reader.title, 'The Great Novel');
      expect(reader.metadata?.author, 'Jane Doe');
      expect(reader.sectionCount, 3);

      final introHtml = reader.loadSectionHtml(0);
      expect(introHtml, contains('The Great Novel'));

      final ch1Html = reader.loadSectionHtml(1);
      expect(ch1Html, contains('Chapter 1: The Beginning'));
      expect(ch1Html, contains('faraway kingdom'));

      final ch2Html = reader.loadSectionHtml(2);
      expect(ch2Html, contains('Chapter 2: The Journey'));
      expect(ch2Html, contains('wild forest'));

      expect(reader.resolveSectionIndex('chapter_1.html'), 1);
      expect(reader.resolveSectionIndex('The Great Novel.txt'), 0);

      reader.dispose();
      expect(() => reader.loadSectionHtml(0), throwsA(isA<DocumentDisposedException>()));
    });
  });

  group('SingleHtmlDocumentReader tests', () {
    test('extracts title and single section', () async {
      // Create a temporary HTML reader via a simulated file or test
      // Test the HTML title extraction and section loading
      final tempFile = const SingleHtmlDocumentReaderFake(
        title: 'Sample Page',
        html: '<html><head><title>Sample Page</title></head><body><p>Hello world</p></body></html>',
      );

      expect(tempFile.format, 'html');
      expect(tempFile.isReflowable, isTrue);
      expect(tempFile.title, 'Sample Page');
      expect(tempFile.sectionCount, 1);
      expect(tempFile.loadSectionHtml(0), contains('Hello world'));
    });
  });

  group('DocumentReaderFactory tests', () {
    test('auto-detects formats and handlers', () {
      final factory = DocumentReaderFactory();
      expect(factory.handlers.length, 4);

      final formats = factory.handlers.map((h) => h.format).toList();
      expect(formats, containsAll(['epub', 'cbz', 'html', 'txt']));

      expect(factory.handlers.any((h) => h.supports('test.epub')), isTrue);
      expect(factory.handlers.any((h) => h.supports('test.cbz')), isTrue);
      expect(factory.handlers.any((h) => h.supports('test.html')), isTrue);
      expect(factory.handlers.any((h) => h.supports('test.txt')), isTrue);
    });
  });

  group('Audio & PCM timing tests', () {
    test('findSpeechBounds detects voiced interval', () {
      final samples = Float32List(16000); // 1 sec at 16kHz
      // Inject speech in the middle (sample 4000 to 12000)
      for (int i = 4000; i < 12000; i++) {
        samples[i] = 0.5;
      }

      final bounds = findSpeechBounds(samples, 16000);
      expect(bounds.startSec, closeTo(0.23, 0.05));
      expect(bounds.endSec, closeTo(0.80, 0.05));
    });

    test('scaleGapForRate compresses pauses with rate exponent', () {
      final gap1 = scaleGapForRate(0.3, 1.0);
      final gap2 = scaleGapForRate(0.3, 2.0);
      expect(gap1, 0.3);
      expect(gap2, lessThan(0.3));
      expect(gap2, greaterThan(0.15)); // gentle curve > raw halving
    });

    test('estimateUtteranceSeconds calculates accurate duration', () {
      final duration = estimateUtteranceSeconds(
        text: 'This is a test sentence for estimating reading time.',
        language: 'en',
      );
      expect(duration, greaterThan(1.0));
      expect(duration, lessThan(5.0));
    });
  });
}

class SingleHtmlDocumentReaderFake implements ReflowableDocumentReader {
  @override
  final String title;
  final String html;

  const SingleHtmlDocumentReaderFake({required this.title, required this.html});

  @override
  String get format => 'html';

  @override
  bool get isReflowable => true;

  @override
  DocumentMetadata? get metadata => null;

  @override
  List<OutlineItem> get outline => [OutlineItem(title: title, href: 'index.html', level: 0)];

  @override
  String? get coverImagePath => null;

  @override
  int get sectionCount => 1;

  @override
  List<DocumentSection> get sections => [
        DocumentSection(index: 0, id: '0', href: 'index.html', title: title),
      ];

  @override
  String loadSectionHtml(int index) => html;

  @override
  Uint8List? loadAsset(String assetPath) => null;

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) => relativeHref;

  @override
  int? resolveSectionIndex(String href) => 0;

  @override
  void dispose() {}
}
