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
          VsCodeThemeExtension(BuiltinVsCodeThemes.kanagawaDragon),
        ],
      ),
      home: Scaffold(
        bottomNavigationBar: child,
        body: const Center(child: Text('Main Body')),
      ),
    );
  }

  group('MetroAppBar', () {
    testWidgets('renders action buttons with icons and lowercase labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildThemed(
          MetroAppBar(
            actions: [
              MetroAppBarAction(
                icon: LucideIcons.plus,
                label: 'Add',
                onTap: () {},
              ),
              MetroAppBarAction(
                icon: LucideIcons.search,
                label: 'Search',
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.text('add'), findsOneWidget);

      expect(find.byIcon(LucideIcons.search), findsOneWidget);
      expect(find.text('search'), findsOneWidget);
    });

    testWidgets('triggers action callback when tapped', (tester) async {
      var actionTapped = false;

      await tester.pumpWidget(
        buildThemed(
          MetroAppBar(
            actions: [
              MetroAppBarAction(
                icon: LucideIcons.plus,
                label: 'Add',
                onTap: () => actionTapped = true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('add'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
    });

    testWidgets(
      'opens more menu sheet on ellipsis tap and triggers menu callback',
      (tester) async {
        var menuActionTapped = false;

        await tester.pumpWidget(
          buildThemed(
            MetroAppBar(
              actions: [
                MetroAppBarAction(
                  icon: LucideIcons.plus,
                  label: 'Add',
                  onTap: () {},
                ),
              ],
              menuItems: [
                MetroAppBarMenuItem(
                  label: 'Settings',
                  icon: LucideIcons.settings,
                  onTap: () => menuActionTapped = true,
                ),
              ],
            ),
          ),
        );

        // Verify "more" button exists
        expect(find.text('more'), findsOneWidget);

        // Tap "more" to open sheet
        await tester.tap(find.text('more'));
        await tester.pumpAndSettle();

        // Menu item should appear in modal sheet
        expect(find.text('settings'), findsOneWidget);
        expect(find.byIcon(LucideIcons.settings), findsOneWidget);

        // Tap menu item
        await tester.tap(find.text('settings'));
        await tester.pumpAndSettle();

        expect(menuActionTapped, isTrue);
        // Sheet should be dismissed
        expect(find.text('settings'), findsNothing);
      },
    );
  });
}
