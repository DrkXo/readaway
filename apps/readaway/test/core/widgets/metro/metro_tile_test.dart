import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: child,
          ),
        ),
      ),
    );
  }

  group('MetroTile', () {
    testWidgets('renders flat styling with zero border radius', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroTile(
            title: 'Dune',
            subtitle: 'Frank Herbert',
          ),
        ),
      );

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Frank Herbert'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MetroTile),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration?.borderRadius, equals(BorderRadius.zero));
      expect(decoration?.boxShadow, isNull);
    });

    testWidgets('renders counter and icon slots', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroTile(
            title: 'Reading',
            counter: '75%',
            icon: LucideIcons.bookOpen,
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
    });

    testWidgets('renders badge tag in custom child tile', (tester) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroTile(
            badge: 'EPUB',
            child: Text('Custom Book Cover'),
          ),
        ),
      );

      expect(find.text('EPUB'), findsOneWidget);
      expect(find.text('Custom Book Cover'), findsOneWidget);
    });

    testWidgets('renders selection checkbox and highlight in selection mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          const MetroTile(
            title: 'Selected Book',
            isSelectMode: true,
            isSelected: true,
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.check), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MetroTile),
          matching: find.byType(Container).first,
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('triggers onTap and onLongPress callbacks', (tester) async {
      var tapped = false;
      var longPressed = false;

      await tester.pumpWidget(
        buildThemed(
          MetroTile(
            title: 'Action Tile',
            onTap: () => tapped = true,
            onLongPress: () => longPressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Action Tile'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      await tester.longPress(find.text('Action Tile'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });
  });
}
