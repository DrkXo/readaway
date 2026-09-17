import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('DisposableMixin and Reader Lifecycle Tests', () {
    test('EpubDocumentReader lifecycle disposal and guards', () async {
      // Create minimal EPUB in memory
      final archive = Archive();
      archive.addFile(
        ArchiveFile.string(
          'META-INF/container.xml',
          '<?xml version="1.0"?>'
              '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
              '<rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>'
              '</container>',
        ),
      );
      archive.addFile(
        ArchiveFile.string(
          'OEBPS/content.opf',
          '<?xml version="1.0" encoding="utf-8"?>'
              '<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="id" version="2.0">'
              '<metadata><title>Test Book</title></metadata>'
              '<manifest><item id="sec1" href="sec1.xhtml" media-type="application/xhtml+xml"/></manifest>'
              '<spine><itemref idref="sec1"/></spine>'
              '</package>',
        ),
      );
      archive.addFile(
        ArchiveFile.string(
          'OEBPS/sec1.xhtml',
          '<html><body><p>Chapter 1 text</p></body></html>',
        ),
      );
      final zipBytes = ZipEncoder().encode(archive);

      final reader = await EpubDocumentReader.fromBytes(
        Uint8List.fromList(zipBytes),
      );
      expect(reader.isDisposed, isFalse);
      expect(reader.loadSectionHtml(0), contains('Chapter 1 text'));

      reader.dispose();
      expect(reader.isDisposed, isTrue);
      expect(
        () => reader.loadSectionHtml(0),
        throwsA(isA<DocumentDisposedException>()),
      );
      expect(reader.loadAsset('OEBPS/sec1.xhtml'), isNull);
    });

    test('CbzDocumentReader lifecycle disposal and guards', () async {
      final archive = Archive();
      archive.addFile(
        ArchiveFile('page01.png', 4, Uint8List.fromList([1, 2, 3, 4])),
      );
      final zipBytes = ZipEncoder().encode(archive);

      final reader = await CbzDocumentReader.fromBytes(
        Uint8List.fromList(zipBytes),
      );
      expect(reader.isDisposed, isFalse);
      expect(reader.loadPageSync(0), equals(Uint8List.fromList([1, 2, 3, 4])));

      reader.dispose();
      expect(reader.isDisposed, isTrue);
      expect(
        () => reader.loadPageSync(0),
        throwsA(isA<DocumentDisposedException>()),
      );
      expect(reader.loadAsset('page01.png'), isNull);
    });

    test('PlainTextDocumentReader lifecycle disposal and guards', () async {
      final text = 'Chapter 1: The Beginning\nHello plain text world.';
      final bytes = Uint8List.fromList(text.codeUnits);

      final reader = await PlainTextDocumentReader.fromBytes(bytes);
      expect(reader.isDisposed, isFalse);
      expect(reader.loadSectionHtml(0), contains('Chapter 1: The Beginning'));

      reader.dispose();
      expect(reader.isDisposed, isTrue);
      expect(
        () => reader.loadSectionHtml(0),
        throwsA(isA<DocumentDisposedException>()),
      );
    });
  });

  group('Fluent String & Bytes Extensions Tests', () {
    test('ReadAwayHtmlStringX extensions work seamlessly', () {
      const html = '''
        <html>
          <body>
            <h1>Title Header</h1>
            <p>Welcome to <em>ReadAway</em> &amp; enjoying books!</p>
            <aside id="note-1">Footnote 1 text</aside>
          </body>
        </html>
      ''';

      // 1. extractPageText
      final pageText = html.extractPageText();
      expect(pageText, contains('Title Header'));
      expect(pageText, contains('Welcome to ReadAway & enjoying books!'));

      // 2. extractSpeechText
      final speechText = html.extractSpeechText();
      expect(speechText, contains('Title Header'));
      expect(speechText, isNot(contains('Footnote 1 text')));

      // 3. extractFootnotes
      final footnotes = html.extractFootnotes();
      expect(footnotes.length, equals(1));
      expect(footnotes.first.id, equals('note-1'));
      expect(footnotes.first.contentHtml, contains('Footnote 1 text'));

      // 4. decodeHtmlEntities
      expect(
        '&lt;hello &amp; world&gt;'.decodeHtmlEntities(),
        equals('<hello & world>'),
      );
    });

    test('ReadAwaySpeechStringX extensions work seamlessly', () {
      const text = 'Dr. Smith won \$100 on the 1st day (50%).';

      // 1. normalizeForSpeech
      final normalized = text.normalizeForSpeech();
      expect(normalized, contains('Doctor Smith'));
      expect(normalized, contains('one hundred dollars'));
      expect(normalized, contains('first day'));
      expect(normalized, contains('fifty percent'));

      // 2. segmentSentences
      final sentences = 'First sentence. Second sentence! Third?'
          .segmentSentences('en');
      expect(sentences.length, equals(3));
      expect(sentences[0].text, equals('First sentence.'));
      expect(sentences[1].text, equals('Second sentence!'));
      expect(sentences[2].text, equals('Third?'));

      // 3. sanitizeUnicode
      final sanitized = 'Hello\u200BWorld\uFEFF!'.sanitizeUnicode();
      expect(sanitized, equals('HelloWorld!'));

      // 4. isLatinDominant
      expect('English text 123'.isLatinDominant(), isTrue);
      expect('这是一段中文测试文本'.isLatinDominant(), isFalse);

      // 5. estimateSpeechDurationMs
      final duration = 'A short sentence for testing speech duration.'
          .estimateSpeechDurationMs();
      expect(duration, greaterThan(0));

      // 6. preprocessTtsChunks
      final chunks = 'This is a test paragraph for chunking.'
          .preprocessTtsChunks(language: 'en');
      expect(chunks, isNotEmpty);
    });

    test('ReadAwayBytesEncodingX extensions work seamlessly', () {
      final utf8Bytes = Uint8List.fromList('Hello Dart 3!'.codeUnits);

      final detected = utf8Bytes.detectEncoding();
      expect(detected.name, equals('utf-8'));

      final decoded = utf8Bytes.decodeText();
      expect(decoded, equals('Hello Dart 3!'));
    });

    test('ReadAwayFloatPcmX extensions work seamlessly', () {
      final samples = Float32List.fromList([
        0.0, 0.0, 0.0, // silence
        0.5, 0.8, -0.6, // speech
        0.0, 0.0, 0.0, // silence
      ]);

      final bounds = samples.findSpeechBounds(16000);
      expect(bounds.durationSec, greaterThan(0));

      samples.applyEdgeFade(16000);
      expect(samples.first, closeTo(0.0, 0.01));
    });
  });
}
