import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({
    required Widget child,
    Size size = const Size(800, 600),
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
        ],
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF181616),
          modalBackgroundColor: Color(0xFF181616),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            side: BorderSide(color: Color(0xFFE82424), width: 1.0),
          ),
        ),
      ),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('showAppSheet Adaptive Behavior', () {
    testWidgets('shows Dialog on wide screen (width >= 600)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1024, 768),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppSheet<void>(
                  context: context,
                  title: 'Test Dialog',
                  builder: (ctx) => const Text('Dialog Content'),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Should be presented as a Dialog, NOT a ModalBottomSheet
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);

      // Verify close button is present and functional
      final closeButton = find.byIcon(LucideIcons.x);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('shows BottomSheet on compact screen (width < 600)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(400, 800),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppSheet<void>(
                  context: context,
                  title: 'Test Sheet',
                  builder: (ctx) => const Text('Sheet Content'),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Should be presented as a BottomSheet, NOT a Dialog
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Test Sheet'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);

      // Verify outer BottomSheet does NOT inherit the theme border on transparent background
      final bottomSheetWidget = tester.widget<BottomSheet>(
        find.byType(BottomSheet),
      );
      expect(
        bottomSheetWidget.shape,
        isA<RoundedRectangleBorder>().having(
          (s) => s.side,
          'side',
          BorderSide.none,
        ),
      );

      // Dismiss via close button
      final closeButton = find.byIcon(LucideIcons.x);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('aligns close button to top-right when title is null', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(800, 600),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppSheet<void>(
                  context: context,
                  builder: (ctx) => const SizedBox(
                    width: 300,
                    height: 100,
                    child: Text('Content Without Title'),
                  ),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Content Without Title'), findsOneWidget);

      final closeButton = find.byIcon(LucideIcons.x);
      expect(closeButton, findsOneWidget);

      // Get the right position of the card and close button
      final cardBox = tester.getRect(find.byType(Dialog));
      final closeBox = tester.getRect(closeButton);

      // Close button should be positioned towards the right side of the card, not left
      expect(closeBox.center.dx, greaterThan(cardBox.center.dx));
    });

    testWidgets('dismisses Dialog on barrier tap', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1024, 768),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppSheet<void>(
                  context: context,
                  title: 'Dismissible Dialog',
                  builder: (ctx) => const Text('Dialog Body'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      // Tap on top-left of the screen outside the dialog card (on the scrim)
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('respects custom maxWidth in Dialog mode', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          size: const Size(1024, 768),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppSheet<void>(
                  context: context,
                  maxWidth: 320,
                  title: 'Custom Width',
                  builder: (ctx) => const Text('Custom Width Content'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final cardFinder = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(ConstrainedBox),
      );
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(cardFinder);
      final matchingBox = constrainedBoxes.firstWhere(
        (cb) => cb.constraints.maxWidth == 320,
      );
      expect(matchingBox.constraints.maxWidth, 320);
    });
  });
}
