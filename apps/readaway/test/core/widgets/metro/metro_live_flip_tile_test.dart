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
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('MetroLiveFlipTile', () {
    testWidgets('displays front face initially', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroLiveFlipTile(
            front: Text('Front Content'),
            back: Text('Back Content'),
          ),
        ),
      );

      expect(find.text('Front Content'), findsOneWidget);
    });

    testWidgets('flips to back face on tap', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroLiveFlipTile(
            front: Text('Front Face'),
            back: Text('Back Face'),
            flipDuration: Duration(milliseconds: 200),
          ),
        ),
      );

      expect(find.text('Front Face'), findsOneWidget);

      await tester.tap(find.text('Front Face'));
      await tester.pumpAndSettle();

      expect(find.text('Back Face'), findsOneWidget);
    });

    testWidgets('flips back and forth programmatically via state key', (
      tester,
    ) async {
      final key = GlobalKey<MetroLiveFlipTileState>();

      await tester.pumpWidget(
        buildThemed(
          MetroLiveFlipTile(
            key: key,
            front: const Text('Side A'),
            back: const Text('Side B'),
            flipDuration: const Duration(milliseconds: 200),
          ),
        ),
      );

      expect(key.currentState?.isFront, isTrue);

      key.currentState?.flip();
      await tester.pumpAndSettle();

      expect(key.currentState?.isFront, isFalse);
      expect(find.text('Side B'), findsOneWidget);

      key.currentState?.flip();
      await tester.pumpAndSettle();

      expect(key.currentState?.isFront, isTrue);
      expect(find.text('Side A'), findsOneWidget);
    });

    testWidgets('respects disableAnimations MediaQuery setting', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          disableAnimations: true,
          const MetroLiveFlipTile(
            front: Text('Instant Front'),
            back: Text('Instant Back'),
          ),
        ),
      );

      expect(find.text('Instant Front'), findsOneWidget);

      await tester.tap(find.text('Instant Front'));
      await tester.pump();

      // With disableAnimations, flipping happens immediately without animation curves
      expect(find.text('Instant Back'), findsOneWidget);
    });

    testWidgets('updates periodic flipping when its configuration changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroLiveFlipTile(
            front: Text('Dynamic Front'),
            back: Text('Dynamic Back'),
            autoFlip: false,
            flipInterval: Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Dynamic Front'), findsOneWidget);

      await tester.pumpWidget(
        buildThemed(
          const MetroLiveFlipTile(
            front: Text('Dynamic Front'),
            back: Text('Dynamic Back'),
            autoFlip: true,
            flipInterval: Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 110));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Dynamic Back'), findsOneWidget);
    });
  });
}
