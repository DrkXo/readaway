import 'dart:io';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('PlainTextDocumentReader', () {
    late Directory tempDir;
    late File textFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('readaway_core_txt_');
      textFile = File('${tempDir.path}/notes.txt')
        ..writeAsStringSync(
          'First paragraph line one.\n'
          'First paragraph line two.\n'
          '\n'
          'Second paragraph.\n'
          '\n'
          'Third <paragraph> & more.',
        );
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('opens a plain-text file', () async {
      final reader = await PlainTextDocumentReader.fromFile(textFile.path);

      expect(reader.format, 'txt');
      expect(reader.isReflowable, isTrue);
      expect(reader.title, 'notes');
      expect(reader.sectionCount, 1);

      reader.dispose();
    });

    test(
      'wraps text into semantic HTML with paragraphs and line breaks',
      () async {
        final reader = await PlainTextDocumentReader.fromFile(textFile.path);

        final html = reader.loadSectionHtml(0);
        expect(html, contains('<p>'));
        expect(html, contains('<br/>'));
        expect(html, contains('First paragraph line one.'));
        expect(html, contains('Second paragraph.'));
        // HTML-sensitive characters are escaped.
        expect(html, contains('Third &lt;paragraph&gt; &amp; more.'));

        reader.dispose();
      },
    );

    test('exposes a single section and resolves its index', () async {
      final reader = await PlainTextDocumentReader.fromFile(textFile.path);

      expect(reader.sections[0].mediaType, 'text/plain');
      expect(reader.resolveSectionIndex('notes.txt'), 0);
      expect(reader.resolveSectionIndex('other.txt'), isNull);
      expect(reader.loadAsset('anything'), isNull);

      reader.dispose();
    });
  });
}
