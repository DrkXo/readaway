import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/library/presentation/bloc/library_bloc.dart';
import 'package:readaway/src/features/library/presentation/widgets/library_actions_fab.dart';
import 'package:readaway/src/features/library/presentation/widgets/library_tools_panel.dart';

void main() {
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
    expect(find.byTooltip('Add Book'), findsNothing);
    expect(find.byTooltip('Open Book'), findsNothing);

    final toggle = find.byKey(const ValueKey('library-actions-toggle'));
    final initialRight = tester.getRect(toggle).right;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add Book'), findsOneWidget);
    expect(find.byTooltip('Open Book'), findsOneWidget);
    expect(tester.getRect(toggle).right, closeTo(initialRight, 0.1));

    await tester.tap(find.byTooltip('Open Book'));
    await tester.pumpAndSettle();
    expect(openCalls, 1);
    expect(addCalls, 0);

    await tester.tap(find.byTooltip('Add Book'));
    await tester.pumpAndSettle();
    expect(openCalls, 1);
    expect(addCalls, 1);
  });
}
