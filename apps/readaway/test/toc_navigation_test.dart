import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/widgets/toc/outline_item_tile.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  const threadColors = [Colors.blue, Colors.green, Colors.purple];

  group('OutlineItemTile Widget Tests', () {
    testWidgets('renders outline title and handles tap correctly', (
      tester,
    ) async {
      var tapped = false;
      final item = OutlineItem(
        title: 'Prologue',
        href: 'OEBPS/intro.xhtml',
        chapterIndex: 0,
        level: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: false,
              threadColors: threadColors,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Prologue'), findsOneWidget);
      expect(find.text('Current'), findsNothing);

      await tester.tap(find.text('Prologue'));
      expect(tapped, isTrue);
    });

    testWidgets('displays Current badge and semantic Chapter label', (
      tester,
    ) async {
      final item = OutlineItem(
        title: 'Chapter 1: The Heart of a Demon',
        href: 'OEBPS/c1.xhtml',
        chapterIndex: 1,
        level: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: true,
              threadColors: threadColors,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Chapter 1: The Heart of a Demon'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(OutlineItemTile));
      expect(semantics.label, contains('Chapter 2'));
    });

    testWidgets('falls back to plain title when chapterIndex is null', (
      tester,
    ) async {
      final item = OutlineItem(
        title: 'Introduction to Algorithms',
        level: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: false,
              threadColors: threadColors,
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(OutlineItemTile));
      expect(semantics.label, contains('Introduction to Algorithms'));
      expect(semantics.label, isNot(contains('Chapter')));
    });
  });
}
