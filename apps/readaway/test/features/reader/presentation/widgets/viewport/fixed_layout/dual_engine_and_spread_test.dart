import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/reader/presentation/gestures/reader_gesture_arena.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/fixed_layout/fixed_layout_page_shimmer.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/fixed_layout/fixed_layout_spread.dart';

void main() {
  group('FixedLayoutSpreadHelper Unit Tests', () {
    test('isDualSpreadActive respects ReaderPageSpread options', () {
      const portrait = BoxConstraints(maxWidth: 400, maxHeight: 800);
      const landscape = BoxConstraints(maxWidth: 900, maxHeight: 600);

      // Single
      const singlePrefs = ReaderPreferences(
        pageSpread: ReaderPageSpread.single,
      );
      expect(
        FixedLayoutSpreadHelper.isDualSpreadActive(
          prefs: singlePrefs,
          constraints: portrait,
        ),
        isFalse,
      );
      expect(
        FixedLayoutSpreadHelper.isDualSpreadActive(
          prefs: singlePrefs,
          constraints: landscape,
        ),
        isFalse,
      );

      // Dual
      const dualPrefs = ReaderPreferences(pageSpread: ReaderPageSpread.dual);
      expect(
        FixedLayoutSpreadHelper.isDualSpreadActive(
          prefs: dualPrefs,
          constraints: portrait,
        ),
        isTrue,
      );
      expect(
        FixedLayoutSpreadHelper.isDualSpreadActive(
          prefs: dualPrefs,
          constraints: landscape,
        ),
        isTrue,
      );

      // Auto
      const autoPrefs = ReaderPreferences(pageSpread: ReaderPageSpread.auto);
      expect(
        FixedLayoutSpreadHelper.isDualSpreadActive(
          prefs: autoPrefs,
          constraints: portrait,
        ),
        isFalse,
      );
      expect(
        FixedLayoutSpreadHelper.isDualSpreadActive(
          prefs: autoPrefs,
          constraints: landscape,
        ),
        isTrue,
      );
    });

    test(
      'totalSpreads accurately calculates spread count with cover handling',
      () {
        // Single mode
        expect(FixedLayoutSpreadHelper.totalSpreads(0, isDualSpread: false), 0);
        expect(FixedLayoutSpreadHelper.totalSpreads(5, isDualSpread: false), 5);

        // Dual mode: Page 0 is cover, pages [1, 2], [3, 4]
        expect(FixedLayoutSpreadHelper.totalSpreads(0, isDualSpread: true), 0);
        expect(FixedLayoutSpreadHelper.totalSpreads(1, isDualSpread: true), 1);
        // 2 pages: [0], [1] -> 2 spreads
        expect(FixedLayoutSpreadHelper.totalSpreads(2, isDualSpread: true), 2);
        // 3 pages: [0], [1, 2] -> 2 spreads
        expect(FixedLayoutSpreadHelper.totalSpreads(3, isDualSpread: true), 2);
        // 4 pages: [0], [1, 2], [3] -> 3 spreads
        expect(FixedLayoutSpreadHelper.totalSpreads(4, isDualSpread: true), 3);
        // 5 pages: [0], [1, 2], [3, 4] -> 3 spreads
        expect(FixedLayoutSpreadHelper.totalSpreads(5, isDualSpread: true), 3);
        // 6 pages: [0], [1, 2], [3, 4], [5] -> 4 spreads
        expect(FixedLayoutSpreadHelper.totalSpreads(6, isDualSpread: true), 4);
      },
    );

    test('spreadForPage maps document pages to corresponding spreads', () {
      expect(FixedLayoutSpreadHelper.spreadForPage(0, isDualSpread: true), 0);
      expect(FixedLayoutSpreadHelper.spreadForPage(1, isDualSpread: true), 1);
      expect(FixedLayoutSpreadHelper.spreadForPage(2, isDualSpread: true), 1);
      expect(FixedLayoutSpreadHelper.spreadForPage(3, isDualSpread: true), 2);
      expect(FixedLayoutSpreadHelper.spreadForPage(4, isDualSpread: true), 2);
      expect(FixedLayoutSpreadHelper.spreadForPage(5, isDualSpread: true), 3);
    });

    test('primaryPageForSpread retrieves primary page index', () {
      expect(
        FixedLayoutSpreadHelper.primaryPageForSpread(0, isDualSpread: true),
        0,
      );
      expect(
        FixedLayoutSpreadHelper.primaryPageForSpread(1, isDualSpread: true),
        1,
      );
      expect(
        FixedLayoutSpreadHelper.primaryPageForSpread(2, isDualSpread: true),
        3,
      );
      expect(
        FixedLayoutSpreadHelper.primaryPageForSpread(3, isDualSpread: true),
        5,
      );
    });

    test('pagesForSpread resolves pair of pages correctly', () {
      const pageCount = 5;
      // Spread 0: Cover page alone
      final s0 = FixedLayoutSpreadHelper.pagesForSpread(
        0,
        pageCount,
        isDualSpread: true,
      );
      expect(s0.$1, 0);
      expect(s0.$2, isNull);

      // Spread 1: [1, 2]
      final s1 = FixedLayoutSpreadHelper.pagesForSpread(
        1,
        pageCount,
        isDualSpread: true,
      );
      expect(s1.$1, 1);
      expect(s1.$2, 2);

      // Spread 2: [3, 4]
      final s2 = FixedLayoutSpreadHelper.pagesForSpread(
        2,
        pageCount,
        isDualSpread: true,
      );
      expect(s2.$1, 3);
      expect(s2.$2, 4);

      // If document had only 4 pages: Spread 2 would have [3, null]
      final s2Trailing = FixedLayoutSpreadHelper.pagesForSpread(
        2,
        4,
        isDualSpread: true,
      );
      expect(s2Trailing.$1, 3);
      expect(s2Trailing.$2, isNull);
    });
  });

  group('ReaderPreferences Dual-Engine & Manga Extensions Tests', () {
    test('default preferences are configured correctly', () {
      const prefs = ReaderPreferences();
      expect(prefs.pdfEngineMode, equals(PdfEngineMode.vector));
      expect(
        prefs.readingDirection,
        equals(ReaderReadingDirection.leftToRight),
      );
      expect(prefs.isRtl, isFalse);
      expect(prefs.pageSpread, equals(ReaderPageSpread.auto));
    });

    test('isRtl returns true when readingDirection is rightToLeft', () {
      const mangaPrefs = ReaderPreferences(
        readingDirection: ReaderReadingDirection.rightToLeft,
      );
      expect(mangaPrefs.isRtl, isTrue);
    });

    test('JSON serialization round-trip retains new preferences', () {
      const prefs = ReaderPreferences(
        pdfEngineMode: PdfEngineMode.snapshot,
        readingDirection: ReaderReadingDirection.rightToLeft,
        pageSpread: ReaderPageSpread.dual,
      );

      final json = prefs.toJson();
      final restored = ReaderPreferences.fromJson(json);

      expect(restored.pdfEngineMode, equals(PdfEngineMode.snapshot));
      expect(
        restored.readingDirection,
        equals(ReaderReadingDirection.rightToLeft),
      );
      expect(restored.isRtl, isTrue);
      expect(restored.pageSpread, equals(ReaderPageSpread.dual));
    });
  });

  group('ReaderGestureArena RTL Inversion Tests', () {
    testWidgets('inverts drag normalized delta when isRtl is true', (
      tester,
    ) async {
      double? receivedNormalizedDelta;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ReaderGestureArena(
                isRtl: true,
                isVerticalPaging: false,
                onTapAction: (_) {},
                onPageDragUpdate: (primary, normalized) {
                  receivedNormalizedDelta = normalized;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      // Drag to the right (dx: 100): in LTR that is going backward (normalized < 0).
      // In RTL, dragging right moves forward (normalized > 0).
      final gesture = await tester.startGesture(const Offset(100, 300));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.up();

      expect(receivedNormalizedDelta, isNotNull);
      expect(receivedNormalizedDelta!, greaterThan(0));
    });
  });

  group('FixedLayoutPageShimmer Widget Tests', () {
    testWidgets('renders shimmer with given page number and aspect ratio', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
            ],
          ),
          home: const Scaffold(
            body: FixedLayoutPageShimmer(
              pageIndex: 11,
              aspectRatio: 0.75,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('12'),
        findsOneWidget,
      ); // page 11 (0-based) displays as "12"
      expect(find.byType(AspectRatio), findsOneWidget);
      final aspectRatioWidget = tester.widget<AspectRatio>(
        find.byType(AspectRatio),
      );
      expect(aspectRatioWidget.aspectRatio, equals(0.75));
    });
  });
}
