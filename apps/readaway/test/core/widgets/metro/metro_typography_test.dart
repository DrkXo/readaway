import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

void main() {
  Widget buildThemed(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          VsCodeThemeExtension(
            MetroColorScheme.kanagawaDragon.toVsCodeTheme(),
          ),
        ],
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MetroTypography tokens', () {
    test('defines authentic Swiss / Lumia scale', () {
      expect(MetroTypography.pivotTitle.fontSize, 54);
      expect(MetroTypography.pivotTitle.fontWeight, FontWeight.w300);

      expect(MetroTypography.pivotItemActive.fontSize, 34);
      expect(MetroTypography.pivotItemActive.fontWeight, FontWeight.w600);

      expect(MetroTypography.pivotItemInactive.fontSize, 26);
      expect(MetroTypography.pivotItemInactive.fontWeight, FontWeight.w300);

      expect(MetroTypography.bottomAction.fontSize, 18);
      expect(MetroTypography.bottomAction.fontWeight, FontWeight.w400);

      expect(MetroTypography.tileTitle.fontSize, 14);
      expect(MetroTypography.tileTitle.fontWeight, FontWeight.w600);

      expect(MetroTypography.tileNumber.fontSize, 38);
      expect(MetroTypography.tileNumber.fontWeight, FontWeight.w700);

      expect(MetroTypography.tag.fontSize, 10);
      expect(MetroTypography.tag.letterSpacing, 1.5);
    });
  });

  group('MetroText widgets', () {
    testWidgets('renders pivotTitle and formats properly', (tester) async {
      await tester.pumpWidget(
        buildThemed(const MetroText.pivotTitle('library')),
      );

      final textFinder = find.text('library');
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.style?.fontSize, 54);
      expect(text.style?.fontWeight, FontWeight.w300);
    });

    testWidgets('renders tag with uppercase transformation', (tester) async {
      await tester.pumpWidget(
        buildThemed(const MetroText.tag('epub')),
      );

      expect(find.text('EPUB'), findsOneWidget);
    });

    testWidgets('renders pivotItem with active and inactive sizes and colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          const Column(
            children: [
              MetroText.pivotItem('active item', isActive: true),
              MetroText.pivotItem('inactive item', isActive: false),
            ],
          ),
        ),
      );

      final activeText = tester.widget<Text>(find.text('active item'));
      final inactiveText = tester.widget<Text>(find.text('inactive item'));

      expect(activeText.style?.fontSize, 34);
      expect(inactiveText.style?.fontSize, 26);

      expect(activeText.style?.color, isNotNull);
      expect(inactiveText.style?.color, isNotNull);
      expect(activeText.style?.color != inactiveText.style?.color, isTrue);
    });

    testWidgets('renders bottomAction with authentic 18sp typography', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(const MetroText.bottomAction('open')),
      );

      final textFinder = find.text('open');
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.style?.fontSize, 18);
      expect(text.style?.fontWeight, FontWeight.w400);
    });
  });
}
