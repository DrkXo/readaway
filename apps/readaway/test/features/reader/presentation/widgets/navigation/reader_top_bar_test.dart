import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';
import 'package:readaway/src/features/annotations/presentation/widgets/reader_bookmark_button.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/navigation/reader_top_bar.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReaderBloc readerBloc;
  late MockAnnotationsBloc annotationsBloc;
  late PaginationCoordinator coordinator;

  setUp(() {
    readerBloc = MockReaderBloc();
    annotationsBloc = MockAnnotationsBloc();
    coordinator = PaginationCoordinator();
    GetIt.I.registerSingleton<PaginationCoordinator>(coordinator);
  });

  tearDown(() {
    GetIt.I.reset();
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

  group('ReaderTopBar Widget Tests', () {
    testWidgets('renders nothing when no document is open', (tester) async {
      await tester.pumpTestApp(
        const ReaderTopBar(),
        readerBloc: readerBloc,
        readerInitialState: const ReaderState(
          documentPath: null,
          pageCount: 0,
        ),
        theme: testTheme(),
      );
      await tester.pump();

      expect(find.byType(MetroPressable), findsNothing);
      expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
    });

    testWidgets(
      'renders title, lowercase progress, and all action buttons when document is open',
      (tester) async {
        await tester.pumpTestApp(
          const ReaderTopBar(),
          readerBloc: readerBloc,
          annotationsBloc: annotationsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/books/metro.epub',
            pageCount: 200,
            currentPage: 9,
            bookTitle: 'Metro Guidelines',
          ),
          theme: testTheme(),
        );
        await tester.pump();

        // Title and progress
        expect(find.text('Metro Guidelines'), findsOneWidget);
        expect(find.text('page 10 of 200'), findsOneWidget);

        // Leading close button
        expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

        // Actions: Bookmark, Share, Settings
        expect(find.byType(ReaderBookmarkButton), findsOneWidget);
        expect(find.byIcon(LucideIcons.share2), findsOneWidget);
        expect(find.byIcon(LucideIcons.sliders), findsOneWidget);
      },
    );

    testWidgets(
      'triggers onCloseDocument callback when close button is tapped',
      (
        tester,
      ) async {
        var closeCallbackInvoked = false;

        await tester.pumpTestApp(
          ReaderTopBar(
            onCloseDocument: () {
              closeCallbackInvoked = true;
            },
          ),
          readerBloc: readerBloc,
          annotationsBloc: annotationsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/books/metro.epub',
            pageCount: 100,
            currentPage: 0,
            bookTitle: 'Test Title',
          ),
          theme: testTheme(),
        );
        await tester.pump();

        final closeButtonFinder = find.byIcon(LucideIcons.arrowLeft);
        expect(closeButtonFinder, findsOneWidget);

        await tester.tap(closeButtonFinder);
        await tester.pump();

        expect(closeCallbackInvoked, isTrue);
      },
    );

    testWidgets(
      'dispatches ReaderEvent.closeDocument when onCloseDocument is not provided',
      (tester) async {
        await tester.pumpTestApp(
          const ReaderTopBar(),
          readerBloc: readerBloc,
          annotationsBloc: annotationsBloc,
          readerInitialState: const ReaderState(
            documentPath: '/books/metro.epub',
            pageCount: 100,
            currentPage: 0,
            bookTitle: 'Test Title',
          ),
          theme: testTheme(),
        );
        await tester.pump();

        final closeButtonFinder = find.byIcon(LucideIcons.arrowLeft);
        await tester.tap(closeButtonFinder);
        await tester.pump();

        expect(
          readerBloc.addedEvents,
          contains(const ReaderEvent.closeDocument()),
        );
      },
    );

    testWidgets('adheres strictly to non-circular geometry', (tester) async {
      await tester.pumpTestApp(
        const ReaderTopBar(),
        readerBloc: readerBloc,
        annotationsBloc: annotationsBloc,
        readerInitialState: const ReaderState(
          documentPath: '/books/metro.epub',
          pageCount: 100,
          currentPage: 0,
          bookTitle: 'Non Circular Test',
        ),
        theme: testTheme(),
      );
      await tester.pump();

      // Ensure no circular shapes, clip ovals, or circular borders exist
      expect(find.byType(ClipOval), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);

      final containerDecorations = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>();

      for (final decoration in containerDecorations) {
        expect(decoration.shape, isNot(BoxShape.circle));
        if (decoration.borderRadius != null) {
          expect(decoration.borderRadius, equals(BorderRadius.zero));
        }
      }
    });

    testWidgets('provides accessible semantic labels and tooltips', (
      tester,
    ) async {
      await tester.pumpTestApp(
        const ReaderTopBar(),
        readerBloc: readerBloc,
        annotationsBloc: annotationsBloc,
        readerInitialState: const ReaderState(
          documentPath: '/books/metro.epub',
          pageCount: 100,
          currentPage: 0,
          bookTitle: 'Accessibility Test',
        ),
        theme: testTheme(),
      );
      await tester.pump();

      expect(find.byTooltip('Close document'), findsOneWidget);
      expect(find.byTooltip('Share document or page'), findsOneWidget);
      expect(find.byTooltip('Reader options'), findsOneWidget);
      expect(find.bySemanticsLabel('Close document'), findsOneWidget);
      expect(find.bySemanticsLabel('Share document or page'), findsOneWidget);
      expect(find.bySemanticsLabel('Reader options'), findsOneWidget);
    });
  });
}
