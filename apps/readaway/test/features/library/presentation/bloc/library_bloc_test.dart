import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/presentation/bloc/library_bloc.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';

import '../../../../helpers/test_mocks.dart';

void main() {
  setUpAll(registerMockitoDummies);
  late MockLibraryRepository mockRepo;
  late MockSettingsService mockSettingsService;

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
    mockSettingsService = MockSettingsService();
    when(mockSettingsService.settings).thenReturn(const Settings());
    when(mockRepo.getCoverArtPath(any))
        .thenAnswer((_) async => const Success(null));
  });

  group('LibraryBloc', () {
    blocTest<LibraryBloc, LibraryState>(
      'emits loaded state with documents when loadRequested succeeds',
      build: () {
        when(mockRepo.watchRecentDocuments()).thenAnswer(
          (_) => Stream.value(Success([doc1])),
        );
        return LibraryBloc(mockRepo, mockSettingsService);
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
        verify(mockRepo.watchRecentDocuments()).called(1);
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'reactively updates state when watchRecentDocuments emits updated documents',
      build: () {
        final doc2 = doc1.copyWith(
          path: '/path/2.epub',
          title: 'Book 2',
          lastOpened: DateTime(2026),
        );
        when(mockRepo.watchRecentDocuments()).thenAnswer(
          (_) => Stream.fromIterable([
            Success([doc1]),
            Success([doc2, doc1]),
          ]),
        );
        return LibraryBloc(mockRepo, mockSettingsService);
      },
      act: (bloc) => bloc.add(const LibraryEvent.loadRequested()),
      expect: () => [
        const LibraryState(isLoading: true),
        LibraryState(
          isLoading: false,
          recentDocuments: [doc1],
        ),
        LibraryState(
          isLoading: false,
          recentDocuments: [
            doc1.copyWith(
              path: '/path/2.epub',
              title: 'Book 2',
              lastOpened: DateTime(2026),
            ),
            doc1,
          ],
        ),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'removes document and updates state on removeDocument event',
      build: () {
        when(mockRepo.removeRecentDocument(doc1.path)).thenAnswer(
          (_) async => const Success(null),
        );
        return LibraryBloc(mockRepo, mockSettingsService);
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
        return LibraryBloc(mockRepo, mockSettingsService);
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

    blocTest<LibraryBloc, LibraryState>(
      'freezes search, filter, sort, and view while selecting documents',
      build: () => LibraryBloc(mockRepo, mockSettingsService),
      seed: () => LibraryState(
        recentDocuments: [doc1],
        isSelectMode: true,
        searchQuery: 'Book',
        filterStatus: ReadingStatusFilter.reading,
        sortBy: LibrarySortBy.title,
        viewMode: LibraryViewMode.list,
      ),
      act: (bloc) {
        bloc
          ..add(const LibraryEvent.searchQueryChanged('other'))
          ..add(const LibraryEvent.filterChanged(ReadingStatusFilter.all))
          ..add(const LibraryEvent.sortByChanged(LibrarySortBy.fileSize))
          ..add(const LibraryEvent.viewModeChanged(LibraryViewMode.grid));
      },
      expect: () => <LibraryState>[],
    );

    test(
      'restores saved library tools and falls back for invalid values',
      () async {
        when(mockSettingsService.settings).thenReturn(
          const Settings(
            libraryViewMode: 'list',
            librarySortBy: 'author',
            librarySortAscending: true,
            libraryFilterStatus: 'favorites',
          ),
        );

        final bloc = LibraryBloc(mockRepo, mockSettingsService);

        expect(bloc.state.viewMode, LibraryViewMode.list);
        expect(bloc.state.sortBy, LibrarySortBy.author);
        expect(bloc.state.sortAscending, isTrue);
        expect(bloc.state.filterStatus, ReadingStatusFilter.favorites);
        await bloc.close();

        when(mockSettingsService.settings).thenReturn(
          const Settings(
            libraryViewMode: 'unknown',
            librarySortBy: 'unknown',
            libraryFilterStatus: 'unknown',
          ),
        );
        final invalidBloc = LibraryBloc(mockRepo, mockSettingsService);
        expect(invalidBloc.state.viewMode, LibraryViewMode.grid);
        expect(invalidBloc.state.sortBy, LibrarySortBy.dateOpened);
        expect(invalidBloc.state.filterStatus, ReadingStatusFilter.all);
        await invalidBloc.close();
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'debounces updated tool choices into app settings',
      build: () => LibraryBloc(mockRepo, mockSettingsService),
      act: (bloc) => bloc
        ..add(const LibraryEvent.viewModeChanged(LibraryViewMode.list))
        ..add(const LibraryEvent.sortByChanged(LibrarySortBy.title))
        ..add(const LibraryEvent.filterChanged(ReadingStatusFilter.reading)),
      expect: () => [
        const LibraryState(viewMode: LibraryViewMode.list),
        const LibraryState(
          viewMode: LibraryViewMode.list,
          sortBy: LibrarySortBy.title,
          sortAscending: true,
        ),
        const LibraryState(
          viewMode: LibraryViewMode.list,
          sortBy: LibrarySortBy.title,
          sortAscending: true,
          filterStatus: ReadingStatusFilter.reading,
        ),
      ],
      verify: (_) {
        verify(mockSettingsService.scheduleSave(any)).called(3);
      },
    );
  });
}
