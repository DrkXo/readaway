part of 'library_bloc.dart';

enum LibraryViewMode {
  grid,
  list;

  String get label => switch (this) {
        LibraryViewMode.grid => 'Grid',
        LibraryViewMode.list => 'List',
      };
}

enum LibrarySortBy {
  dateOpened,
  dateAdded,
  title,
  author,
  progress,
  fileSize;

  String get label => switch (this) {
        LibrarySortBy.dateOpened => 'Date Opened',
        LibrarySortBy.dateAdded => 'Date Added',
        LibrarySortBy.title => 'Title',
        LibrarySortBy.author => 'Author',
        LibrarySortBy.progress => 'Progress',
        LibrarySortBy.fileSize => 'File Size',
      };

  bool get defaultAscending => switch (this) {
        LibrarySortBy.title => true,
        LibrarySortBy.author => true,
        LibrarySortBy.dateOpened => false,
        LibrarySortBy.dateAdded => false,
        LibrarySortBy.progress => false,
        LibrarySortBy.fileSize => false,
      };
}

enum ReadingStatusFilter {
  all,
  reading,
  unread,
  finished,
  favorites;

  String get label => switch (this) {
        ReadingStatusFilter.all => 'All',
        ReadingStatusFilter.reading => 'Reading',
        ReadingStatusFilter.unread => 'Unread',
        ReadingStatusFilter.finished => 'Finished',
        ReadingStatusFilter.favorites => 'Favorites',
      };
}

@freezed
abstract class LibraryState with _$LibraryState {
  const factory LibraryState({
    @Default(false) bool isLoading,
    @Default([]) List<RecentDocument> recentDocuments,
    Failure? failure,
    RecentDocument? openedDocument,
    RecentDocument? directOpenDocument,
    String? noticeMessage,
    @Default(LibraryViewMode.grid) LibraryViewMode viewMode,
    @Default(LibrarySortBy.dateOpened) LibrarySortBy sortBy,
    @Default(false) bool sortAscending,
    @Default(ReadingStatusFilter.all) ReadingStatusFilter filterStatus,
    @Default('') String searchQuery,
    @Default(false) bool isSelectMode,
    @Default({}) Set<String> selectedPaths,
  }) = _LibraryState;

  const LibraryState._();

  int get totalCount => recentDocuments.length;
  int get readingCount =>
      recentDocuments.where((d) => d.readingStatus == ReadingStatus.reading).length;
  int get unreadCount =>
      recentDocuments.where((d) => d.readingStatus == ReadingStatus.unread).length;
  int get finishedCount =>
      recentDocuments.where((d) => d.isFinished).length;
  int get favoritesCount =>
      recentDocuments.where((d) => d.isFavorite).length;

  int countForFilter(ReadingStatusFilter filter) => switch (filter) {
        ReadingStatusFilter.all => totalCount,
        ReadingStatusFilter.reading => readingCount,
        ReadingStatusFilter.unread => unreadCount,
        ReadingStatusFilter.finished => finishedCount,
        ReadingStatusFilter.favorites => favoritesCount,
      };

  List<RecentDocument> get filteredDocuments {
    var list = recentDocuments.where((doc) {
      // 1. Status Filter
      final matchesStatus = switch (filterStatus) {
        ReadingStatusFilter.all => true,
        ReadingStatusFilter.reading =>
          doc.readingStatus == ReadingStatus.reading,
        ReadingStatusFilter.unread =>
          doc.readingStatus == ReadingStatus.unread,
        ReadingStatusFilter.finished => doc.isFinished,
        ReadingStatusFilter.favorites => doc.isFavorite,
      };
      if (!matchesStatus) return false;

      // 2. Search Query Filter
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final inTitle = doc.displayTitle.toLowerCase().contains(query);
        final inAuthor =
            doc.displayAuthor?.toLowerCase().contains(query) ?? false;
        final inFileName = doc.fileName.toLowerCase().contains(query);
        final inFormat = doc.format.toLowerCase().contains(query);
        if (!inTitle && !inAuthor && !inFileName && !inFormat) {
          return false;
        }
      }

      return true;
    }).toList();

    // 3. Sorting
    list.sort((a, b) {
      final order = switch (sortBy) {
        LibrarySortBy.dateOpened => a.lastOpened.compareTo(b.lastOpened),
        LibrarySortBy.dateAdded => a.dateAdded.compareTo(b.dateAdded),
        LibrarySortBy.title => a.displayTitle
            .toLowerCase()
            .compareTo(b.displayTitle.toLowerCase()),
        LibrarySortBy.author => (a.displayAuthor ?? '')
            .toLowerCase()
            .compareTo((b.displayAuthor ?? '').toLowerCase()),
        LibrarySortBy.progress =>
          a.progressPercent.compareTo(b.progressPercent),
        LibrarySortBy.fileSize => a.fileSize.compareTo(b.fileSize),
      };
      return sortAscending ? order : -order;
    });

    return list;
  }
}
