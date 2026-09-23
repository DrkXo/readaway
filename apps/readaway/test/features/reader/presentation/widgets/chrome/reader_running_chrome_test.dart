import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/widgets/chrome/reader_running_footer.dart';
import 'package:readaway/src/features/reader/presentation/widgets/chrome/reader_running_header.dart';
import 'package:readaway/src/features/reader/presentation/widgets/chrome/reader_status_widget.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('ReaderRunningHeader Widget Tests', () {
    testWidgets('renders chapter title correctly', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ReaderRunningHeader(
            title: 'Chapter 1: The Boy Who Lived',
            fontSize: 12.0,
          ),
        ),
      );

      expect(find.text('Chapter 1: The Boy Who Lived'), findsOneWidget);
    });

    testWidgets('renders chapter title with left and right alignment', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ReaderRunningHeader(
            title: 'Prologue',
            alignment: ReaderHeaderAlignment.left,
            fontSize: 12.0,
          ),
        ),
      );

      expect(find.text('Prologue'), findsOneWidget);
      final alignFinder = find.byType(Align);
      expect(alignFinder, findsOneWidget);
      final alignWidget = tester.widget<Align>(alignFinder);
      expect(alignWidget.alignment, Alignment.centerLeft);
    });

    testWidgets('returns empty box when title is empty', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ReaderRunningHeader(
            title: '',
            height: 20.0,
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('ReaderRunningFooter Widget Tests', () {
    testWidgets('renders page count and remaining pages in chapter', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const ReaderRunningFooter(
            pageInChapter: 2,
            totalPagesInChapter: 10,
            globalPageIndex: 14,
            totalGlobalPages: 100,
            progressStyle: ReaderProgressStyle.pageNumber,
            showRemainingPages: true,
          ),
        ),
      );

      // Remaining pages: 10 - 1 - 2 = 7 pages left
      expect(find.text('7 pages left'), findsOneWidget);
      // Page count: 14 + 1 / 100 = 15 / 100
      expect(find.text('15 / 100'), findsOneWidget);
    });

    testWidgets('renders percentage when progressStyle is percentage', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const ReaderRunningFooter(
            pageInChapter: 0,
            totalPagesInChapter: 1,
            globalPageIndex: 49,
            totalGlobalPages: 100,
            progressStyle: ReaderProgressStyle.percentage,
            showRemainingPages: true,
          ),
        ),
      );

      expect(find.text('Last page in chapter'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('renders clock and battery when enabled', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ReaderRunningFooter(
            pageInChapter: 0,
            totalPagesInChapter: 5,
            globalPageIndex: 0,
            totalGlobalPages: 50,
            showCurrentTime: true,
            showBatteryStatus: true,
          ),
        ),
      );

      expect(find.byType(ReaderStatusWidget), findsOneWidget);
    });

    testWidgets('renders progress bar line when showProgressBar is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const ReaderRunningFooter(
            pageInChapter: 0,
            totalPagesInChapter: 5,
            globalPageIndex: 10,
            totalGlobalPages: 50,
            showProgressBar: true,
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
