import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

void main() {
  group('MetroPivotTransition & MetroTurnstileTransition', () {
    testWidgets('renders child content with animation', (tester) async {
      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 260),
      );
      final secAnimController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 220),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MetroPivotTransition(
            animation: animController,
            secondaryAnimation: secAnimController,
            child: const Text('Pivot Content'),
          ),
        ),
      );

      expect(find.text('Pivot Content'), findsOneWidget);

      animController.value = 1.0;
      await tester.pump();

      expect(find.text('Pivot Content'), findsOneWidget);

      animController.dispose();
      secAnimController.dispose();
    });

    testWidgets('respects disableMotion media query', (tester) async {
      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 260),
      );
      final secAnimController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 220),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: MetroPivotTransition(
              animation: animController,
              secondaryAnimation: secAnimController,
              child: const Text('Reduced Motion'),
            ),
          ),
        ),
      );

      expect(find.text('Reduced Motion'), findsOneWidget);

      animController.dispose();
      secAnimController.dispose();
    });

    testWidgets(
      'animates through secondary animation exit and returns to idle',
      (
        tester,
      ) async {
        final animController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 260),
          value: 1.0,
        );
        final secAnimController = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 220),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MetroPivotTransition(
              animation: animController,
              secondaryAnimation: secAnimController,
              child: const Text('Secondary Test Page'),
            ),
          ),
        );

        expect(find.text('Secondary Test Page'), findsOneWidget);

        // Trigger secondary exit
        secAnimController.forward();
        await tester.pump(const Duration(milliseconds: 110));
        expect(find.text('Secondary Test Page'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Secondary Test Page'), findsOneWidget);

        animController.dispose();
        secAnimController.dispose();
      },
    );

    testWidgets('legacy MetroTurnstileTransition operates identically', (
      tester,
    ) async {
      final animController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 260),
      );
      final secAnimController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 220),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MetroTurnstileTransition(
            animation: animController,
            secondaryAnimation: secAnimController,
            child: const Text('Legacy Turnstile Content'),
          ),
        ),
      );

      expect(find.text('Legacy Turnstile Content'), findsOneWidget);

      animController.value = 1.0;
      await tester.pump();
      expect(find.text('Legacy Turnstile Content'), findsOneWidget);

      animController.dispose();
      secAnimController.dispose();
    });

    testWidgets('metroStaggerEntrance applies staggered entrance animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Column(
                children: [
                  const Text('Item 0').metroStaggerEntrance(
                    context: context,
                    index: 0,
                  ),
                  const Text('Item 1').metroStaggerEntrance(
                    context: context,
                    index: 1,
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });
  });

  group('MetroPivotPage & MetroPivotTransitionsBuilder', () {
    test('creates custom route with MetroPivotTransition durations', () {
      final page = MetroPivotPage(
        child: const Text('Page Child'),
      );
      expect(page.transitionDuration, const Duration(milliseconds: 260));
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 220));

      final legacyPage = MetroTurnstilePage(
        child: const Text('Legacy Child'),
      );
      expect(legacyPage.transitionDuration, const Duration(milliseconds: 260));
      expect(
        legacyPage.reverseTransitionDuration,
        const Duration(milliseconds: 220),
      );
    });

    testWidgets('navigates with GoRouter and MetroPivotPage', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => MetroPivotPage(
              key: state.pageKey,
              child: Scaffold(
                body: TextButton(
                  onPressed: () => context.push('/details'),
                  child: const Text('Go to Details'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/details',
            pageBuilder: (context, state) => MetroPivotPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Text('Details Screen'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('Go to Details'), findsOneWidget);

      await tester.tap(find.text('Go to Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 130));
      expect(find.text('Details Screen'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Details Screen'), findsOneWidget);
    });
  });

  group('Theme Integration', () {
    test('appPageTransitionsTheme uses MetroPivotTransitionsBuilder for all platforms', () {
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      ]) {
        final builder = appPageTransitionsTheme.builders[platform];
        expect(
          builder,
          isA<MetroPivotTransitionsBuilder>(),
          reason: 'Expected MetroPivotTransitionsBuilder for $platform',
        );
      }
    });

    testWidgets('MetroPivotTransitionsBuilder builds MetroPivotTransition', (
      tester,
    ) async {
      const builder = MetroPivotTransitionsBuilder();
      final anim = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 260),
      );
      final secAnim = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 220),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return builder.buildTransitions<void>(
                MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
                context,
                anim,
                secAnim,
                const Text('Themed Route Child'),
              );
            },
          ),
        ),
      );

      expect(find.text('Themed Route Child'), findsOneWidget);
      expect(find.byType(MetroPivotTransition), findsOneWidget);

      anim.dispose();
      secAnim.dispose();
    });

    test('AppMotion includes page transition tokens', () {
      final motion = AppMotion.resolve(disableAnimations: false);
      expect(motion.page, const Duration(milliseconds: 260));
      expect(motion.pageReverse, const Duration(milliseconds: 220));
      expect(motion.enter, Curves.easeOutCubic);
      expect(motion.exit, Curves.easeInCubic);

      final disabledMotion = AppMotion.resolve(disableAnimations: true);
      expect(disabledMotion.page, Duration.zero);
      expect(disabledMotion.pageReverse, Duration.zero);
      expect(disabledMotion.enter, Curves.linear);
      expect(disabledMotion.exit, Curves.linear);
    });
  });
}
