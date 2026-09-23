import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/presentation/bloc/library_bloc.dart';

import '../../../../helpers/test_mocks.dart';

void main() {
  setUpAll(registerMockitoDummies);
  late MockLibraryRepository mockRepo;

  final doc1 = RecentDocument(
    path: '/path/1.epub',
    fileName: '1.epub',
    title: 'Book 1',
    dateAdded: DateTime(2025),
    lastOpened: DateTime(2025),
    fileSize: 100,
    format: 'epub',
    coverPath: '/covers/1.png',
  );

  setUp(() {
    mockRepo = MockLibraryRepository();
    when(mockRepo.getCoverArtPath(any))
        .thenAnswer((_) async => const Success(null));
  });

  group('LibraryBloc', () {
    blocTest<LibraryBloc, LibraryState>(
      'emits loaded state with documents when loadRequested succeeds',
      build: () {
        when(mockRepo.getRecentDocuments()).thenAnswer(
          (_) async => Success([doc1]),
        );
        return LibraryBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const LibraryEvent.loadRequested()),
      expect: () => [
        const LibraryState(isLoading: true),
        LibraryState(
          isLoading: false,
          recentDocuments: [doc1],
        ),
      ],
      verify: (_) {
        verify(mockRepo.getRecentDocuments()).called(1);
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'removes document and updates state on removeDocument event',
      build: () {
        when(mockRepo.removeRecentDocument(doc1.path)).thenAnswer(
          (_) async => const Success(null),
        );
        return LibraryBloc(mockRepo);
      },
      seed: () => LibraryState(
        recentDocuments: [doc1],
        selectedPaths: {doc1.path},
      ),
      act: (bloc) => bloc.add(LibraryEvent.removeDocument(doc1.path)),
      expect: () => [
        const LibraryState(
          recentDocuments: [],
          selectedPaths: {},
        ),
      ],
      verify: (_) {
        verify(mockRepo.removeRecentDocument(doc1.path)).called(1);
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'resets progress on resetProgress event',
      build: () {
        final resetDoc = doc1.copyWith(
          lastReadPage: 0,
          lastReadChapter: 0,
          lastReadProgression: 0.0,
          readingStatus: ReadingStatus.unread,
        );
        when(mockRepo.resetReadingProgress(doc1.path)).thenAnswer(
          (_) async => Success(resetDoc),
        );
        return LibraryBloc(mockRepo);
      },
      seed: () => LibraryState(
        recentDocuments: [
          doc1.copyWith(
            lastReadPage: 10,
            lastReadChapter: 2,
            lastReadProgression: 0.5,
            readingStatus: ReadingStatus.reading,
          ),
        ],
      ),
      act: (bloc) => bloc.add(LibraryEvent.resetProgress(doc1.path)),
      expect: () => [
        LibraryState(
          recentDocuments: [
            doc1.copyWith(
              lastReadPage: 0,
              lastReadChapter: 0,
              lastReadProgression: 0.0,
              readingStatus: ReadingStatus.unread,
            ),
          ],
        ),
      ],
      verify: (_) {
        verify(mockRepo.resetReadingProgress(doc1.path)).called(1);
      },
    );
  });
}
