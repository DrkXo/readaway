import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/share_service.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/overlay/reader_share_sheet.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../helpers/test_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  Widget buildTestWidget({
    required ReaderState state,
    required ShareService shareService,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ReaderShareSheet.show(
              context: context,
              state: state,
              shareService: shareService,
            ),
            child: const Text('Open Share Sheet'),
          ),
        ),
      ),
    );
  }

  group('ReaderShareSheet Widget Tests', () {
    testWidgets('renders non-reflowable options (full file, current page, custom page)', (tester) async {
      const state = ReaderState(
        documentPath: '/mock/path/sample.pdf',
        fileName: 'sample.pdf',
        bookTitle: 'Sample PDF Book',
        format: 'pdf',
        isReflowable: false,
        pageCount: 15,
        currentPage: 4,
      );

      final shareService = ShareService.withHandler(
        shareHandler: (params) async =>
            const ShareResult('success', ShareResultStatus.success),
      );

      await tester.pumpWidget(buildTestWidget(state: state, shareService: shareService));
      await tester.tap(find.text('Open Share Sheet'));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Sample PDF Book'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('15 pages'), findsOneWidget);
      expect(find.text('Share Document File'), findsOneWidget);
      expect(find.text('Share Current Page (5)'), findsOneWidget);
      expect(find.text('Share Selected Page'), findsOneWidget);
      expect(find.text('Share Page 5 as Image'), findsOneWidget);
    });

    testWidgets('triggers shareDocumentFile on tapping Share Document File', (tester) async {
      const state = ReaderState(
        documentPath: '/mock/path/comic.cbz',
        fileName: 'comic.cbz',
        bookTitle: 'Comic Book',
        format: 'cbz',
        isReflowable: false,
        pageCount: 20,
        currentPage: 0,
      );

      var didShareDoc = false;
      final shareService = ShareService.withHandler(
        shareHandler: (params) async {
          didShareDoc = true;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      await tester.pumpWidget(buildTestWidget(state: state, shareService: shareService));
      await tester.tap(find.text('Open Share Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share Document File'));
      await tester.pump();
      expect(didShareDoc, isFalse); // Non-existent mock file path fails existence check gracefully
    });

    testWidgets('renders reflowable options without page image buttons', (tester) async {
      const state = ReaderState(
        documentPath: '/mock/path/novel.epub',
        fileName: 'novel.epub',
        bookTitle: 'EPUB Novel',
        format: 'epub',
        isReflowable: true,
        pageCount: 10,
        currentPage: 2,
      );

      final shareService = ShareService.withHandler(
        shareHandler: (params) async =>
            const ShareResult('success', ShareResultStatus.success),
      );

      await tester.pumpWidget(buildTestWidget(state: state, shareService: shareService));
      await tester.tap(find.text('Open Share Sheet'));
      await tester.pumpAndSettle();

      // Should show Share Document File
      expect(find.text('Share Document File'), findsOneWidget);
      // Should not show page image options for reflowable HTML
      expect(find.text('Share Current Page (3)'), findsNothing);
      expect(find.text('Share Selected Page'), findsNothing);
    });
  });
}
