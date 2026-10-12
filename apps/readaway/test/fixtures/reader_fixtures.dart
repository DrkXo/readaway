import 'dart:ui' show Rect;

import 'package:readaway/src/features/reader/domain/entity/reader_document_info.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_link.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_page_data.dart';
import 'package:readaway_core/readaway_core.dart';

/// Creates a fake [TextSpanBox] with sensible defaults.
TextSpanBox fakeTextSpanBox({
  int charStart = 0,
  int charEnd = 20,
  Rect rect = const Rect.fromLTWH(0, 0, 400, 20),
  String? nodeId,
  String nodeTag = 'p',
  String type = 'text',
}) => TextSpanBox(
  charStart: charStart,
  charEnd: charEnd,
  rect: rect,
  nodeId: nodeId,
  nodeTag: nodeTag,
  type: type,
);

/// Creates a fake [PageSlice] with sensible defaults.
PageSlice fakePageSlice({
  int index = 0,
  double startY = 0.0,
  double endY = 800.0,
  int startChar = 0,
  int endChar = 40,
}) => PageSlice(
  index: index,
  startY: startY,
  endY: endY,
  startChar: startChar,
  endChar: endChar,
);

/// Creates a fake [ChapterTextLayout] with sensible defaults.
ChapterTextLayout fakeChapterTextLayout({
  double contentHeight = 1000.0,
  double viewportHeight = 800.0,
  List<({double top, double bottom})> lineBounds = const [],
  List<TextSpanBox>? spans,
  List<PageSlice>? pages,
  String flowText = 'Sample paragraph for reading layout verification.',
  int? totalCharacterCount,
}) {
  final count = totalCharacterCount ?? flowText.length;
  return ChapterTextLayout(
    contentHeight: contentHeight,
    viewportHeight: viewportHeight,
    lineBounds: lineBounds,
    spans:
        spans ??
        [
          TextSpanBox(
            charStart: 0,
            charEnd: count,
            rect: Rect.fromLTWH(0, 0, 400, contentHeight),
            nodeTag: 'p',
            type: 'text',
          ),
        ],
    pages:
        pages ??
        [
          PageSlice(
            index: 0,
            startY: 0.0,
            endY: viewportHeight,
            startChar: 0,
            endChar: count,
          ),
        ],
    flowText: flowText,
    totalCharacterCount: count,
  );
}

/// Creates a fake [ReadingAnchor] with sensible defaults.
ReadingAnchor fakeReadingAnchor({
  int chapterIndex = 0,
  double progressionInChapter = 0.0,
}) => ReadingAnchor(
  chapterIndex: chapterIndex,
  progressionInChapter: progressionInChapter,
);

/// Creates a fake [OutlineItem] with sensible defaults.
OutlineItem fakeOutlineItem({
  String title = 'Chapter 1',
  String? href = 'chapter1.xhtml',
  int level = 0,
  int? chapterIndex = 0,
  List<OutlineItem> children = const [],
}) => OutlineItem(
  title: title,
  href: href,
  level: level,
  chapterIndex: chapterIndex,
  children: children,
);

/// Creates a fake [ReaderDocumentInfo] with sensible defaults.
ReaderDocumentInfo fakeReaderDocumentInfo({
  String path = '/books/test_book.epub',
  String title = 'Test Book',
  String? author = 'Test Author',
  int pageCount = 100,
  List<OutlineItem> outline = const [],
  bool isReflowable = true,
  String format = 'epub',
}) => ReaderDocumentInfo(
  path: path,
  title: title,
  author: author,
  pageCount: pageCount,
  outline: outline,
  isReflowable: isReflowable,
  format: format,
);

/// Creates a fake [ReaderPageData] with sensible defaults.
ReaderPageData fakeReaderPageData({
  int pageIndex = 0,
  List<ReaderLink> links = const [],
  Map<String, dynamic>? renderedData,
  String? html,
}) => ReaderPageData(
  pageIndex: pageIndex,
  links: links,
  renderedData: renderedData,
  html: html ?? '<p>Page content</p>',
);
