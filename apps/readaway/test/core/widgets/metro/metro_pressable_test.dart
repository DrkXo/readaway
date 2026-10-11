import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

void main() {
  Widget buildThemed(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          VsCodeThemeExtension(
            MetroColorScheme.kanagawaDragon.toVsCodeTheme(),
          ),
        ],
      ),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('MetroPressable', () {
    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          MetroPressable(
            onTap: () {},
            child: const Text('Pressable Tile'),
          ),
        ),
      );

      expect(find.text('Pressable Tile'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildThemed(
          MetroPressable(
            onTap: () => tapped = true,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onLongPress callback when long pressed', (
      tester,
    ) async {
      var longPressed = false;

      await tester.pumpWidget(
        buildThemed(
          MetroPressable(
            onLongPress: () => longPressed = true,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Text('Hold Me'),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Hold Me'));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets('does not trigger callbacks when enabled is false', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        buildThemed(
          MetroPressable(
            enabled: false,
            onTap: () => tapped = true,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Text('Disabled'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('applies 3D perspective matrix tilt on pointer down', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          MetroPressable(
            onTap: () {},
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Text('Tilt Target'),
            ),
          ),
        ),
      );

      // Initially no Transform with perspective
      final gesture = await tester.createGesture();
      final targetCenter = tester.getCenter(find.text('Tilt Target'));

      // Press down near bottom-right to cause tilt
      await gesture.down(targetCenter + const Offset(30, 30));
      await tester.pumpAndSettle();

      // Locate Transform widgets inside MetroPressable
      final transformFinder = find.descendant(
        of: find.byType(MetroPressable),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsOneWidget);

      final transform = tester.widget<Transform>(transformFinder);
      expect((transform.transform.entry(3, 2) - 0.0015).abs() < 0.0005, isTrue);

      // Release pointer
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('respects disableAnimations MediaQuery setting', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          disableAnimations: true,
          MetroPressable(
            onTap: () {},
            child: const SizedBox(
              width: 100,
              height: 100,
              child: Text('Instant Tilt'),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture();
      final targetCenter = tester.getCenter(find.text('Instant Tilt'));

      await gesture.down(targetCenter + const Offset(20, 20));
      await tester.pump();

      // With disableAnimations, controller immediately snaps to 1.0
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final tiltedTransform = transforms.firstWhere(
        (t) => (t.transform.entry(3, 2) - 0.0015).abs() < 0.0005,
      );
      expect(tiltedTransform, isNotNull);

      await gesture.up();
      await tester.pump();
    });
  });
}
