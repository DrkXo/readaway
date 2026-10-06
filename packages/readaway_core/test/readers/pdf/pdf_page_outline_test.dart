import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('PdfDocumentReader.buildPageOutline', () {
    test('creates one entry per page targeting the page index', () {
      final outline = PdfDocumentReader.buildPageOutline(3);
      expect(outline, hasLength(3));
      expect(outline[0].title, 'Page 1');
      expect(outline[0].href, 'page:0');
      expect(outline[0].chapterIndex, 0);
      expect(outline[0].level, 0);
      expect(outline[0].children, isEmpty);
      expect(outline[1].title, 'Page 2');
      expect(outline[1].chapterIndex, 1);
      expect(outline[2].title, 'Page 3');
      expect(outline[2].chapterIndex, 2);
    });

    test('keeps a single page navigable so the TOC is never empty', () {
      final outline = PdfDocumentReader.buildPageOutline(1);
      expect(outline.single.title, 'Page 1');
      expect(outline.single.chapterIndex, 0);
      expect(outline.single.href, 'page:0');
    });

    test('returns no entries for a zero-page document', () {
      expect(PdfDocumentReader.buildPageOutline(0), isEmpty);
    });
  });

  group('PdfDocumentReader.hasUsableOutline', () {
    test('rejects an empty outline', () {
      expect(PdfDocumentReader.hasUsableOutline([]), isFalse);
    });

    test('rejects a single stray leaf bookmark', () {
      final stray = [
        OutlineItem(
          title: 'Fig 2: Sign Up Page of Onboarding Portal',
          chapterIndex: 8,
        ),
      ];
      expect(PdfDocumentReader.hasUsableOutline(stray), isFalse);
    });

    test('accepts a single root with children (a real TOC)', () {
      final real = [
        OutlineItem(
          title: 'SOP',
          children: [OutlineItem(title: 'Chapter 1', chapterIndex: 0)],
        ),
      ];
      expect(PdfDocumentReader.hasUsableOutline(real), isTrue);
    });

    test('accepts multiple entries', () {
      final multi = [
        OutlineItem(title: 'Chapter 1', chapterIndex: 0),
        OutlineItem(title: 'Chapter 2', chapterIndex: 10),
      ];
      expect(PdfDocumentReader.hasUsableOutline(multi), isTrue);
    });
  });
}
