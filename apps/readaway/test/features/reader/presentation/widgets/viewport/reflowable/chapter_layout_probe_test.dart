import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/chapter_layout_probe.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway_core/readaway_core.dart';

/// Enough text that the chapter is taller than the viewport, so its page count
/// is more than the placeholder single page.
const String _chapterHtml =
    '<p>Alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu. '
    'Alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu. '
    'Alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu. '
    'Alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu. '
    'Alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu.</p>';

const double _viewportWidth = 300.0;
const double _viewportHeight = 200.0;

PaginationCoordinator _coordinator({int chapterCount = 2}) {
  final coordinator = PaginationCoordinator();
  coordinator.initialize(
    chapterCount: chapterCount,
    viewportHeight: _viewportHeight,
    contentHeight: 0,
  );
  addTearDown(coordinator.dispose);
  return coordinator;
}

void main() {
  testWidgets('measures a chapter that was never shown', (tester) async {
    final coordinator = _coordinator();

    // The hold waits on this future; the offscreen probe is what completes it.
    final measured = coordinator.ensureChapterMeasured(1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OffscreenChapterMeasurer(
            chapterIndex: 1,
            html: _chapterHtml,
            prefs: const ReaderPreferences(),
            coordinator: coordinator,
            viewportWidth: _viewportWidth,
            cacheNamespace: 'probe-test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await measured.timeout(const Duration(seconds: 1));

    expect(coordinator.isChapterMeasured(1), isTrue);
    expect(coordinator.measuredPageCount(1), greaterThan(0));

    // Only the requested chapter is measured; the probe does not disturb the
    // chapter the reader is actually on.
    expect(coordinator.isChapterMeasured(0), isFalse);

    // The measured height must be the chapter's real content height, so the
    // page count is not a placeholder.
    expect(coordinator.getChapterHeight(1), greaterThan(_viewportHeight));
  });

  testWidgets('leaves no footprint on the screen', (tester) async {
    final coordinator = _coordinator(chapterCount: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFFFFFFF)),
              ),
              OffscreenChapterMeasurer(
                chapterIndex: 0,
                html: _chapterHtml,
                prefs: const ReaderPreferences(),
                coordinator: coordinator,
                viewportWidth: _viewportWidth,
                cacheNamespace: 'probe-test',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The probe is in the tree but skipped by default finders, which is exactly
    // the point: it must never be discoverable as part of the visible UI.
    expect(
      find.byType(ChapterLayoutProbe, skipOffstage: false),
      findsOneWidget,
    );

    // In loose constraints an offstage child reports the smallest size, so the
    // probe occupies no space.
    expect(
      tester.getSize(find.byType(OffscreenChapterMeasurer)).isEmpty,
      isTrue,
    );
  });
}
