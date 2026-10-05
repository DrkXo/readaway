import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readaway/src/features/settings/presentation/widgets/settings_sheet.dart';
import 'package:readaway/src/router/router.dart';

/// The settings sheet is a single modal managed as a ShellRoute.
/// Sub-pages push within the shell's nested navigator instead of opening a
/// second modal on top of it.
void main() {
  const manageKey = Key('manage-fonts');
  const closeKey = Key('close');
  const backKey = Key('back');
  const subPageLabel = 'sub-page';

  testWidgets('SettingsSheet renders chrome with child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsSheet(
            child: Text('settings content'),
          ),
        ),
      ),
    );

    expect(find.text('settings content'), findsOneWidget);
    expect(find.byType(SettingsSheet), findsOneWidget);
  });

  group('ShellRoute settings sheet navigation', () {
    late GlobalKey<NavigatorState> rootNavKey;
    late GlobalKey<NavigatorState> settingsNavKey;
    late GoRouter testRouter;

    setUp(() {
      rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');
      settingsNavKey = GlobalKey<NavigatorState>(debugLabel: 'settings');
      testRouter = GoRouter(
        navigatorKey: rootNavKey,
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('open settings'),
                ),
              ),
            ),
          ),
          ShellRoute(
            navigatorKey: settingsNavKey,
            parentNavigatorKey: rootNavKey,
            pageBuilder: (context, state, child) => ModalPage(
              key: const ValueKey('settings-modal'),
              isScrollControlled: true,
              showDragHandle: false,
              builder: (context) => SettingsSheet(child: child),
            ),
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const _Tabs(
                  manageKey: manageKey,
                  closeKey: closeKey,
                ),
                routes: [
                  GoRoute(
                    path: 'sub-page',
                    builder: (context, state) => const _SubPage(
                      label: subPageLabel,
                      backKey: backKey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });

    Widget buildApp() {
      return MaterialApp.router(routerConfig: testRouter);
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

    testWidgets(
      'the back arrow returns to the tabs with the sheet still open',
      (
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
      },
    );

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

    testWidgets(
      'pushing settings and then sub-page keeps one sheet and returns to tabs on back',
      (tester) async {
        await tester.pumpWidget(buildApp());
        testRouter.push('/settings');
        await tester.pumpAndSettle();
        expect(find.text('tabs'), findsOneWidget);

        testRouter.push('/settings/sub-page');
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(subPageLabel), findsOneWidget);

        await tester.tap(find.byKey(backKey));
        await tester.pumpAndSettle();

        expect(find.text(subPageLabel), findsNothing);
        expect(find.text('tabs'), findsOneWidget);
        expect(find.byType(BottomSheet), findsOneWidget);
      },
    );
  });
}

/// Stand-in for the tabbed settings page: a "manage" row that pushes a
/// sub-page, and the sheet's close button.
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.manageKey,
    required this.closeKey,
  });

  final Key manageKey;
  final Key closeKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('tabs'),
        TextButton(
          key: manageKey,
          onPressed: () => context.push('/settings/sub-page'),
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
        KeyedSubtree(
          key: backKey,
          child: const SettingsSheetBackButton(),
        ),
      ],
    );
  }
}
