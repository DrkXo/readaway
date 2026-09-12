import 'dart:io';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlTextExtractor.extractPageText', () {
    test('extracts text from headings, paragraphs, blockquotes, and lists', () {
      const html = '''
        <!DOCTYPE html>
        <html>
        <head><title>Test</title></head>
        <body>
          <h1>Chapter 1: The Awakening</h1>
          <p>It was a dark and stormy night.</p>
          <blockquote>"Knowledge is power," said the elder.</blockquote>
          <ul>
            <li>First revelation</li>
            <li>Second revelation</li>
          </ul>
        </body>
        </html>
      ''';

      final text = HtmlTextExtractor.extractPageText(html);
      expect(text, contains('Chapter 1: The Awakening'));
      expect(text, contains('It was a dark and stormy night.'));
      expect(text, contains('"Knowledge is power," said the elder.'));
      expect(text, contains('First revelation'));
      expect(text, contains('Second revelation'));

      final lines = text.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, equals(5));
      expect(lines[0], equals('Chapter 1: The Awakening'));
      expect(lines[1], equals('It was a dark and stormy night.'));
      expect(lines[2], equals('"Knowledge is power," said the elder.'));
      expect(lines[3], equals('First revelation'));
      expect(lines[4], equals('Second revelation'));
    });

    test('extracts leaf divs without duplicating text from container divs', () {
      const html = '''
        <div class="content">
          <div class="chapter-header">
            <h2>Prologue</h2>
          </div>
          <div class="chapter-body">
            <p>The journey begins here.</p>
            <div class="note">Footnote: Historical archive.</div>
          </div>
        </div>
      ''';

      final text = HtmlTextExtractor.extractPageText(html);
      final lines = text.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, equals(3));
      expect(lines[0], equals('Prologue'));
      expect(lines[1], equals('The journey begins here.'));
      expect(lines[2], equals('Footnote: Historical archive.'));
    });

    test('ignores script and style tags', () {
      const html = '''
        <style>body { font-size: 16px; }</style>
        <h1>Title</h1>
        <script>console.log("ignore me");</script>
        <p>Actual content</p>
      ''';

      final text = HtmlTextExtractor.extractPageText(html);
      expect(text, isNot(contains('font-size')));
      expect(text, isNot(contains('ignore me')));
      expect(text, contains('Title'));
      expect(text, contains('Actual content'));
    });

    test('returns empty string for empty html or missing body', () {
      expect(HtmlTextExtractor.extractPageText(''), equals(''));
      expect(
        HtmlTextExtractor.extractPageText('<html><head></head></html>'),
        equals(''),
      );
    });
  });

  group('ReflowableSectionText.extractSectionText', () {
    late Directory tempDir;
    late File htmlFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('readaway_core_text_');
      htmlFile = File('${tempDir.path}/sample.html')
        ..writeAsStringSync('''
<!DOCTYPE html>
<html>
  <head><title>Sample Page</title></head>
  <body>
    <h1>Hello</h1>
    <p>Some <b>bold</b> text.</p>
    <p>Second paragraph.</p>
  </body>
</html>
''');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test(
      'extracts plain text from a section without manual chaining',
      () async {
        final reader = await SingleHtmlDocumentReader.fromFile(htmlFile.path);

        final text = reader.extractSectionText(0);
        expect(text, contains('Hello'));
        expect(text, contains('Some bold text.'));
        expect(text, contains('Second paragraph.'));

        reader.dispose();
      },
    );
  });
}
