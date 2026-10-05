import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/presentation/widgets/book_list_tile.dart';

RecentDocument _doc() => RecentDocument(
  path: '/books/sample.epub',
  fileName: 'sample.epub',
  title: 'A Very Long Book Title That Should Ellipsize Nicely',
  author: 'Some Quite Long Author Name',
  dateAdded: DateTime(2024, 1, 1),
  lastOpened: DateTime(2024, 1, 2),
  fileSize: 2048,
  format: 'epub',
  pageCount: 300,
  lastReadPage: 10,
  readingStatus: ReadingStatus.reading,
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: child),
);

void main() {
  testWidgets('list tile renders without overflow on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        BookListTile(
          document: _doc(),
          onTap: () {},
          onLongPress: () {},
          onToggleFavorite: () {},
          onOpenDetails: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('list tile renders without overflow at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: BookListTile(
                document: _doc(),
                onTap: () {},
                onLongPress: () {},
                onToggleFavorite: () {},
                onOpenDetails: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
