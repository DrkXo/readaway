import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/modes/paged_transition_controller.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/chapter_layout_probe.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  testWidgets('showing dialog over hyper render with semantics enabled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    final doc = DocumentNode(
      children: [
        BlockNode.h1(children: [TextNode('Chapter 1')]),
        BlockNode(
          tagName: 'p',
          children: [
            TextNode('Some text with a '),
            InlineNode(
              tagName: 'a',
              attributes: {'href': 'https://example.com'},
              children: [TextNode('link')],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: Column(
                  children: [
                    HyperSelectionOverlay(
                      document: doc,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showAppSheet<void>(
                          context: context,
                          title: 'Test Sheet',
                          builder: (_) => const Text('Dialog content'),
                        );
                      },
                      child: const Text('Open Sheet'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    handle.dispose();
  });

  testWidgets(
    'OffscreenChapterMeasurer has ExcludeSemantics so no probe nodes enter semantics',
    (tester) async {
      final handle = tester.ensureSemantics();
      final coordinator = PaginationCoordinator();
      coordinator.initialize(
        chapterCount: 2,
        viewportHeight: 400,
        contentHeight: 0,
      );
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OffscreenChapterMeasurer(
              chapterIndex: 0,
              html: '<h1>Hidden Heading</h1><p><a href="https://test.com">Hidden Link</a></p>',
              prefs: const ReaderPreferences(),
              coordinator: coordinator,
              viewportWidth: 300,
              cacheNamespace: 'test-ns',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The probe is wrapped in ExcludeSemantics, so its headings and links are not present in semantics
      expect(find.byType(ExcludeSemantics), findsAtLeastNWidgets(1));

      handle.dispose();
    },
  );

  group('PagedTransitionController syncCurrentPage', () {
    testWidgets(
      'non-adjacent jump updates currentPage immediately without animation',
      (tester) async {
        late PagedTransitionController controller;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final vsync = Navigator.of(context);
                  controller = PagedTransitionController(
                    vsync: vsync,
                    currentPage: 0,
                    pageCount: 100,
                    transition: ReaderPageTransition.slide,
                    direction: ReaderScrollDirection.horizontal,
                    duration: const Duration(milliseconds: 300),
                    viewportController: null,
                    onPageCommitted: (_) {},
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(controller.currentPage, equals(0));

        // Jump from page 0 to page 45 (non-adjacent: difference > 1)
        controller.syncCurrentPage(45);
        expect(controller.currentPage, equals(45));
        expect(controller.targetPage, isNull);
        expect(controller.animationController.isAnimating, isFalse);

        controller.dispose();
      },
    );

    testWidgets('adjacent step animates when transition is slide', (
      tester,
    ) async {
      late PagedTransitionController controller;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final vsync = Navigator.of(context);
                controller = PagedTransitionController(
                  vsync: vsync,
                  currentPage: 0,
                  pageCount: 10,
                  transition: ReaderPageTransition.slide,
                  direction: ReaderScrollDirection.horizontal,
                  duration: const Duration(milliseconds: 300),
                  viewportController: null,
                  onPageCommitted: (_) {},
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(controller.currentPage, equals(0));

      // Adjacent turn: 0 to 1
      controller.syncCurrentPage(1);
      expect(controller.targetPage, equals(1));
      expect(controller.animationController.isAnimating, isTrue);

      await tester.pumpAndSettle();
      expect(controller.currentPage, equals(1));
      expect(controller.targetPage, isNull);

      controller.dispose();
    });
  });
}
