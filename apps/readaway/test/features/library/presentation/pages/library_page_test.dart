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
            onAddBooks: () => addCalls++,
            onOpenBook: () => openCalls++,
          ),
        ),
      ),
    );

    expect(find.text('Adding…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-add-books')));
    await tester.tap(find.byKey(const ValueKey('library-open-book')));
    await tester.pump();

    expect(addCalls, 0);
    expect(openCalls, 0);
  });
}
