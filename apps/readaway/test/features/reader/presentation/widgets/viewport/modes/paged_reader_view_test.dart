import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/controllers/reader_viewport_controller.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/modes/paged_reader_view.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

void main() {
  testWidgets('wheel paging is ignored while the active page is zoomed', (
    tester,
  ) async {
    final viewportController = ReaderViewportController(
      initialPage: 0,
      pageCount: 3,
    );
    addTearDown(viewportController.dispose);
    final committedPages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 800,
          child: PagedReaderView(
            currentPage: 0,
            pageCount: 3,
            transition: ReaderPageTransition.none,
            direction: ReaderScrollDirection.horizontal,
            controller: viewportController,
            itemBuilder: (context, index) => Center(child: Text('$index')),
            onPageChangeRequested: (index) {
              committedPages.add(index);
              viewportController.setCurrentPage(index);
            },
          ),
        ),
      ),
    );

    final position = tester.getCenter(find.byType(PagedReaderView));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        device: 1,
        position: position,
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();
    expect(committedPages, [1]);

    viewportController.setPageZoom(1, true);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        device: 1,
        position: position,
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();

    expect(committedPages, [1]);
  });
}
