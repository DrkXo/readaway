import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart'
    show HyperSelectionAnchorDetails, HyperSelectionAnchorType;
import 'package:readaway/src/features/reader/presentation/widgets/selection/reader_selection_anchor.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

HyperSelectionAnchorDetails _createTestDetails({
  HyperSelectionAnchorType type = HyperSelectionAnchorType.start,
  bool isDragging = false,
  Color handleColor = Colors.blue,
  Rect rect = const Rect.fromLTWH(10, 20, 10, 16),
  String? selectedText = 'Sample selection',
}) {
  final anchorPoint = type == HyperSelectionAnchorType.start
      ? Offset(rect.left, rect.top)
      : Offset(rect.right, rect.bottom);

  return HyperSelectionAnchorDetails(
    type: type,
    rect: rect,
    anchorPoint: anchorPoint,
    isDragging: isDragging,
    handleColor: handleColor,
    textDirection: TextDirection.ltr,
    selectedText: selectedText,
    defaultHandle: const SizedBox(width: 22, height: 22),
    defaultOffset: anchorPoint,
  );
}

void main() {
  group('ReaderSelectionAnchor', () {
    testWidgets('renders start anchor with 44x44 hitbox and semantics', (
      tester,
    ) async {
      final details = _createTestDetails(type: HyperSelectionAnchorType.start);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderSelectionAnchor(
              details: details,
              enableHaptics: false,
            ),
          ),
        ),
      );

      final sizedBoxFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 44 && w.height == 44,
      );
      expect(sizedBoxFinder, findsOneWidget);

      final semanticsFinder = find.bySemanticsLabel('Selection start handle');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('renders end anchor with 44x44 hitbox and semantics', (
      tester,
    ) async {
      final details = _createTestDetails(type: HyperSelectionAnchorType.end);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderSelectionAnchor(
              details: details,
              enableHaptics: false,
            ),
          ),
        ),
      );

      final semanticsFinder = find.bySemanticsLabel('Selection end handle');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('animates scale on isDragging transition', (tester) async {
      final restingDetails = _createTestDetails(isDragging: false);
      final draggingDetails = _createTestDetails(isDragging: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderSelectionAnchor(
              details: restingDetails,
              enableHaptics: false,
            ),
          ),
        ),
      );

      final initialScale = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(initialScale.scale, 1.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderSelectionAnchor(
              details: draggingDetails,
              enableHaptics: false,
            ),
          ),
        ),
      );

      final draggingScale = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(draggingScale.scale, 1.2);

      // Verify animation settles
      await tester.pumpAndSettle();
    });

    testWidgets('renders all ReaderAnchorStyle variants without error', (
      tester,
    ) async {
      for (final style in ReaderAnchorStyle.values) {
        for (final type in HyperSelectionAnchorType.values) {
          final details = _createTestDetails(type: type, isDragging: true);

          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: Scaffold(
                body: ReaderSelectionAnchor(
                  details: details,
                  style: style,
                  enableHaptics: false,
                ),
              ),
            ),
          );

          expect(find.byType(ReaderSelectionAnchor), findsOneWidget);
        }
      }
    });

    testWidgets('builder factory returns valid ReaderSelectionAnchor widget', (
      tester,
    ) async {
      final builder = ReaderSelectionAnchor.builder(
        style: ReaderAnchorStyle.lollipop,
        enableHaptics: false,
      );

      final details = _createTestDetails();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => builder(ctx, details),
            ),
          ),
        ),
      );

      final anchorFinder = find.byType(ReaderSelectionAnchor);
      expect(anchorFinder, findsOneWidget);

      final anchorWidget = tester.widget<ReaderSelectionAnchor>(anchorFinder);
      expect(anchorWidget.style, ReaderAnchorStyle.lollipop);
    });
  });
}
