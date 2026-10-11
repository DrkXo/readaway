import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

void main() {
  Widget buildThemed(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          VsCodeThemeExtension(
            MetroColorScheme.kanagawaDragon.toVsCodeTheme(),
          ),
        ],
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('MetroPivot', () {
    testWidgets('renders horizon title and tab items with counts', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroPivot(
            title: 'Library',
            items: [
              MetroPivotItem(
                label: 'all books',
                count: '42',
                content: Text('Content: all books'),
              ),
              MetroPivotItem(
                label: 'reading',
                count: '3',
                content: Text('Content: reading'),
              ),
            ],
          ),
        ),
      );

      // Lowercase title
      expect(find.text('library'), findsOneWidget);

      // Tabs
      expect(find.text('all books'), findsOneWidget);
      expect(find.text('reading'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Initial page content
      expect(find.text('Content: all books'), findsOneWidget);
    });

    testWidgets('switches pages when tab is tapped', (tester) async {
      int? changedIndex;

      await tester.pumpWidget(
        buildThemed(
          MetroPivot(
            title: 'Library',
            onIndexChanged: (i) => changedIndex = i,
            items: const [
              MetroPivotItem(
                label: 'pane 1',
                content: Text('Content 1'),
              ),
              MetroPivotItem(
                label: 'pane 2',
                content: Text('Content 2'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Content 1'), findsOneWidget);

      await tester.tap(find.text('pane 2'));
      await tester.pumpAndSettle();

      expect(changedIndex, equals(1));
      expect(find.text('Content 2'), findsOneWidget);
    });

    testWidgets('switches tabs on swipe gesture in content area', (
      tester,
    ) async {
      int? changedIndex;

      await tester.pumpWidget(
        buildThemed(
          MetroPivot(
            title: 'Library',
            onIndexChanged: (i) => changedIndex = i,
            items: const [
              MetroPivotItem(
                label: 'pane 1',
                content: SizedBox.expand(
                  child: Center(child: Text('Swipe Me')),
                ),
              ),
              MetroPivotItem(
                label: 'pane 2',
                content: SizedBox.expand(
                  child: Center(child: Text('Second Page')),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Swipe Me'), findsOneWidget);

      // Drag left to advance to next page
      await tester.drag(find.text('Swipe Me'), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(changedIndex, equals(1));
      expect(find.text('Second Page'), findsOneWidget);
    });

    testWidgets('switches tabs on desktop mouse drag gesture', (
      tester,
    ) async {
      int? changedIndex;

      await tester.pumpWidget(
        buildThemed(
          MetroPivot(
            title: 'Library',
            onIndexChanged: (i) => changedIndex = i,
            items: const [
              MetroPivotItem(
                label: 'pane 1',
                content: SizedBox.expand(
                  child: Center(child: Text('Desktop Mouse Pane 1')),
                ),
              ),
              MetroPivotItem(
                label: 'pane 2',
                content: SizedBox.expand(
                  child: Center(child: Text('Desktop Mouse Pane 2')),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Desktop Mouse Pane 1'), findsOneWidget);

      await tester.drag(
        find.text('Desktop Mouse Pane 1'),
        const Offset(-400, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(changedIndex, equals(1));
      expect(find.text('Desktop Mouse Pane 2'), findsOneWidget);
    });

    testWidgets(
      'switches tabs on horizontal pointer scroll event (wheel/trackpad)',
      (tester) async {
        int? changedIndex;

        await tester.pumpWidget(
          buildThemed(
            MetroPivot(
              title: 'Library',
              onIndexChanged: (i) => changedIndex = i,
              items: const [
                MetroPivotItem(
                  label: 'pane 1',
                  content: SizedBox.expand(
                    child: Center(child: Text('Scroll Target 1')),
                  ),
                ),
                MetroPivotItem(
                  label: 'pane 2',
                  content: SizedBox.expand(
                    child: Center(child: Text('Scroll Target 2')),
                  ),
                ),
              ],
            ),
          ),
        );

        expect(find.text('Scroll Target 1'), findsOneWidget);

        final center = tester.getCenter(find.text('Scroll Target 1'));
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(50, 0),
          ),
        );
        await tester.pumpAndSettle();

        expect(changedIndex, equals(1));
        expect(find.text('Scroll Target 2'), findsOneWidget);
      },
    );

    testWidgets('renders trailing widget in title row', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroPivot(
            title: 'Library',
            trailing: Text('TrailingAction'),
            items: [
              MetroPivotItem(
                label: 'main',
                content: Text('Main Content'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('TrailingAction'), findsOneWidget);
    });

    testWidgets('synchronizes with external MetroPivotController', (
      tester,
    ) async {
      final controller = MetroPivotController(length: 3, initialIndex: 0);
      addTearDown(controller.dispose);

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await tester.pumpWidget(
        buildThemed(
          MetroPivot(
            title: 'Library',
            controller: controller,
            items: const [
              MetroPivotItem(label: 'tab 0', content: Text('Page 0')),
              MetroPivotItem(label: 'tab 1', content: Text('Page 1')),
              MetroPivotItem(label: 'tab 2', content: Text('Page 2')),
            ],
          ),
        ),
      );

      expect(find.text('Page 0'), findsOneWidget);
      expect(controller.index, 0);

      // External animateTo switches page and updates controller state
      controller.animateTo(2);
      await tester.pumpAndSettle();

      expect(controller.index, 2);
      expect(controller.previousIndex, 0);
      expect(find.text('Page 2'), findsOneWidget);
      expect(notifyCount, greaterThan(0));

      // Tapping tab updates external controller
      await tester.tap(find.text('tab 1'));
      await tester.pumpAndSettle();

      expect(controller.index, 1);
      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('updates active page when currentIndex changes declaratively', (
      tester,
    ) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildThemed(
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => activeIndex = 1),
                    child: const Text('Go to 1'),
                  ),
                  Expanded(
                    child: MetroPivot(
                      title: 'Library',
                      currentIndex: activeIndex,
                      items: const [
                        MetroPivotItem(
                          label: 'pane a',
                          content: Text('Pane A'),
                        ),
                        MetroPivotItem(
                          label: 'pane b',
                          content: Text('Pane B'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.text('Pane A'), findsOneWidget);

      await tester.tap(find.text('Go to 1'));
      await tester.pumpAndSettle();

      expect(find.text('Pane B'), findsOneWidget);
    });

    testWidgets('animateTo transitions smoothly without premature page snap', (
      tester,
    ) async {
      final controller = MetroPivotController(length: 3, initialIndex: 0);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildThemed(
          MetroPivot(
            title: 'Library',
            controller: controller,
            items: const [
              MetroPivotItem(label: 'tab 0', content: Text('Page 0')),
              MetroPivotItem(label: 'tab 1', content: Text('Page 1')),
              MetroPivotItem(label: 'tab 2', content: Text('Page 2')),
            ],
          ),
        ),
      );

      controller.animateTo(2);

      // On frame 0, controller.page must remain at current page and not jump to target prematurely
      expect(controller.page, 0.0);
      expect(controller.indexIsChanging, isTrue);
      expect(controller.index, 2);

      // Pump intermediate frames and verify monotonic progression
      await tester.pump(const Duration(milliseconds: 50));
      final p1 = controller.page;
      expect(p1, greaterThanOrEqualTo(0.0));
      expect(p1, lessThan(2.0));

      await tester.pump(const Duration(milliseconds: 100));
      final p2 = controller.page;
      expect(p2, greaterThan(p1));
      expect(p2, lessThanOrEqualTo(2.0));

      await tester.pumpAndSettle();
      expect(controller.page, 2.0);
      expect(controller.indexIsChanging, isFalse);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets(
      'selected item moves to leading position and pushes previous items to end of carousel',
      (tester) async {
        await tester.pumpWidget(
          buildThemed(
            const MetroPivot(
              title: 'Library',
              items: [
                MetroPivotItem(label: 'all books', content: Text('Page 0')),
                MetroPivotItem(label: 'reading', content: Text('Page 1')),
                MetroPivotItem(label: 'favorites', content: Text('Page 2')),
              ],
            ),
          ),
        );

        // Initially on page 0: 'all books' is at the leading position (x = 20.0)
        final initialAllBooksPos = tester.getTopLeft(find.text('all books')).dx;
        final initialReadingPos = tester.getTopLeft(find.text('reading')).dx;
        final initialFavoritesPos = tester
            .getTopLeft(find.text('favorites'))
            .dx;

        expect(initialAllBooksPos, equals(20.0));
        expect(initialReadingPos, greaterThan(initialAllBooksPos));
        expect(initialFavoritesPos, greaterThan(initialReadingPos));

        // Tap 'reading'
        await tester.tap(find.text('reading'));
        await tester.pumpAndSettle();

        // After switching to 'reading':
        // 'reading' has moved to the leading position (x = 20.0),
        // and 'all books' has been pushed out of the way to the end of the carousel!
        final newReadingPos = tester.getTopLeft(find.text('reading')).dx;
        final newFavoritesPos = tester.getTopLeft(find.text('favorites')).dx;
        final newAllBooksPos = tester.getTopLeft(find.text('all books')).dx;

        expect(newReadingPos, equals(20.0));
        expect(newFavoritesPos, greaterThan(newReadingPos));
        expect(newAllBooksPos, greaterThan(newFavoritesPos));

        // Tap 'all books' at the end to return to page 0
        await tester.tap(find.text('all books'));
        await tester.pumpAndSettle();

        // 'all books' is back at the leading position
        expect(tester.getTopLeft(find.text('all books')).dx, equals(20.0));
        expect(find.text('Page 0'), findsOneWidget);
      },
    );

    testWidgets(
      'tab positions transition with zero readjustment snap when settling at rest',
      (tester) async {
        final controller = MetroPivotController(length: 3, initialIndex: 0);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildThemed(
            MetroPivot(
              title: 'Library',
              controller: controller,
              items: const [
                MetroPivotItem(label: 'all books', content: Text('Page 0')),
                MetroPivotItem(label: 'reading', content: Text('Page 1')),
                MetroPivotItem(label: 'favorites', content: Text('Page 2')),
              ],
            ),
          ),
        );

        // Initially at rest: 'all books' at x = 20.0
        expect(tester.getTopLeft(find.text('all books')).dx, equals(20.0));

        // Start animation to page 1
        controller.animateTo(1, duration: const Duration(milliseconds: 300));
        await tester.pump();

        // Sample intermediate frames and verify 'reading' glides continuously toward 20.0
        double previousReadingPos = tester.getTopLeft(find.text('reading')).dx;
        expect(previousReadingPos, greaterThan(20.0));

        await tester.pump(const Duration(milliseconds: 100));
        double midReadingPos = tester.getTopLeft(find.text('reading')).dx;
        expect(midReadingPos, lessThan(previousReadingPos));
        expect(midReadingPos, greaterThan(20.0));

        await tester.pump(const Duration(milliseconds: 150));
        double nearEndReadingPos = tester.getTopLeft(find.text('reading')).dx;
        expect(nearEndReadingPos, lessThan(midReadingPos));
        expect(nearEndReadingPos, greaterThanOrEqualTo(20.0));

        // Finish the animation to rest
        await tester.pumpAndSettle();
        final finalReadingPos = tester.getTopLeft(find.text('reading')).dx;
        expect(finalReadingPos, equals(20.0));

        // The delta between near-end frame and resting state must be continuous
        expect((nearEndReadingPos - finalReadingPos).abs(), lessThan(8.0));
      },
    );
  });

  group('MetroPivotController unit tests', () {
    test('initializes with correct properties', () {
      final controller = MetroPivotController(length: 4, initialIndex: 1);
      addTearDown(controller.dispose);

      expect(controller.length, 4);
      expect(controller.index, 1);
      expect(controller.previousIndex, isNull);
      expect(controller.page, 1.0);
    });

    test('updatePage clamps within bounds and notifies listeners', () {
      final controller = MetroPivotController(length: 3, initialIndex: 0);
      addTearDown(controller.dispose);

      var notified = false;
      controller.addListener(() => notified = true);

      controller.updatePage(1.6);
      expect(notified, isTrue);
      expect(controller.page, 1.6);
      expect(controller.index, 2);
      expect(controller.previousIndex, 0);

      // Clamping bounds
      controller.updatePage(5.0);
      expect(controller.page, 2.0);

      controller.updatePage(-2.0);
      expect(controller.page, 0.0);
    });

    test('jumpTo updates index and previousIndex immediately', () {
      final controller = MetroPivotController(length: 4, initialIndex: 0);
      addTearDown(controller.dispose);

      controller.jumpTo(3);
      expect(controller.index, 3);
      expect(controller.previousIndex, 0);
      expect(controller.page, 3.0);
    });
  });
}
