import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';

void main() {
  RecentDocument doc({
    int lastReadPage = 0,
    int pageCount = 10,
    int lastReadChapter = 0,
    double lastReadProgression = 0.0,
    ReadingStatus readingStatus = ReadingStatus.reading,
  }) {
    return RecentDocument(
      path: '/tmp/book.epub',
      fileName: 'book.epub',
      title: 'Book',
      dateAdded: DateTime(2024),
      lastOpened: DateTime(2024),
      fileSize: 100,
      format: 'epub',
      lastReadPage: lastReadPage,
      pageCount: pageCount,
      lastReadChapter: lastReadChapter,
      lastReadProgression: lastReadProgression,
      readingStatus: readingStatus,
    );
  }

  group('RecentDocument progressPercent', () {
    test('uses anchor (chapter + progression) when present', () {
      // Chapter 5 of 10 with 50% progression → 55%, not a premature 100%.
      final d = doc(lastReadChapter: 5, lastReadProgression: 0.5);
      expect(d.progressPercent, closeTo(0.55, 0.001));
      expect(d.progressFormatted, '55%');
    });

    test('falls back to legacy page-based progress without an anchor', () {
      final d = doc(lastReadPage: 4);
      expect(d.progressPercent, closeTo(0.5, 0.001));
    });

    test('returns 0 for empty documents', () {
      final d = doc(pageCount: 0);
      expect(d.progressPercent, 0.0);
    });

    test('returns 0 for unread documents even if page data was previously recorded', () {
      final d = doc(
        lastReadChapter: 5,
        lastReadProgression: 0.5,
        readingStatus: ReadingStatus.unread,
      );
      expect(d.progressPercent, 0.0);
      expect(d.progressFormatted, '0%');
    });

    test('returns 1.0 (100%) when readingStatus is finished', () {
      final d = doc(
        lastReadChapter: 2,
        readingStatus: ReadingStatus.finished,
      );
      expect(d.progressPercent, 1.0);
      expect(d.progressFormatted, '100%');
      expect(d.isFinished, isTrue);
    });
  });

  group('RecentDocument isFinished', () {
    test('is finished when the anchor chapter reaches the last chapter', () {
      final d = doc(lastReadChapter: 9);
      expect(d.isFinished, isTrue);
    });

    test('is not finished mid-book with an anchor', () {
      final d = doc(lastReadChapter: 5, lastReadProgression: 0.5);
      expect(d.isFinished, isFalse);
    });

    test('is not finished when readingStatus is unread', () {
      final d = doc(lastReadChapter: 9, readingStatus: ReadingStatus.unread);
      expect(d.isFinished, isFalse);
    });

    test('is finished when readingStatus is finished', () {
      final d = doc(readingStatus: ReadingStatus.finished);
      expect(d.isFinished, isTrue);
    });

    test('falls back to legacy page-based finished without an anchor', () {
      final d = doc(lastReadPage: 9);
      expect(d.isFinished, isTrue);
    });
  });
}
