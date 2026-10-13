import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/tts/reader_tts_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/navigation/reader_bottom_bar.dart';

import '../../../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late MockReaderBloc readerBloc;
  late MockReaderTtsBloc readerTtsBloc;
  late MockSettingsBloc settingsBloc;

  setUp(() {
    readerBloc = MockReaderBloc();
    readerTtsBloc = MockReaderTtsBloc();
    settingsBloc = MockSettingsBloc();
  });

  ThemeData testTheme() {
    return ThemeData(
      extensions: [
        VsCodeThemeExtension(
          MetroColorScheme.kanagawaDragon.toVsCodeTheme(),
        ),
      ],
    );
  }

  Widget buildBottomBar({
    VoidCallback? onOutlineTap,
    VoidCallback? onPreviousPage,
    VoidCallback? onNextPage,
    ValueChanged<int>? onSeekToPage,
  }) {
    return Scaffold(
      bottomNavigationBar: ReaderBottomBar(
        onOutlineTap: onOutlineTap,
        onPreviousPage: onPreviousPage ?? () {},
        onNextPage: onNextPage ?? () {},
        onSeekToPage: onSeekToPage ?? (_) {},
      ),
    );
  }

  group('ReaderBottomBar Widget Tests', () {
    testWidgets('renders nothing when no document is open', (tester) async {
      await tester.pumpTestApp(
        buildBottomBar(),
        readerBloc: readerBloc,
        readerTtsBloc: readerTtsBloc,
        settingsBloc: settingsBloc,
        readerInitialState: const ReaderState(
          documentPath: null,
          pageCount: 0,
        ),
        theme: testTheme(),
      );
      await tester.pump();

      expect(find.text('contents'), findsNothing);
      expect(find.text('theme'), findsNothing);
      expect(find.text('pages'), findsNothing);
      expect(find.text('font'), findsNothing);
      expect(find.text('listen'), findsNothing);
    });

    testWidgets(
      'renders all 5 flat Metro actions with lowercase labels for reflowable documents',
      (tester) async {
        await tester.pumpTestApp(
          buildBottomBar(),
          readerBloc: readerBloc,
          readerTtsBloc: readerTtsBloc,
          settingsBloc: settingsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/book.epub',
            pageCount: 150,
            currentPage: 5,
            isReflowable: true,
          ),
          theme: testTheme(),
        );
        await tester.pump();

        // Check lowercase typography labels
        expect(find.text('contents'), findsOneWidget);
        expect(find.text('theme'), findsOneWidget);
        expect(find.text('pages'), findsOneWidget);
        expect(find.text('font'), findsOneWidget);
        expect(find.text('listen'), findsOneWidget);

        // Check vector icons
        expect(find.byIcon(LucideIcons.panelLeft), findsOneWidget);
        expect(find.byIcon(LucideIcons.sunMedium), findsOneWidget);
        expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
        expect(find.byIcon(LucideIcons.type), findsOneWidget);
        expect(find.byIcon(LucideIcons.audioLines), findsOneWidget);
      },
    );

    testWidgets(
      'omits font and listen actions for non-reflowable documents',
      (tester) async {
        await tester.pumpTestApp(
          buildBottomBar(),
          readerBloc: readerBloc,
          readerTtsBloc: readerTtsBloc,
          settingsBloc: settingsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/comic.cbz',
            pageCount: 50,
            currentPage: 0,
            isReflowable: false,
          ),
          theme: testTheme(),
        );
        await tester.pump();

        // Only 3 actions visible
        expect(find.text('contents'), findsOneWidget);
        expect(find.text('theme'), findsOneWidget);
        expect(find.text('pages'), findsOneWidget);
        expect(find.text('font'), findsNothing);
        expect(find.text('listen'), findsNothing);

        expect(find.byIcon(LucideIcons.panelLeft), findsOneWidget);
        expect(find.byIcon(LucideIcons.sunMedium), findsOneWidget);
        expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
        expect(find.byIcon(LucideIcons.type), findsNothing);
        expect(find.byIcon(LucideIcons.audioLines), findsNothing);
      },
    );

    testWidgets('tapping contents triggers onOutlineTap callback', (
      tester,
    ) async {
      var outlineInvoked = false;

      await tester.pumpTestApp(
        buildBottomBar(
          onOutlineTap: () {
            outlineInvoked = true;
          },
        ),
        readerBloc: readerBloc,
        readerTtsBloc: readerTtsBloc,
        settingsBloc: settingsBloc,
        readerInitialState: const ReaderState(
          documentPath: '/book.epub',
          pageCount: 100,
          currentPage: 0,
          isReflowable: true,
        ),
        theme: testTheme(),
      );
      await tester.pump();

      await tester.tap(find.text('contents'));
      await tester.pump();

      expect(outlineInvoked, isTrue);
    });

    testWidgets(
      'toggling theme panel opens and closes brightness quick panel',
      (tester) async {
        await tester.pumpTestApp(
          buildBottomBar(),
          readerBloc: readerBloc,
          readerTtsBloc: readerTtsBloc,
          settingsBloc: settingsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/book.epub',
            pageCount: 100,
            currentPage: 0,
            isReflowable: true,
          ),
          theme: testTheme(),
        );
        await tester.pump();

        // Tap 'theme' to open brightness quick panel
        await tester.tap(find.text('theme'));
        await tester.pumpAndSettle();

        expect(find.byType(ReaderBrightnessQuickView), findsOneWidget);

        // Tap 'theme' again to close
        await tester.tap(find.text('theme'));
        await tester.pumpAndSettle();

        expect(find.byType(ReaderBrightnessQuickView), findsNothing);
      },
    );

    testWidgets(
      'toggling pages panel opens page navigation quick panel',
      (tester) async {
        await tester.pumpTestApp(
          buildBottomBar(),
          readerBloc: readerBloc,
          readerTtsBloc: readerTtsBloc,
          settingsBloc: settingsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/book.epub',
            pageCount: 100,
            currentPage: 0,
            isReflowable: true,
          ),
          theme: testTheme(),
        );
        await tester.pump();

        // Tap 'pages' to open page navigation quick panel
        await tester.tap(find.text('pages'));
        await tester.pumpAndSettle();

        expect(find.byType(ReaderPageNavigationQuickView), findsOneWidget);
      },
    );

    testWidgets(
      'toggling font panel opens font size quick panel on reflowable format',
      (tester) async {
        await tester.pumpTestApp(
          buildBottomBar(),
          readerBloc: readerBloc,
          readerTtsBloc: readerTtsBloc,
          settingsBloc: settingsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/book.epub',
            pageCount: 100,
            currentPage: 0,
            isReflowable: true,
          ),
          theme: testTheme(),
        );
        await tester.pump();

        // Tap 'font' to open font size quick panel
        await tester.tap(find.text('font'));
        await tester.pumpAndSettle();

        expect(find.byType(ReaderFontSizeQuickView), findsOneWidget);
      },
    );

    testWidgets(
      'tapping listen dispatches ReaderTtsEvent.start to ReaderTtsBloc',
      (
        tester,
      ) async {
        await tester.pumpTestApp(
          buildBottomBar(),
          readerBloc: readerBloc,
          readerTtsBloc: readerTtsBloc,
          settingsBloc: settingsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/book.epub',
            pageCount: 100,
            currentPage: 0,
            isReflowable: true,
          ),
          readerTtsInitialState: const ReaderTtsState(ttsActive: false),
          theme: testTheme(),
        );
        await tester.pump();

        await tester.tap(find.text('listen'));
        await tester.pump();

        expect(readerTtsBloc.addedEvents, isNotEmpty);
      },
    );

    testWidgets('adheres strictly to non-circular geometry', (tester) async {
      await tester.pumpTestApp(
        buildBottomBar(),
        readerBloc: readerBloc,
        readerTtsBloc: readerTtsBloc,
        settingsBloc: settingsBloc,
        readerInitialState: const ReaderState(
          documentPath: '/book.epub',
          pageCount: 100,
          currentPage: 0,
          isReflowable: true,
        ),
        theme: testTheme(),
      );
      await tester.pump();

      // Ensure no circular clip ovals, avatars, or circular containers
      expect(find.byType(ClipOval), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);

      final barContainers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ReaderBottomBar),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>();

      for (final decoration in barContainers) {
        expect(decoration.shape, isNot(BoxShape.circle));
        if (decoration.borderRadius != null) {
          expect(decoration.borderRadius, equals(BorderRadius.zero));
        }
      }
    });
  });
}
