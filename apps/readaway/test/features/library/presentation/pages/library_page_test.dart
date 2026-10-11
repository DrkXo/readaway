import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';
import 'package:readaway/src/features/library/presentation/bloc/library_bloc.dart';
import 'package:readaway/src/features/library/presentation/pages/library_page.dart';
import 'package:readaway/src/features/library/presentation/widgets/library_actions_fab.dart';
import 'package:readaway/src/features/library/presentation/widgets/library_tools_panel.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';

import '../../../../helpers/test_mocks.dart';

void main() {
  setUpAll(registerMockitoDummies);

  testWidgets(
    'renders MetroPivot hub with panoramic sections and toggles search',
    (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockLibraryRepository();
      final mockSettings = MockSettingsService();
      when(mockSettings.settings).thenReturn(const Settings());
      when(mockRepo.watchRecentDocuments())
          .thenAnswer((_) => Stream.value(const Success([])));

      final bloc = LibraryBloc(mockRepo, mockSettings);
      GetIt.I.registerSingleton<LibraryBloc>(bloc);
      addTearDown(() => GetIt.I.unregister<LibraryBloc>());

      await tester.pumpWidget(const MaterialApp(home: LibraryPage()));
      await tester.pumpAndSettle();

      expect(find.byType(MetroPivot), findsOneWidget);
      expect(find.text('library'), findsOneWidget);
      expect(find.text('all books'), findsOneWidget);
      expect(find.text('reading'), findsOneWidget);
      expect(find.text('favorites'), findsOneWidget);
      expect(find.text('finished'), findsOneWidget);

      expect(find.text('add'), findsOneWidget);
      expect(find.text('open'), findsOneWidget);
      expect(find.text('search'), findsOneWidget);
      expect(find.text('settings'), findsOneWidget);

      // Toggle search
      await tester.tap(find.text('search'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Toggle search off via cancel button
      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'MetroPivot horizontal gestures change active section in LibraryPage',
    (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockLibraryRepository();
      final mockSettings = MockSettingsService();
      when(mockSettings.settings).thenReturn(const Settings());
      when(mockRepo.watchRecentDocuments())
          .thenAnswer((_) => Stream.value(const Success([])));

      final bloc = LibraryBloc(mockRepo, mockSettings);
      GetIt.I.registerSingleton<LibraryBloc>(bloc);
      addTearDown(() => GetIt.I.unregister<LibraryBloc>());

      await tester.pumpWidget(const MaterialApp(home: LibraryPage()));
      await tester.pumpAndSettle();

      final pivotFinder = find.byType(MetroPivot);
      expect(pivotFinder, findsOneWidget);

      final pivot = tester.widget<MetroPivot>(pivotFinder);
      expect(pivot.controller, isNotNull);
      expect(pivot.controller!.index, 0);

      // Verify dragging horizontally changes pivot section to 'reading' (index 1)
      await tester.drag(
        find.text('No matching books found.'),
        const Offset(-600, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(pivot.controller!.index, 1);
      expect(find.text('No books currently in progress.'), findsOneWidget);

      // Verify horizontal pointer scroll event changes pivot section to 'favorites' (index 2)
      final center = tester.getCenter(
        find.text('No books currently in progress.'),
      );
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(50, 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(pivot.controller!.index, 2);
      expect(find.text('No favorite books marked yet.'), findsOneWidget);
    },
  );

  testWidgets('library tools slide into view when opened', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              LibraryToolsPanel(
                    key: const ValueKey('library-tools-panel'),
                    state: const LibraryState(),
                    searchController: TextEditingController(),
                    selecting: false,
                    onSearchChanged: (_) {},
                    onFilterChanged: (_) {},
                    onSortChanged: (_) {},
                    onSortOrderToggled: () {},
                    onViewModeChanged: (_) {},
                    onReset: () {},
                    onSelectMode: () {},
                  )
                  .animate()
                  .slideY(
                    begin: -0.12,
                    duration: 240.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(duration: 180.ms),
        ),
      ),
    );

    final panelSlide = find.byWidgetPredicate(
      (widget) => widget is SlideTransition && widget.position.value.dy < 0,
    );
    expect(panelSlide, findsOneWidget);
    expect(
      tester.widget<SlideTransition>(panelSlide).position.value.dy,
      lessThan(0),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(LibraryToolsPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('book picker actions show loading and ignore repeat taps', (
    tester,
  ) async {
    var addCalls = 0;
    var openCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: LibraryActionsFab(
            isLoading: true,
            isExpanded: false,
            onToggle: () {},
            onAddBooks: () => addCalls++,
            onOpenBook: () => openCalls++,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Adding…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final addButton = find.descendant(
      of: find.byKey(const ValueKey('library-add-books')),
      matching: find.byType(FloatingActionButton),
    );
    await tester.tap(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(addCalls, 0);
    expect(openCalls, 0);
  });

  testWidgets('library actions expand and invoke both actions', (tester) async {
    var addCalls = 0;
    var openCalls = 0;
    var isExpanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            floatingActionButton: LibraryActionsFab(
              isLoading: false,
              isExpanded: isExpanded,
              onToggle: () => setState(() => isExpanded = !isExpanded),
              onAddBooks: () => addCalls++,
              onOpenBook: () => openCalls++,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byTooltip('Add'), findsNothing);
    expect(find.byTooltip('Open'), findsNothing);

    final toggle = find.byKey(const ValueKey('library-actions-toggle'));
    final initialRight = tester.getRect(toggle).right;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add'), findsOneWidget);
    expect(find.byTooltip('Open'), findsOneWidget);
    expect(tester.getRect(toggle).right, closeTo(initialRight, 0.1));

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();
    expect(openCalls, 1);
    expect(addCalls, 0);

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    expect(openCalls, 1);
    expect(addCalls, 1);
  });

  testWidgets(
    'Bottom bar right-aligned text actions trigger document picking',
    (tester) async {
      final mockRepo = MockLibraryRepository();
      final mockSettings = MockSettingsService();
      when(mockSettings.settings).thenReturn(const Settings());
      when(mockRepo.watchRecentDocuments())
          .thenAnswer((_) => Stream.value(const Success([])));
      when(mockRepo.pickAndAddDocuments())
          .thenAnswer((_) async => const Success([]));
      when(mockRepo.pickDocumentWithoutSaving())
          .thenAnswer((_) async => const Success(null));

      final bloc = LibraryBloc(mockRepo, mockSettings);
      GetIt.I.registerSingleton<LibraryBloc>(bloc);
      addTearDown(() => GetIt.I.unregister<LibraryBloc>());

      await tester.pumpWidget(
        const MaterialApp(home: LibraryPage()),
      );
      await tester.pumpAndSettle();

      // 1. Verify right-aligned text actions exist
      expect(find.text('open'), findsOneWidget);
      expect(find.text('add'), findsOneWidget);

      // 2. Tap Add button in bottom bar
      await tester.tap(find.text('add'));
      await tester.pumpAndSettle();
      verify(mockRepo.pickAndAddDocuments()).called(1);

      // 3. Tap Open button in bottom bar
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      verify(mockRepo.pickDocumentWithoutSaving()).called(1);

      // 4. Toggle selection mode via BLoC event
      bloc.add(const LibraryEvent.selectModeToggled());
      await tester.pumpAndSettle();

      // Verify entered selection mode with flat text actions
      expect(find.text('0 selected'), findsOneWidget);
      expect(find.text('select all'), findsOneWidget);
      expect(find.text('cancel'), findsOneWidget);

      // 5. Close selection mode
      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      // Back to two-action bottom bar
      expect(find.text('open'), findsOneWidget);
      expect(find.text('add'), findsOneWidget);
    },
  );
}
