import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/gestures/reader_gesture_arena.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        expect(lastPrimaryDelta!, lessThan(0)); // upward is negative primary delta
        expect(lastNormalizedDelta!, greaterThan(0)); // normalized advances forward

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
  });
}
