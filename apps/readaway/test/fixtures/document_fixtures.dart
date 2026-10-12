import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';

/// Creates a fake [RecentDocument] with sensible defaults.
RecentDocument fakeRecentDocument({
  String path = '/books/test_book.epub',
  String fileName = 'test_book.epub',
  String title = 'Test Book',
  String? author = 'Test Author',
  DateTime? dateAdded,
  DateTime? lastOpened,
  int fileSize = 1024,
  String format = 'epub',
  int lastReadPage = 0,
  int pageCount = 100,
  int lastReadChapter = 0,
  double lastReadProgression = 0.0,
  ReadingStatus readingStatus = ReadingStatus.unread,
  bool isFavorite = false,
  List<String> tags = const [],
  String? coverPath,
}) => RecentDocument(
  path: path,
  fileName: fileName,
  title: title,
  author: author,
  dateAdded: dateAdded ?? DateTime(2025, 1, 1),
  lastOpened: lastOpened ?? DateTime(2025, 1, 1),
  fileSize: fileSize,
  format: format,
  lastReadPage: lastReadPage,
  pageCount: pageCount,
  lastReadChapter: lastReadChapter,
  lastReadProgression: lastReadProgression,
  readingStatus: readingStatus,
  isFavorite: isFavorite,
  tags: tags,
  coverPath: coverPath,
);

/// Preset for a document marked as finished.
RecentDocument fakeFinishedDocument({
  String path = '/books/finished.epub',
  String title = 'Finished Book',
  int pageCount = 100,
}) => fakeRecentDocument(
  path: path,
  fileName: 'finished.epub',
  title: title,
  pageCount: pageCount,
  lastReadPage: pageCount > 0 ? pageCount - 1 : 0,
  lastReadChapter: pageCount > 0 ? pageCount - 1 : 0,
  lastReadProgression: 1.0,
  readingStatus: ReadingStatus.finished,
);

/// Preset for an unread document.
RecentDocument fakeUnreadDocument({
  String path = '/books/unread.epub',
  String title = 'Unread Book',
}) => fakeRecentDocument(
  path: path,
  fileName: 'unread.epub',
  title: title,
  lastReadPage: 0,
  lastReadChapter: 0,
  lastReadProgression: 0.0,
  readingStatus: ReadingStatus.unread,
);

/// Preset for a document actively being read.
RecentDocument fakeReadingDocument({
  String path = '/books/reading.epub',
  String title = 'Reading Book',
  int lastReadPage = 40,
  int lastReadChapter = 4,
  double lastReadProgression = 0.4,
}) => fakeRecentDocument(
  path: path,
  fileName: 'reading.epub',
  title: title,
  lastReadPage: lastReadPage,
  lastReadChapter: lastReadChapter,
  lastReadProgression: lastReadProgression,
  readingStatus: ReadingStatus.reading,
);
