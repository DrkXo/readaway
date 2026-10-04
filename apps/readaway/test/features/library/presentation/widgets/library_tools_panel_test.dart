import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/presentation/bloc/library_bloc.dart';
import 'package:readaway/src/features/library/presentation/widgets/book_list_tile.dart';
import 'package:readaway/src/features/library/presentation/widgets/library_tools_panel.dart';

void main() {
  final document = RecentDocument(
    path: '/book.epub',
    fileName: 'book.epub',
    title: 'A Readable Title',
    author: 'An Author',
    dateAdded: DateTime(2025),
    lastOpened: DateTime(2025),
    fileSize: 1024,
    format: 'epub',
  );

  testWidgets('tools panel remains usable at compact width', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectedFilter = ReadingStatusFilter.all;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LibraryToolsPanel(
              state: LibraryState(recentDocuments: [document]),
              searchController: TextEditingController(),
              selecting: false,
              onSearchChanged: (_) {},
              onFilterChanged: (filter) => selectedFilter = filter,
              onSortChanged: (_) {},
              onSortOrderToggled: () {},
              onViewModeChanged: (_) {},
              onReset: () {},
              onSelectMode: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('library-search-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-filter-reading')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('library-filter-reading')));
    await tester.pump();
    expect(selectedFilter, ReadingStatusFilter.reading);
  });

  testWidgets('selection mode disables query and filter controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryToolsPanel(
            state: LibraryState(
              recentDocuments: [document],
              isSelectMode: true,
              searchQuery: 'Readable',
              filterStatus: ReadingStatusFilter.reading,
            ),
            searchController: TextEditingController(text: 'Readable'),
            selecting: true,
            onSearchChanged: (_) {},
            onFilterChanged: (_) {},
            onSortChanged: (_) {},
            onSortOrderToggled: () {},
            onViewModeChanged: (_) {},
            onReset: () {},
            onSelectMode: () {},
          ),
        ),
      ),
    );

    expect(find.text('Readable'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('library-search-field')))
          .enabled,
      isFalse,
    );
    expect(find.text('Results are frozen'), findsOneWidget);
  });

  testWidgets('sort and view choices are chips and update immediately', (
    tester,
  ) async {
    var selectedSort = LibrarySortBy.dateOpened;
    var selectedView = LibraryViewMode.grid;
    var ascending = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LibraryToolsPanel(
              state: LibraryState(recentDocuments: [document]),
              searchController: TextEditingController(),
              selecting: false,
              onSearchChanged: (_) {},
              onFilterChanged: (_) {},
              onSortChanged: (sort) => selectedSort = sort,
              onSortOrderToggled: () => ascending = !ascending,
              onViewModeChanged: (mode) => selectedView = mode,
              onReset: () {},
              onSelectMode: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('library-sort-button')), findsNothing);
    expect(find.byKey(const ValueKey('library-sort-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-view-list')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-sort-title')));
    await tester.pump();
    expect(selectedSort, LibrarySortBy.title);

    await tester.tap(find.byKey(const ValueKey('library-view-list')));
    await tester.pump();
    expect(selectedView, LibraryViewMode.list);

    await tester.tap(find.byKey(const ValueKey('library-sort-order')));
    await tester.pump();
    expect(ascending, isTrue);
  });

  testWidgets('narrow list tile keeps details action and readable cover', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookListTile(
            document: document,
            onTap: () {},
            onLongPress: () {},
            onToggleFavorite: () {},
            onOpenDetails: () {},
          ),
        ),
      ),
    );

    expect(find.text('A Readable Title'), findsNWidgets(2));
    expect(find.byTooltip('Book details & actions'), findsOneWidget);
    expect(find.byTooltip('Mark as favorite'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
