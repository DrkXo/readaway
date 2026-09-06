import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../../domain/repositories/library_repository.dart';

part 'library_bloc.freezed.dart';
part 'library_event.dart';
part 'library_state.dart';

@injectable
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryRepository _repository;

  LibraryBloc(this._repository) : super(const LibraryState()) {
    on<_LoadRequested>(_onLoadRequested, transformer: droppable());
    on<_AddDocuments>(_onAddDocuments, transformer: droppable());
    on<_OpenDirectly>(_onOpenDirectly, transformer: droppable());
    on<_PickAndOpenDocument>(_onPickAndOpenDocument, transformer: droppable());
    on<_RemoveDocument>(_onRemoveDocument);
    on<_ToggleFavorite>(_onToggleFavorite);
    on<_UpdateReadingStatus>(_onUpdateReadingStatus);
    on<_ViewModeChanged>(_onViewModeChanged);
    on<_SortByChanged>(_onSortByChanged);
    on<_SortOrderToggled>(_onSortOrderToggled);
    on<_FilterChanged>(_onFilterChanged);
    on<_SearchQueryChanged>(_onSearchQueryChanged, transformer: restartable());
    on<_SelectModeToggled>(_onSelectModeToggled);
    on<_SelectDocumentToggled>(_onSelectDocumentToggled);
    on<_SelectAll>(_onSelectAll);
    on<_DeselectAll>(_onDeselectAll);
    on<_BatchDeleteSelected>(_onBatchDeleteSelected, transformer: droppable());
    on<_BatchUpdateStatusSelected>(
      _onBatchUpdateStatusSelected,
      transformer: droppable(),
    );
    on<_ClearOpened>(_onClearOpened);
    on<_ClearDirectOpen>(_onClearDirectOpen);
    on<_ClearNotice>(_onClearNotice);
    on<_CoverUpdated>(_onCoverUpdated);
  }

  Future<void> _onLoadRequested(
    _LoadRequested event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _repository.getRecentDocuments().run();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (documents) {
        emit(
          state.copyWith(
            isLoading: false,
            recentDocuments: documents,
            failure: null,
          ),
        );
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
                add(
                  LibraryEvent.coverUpdated(
                    path: doc.path,
                    coverPath: path,
                  ),
                );
              },
            );
          },
        );
      }
    }
  }

  void _onCoverUpdated(
    _CoverUpdated event,
    Emitter<LibraryState> emit,
  ) {
    final currentList = state.recentDocuments;
    final index = currentList.indexWhere((d) => d.path == event.path);
    if (index != -1) {
      final updatedList = List<RecentDocument>.from(currentList);
      updatedList[index] = updatedList[index].copyWith(
        coverPath: event.coverPath,
      );
      emit(state.copyWith(recentDocuments: updatedList));
    }
  }

  Future<void> _onAddDocuments(
    _AddDocuments event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _repository.pickAndAddDocuments().run();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (newDocs) {
        if (newDocs.isEmpty) {
          emit(state.copyWith(isLoading: false));
          return;
        }

        final newPaths = newDocs.map((d) => d.path).toSet();
        final updated = [
          ...newDocs,
          ...state.recentDocuments.where((d) => !newPaths.contains(d.path)),
        ];

        final message = newDocs.length == 1
            ? 'Added 1 book to library'
            : 'Added ${newDocs.length} books to library';

        emit(
          state.copyWith(
            isLoading: false,
            recentDocuments: updated,
            noticeMessage: message,
            failure: null,
          ),
        );

        _populateMissingCovers(newDocs);
      },
    );
  }

  Future<void> _onOpenDirectly(
    _OpenDirectly event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(failure: null, directOpenDocument: null));

    final result = await _repository.pickDocumentWithoutSaving().run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (optionDoc) {
        optionDoc.fold(
          () {}, // User cancelled picker
          (doc) {
            emit(state.copyWith(directOpenDocument: doc));
          },
        );
      },
    );
  }

  /// Convenience helper to pick a document without adding it to the library.
  Future<RecentDocument?> pickDocumentWithoutAdding() async {
    final result = await _repository.pickDocumentWithoutSaving().run();
    return result.fold(
      (failure) => null,
      (optionDoc) => optionDoc.toNullable(),
    );
  }

  Future<void> _onPickAndOpenDocument(
    _PickAndOpenDocument event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null, openedDocument: null));

    final result = await _repository.pickDocument().run();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (optionDoc) {
        optionDoc.fold(
          () => emit(state.copyWith(isLoading: false)),
          (doc) {
            final updated = [
              doc,
              ...state.recentDocuments.where((d) => d.path != doc.path),
            ];
            emit(
              state.copyWith(
                isLoading: false,
                recentDocuments: updated,
                openedDocument: doc,
                failure: null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onRemoveDocument(
    _RemoveDocument event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await _repository.removeRecentDocument(event.path).run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final updated = state.recentDocuments
            .where((d) => d.path != event.path)
            .toList();
        final updatedSelection = Set<String>.from(state.selectedPaths)
          ..remove(event.path);
        emit(
          state.copyWith(
            recentDocuments: updated,
            selectedPaths: updatedSelection,
          ),
        );
      },
    );
  }

  Future<void> _onToggleFavorite(
    _ToggleFavorite event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await _repository.toggleFavorite(event.path).run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (updatedDoc) {
        final currentList = state.recentDocuments;
        final index = currentList.indexWhere((d) => d.path == event.path);
        if (index != -1) {
          final updatedList = List<RecentDocument>.from(currentList);
          updatedList[index] = updatedDoc;
          emit(state.copyWith(recentDocuments: updatedList));
        }
      },
    );
  }

  Future<void> _onUpdateReadingStatus(
    _UpdateReadingStatus event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await _repository
        .updateReadingStatus(event.path, event.status)
        .run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (updatedDoc) {
        final currentList = state.recentDocuments;
        final index = currentList.indexWhere((d) => d.path == event.path);
        if (index != -1) {
          final updatedList = List<RecentDocument>.from(currentList);
          updatedList[index] = updatedDoc;
          emit(state.copyWith(recentDocuments: updatedList));
        }
      },
    );
  }

  void _onViewModeChanged(
    _ViewModeChanged event,
    Emitter<LibraryState> emit,
  ) {
    if (state.viewMode != event.viewMode) {
      emit(state.copyWith(viewMode: event.viewMode));
    }
  }

  void _onSortByChanged(
    _SortByChanged event,
    Emitter<LibraryState> emit,
  ) {
    emit(
      state.copyWith(
        sortBy: event.sortBy,
        sortAscending: event.ascending ?? event.sortBy.defaultAscending,
      ),
    );
  }

  void _onSortOrderToggled(
    _SortOrderToggled event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(sortAscending: !state.sortAscending));
  }

  void _onFilterChanged(
    _FilterChanged event,
    Emitter<LibraryState> emit,
  ) {
    if (state.filterStatus != event.filter) {
      emit(state.copyWith(filterStatus: event.filter));
    }
  }

  void _onSearchQueryChanged(
    _SearchQueryChanged event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onSelectModeToggled(
    _SelectModeToggled event,
    Emitter<LibraryState> emit,
  ) {
    final newMode = !state.isSelectMode;
    emit(
      state.copyWith(
        isSelectMode: newMode,
        selectedPaths: newMode ? state.selectedPaths : const {},
      ),
    );
  }

  void _onSelectDocumentToggled(
    _SelectDocumentToggled event,
    Emitter<LibraryState> emit,
  ) {
    final updated = Set<String>.from(state.selectedPaths);
    if (updated.contains(event.path)) {
      updated.remove(event.path);
    } else {
      updated.add(event.path);
    }
    emit(state.copyWith(selectedPaths: updated));
  }

  void _onSelectAll(
    _SelectAll event,
    Emitter<LibraryState> emit,
  ) {
    final allPaths = state.filteredDocuments.map((d) => d.path).toSet();
    emit(state.copyWith(selectedPaths: allPaths));
  }

  void _onDeselectAll(
    _DeselectAll event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(selectedPaths: const {}));
  }

  Future<void> _onBatchDeleteSelected(
    _BatchDeleteSelected event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.selectedPaths.isEmpty) return;

    final pathsToDelete = state.selectedPaths.toList();
    final result = await _repository
        .removeMultipleDocuments(pathsToDelete)
        .run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final pathSet = pathsToDelete.toSet();
        final updated = state.recentDocuments
            .where((d) => !pathSet.contains(d.path))
            .toList();
        emit(
          state.copyWith(
            recentDocuments: updated,
            selectedPaths: const {},
            isSelectMode: false,
          ),
        );
      },
    );
  }

  Future<void> _onBatchUpdateStatusSelected(
    _BatchUpdateStatusSelected event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.selectedPaths.isEmpty) return;

    for (final path in state.selectedPaths) {
      await _repository.updateReadingStatus(path, event.status).run();
    }
    add(const LibraryEvent.loadRequested());
    emit(state.copyWith(selectedPaths: const {}, isSelectMode: false));
  }

  void _onClearOpened(
    _ClearOpened event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(openedDocument: null));
  }

  void _onClearDirectOpen(
    _ClearDirectOpen event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(directOpenDocument: null));
  }

  void _onClearNotice(
    _ClearNotice event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(noticeMessage: null));
  }
}
