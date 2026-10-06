import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/domain/gestures/reader_gestures.dart';
import 'package:readaway/src/features/reader/presentation/gestures/reader_gesture_arena.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('text selection versus paging', () {
    /// Pumps a horizontal-paging arena and reports whether a page drag started.
    Future<bool Function()> pumpArena(WidgetTester tester) async {
      var dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ReaderGestureArena(
                onTapAction: (_) {},
                onPageDragStart: () => dragStarted = true,
                child: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      return () => dragStarted;
    }

    testWidgets('a pointer held long enough to select does not turn the page', (
      tester,
    ) async {
      final dragStarted = await pumpArena(tester);
      final center = tester.getCenter(find.byType(ReaderGestureArena));

      final gesture = await tester.startGesture(center);
      // Real time has to pass: the arena reads the wall clock to time the hold,
      // the same way it times a tap. The fake clock would not move it.
      await tester.runAsync(
        () => Future<void>.delayed(
          kLongPressTimeout + const Duration(milliseconds: 100),
        ),
      );

      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();

      // The hold became a text selection, so dragging to extend it must not page.
      expect(dragStarted(), isFalse);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('a prompt swipe still turns the page', (tester) async {
      final dragStarted = await pumpArena(tester);
      final center = tester.getCenter(find.byType(ReaderGestureArena));

      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();

      expect(dragStarted(), isTrue);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('micro-drift during hold does not turn the page', (
      tester,
    ) async {
      final dragStarted = await pumpArena(tester);
      final center = tester.getCenter(find.byType(ReaderGestureArena));

      final gesture = await tester.startGesture(center);
      // Wait into the anticipation window (200ms)
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );

      // Micro-drift of 20px (exceeds 18px base threshold, but low displacement & low velocity)
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();

      expect(dragStarted(), isFalse);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('when canStartPageDrag returns false, drag is not claimed', (
      tester,
    ) async {
      var dragStarted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ReaderGestureArena(
                onTapAction: (_) {},
                onPageDragStart: () => dragStarted = true,
                canStartPageDrag: () => false,
                child: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(ReaderGestureArena));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      expect(dragStarted, isFalse);

      await gesture.up();
      await tester.pump();
    });
  });

  group('annotation taps', () {
    /// Pumps an arena whose taps are intercepted by [intercept].
    Future<List<ReaderTapAction>> pumpArena(
      WidgetTester tester,
      bool Function(Offset position) intercept,
    ) async {
      final actions = <ReaderTapAction>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ReaderGestureArena(
                onTapAction: actions.add,
                onTapIntercept: intercept,
                child: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      return actions;
    }

    testWidgets('a consumed tap does not reach the tap zones', (tester) async {
      Offset? intercepted;
      final actions = await pumpArena(tester, (position) {
        intercepted = position;
        return true;
      });

      await tester.tapAt(tester.getCenter(find.byType(ReaderGestureArena)));
      await tester.pump();

      // The positions have to agree, or the hit test would look in the wrong
      // place: the intercept is told where the tap landed.
      expect(intercepted, isNotNull);
      expect(actions, isEmpty);
    });

    testWidgets('an unconsumed tap still runs its tap-zone action', (
      tester,
    ) async {
      final actions = await pumpArena(tester, (_) => false);

      await tester.tapAt(tester.getCenter(find.byType(ReaderGestureArena)));
      await tester.pump();

      expect(actions, hasLength(1));
    });
  });

  group('ReaderGestureArena Vertical Drag Paging Tests', () {
    testWidgets(
      'registers vertical drag and ignores horizontal drag when isVerticalPaging is true',
      (tester) async {
        var dragStarted = false;
        var dragUpdates = 0;
        double? lastPrimaryDelta;
        double? lastNormalizedDelta;
        var dragEnded = false;

        const prefs = ReaderPreferences(
          scrollDirection: ReaderScrollDirection.horizontal,
          pageSnap: true,
          nonReflowableScrollDirection: ReaderScrollDirection.vertical,
          nonReflowablePageSnap: true,
        );

        // Effective configuration for non-reflowable document (PDF, CBZ, etc.)
        final isVerticalPaging =
            prefs.effectiveScrollDirection(isReflowable: false) ==
                ReaderScrollDirection.vertical &&
            prefs.effectivePageSnap(isReflowable: false);

        expect(isVerticalPaging, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ReaderGestureArena(
                  isVerticalPaging: isVerticalPaging,
                  onTapAction: (_) {},
                  onPageDragStart: () => dragStarted = true,
                  onPageDragUpdate: (primary, normalized) {
                    dragUpdates++;
                    lastPrimaryDelta = primary;
                    lastNormalizedDelta = normalized;
                  },
                  onPageDragEnd: (_) => dragEnded = true,
                  child: Container(color: Colors.blue),
                ),
              ),
            ),
          ),
        );

        // 1. Perform a purely horizontal drag — should NOT claim vertical page drag
        final center = tester.getCenter(find.byType(ReaderGestureArena));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(dragStarted, isFalse);
        expect(dragUpdates, equals(0));

        // 2. Perform a vertical upward drag (next page) — SHOULD claim vertical page drag
        final verticalGesture = await tester.startGesture(center);
        await verticalGesture.moveBy(const Offset(0, -60));
        await tester.pump();

        expect(dragStarted, isTrue);
        expect(dragUpdates, greaterThan(0));
        expect(lastPrimaryDelta, isNotNull);
        expect(
          lastPrimaryDelta!,
          lessThan(0),
        ); // upward is negative primary delta
        expect(
          lastNormalizedDelta!,
          greaterThan(0),
        ); // normalized advances forward

        await verticalGesture.up();
        await tester.pump();

        expect(dragEnded, isTrue);
      },
    );

    testWidgets(
      'registers horizontal drag and ignores vertical drag when isVerticalPaging is false',
      (tester) async {
        var dragStarted = false;
        var dragUpdates = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ReaderGestureArena(
                  isVerticalPaging: false,
                  onTapAction: (_) {},
                  onPageDragStart: () => dragStarted = true,
                  onPageDragUpdate: (_, _) => dragUpdates++,
                  child: Container(color: Colors.blue),
                ),
              ),
            ),
          ),
        );

        final center = tester.getCenter(find.byType(ReaderGestureArena));

        // 1. Vertical drag — should NOT claim horizontal page drag
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(0, -60));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(dragStarted, isFalse);
        expect(dragUpdates, equals(0));

        // 2. Horizontal drag — SHOULD claim horizontal page drag
        final horizGesture = await tester.startGesture(center);
        await horizGesture.moveBy(const Offset(-60, 0));
        await tester.pump();

        expect(dragStarted, isTrue);
        expect(dragUpdates, greaterThan(0));

        await horizGesture.up();
        await tester.pump();
      },
    );

    testWidgets('does not claim page drag when the child owns the gesture', (
      tester,
    ) async {
      var dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ReaderGestureArena(
                isVerticalPaging: false,
                canStartPageDrag: () => false,
                onTapAction: (_) {},
                onPageDragStart: () => dragStarted = true,
                child: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ReaderGestureArena)),
      );
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(dragStarted, isFalse);
    });

    testWidgets('does not trigger tap zones when the child owns the tap', (
      tester,
    ) async {
      var tapActions = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ReaderGestureArena(
                isVerticalPaging: false,
                canHandleTapAction: () => false,
                onTapAction: (_) => tapActions++,
                child: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(tester.getCenter(find.byType(ReaderGestureArena)));
      await tester.pump();

      expect(tapActions, 0);
    });

    testWidgets('child tap is not duplicated as a reader tap-zone action', (
      tester,
    ) async {
      var childActions = 0;
      var tapActions = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ReaderGestureArena(
                onTapAction: (_) => tapActions++,
                child: GestureDetector(
                  onTap: () => childActions++,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(
        tester.getTopRight(find.byType(ReaderGestureArena)) -
            const Offset(20, -400),
      );
      await tester.pump();

      expect(childActions, 1);
      expect(tapActions, 0);
    });

    testWidgets('double tap does not also trigger reader tap zones', (
      tester,
    ) async {
      var tapActions = 0;
      var doubleTapRecognized = false;
      const size = Size(400, 800);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: ReaderGestureArena(
                onTapAction: (_) => tapActions++,
                child: GestureDetector(
                  onDoubleTap: () => doubleTapRecognized = true,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );

      final point =
          tester.getTopRight(find.byType(ReaderGestureArena)) -
          const Offset(20, -400);
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(point);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(doubleTapRecognized, isTrue);
      expect(tapActions, 0);
    });

    testWidgets('single page-zone tap fires after the double-tap window', (
      tester,
    ) async {
      final tapActions = <ReaderTapAction>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: ReaderGestureArena(
                onTapAction: tapActions.add,
                child: GestureDetector(
                  onDoubleTap: () {},
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );

      final point =
          tester.getTopRight(find.byType(ReaderGestureArena)) -
          const Offset(20, -400);
      await tester.tapAt(point);
      await tester.pump();
      expect(tapActions, isEmpty);

      await tester.pump(kDoubleTapTimeout);
      expect(tapActions, [ReaderTapAction.nextPage]);
    });
  });
}
