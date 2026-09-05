import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../../domain/repositories/library_repository.dart';
import 'library_state.dart';

@injectable
class LibraryCubit extends Cubit<LibraryState> {
  final LibraryRepository _repository;

  LibraryCubit(this._repository) : super(const LibraryState());

  Future<void> loadRecentDocuments() async {
    emit(state.copyWith(isLoading: true, clearFailure: true));

    final result = await _repository.getRecentDocuments().run();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (documents) {
        emit(state.copyWith(
          isLoading: false,
          recentDocuments: documents,
          clearFailure: true,
        ));
        _populateMissingCovers(documents);
      },
    );
  }

  Future<void> _populateMissingCovers(List<RecentDocument> documents) async {
    for (final doc in documents) {
      if (doc.coverPath == null || doc.coverPath!.isEmpty) {
        final coverResult = await _repository.getCoverArtPath(doc).run();
        coverResult.fold(
          (_) {},
          (optionPath) {
            optionPath.fold(
              () {},
              (path) {
                final currentList = state.recentDocuments;
                final index = currentList.indexWhere((d) => d.path == doc.path);
                if (index != -1) {
                  final updatedList = List<RecentDocument>.from(currentList);
                  updatedList[index] =
                      updatedList[index].copyWith(coverPath: path);
                  emit(state.copyWith(recentDocuments: updatedList));
                }
              },
            );
          },
        );
      }
    }
  }

  Future<void> pickAndOpenDocument() async {
    emit(state.copyWith(isLoading: true, clearFailure: true, clearOpened: true));

    final result = await _repository.pickDocument().run();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (optionDoc) {
        optionDoc.fold(
          () => emit(state.copyWith(isLoading: false)), // User cancelled
          (doc) {
            final updated = [
              doc,
              ...state.recentDocuments.where((d) => d.path != doc.path)
            ];
            emit(state.copyWith(
              isLoading: false,
              recentDocuments: updated,
              openedDocument: doc,
              clearFailure: true,
            ));
          },
        );
      },
    );
  }

  Future<void> removeRecent(String path) async {
    final result = await _repository.removeRecentDocument(path).run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final updated =
            state.recentDocuments.where((d) => d.path != path).toList();
        final updatedSelection = Set<String>.from(state.selectedPaths)
          ..remove(path);
        emit(state.copyWith(
          recentDocuments: updated,
          selectedPaths: updatedSelection,
        ));
      },
    );
  }

  Future<void> toggleFavorite(String path) async {
    final result = await _repository.toggleFavorite(path).run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (updatedDoc) {
        final currentList = state.recentDocuments;
        final index = currentList.indexWhere((d) => d.path == path);
        if (index != -1) {
          final updatedList = List<RecentDocument>.from(currentList);
          updatedList[index] = updatedDoc;
          emit(state.copyWith(recentDocuments: updatedList));
        }
      },
    );
  }

  Future<void> updateReadingStatus(String path, ReadingStatus status) async {
    final result = await _repository.updateReadingStatus(path, status).run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (updatedDoc) {
        final currentList = state.recentDocuments;
        final index = currentList.indexWhere((d) => d.path == path);
        if (index != -1) {
          final updatedList = List<RecentDocument>.from(currentList);
          updatedList[index] = updatedDoc;
          emit(state.copyWith(recentDocuments: updatedList));
        }
      },
    );
  }

  void setViewMode(LibraryViewMode mode) {
    if (state.viewMode != mode) {
      emit(state.copyWith(viewMode: mode));
    }
  }

  void setSortBy(LibrarySortBy sortBy, {bool? ascending}) {
    emit(state.copyWith(
      sortBy: sortBy,
      sortAscending: ascending ?? sortBy.defaultAscending,
    ));
  }

  void toggleSortAscending() {
    emit(state.copyWith(sortAscending: !state.sortAscending));
  }

  void setFilterStatus(ReadingStatusFilter filter) {
    if (state.filterStatus != filter) {
      emit(state.copyWith(filterStatus: filter));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void toggleSelectMode() {
    final newMode = !state.isSelectMode;
    emit(state.copyWith(
      isSelectMode: newMode,
      selectedPaths: newMode ? state.selectedPaths : const {},
    ));
  }

  void toggleSelectDocument(String path) {
    final updated = Set<String>.from(state.selectedPaths);
    if (updated.contains(path)) {
      updated.remove(path);
    } else {
      updated.add(path);
    }
    emit(state.copyWith(selectedPaths: updated));
  }

  void selectAll() {
    final allPaths = state.filteredDocuments.map((d) => d.path).toSet();
    emit(state.copyWith(selectedPaths: allPaths));
  }

  void deselectAll() {
    emit(state.copyWith(selectedPaths: const {}));
  }

  Future<void> batchDeleteSelected() async {
    if (state.selectedPaths.isEmpty) return;

    final pathsToDelete = state.selectedPaths.toList();
    final result =
        await _repository.removeMultipleDocuments(pathsToDelete).run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final pathSet = pathsToDelete.toSet();
        final updated =
            state.recentDocuments.where((d) => !pathSet.contains(d.path)).toList();
        emit(state.copyWith(
          recentDocuments: updated,
          selectedPaths: const {},
          isSelectMode: false,
        ));
      },
    );
  }

  Future<void> batchUpdateStatusSelected(ReadingStatus status) async {
    if (state.selectedPaths.isEmpty) return;

    for (final path in state.selectedPaths) {
      await _repository.updateReadingStatus(path, status).run();
    }
    await loadRecentDocuments();
    emit(state.copyWith(selectedPaths: const {}, isSelectMode: false));
  }

  void clearOpened() {
    emit(state.copyWith(clearOpened: true));
  }
}
