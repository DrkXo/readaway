import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_document_info.dart';
import 'package:readaway/src/features/reader/presentation/widgets/overlay/reader_footnote_sheet.dart';
import 'package:readaway_core/readaway_core.dart';

class FakeReflowableReader extends Fake implements ReflowableDocumentReader {
  @override
  int get sectionCount => 2;

  @override
  String? get title => 'Test Book';

  @override
  DocumentMetadata? get metadata => const DocumentMetadata(
    title: 'Test Book',
    creator: 'Test Author',
    language: 'ja',
  );

  @override
  List<OutlineItem> get outline => const [
    OutlineItem(title: 'Chapter 1', chapterIndex: 0),
    OutlineItem(title: 'Chapter 2', chapterIndex: 1),
  ];

  @override
  String loadSectionHtml(int index) {
    if (index == 0) {
      return '''
      <html>
        <body>
          <h1>Chapter 1</h1>
          <p>This is natural reading with <ruby>漢<rt>かん</rt></ruby> and note<a href="#fn1"><sup>[1]</sup></a>.</p>
          <aside id="fn1" epub:type="footnote">
            <p>This is the detailed explanation for footnote 1.</p>
          </aside>
        </body>
      </html>
      ''';
    }
    return '<html><body><h1>Chapter 2</h1><p>Second chapter</p></body></html>';
  }

  @override
  int? resolveSectionIndex(String href) {
    if (href.contains('ch2') || href.contains('chapter2')) return 1;
    return 0;
  }

  @override
  void dispose() {}
}

void main() {
  group('ReaderDocumentInfo Tests', () {
    test('instantiates with author and metadata', () {
      const info = ReaderDocumentInfo(
        path: '/path/to/book.txt',
        title: 'My Book',
        author: 'John Doe',
        pageCount: 10,
        outline: [],
      );

      expect(info.title, 'My Book');
      expect(info.author, 'John Doe');
      expect(info.pageCount, 10);
    });
  });

  group('FootnoteTransformer & Repository Integration', () {
    test('findFootnote locates aside footnote in section HTML', () {
      const html = '''
      <div>
        <p>Text<a href="#note-1">1</a></p>
        <aside id="note-1" epub:type="footnote">
          <p>Explanation of note 1.</p>
        </aside>
      </div>
      ''';

      final fn = FootnoteTransformer.findFootnote(html, 'note-1');
      expect(fn, isNotNull);
      expect(fn!.id, 'note-1');
      expect(fn.contentHtml, contains('Explanation of note 1.'));
    });

    test('findFootnote returns null when anchor does not match', () {
      const html = '<aside id="fn-other">Other</aside>';
      final fn = FootnoteTransformer.findFootnote(html, 'nonexistent');
      expect(fn, isNull);
    });

    test('ReflowableSectionText voices Ruby kana and excludes footnote body in speech text', () {
      final reader = FakeReflowableReader();
      final speechText = reader.extractSectionSpeechText(0);

      // Japanese Ruby: voices 'かん'
      expect(speechText, contains('かん'));
      // Kanji '漢' should be omitted from speech text
      expect(speechText, isNot(contains('漢')));
      // Footnote body should not be voiced in chapter speech
      expect(speechText, isNot(contains('detailed explanation')));
      // Footnote anchor [1] should be stripped from speech
      expect(speechText, isNot(contains('[1]')));
    });
  });

  group('ReaderFootnoteSheet Widget Tests', () {
    testWidgets('renders footnote details and triggers onJumpToNote', (
      tester,
    ) async {
      bool jumped = false;
      const footnote = FootnoteItem(
        id: 'fn1',
        contentHtml: '<p>A deep explanation of the concept.</p>',
        type: 'footnote',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderFootnoteSheet(
              footnote: footnote,
              onJumpToNote: () => jumped = true,
            ),
          ),
        ),
      );

      expect(find.text('FN1'), findsOneWidget);
      expect(find.text('A deep explanation of the concept.'), findsOneWidget);
      expect(find.text('Jump to Note'), findsOneWidget);

      await tester.tap(find.text('Jump to Note'));
      await tester.pump();

      expect(jumped, isTrue);
    });
  });
}
