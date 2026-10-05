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

  group('single-line chip rows', () {
    Future<void> pumpPanelAtCompactWidth(
      WidgetTester tester, {
      ValueChanged<ReadingStatusFilter>? onFilterChanged,
    }) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LibraryToolsPanel(
                state: LibraryState(recentDocuments: [document]),
                searchController: TextEditingController(),
                selecting: false,
                onSearchChanged: (_) {},
                onFilterChanged: onFilterChanged ?? (_) {},
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
    }

    testWidgets('filter chips never reflow onto a second row', (
      tester,
    ) async {
      await pumpPanelAtCompactWidth(tester);

      final centres = <double>[];
      for (final filter in ReadingStatusFilter.values) {
        final chip = tester.getRect(
          find.byKey(ValueKey('library-filter-${filter.name}')),
        );
        centres.add(chip.center.dy);
      }

      expect(centres, isNotEmpty);
      expect(
        centres.toSet().length,
        1,
        reason: 'every filter chip must share one horizontal line',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sort and view chips never reflow onto a second row', (
      tester,
    ) async {
      await pumpPanelAtCompactWidth(tester);

      for (final group in [
        LibrarySortBy.values
            .map((sort) => ValueKey('library-sort-${sort.name}'))
            .toList(),
        LibraryViewMode.values
            .map((mode) => ValueKey('library-view-${mode.name}'))
            .toList(),
      ]) {
        final centres = group
            .map(
              (key) => tester.getRect(find.byKey(key)).center.dy,
            )
            .toSet();
        expect(centres.length, 1, reason: 'chips in a group share one line');
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('chips past the edge stay reachable by horizontal scroll', (
      tester,
    ) async {
      var selectedFilter = ReadingStatusFilter.all;
      await pumpPanelAtCompactWidth(
        tester,
        onFilterChanged: (filter) => selectedFilter = filter,
      );

      final favorites = find.byKey(const ValueKey('library-filter-favorites'));
      final horizontalStrip = find
          .ancestor(
            of: favorites,
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        tester.widget<Scrollable>(horizontalStrip).axisDirection,
        AxisDirection.right,
      );

      final viewport = tester.getRect(horizontalStrip);
      expect(tester.getRect(favorites).right, greaterThan(viewport.right));

      await tester.drag(horizontalStrip, const Offset(-1000, 0));
      await tester.pumpAndSettle();

      final revealedFavorites = tester.getRect(favorites);
      expect(viewport.contains(revealedFavorites.center), isTrue);
      expect(
        tester.state<ScrollableState>(horizontalStrip).position.pixels,
        greaterThan(0),
      );

      await tester.tap(favorites);
      await tester.pump();
      expect(selectedFilter, ReadingStatusFilter.favorites);
    });
  });
}
