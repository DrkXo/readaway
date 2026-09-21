import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/widgets/toc/reader_toc_content.dart';
import 'package:readaway_core/readaway_core.dart';

OutlineItem chapter(String title, int page, {int level = 1}) => OutlineItem(
  title: title,
  href: '$title.xhtml',
  chapterIndex: page,
  level: level,
);

OutlineItem volume(String title, {required List<OutlineItem> children}) =>
    OutlineItem(
      title: title,
      href: '$title.xhtml',
      chapterIndex: children.first.chapterIndex,
      level: 0,
      children: children,
    );

void main() {
  group('tocVisibleRows', () {
    final outline = [
      volume('Volume 1', children: [
        chapter('Chapter 1', 0),
        chapter('Chapter 2', 10),
      ]),
      volume('Volume 2', children: [
        chapter('Chapter 3', 20),
      ]),
      chapter('Epilogue', 30),
    ];

    test('collapses children of folded parents', () {
      expect(
        tocVisibleRows(outline, (_) => false).map((o) => o.title),
        ['Volume 1', 'Volume 2', 'Epilogue'],
      );
    });

    test('expands children recursively when parent is open', () {
      expect(
        tocVisibleRows(
          outline,
          (o) => o.title == 'Volume 1',
        ).map((o) => o.title),
        ['Volume 1', 'Chapter 1', 'Chapter 2', 'Volume 2', 'Epilogue'],
      );
    });
  });

  group('tocCurrentPath', () {
    final outline = [
      volume('Volume 1', children: [
        chapter('Chapter 1', 0),
        chapter('Chapter 2', 10),
      ]),
      volume('Volume 2', children: [
        chapter('Chapter 3', 20),
      ]),
      chapter('Epilogue', 30),
    ];

    test('picks the deepest chapter covering the page', () {
      final (node, path) = tocCurrentPath(outline, 12)!;
      expect(node.title, 'Chapter 2');
      expect(path.map((o) => o.title), ['Volume 1', 'Chapter 2']);
    });

    test('falls back to the last chapter before the page', () {
      final (node, _) = tocCurrentPath(outline, 25)!;
      expect(node.title, 'Chapter 3');
      final (node2, _) = tocCurrentPath(outline, 100)!;
      expect(node2.title, 'Epilogue');
    });

    test('prefers a chapter over its parent when pages tie', () {
      // Volume 2 and Chapter 3 both start at page 20: the deeper node wins.
      final (node, path) = tocCurrentPath(outline, 20)!;
      expect(node.title, 'Chapter 3');
      expect(path.map((o) => o.title), ['Volume 2', 'Chapter 3']);
    });

    test('returns null when nothing navigable covers the page', () {
      expect(tocCurrentPath(outline, -1), isNull);
      final leafOnly = OutlineItem(title: 'Intro', level: 0);
      expect(tocCurrentPath([leafOnly], 0), isNull);
    });
  });
}