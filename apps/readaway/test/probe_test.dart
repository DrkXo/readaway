import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter_test/flutter_test.dart';

SelectedContent? last;

void main() {
  testWidgets('probe right-click tree', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SelectionArea(
          onSelectionChanged: (c) => last = c,
          contextMenuBuilder: (_, _) => const SizedBox.shrink(),
          child: const Center(child: Text('Hello World')),
        ),
      ),
    ));
    final center = tester.getCenter(find.text('Hello World'));
    // select word via double click
    for (final _ in List.filled(2, 0)) {
      await tester.tapAt(center);
      await tester.pump(kDoubleTapMinTime);
    }
    await tester.pumpAndSettle();
    debugPrint('SELECTION: "${last?.plainText}"');
    // right click on it
    final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    debugPrint('adaptive toolbars: ${find.byType(AdaptiveTextSelectionToolbar).evaluate().length}');
    debugPrint('material toolbars: ${find.byType(TextSelectionToolbar).evaluate().length}');
  });
}
