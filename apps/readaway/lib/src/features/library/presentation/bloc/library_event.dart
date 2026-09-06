part of 'library_bloc.dart';

@freezed
abstract class LibraryEvent with _$LibraryEvent {
  const factory LibraryEvent.loadRequested() = _LoadRequested;
  const factory LibraryEvent.addDocuments() = _AddDocuments;
  const factory LibraryEvent.openDirectly() = _OpenDirectly;
  const factory LibraryEvent.pickAndOpenDocument() = _PickAndOpenDocument;
  const factory LibraryEvent.removeDocument(String path) = _RemoveDocument;
  const factory LibraryEvent.toggleFavorite(String path) = _ToggleFavorite;
  const factory LibraryEvent.updateReadingStatus(
    String path,
    ReadingStatus status,
  ) = _UpdateReadingStatus;
  const factory LibraryEvent.viewModeChanged(LibraryViewMode viewMode) =
      _ViewModeChanged;
  const factory LibraryEvent.sortByChanged(
    LibrarySortBy sortBy, {
    bool? ascending,
  }) = _SortByChanged;
  const factory LibraryEvent.sortOrderToggled() = _SortOrderToggled;
  const factory LibraryEvent.filterChanged(ReadingStatusFilter filter) =
      _FilterChanged;
  const factory LibraryEvent.searchQueryChanged(String query) =
      _SearchQueryChanged;
  const factory LibraryEvent.selectModeToggled() = _SelectModeToggled;
  const factory LibraryEvent.selectDocumentToggled(String path) =
      _SelectDocumentToggled;
  const factory LibraryEvent.selectAll() = _SelectAll;
  const factory LibraryEvent.deselectAll() = _DeselectAll;
  const factory LibraryEvent.batchDeleteSelected() = _BatchDeleteSelected;
  const factory LibraryEvent.batchUpdateStatusSelected(ReadingStatus status) =
      _BatchUpdateStatusSelected;
  const factory LibraryEvent.clearOpened() = _ClearOpened;
  const factory LibraryEvent.clearDirectOpen() = _ClearDirectOpen;
  const factory LibraryEvent.clearNotice() = _ClearNotice;
  const factory LibraryEvent.coverUpdated({
    required String path,
    required String coverPath,
  }) = _CoverUpdated;
}
