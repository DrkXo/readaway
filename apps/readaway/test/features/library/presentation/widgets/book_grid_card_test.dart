import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/library/domain/entity/reading_status.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/presentation/widgets/book_grid_card.dart';

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

void main() {
  testWidgets('grid card renders without overflow on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 163,
              height: 313,
              child: BookGridCard(
                document: _doc(),
                onTap: () {},
                onLongPress: () {},
                onToggleFavorite: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('grid favorite star is tappable and does not open the book', (
    tester,
  ) async {
    var toggled = 0;
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 360,
              child: BookGridCard(
                document: _doc(),
                onTap: () => taps++,
                onLongPress: () {},
                onToggleFavorite: () => toggled++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Mark as favorite'));
    expect(toggled, 1);
    expect(taps, 0);
  });
}
