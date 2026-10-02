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
}
