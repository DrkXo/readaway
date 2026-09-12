import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mupdf/mupdf.dart';
import 'package:readaway/src/features/reader/presentation/widgets/toc/outline_item_tile.dart';

void main() {
  const threadColors = [Colors.blue, Colors.green, Colors.purple];

  group('OutlineItemTile Widget Tests', () {
    testWidgets('renders outline title and handles tap correctly', (tester) async {
      var tapped = false;
      final item = OutlineItem(
        title: 'Prologue',
        uri: 'OEBPS/intro.xhtml',
        chapter: 0,
        page: 0,
        level: 0,
        isOpen: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: false,
              threadColors: threadColors,
              isReflowable: true,
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

    testWidgets('displays Current badge and semantic Chapter label for reflowable docs', (tester) async {
      final item = OutlineItem(
        title: 'Chapter 1: The Heart of a Demon',
        uri: 'OEBPS/c1.xhtml',
        chapter: 1,
        page: 16,
        level: 0,
        isOpen: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: true,
              threadColors: threadColors,
              isReflowable: true,
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

    testWidgets('displays Page label for fixed-layout (PDF) docs', (tester) async {
      final item = OutlineItem(
        title: 'Introduction to Algorithms',
        chapter: -1,
        page: 15,
        level: 0,
        isOpen: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: false,
              threadColors: threadColors,
              isReflowable: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(OutlineItemTile));
      expect(semantics.label, contains('Page 16'));
    });
  });
}
