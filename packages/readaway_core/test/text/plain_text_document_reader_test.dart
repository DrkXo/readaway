import 'dart:io';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('PlainTextDocumentReader', () {
    late Directory tempDir;
    late File textFile;
    late File novelFile;

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

      novelFile = File('${tempDir.path}/《三体》作者：刘慈欣.txt')
        ..writeAsStringSync(
          '第1章 科学边界\n'
          '汪淼觉得，纳米研究中心的气氛有些异样。\n'
          '\n'
          '第2章 台球\n'
          '丁仪在台球桌前停下了脚步。\n',
        );
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('opens a single-section plain-text file', () async {
      final reader = await PlainTextDocumentReader.fromFile(textFile.path);

      expect(reader.format, 'txt');
      expect(reader.isReflowable, isTrue);
      expect(reader.title, 'notes');
      expect(reader.sectionCount, 1);

      final html = reader.loadSectionHtml(0);
      expect(html, contains('<p>'));
      expect(html, contains('First paragraph line one.'));
      expect(html, contains('Second paragraph.'));
      expect(html, contains('Third &lt;paragraph&gt; &amp; more.'));

      reader.dispose();
    });

    test('opens a multi-chapter text file with metadata and outline', () async {
      final reader = await PlainTextDocumentReader.fromFile(novelFile.path);

      expect(reader.title, equals('三体'));
      expect(reader.metadata?.creator, equals('刘慈欣'));
      expect(reader.sectionCount, equals(2));

      expect(reader.outline.length, equals(2));
      expect(reader.outline[0].title, equals('第1章 科学边界'));
      expect(reader.outline[0].href, equals('chapter_0.html'));
      expect(reader.outline[1].title, equals('第2章 台球'));
      expect(reader.outline[1].href, equals('chapter_1.html'));

      final ch1Html = reader.loadSectionHtml(0);
      expect(ch1Html, contains('<h2>第1章 科学边界</h2>'));
      expect(ch1Html, contains('汪淼觉得'));

      final ch2Html = reader.loadSectionHtml(1);
      expect(ch2Html, contains('<h2>第2章 台球</h2>'));
      expect(ch2Html, contains('丁仪在台球桌前'));

      expect(reader.resolveSectionIndex('chapter_1.html'), equals(1));
      expect(reader.resolveSectionIndex(novelFile.path), equals(0));

      reader.dispose();
    });

    test('resolves section indices and rejects out of bounds indices', () async {
      final reader = await PlainTextDocumentReader.fromFile(textFile.path);

      expect(reader.sections[0].mediaType, 'text/html');
      expect(reader.resolveSectionIndex('chapter_0.html'), 0);
      expect(reader.resolveSectionIndex('notes.txt'), 0);
      expect(reader.resolveSectionIndex('nonexistent.html'), isNull);
      expect(reader.loadAsset('anything'), isNull);

      expect(() => reader.loadSectionHtml(10), throwsA(isA<RangeError>()));

      reader.dispose();
    });
  });
}
