import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('TxtMetadataExtractor', () {
    test('extracts title and author from Chinese book bracket filename', () {
      final meta = TxtMetadataExtractor.extract(
        filePath: '/books/《三体》作者：刘慈欣.txt',
        headerText: '',
        encoding: 'utf-8',
      );

      expect(meta.title, equals('三体'));
      expect(meta.author, equals('刘慈欣'));
    });

    test('extracts title and author from Western dash filename', () {
      final meta = TxtMetadataExtractor.extract(
        filePath: '/downloads/Dune - Frank Herbert.txt',
        headerText: '',
        encoding: 'utf-8',
      );

      expect(meta.title, equals('Dune'));
      expect(meta.author, equals('Frank Herbert'));
    });

    test('extracts author from header text when filename has no author', () {
      const header = '''
《雪国》
作者：川端康成
穿过县界长长的隧道，便是雪国。
''';
      final meta = TxtMetadataExtractor.extract(
        filePath: '/books/雪国.txt',
        headerText: header,
        encoding: 'utf-8',
      );

      expect(meta.title, equals('雪国'));
      expect(meta.author, equals('川端康成'));
    });
  });

  group('TxtChapterExtractor', () {
    const extractor = TxtChapterExtractor();

    test('extracts Chinese chapters and volumes', () {
      const content = '''
前言
这是本书的前言部分。

第一卷 起源
第1章 天地初开
很久很久以前，混沌未分。

第2章 万物萌生
万物开始生长繁衍。
''';

      final chapters = extractor.extractChapters(content);
      expect(chapters.length, equals(4));

      expect(chapters[0].title, equals('前言'));
      expect(chapters[0].contentHtml, contains('<h2>前言</h2>'));
      expect(chapters[0].contentHtml, contains('<p>这是本书的前言部分。</p>'));

      expect(chapters[1].title, equals('第一卷 起源'));
      expect(chapters[1].isVolume, isTrue);
      expect(chapters[1].contentHtml, contains('<h1>第一卷 起源</h1>'));

      expect(chapters[2].title, equals('第1章 天地初开'));
      expect(chapters[2].isVolume, isFalse);

      expect(chapters[3].title, equals('第2章 万物萌生'));
    });

    test('extracts English chapters', () {
      const content = '''
Chapter 1. A New Beginning
Call me Ishmael. Some years ago...

Chapter 2. The Carpet-Bag
I stuffed a shirt or two into my old carpet-bag...
''';

      final chapters = extractor.extractChapters(content);
      expect(chapters.length, equals(2));
      expect(chapters[0].title, equals('Chapter 1. A New Beginning'));
      expect(chapters[1].title, equals('Chapter 2. The Carpet-Bag'));
    });

    test('falls back to 100-paragraph chunking when no chapter titles exist', () {
      final paragraphs = List.generate(250, (i) => 'Paragraph $i text.').join('\n\n');
      final chapters = extractor.extractChapters(paragraphs);

      // 250 paragraphs with chunk size 100 -> 3 chapters (100, 100, 50)
      expect(chapters.length, equals(3));
      expect(chapters[0].title, equals('Section 1'));
      expect(chapters[0].detected, isFalse);
      expect(chapters[1].title, equals('Section 2'));
      expect(chapters[2].title, equals('Section 3'));
    });
  });
}
