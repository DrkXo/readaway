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

  test(
    'clearSelection invokes clearSelectionDelegate and resets selection',
    () {
      final controller = ReaderViewportController();
      addTearDown(controller.dispose);

      var delegateCalled = false;
      controller.clearSelectionDelegate = () => delegateCalled = true;

      controller.setSelectionActive(true);
      expect(controller.hasActiveSelection, isTrue);

      controller.clearSelection();
      expect(delegateCalled, isTrue);
      expect(controller.hasActiveSelection, isFalse);
    },
  );

  test('setCurrentPage clears active selection', () {
    final controller = ReaderViewportController(initialPage: 0, pageCount: 5);
    addTearDown(controller.dispose);

    var delegateCalled = false;
    controller.clearSelectionDelegate = () => delegateCalled = true;

    controller.setSelectionActive(true);
    expect(controller.hasActiveSelection, isTrue);

    controller.setCurrentPage(1);
    expect(delegateCalled, isTrue);
    expect(controller.hasActiveSelection, isFalse);
    expect(controller.currentPage, 1);
  });

  test('goToPage clears active selection', () async {
    final controller = ReaderViewportController(initialPage: 0, pageCount: 5);
    addTearDown(controller.dispose);

    var delegateCalled = false;
    controller.clearSelectionDelegate = () => delegateCalled = true;

    controller.setSelectionActive(true);
    expect(controller.hasActiveSelection, isTrue);

    await controller.goToPage(2, animated: false);
    expect(delegateCalled, isTrue);
    expect(controller.hasActiveSelection, isFalse);
    expect(controller.currentPage, 2);
  });
}
