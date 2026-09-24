import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/features/library/data/datasources/file_picker_data_source.dart';
import 'package:readaway/src/features/library/data/datasources/library_local_data_source.dart';
import 'package:readaway/src/features/library/data/repositories/library_repository_impl.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';

import 'library_repository_impl_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<LibraryLocalDataSource>(),
  MockSpec<FilePickerDataSource>(),
  MockSpec<AppPathService>(),
])
void main() {
  late MockLibraryLocalDataSource mockDataSource;
  late MockFilePickerDataSource mockPicker;
  late MockAppPathService mockPathService;
  late LibraryRepositoryImpl repository;

  final testDoc = RecentDocument(
    path: '/path/to/book.epub',
    fileName: 'book.epub',
    title: 'Test Book',
    dateAdded: DateTime(2025),
    lastOpened: DateTime(2025),
    fileSize: 1024,
    format: 'epub',
    pageCount: 100,
    lastReadPage: 45,
    lastReadChapter: 4,
    lastReadProgression: 0.5,
    readingStatus: ReadingStatus.reading,
  );

  setUp(() {
    mockDataSource = MockLibraryLocalDataSource();
    mockPicker = MockFilePickerDataSource();
    mockPathService = MockAppPathService();

    repository = LibraryRepositoryImpl(
      mockDataSource,
      mockPicker,
      mockPathService,
    );
  });

  group('LibraryRepositoryImpl - Status and Progress Management', () {
    test(
      'marking as unread resets lastReadPage, chapter, and progression',
      () async {
        when(mockDataSource.getRecentDocuments())
            .thenAnswer((_) async => [testDoc]);
        when(mockDataSource.saveRecentDocument(any))
            .thenAnswer((_) async => Future.value());

        final result = await repository.updateReadingStatus(
          testDoc.path,
          ReadingStatus.unread,
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.readingStatus, ReadingStatus.unread);
        expect(updated.lastReadPage, 0);
        expect(updated.lastReadChapter, 0);
        expect(updated.lastReadProgression, 0.0);
        expect(updated.progressPercent, 0.0);
        expect(updated.isFinished, isFalse);

        verify(
          mockDataSource.saveRecentDocument(
            argThat(
              predicate<RecentDocument>(
                (d) =>
                    d.readingStatus == ReadingStatus.unread &&
                    d.lastReadPage == 0 &&
                    d.lastReadChapter == 0 &&
                    d.lastReadProgression == 0.0,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('resetReadingProgress resets progress and marks as unread', () async {
      when(mockDataSource.getRecentDocuments())
          .thenAnswer((_) async => [testDoc]);
      when(mockDataSource.saveRecentDocument(any))
          .thenAnswer((_) async => Future.value());

      final result = await repository.resetReadingProgress(testDoc.path);

      expect(result.isSuccess, isTrue);
      final updated = result.dataOrNull!;
      expect(updated.readingStatus, ReadingStatus.unread);
      expect(updated.lastReadPage, 0);
      expect(updated.lastReadChapter, 0);
      expect(updated.lastReadProgression, 0.0);
    });

    test(
      'marking as finished sets 100% progress and finished status',
      () async {
        when(mockDataSource.getRecentDocuments())
            .thenAnswer((_) async => [testDoc]);
        when(mockDataSource.saveRecentDocument(any))
            .thenAnswer((_) async => Future.value());

        final result = await repository.updateReadingStatus(
          testDoc.path,
          ReadingStatus.finished,
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.readingStatus, ReadingStatus.finished);
        expect(updated.lastReadPage, 99);
        expect(updated.lastReadChapter, 99);
        expect(updated.lastReadProgression, 1.0);
        expect(updated.progressPercent, 1.0);
        expect(updated.isFinished, isTrue);
      },
    );

    test('marking as abandoned sets On Hold status', () async {
      when(mockDataSource.getRecentDocuments())
          .thenAnswer((_) async => [testDoc]);
      when(mockDataSource.saveRecentDocument(any))
          .thenAnswer((_) async => Future.value());

      final result = await repository.updateReadingStatus(
        testDoc.path,
        ReadingStatus.abandoned,
      );

      expect(result.isSuccess, isTrue);
      final updated = result.dataOrNull!;
      expect(updated.readingStatus, ReadingStatus.abandoned);
      expect(updated.lastReadPage, 45); // preserves progress
    });
  });

  group('LibraryRepositoryImpl - Document Deletion', () {
    test(
      'removeRecentDocument calls localDataSource.removeRecentDocument',
      () async {
        when(mockDataSource.getRecentDocuments())
            .thenAnswer((_) async => [testDoc]);
        when(mockDataSource.removeRecentDocument(testDoc.path))
            .thenAnswer((_) async => Future.value());

        final result = await repository.removeRecentDocument(testDoc.path);

        expect(result.isSuccess, isTrue);
        verify(mockDataSource.removeRecentDocument(testDoc.path)).called(1);
      },
    );
  });
}
