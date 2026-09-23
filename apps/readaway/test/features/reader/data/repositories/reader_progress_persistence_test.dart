import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../helpers/test_mocks.dart';

void main() {
  setUpAll(registerMockitoDummies);
  late MockLibraryRepository libRepo;
  late ReaderRepositoryImpl repository;
  late RecentDocument storedDoc;

  setUp(() {
    libRepo = MockLibraryRepository();
    storedDoc = RecentDocument(
      path: '/tmp/book.epub',
      fileName: 'book.epub',
      title: 'Book',
      dateAdded: DateTime(2024),
      lastOpened: DateTime(2024),
      fileSize: 100,
      format: 'epub',
      lastReadPage: 0,
      pageCount: 10,
    );

    when(libRepo.getRecentDocuments()).thenAnswer(
      (_) => TaskEither<Failure, List<RecentDocument>>.of([storedDoc]),
    );
    when(libRepo.saveRecentDocument(any)).thenAnswer(
      (invocation) {
        storedDoc = invocation.positionalArguments.first as RecentDocument;
        return TaskEither<Failure, Unit>.of(unit);
      },
    );

    repository = ReaderRepositoryImpl(
      MockWindowService(),
      MockNotificationService(),
      MockAppPathService(),
      libRepo,
    );
  });

  group('reading progress anchor persistence', () {
    test('saves and restores a reading anchor', () async {
      final save = await repository
          .updateReadingProgress(
            path: '/tmp/book.epub',
            page: 12,
            pageCount: 10,
            anchor: const ReadingAnchor(
              chapterIndex: 5,
              progressionInChapter: 0.5,
            ),
          )
          .run();
      expect(save.isRight(), isTrue);

      final anchorResult = await repository
          .getLastReadAnchor('/tmp/book.epub')
          .run();
      final anchor = anchorResult.getRight().toNullable();
      expect(anchor, isNotNull);
      expect(anchor!.chapterIndex, 5);
      expect(anchor.progressionInChapter, closeTo(0.5, 0.001));
    });

    test('null anchor preserves the previously stored anchor', () async {
      storedDoc = storedDoc.copyWith(
        lastReadChapter: 3,
        lastReadProgression: 0.25,
      );

      final save = await repository
          .updateReadingProgress(
            path: '/tmp/book.epub',
            page: 8,
            pageCount: 10,
            anchor: null,
          )
          .run();
      expect(save.isRight(), isTrue);

      expect(storedDoc.lastReadChapter, 3);
      expect(storedDoc.lastReadProgression, closeTo(0.25, 0.001));
    });

    test('returns null when no anchor has been saved', () async {
      final anchorResult = await repository
          .getLastReadAnchor('/tmp/book.epub')
          .run();
      expect(anchorResult.getRight().toNullable(), isNull);
    });

    test(
      'marks the document finished when the anchor reaches the last chapter',
      () async {
        await repository
            .updateReadingProgress(
              path: '/tmp/book.epub',
              page: 20,
              pageCount: 10,
              anchor: const ReadingAnchor(
                chapterIndex: 9,
                progressionInChapter: 1.0,
              ),
            )
            .run();

        expect(storedDoc.readingStatus, ReadingStatus.finished);
      },
    );
  });
}
