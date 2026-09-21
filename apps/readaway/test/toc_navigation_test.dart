import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/features/reader/presentation/widgets/toc/outline_item_tile.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
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
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Prologue'), findsOneWidget);

      await tester.tap(find.text('Prologue'));
      expect(tapped, isTrue);
    });

    testWidgets('marks the current row and exposes a semantic Chapter label', (
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
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Chapter 1: The Heart of a Demon'), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(OutlineItemTile));
      expect(semantics.label, contains('Chapter 2'));
      expect(
        semantics.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
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
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(OutlineItemTile));
      expect(semantics.label, contains('Introduction to Algorithms'));
      expect(semantics.label, isNot(contains('Chapter')));
    });

    testWidgets('parent rows show a chevron and a toggled semantic state', (
      tester,
    ) async {
      final item = OutlineItem(
        title: 'Volume 1',
        href: 'OEBPS/vol1.xhtml',
        chapterIndex: 0,
        level: 0,
        children: [
          OutlineItem(
            title: 'Chapter 1',
            href: 'OEBPS/c1.xhtml',
            chapterIndex: 0,
            level: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: false,
              isExpanded: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);

      final expandedFlags = tester
          .getSemantics(find.byType(OutlineItemTile))
          .getSemanticsData()
          .flagsCollection;
      expect(expandedFlags.isToggled, Tristate.isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineItemTile(
              item: item,
              isCurrent: false,
              isExpanded: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final collapsedFlags = tester
          .getSemantics(find.byType(OutlineItemTile))
          .getSemanticsData()
          .flagsCollection;
      expect(collapsedFlags.isToggled, Tristate.isFalse);
    });
  });
}
