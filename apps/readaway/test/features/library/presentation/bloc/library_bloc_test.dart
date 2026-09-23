import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/error/failures.dart';
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
        .thenAnswer((_) => TaskEither.of(const None()));
  });

  group('LibraryBloc', () {
    blocTest<LibraryBloc, LibraryState>(
      'emits loaded state with documents when loadRequested succeeds',
      build: () {
        when(mockRepo.getRecentDocuments()).thenAnswer(
          (_) => TaskEither<Failure, List<RecentDocument>>.of([doc1]),
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
          (_) => TaskEither<Failure, Unit>.of(unit),
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
  });
}
