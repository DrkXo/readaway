import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/controllers/reader_viewport_controller.dart';

void main() {
  test('page zoom belongs to the active page only', () {
    final controller = ReaderViewportController(
      initialPage: 2,
      pageCount: 8,
    );
    addTearDown(controller.dispose);

    controller.setPageZoom(2, true);
    expect(controller.isPageZoomed, isTrue);

    controller.setCurrentPage(3);
    expect(controller.isPageZoomed, isFalse);

    controller.setPageZoom(2, true);
    expect(controller.isPageZoomed, isFalse);

    controller.setPageZoom(3, true);
    expect(controller.isPageZoomed, isTrue);

    controller.clearPageZoom();
    expect(controller.isPageZoomed, isFalse);
  });

  test('active selection state notifies listeners and tracks state', () {
    final controller = ReaderViewportController();
    addTearDown(controller.dispose);

    expect(controller.hasActiveSelection, isFalse);
    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    controller.setSelectionActive(true);
    expect(controller.hasActiveSelection, isTrue);
    expect(notifyCount, 1);

    // Idempotent call doesn't notify
    controller.setSelectionActive(true);
    expect(notifyCount, 1);

    controller.setSelectionActive(false);
    expect(controller.hasActiveSelection, isFalse);
    expect(notifyCount, 2);
  });
}
