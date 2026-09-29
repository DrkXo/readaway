import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/settings/presentation/widgets/settings_sheet.dart';

/// The settings sheet is a single modal, so a sub-page has to push *inside* it.
///
/// These tests drive the real [SettingsSheet] the same way a panel does —
/// [pushSettingsPage] from a row inside the sheet — and assert the result: one
/// sheet, the sub-page stacked on the tabs, and a back arrow that returns to
/// the tabs rather than dismissing the sheet.
void main() {
  const manageKey = Key('manage-fonts');
  const closeKey = Key('close');
  const backKey = Key('back');
  const subPageLabel = 'sub-page';

  Widget buildApp() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              // The same route the app's `ModalPage` builds, so the sheet is
              // exercised as a real bottom sheet rather than a plain page.
              onPressed: () => Navigator.of(context).push(
                ModalBottomSheetRoute<void>(
                  isScrollControlled: true,
                  showDragHandle: false,
                  builder: (context) => SettingsSheet(
                    home: _Tabs(
                      manageKey: manageKey,
                      closeKey: closeKey,
                      subPageBackKey: backKey,
                      subPageLabel: subPageLabel,
                    ),
                  ),
                ),
              ),
              child: const Text('open settings'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    expect(find.text('tabs'), findsOneWidget);
  }

  testWidgets('a sub-page pushes inside the sheet, keeping one modal', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.byKey(manageKey));
    await tester.pumpAndSettle();

    // The sub-page is on top, and the tabs are still alive underneath it.
    expect(find.text(subPageLabel), findsOneWidget);
    expect(find.text('tabs', skipOffstage: false), findsOneWidget);

    // One sheet, not two.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(SettingsSheet), findsOneWidget);
  });

  testWidgets('the back arrow returns to the tabs with the sheet still open', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.byKey(manageKey));
    await tester.pumpAndSettle();
    expect(find.text(subPageLabel), findsOneWidget);

    await tester.tap(find.byKey(backKey));
    await tester.pumpAndSettle();

    expect(find.text(subPageLabel), findsNothing);
    expect(find.text('tabs'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets(
    'dismissing the sheet closes it from the tabs and from a sub-page',
    (
      tester,
    ) async {
      await openSheet(tester);

      // From the tabs: the close button pops the root navigator, taking the
      // sheet with it.
      await tester.tap(find.byKey(closeKey));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('open settings'), findsOneWidget);

      // Same from a sub-page: the sheet goes away rather than revealing the tabs.
      await tester.tap(find.text('open settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(manageKey));
      await tester.pumpAndSettle();
      expect(find.text(subPageLabel), findsOneWidget);

      final sheetContext = tester.element(find.byType(SettingsSheet));
      Navigator.of(sheetContext, rootNavigator: true).pop();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(subPageLabel), findsNothing);
    },
  );
}

/// Stand-in for the tabbed settings page: a "manage" row that pushes a
/// sub-page, and the sheet's close button.
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.manageKey,
    required this.closeKey,
    required this.subPageBackKey,
    required this.subPageLabel,
  });

  final Key manageKey;
  final Key closeKey;
  final Key subPageBackKey;
  final String subPageLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('tabs'),
        TextButton(
          key: manageKey,
          onPressed: () => pushSettingsPage(
            context,
            _SubPage(label: subPageLabel, backKey: subPageBackKey),
          ),
          child: const Text('manage'),
        ),
        KeyedSubtree(
          key: closeKey,
          child: const SettingsSheetCloseButton(),
        ),
      ],
    );
  }
}

/// Stand-in for a sub-page such as the voice library or the font list.
class _SubPage extends StatelessWidget {
  const _SubPage({required this.label, required this.backKey});

  final String label;
  final Key backKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        IconButton(
          key: backKey,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
    );
  }
}
