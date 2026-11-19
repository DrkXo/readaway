import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/reader/domain/gestures/reader_gestures.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/controllers/reader_viewport_controller.dart';
import 'package:readaway/src/features/reader/presentation/widgets/common/reader_error_view.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/pdf/pdf_reader_view.dart';

class MockReaderBloc extends MockBloc<ReaderEvent, ReaderState>
    implements ReaderBloc {}

File? _resolveSamplePdf() {
  Directory dir = Directory.current;
  for (int i = 0; i < 5; i++) {
    final configFile = File('${dir.path}/.dart_tool/package_config.json');
    if (configFile.existsSync()) {
      try {
        final json =
            jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final packages = json['packages'] as List<dynamic>?;
        final pdfrxPkg = packages?.firstWhere(
          (p) => p['name'] == 'pdfrx',
          orElse: () => null,
        );
        if (pdfrxPkg != null) {
          final rootUriStr = pdfrxPkg['rootUri'] as String;
          final rootUri = configFile.parent.uri.resolve(rootUriStr);
          final asset = File(
            '${rootUri.toFilePath()}/test/assets/multipage40.pdf',
          );
          if (asset.existsSync()) return asset;
        }
      } catch (_) {}
    }
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File testPdfFile;
  late ReaderViewportController viewportController;
  late MockReaderBloc mockReaderBloc;

  setUpAll(() async {
    pdfrxInitialize();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_reader_test_');
    testPdfFile = File('${tempDir.path}/test.pdf');
    final samplePdf = _resolveSamplePdf();
    if (samplePdf != null && samplePdf.existsSync()) {
      await samplePdf.copy(testPdfFile.path);
    }
    viewportController = ReaderViewportController(initialPage: 0, pageCount: 1);
    mockReaderBloc = MockReaderBloc();
    whenListen(
      mockReaderBloc,
      const Stream<ReaderState>.empty(),
      initialState: const ReaderState(),
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildHarness({
    required Widget child,
    double width = 500,
    double height = 800,
  }) {
    return BlocProvider<ReaderBloc>.value(
      value: mockReaderBloc,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }

  Future<void> waitForViewerReady(
    WidgetTester tester,
    ReaderViewportController controller,
  ) async {
    for (var i = 0; i < 30 && controller.pageCount <= 1; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
    }
    await tester.pumpAndSettle();
  }

  testWidgets('renders ReaderErrorView when document path does not exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        child: PdfReaderView(
          state: const ReaderState(
            documentPath: '/non/existent/path.pdf',
            currentPage: 0,
            pageCount: 1,
          ),
          prefs: const ReaderPreferences(),
          viewportController: viewportController,
        ),
      ),
    );

    expect(find.byType(ReaderErrorView), findsOneWidget);
  });

  testWidgets('renders PdfViewer when valid PDF document path is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        child: PdfReaderView(
          state: ReaderState(
            documentPath: testPdfFile.path,
            currentPage: 0,
            pageCount: 1,
          ),
          prefs: const ReaderPreferences(),
          viewportController: viewportController,
        ),
      ),
    );

    expect(find.byType(PdfViewer), findsOneWidget);
  });

  testWidgets(
    'single tap in center zone triggers ReaderTapAction.toggleChrome via onGeneralTap',
    (tester) async {
      ReaderTapAction? receivedAction;

      await tester.pumpWidget(
        buildHarness(
          child: PdfReaderView(
            state: ReaderState(
              documentPath: testPdfFile.path,
              currentPage: 0,
              pageCount: 1,
            ),
            prefs: const ReaderPreferences(),
            viewportController: viewportController,
            onTapAction: (action) => receivedAction = action,
          ),
        ),
      );

      await waitForViewerReady(tester, viewportController);

      // Tap at the center of the viewer
      final center = tester.getCenter(find.byType(PdfReaderView));
      await tester.tapAt(center);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(receivedAction, equals(ReaderTapAction.toggleChrome));
    },
  );

  testWidgets(
    'single tap in left zone triggers ReaderTapAction.previousPage',
    (tester) async {
      ReaderTapAction? receivedAction;

      await tester.pumpWidget(
        buildHarness(
          child: PdfReaderView(
            state: ReaderState(
              documentPath: testPdfFile.path,
              currentPage: 0,
              pageCount: 1,
            ),
            prefs: const ReaderPreferences(),
            viewportController: viewportController,
            onTapAction: (action) => receivedAction = action,
          ),
        ),
      );

      await waitForViewerReady(tester, viewportController);

      // Left zone is < 20% width (i.e. < 100px on a 500px wide box)
      final topLeft = tester.getTopLeft(find.byType(PdfReaderView));
      await tester.tapAt(topLeft + const Offset(40, 400));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(receivedAction, equals(ReaderTapAction.previousPage));
    },
  );

  testWidgets(
    'single tap in right zone triggers ReaderTapAction.nextPage',
    (tester) async {
      ReaderTapAction? receivedAction;

      await tester.pumpWidget(
        buildHarness(
          child: PdfReaderView(
            state: ReaderState(
              documentPath: testPdfFile.path,
              currentPage: 0,
              pageCount: 1,
            ),
            prefs: const ReaderPreferences(),
            viewportController: viewportController,
            onTapAction: (action) => receivedAction = action,
          ),
        ),
      );

      await waitForViewerReady(tester, viewportController);

      // Right zone is > 80% width (i.e. > 400px on a 500px wide box)
      final topRight = tester.getTopRight(find.byType(PdfReaderView));
      await tester.tapAt(topRight + const Offset(-40, 400));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(receivedAction, equals(ReaderTapAction.nextPage));
    },
  );

  testWidgets(
    'tap with active selection clears selection and does NOT trigger onTapAction',
    (tester) async {
      ReaderTapAction? receivedAction;

      await tester.pumpWidget(
        buildHarness(
          child: PdfReaderView(
            state: ReaderState(
              documentPath: testPdfFile.path,
              currentPage: 0,
              pageCount: 1,
            ),
            prefs: const ReaderPreferences(),
            viewportController: viewportController,
            onTapAction: (action) => receivedAction = action,
          ),
        ),
      );

      await waitForViewerReady(tester, viewportController);
      viewportController.setSelectionActive(true);
      expect(viewportController.hasActiveSelection, isTrue);

      final center = tester.getCenter(find.byType(PdfReaderView));
      await tester.tapAt(center);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(receivedAction, isNull);
      expect(viewportController.hasActiveSelection, isFalse);
    },
  );

  testWidgets(
    'tap on annotation highlight intercepts and does NOT trigger onTapAction',
    (tester) async {
      ReaderTapAction? receivedAction;

      viewportController.annotationTapDelegate = (pos) => true;

      await tester.pumpWidget(
        buildHarness(
          child: PdfReaderView(
            state: ReaderState(
              documentPath: testPdfFile.path,
              currentPage: 0,
              pageCount: 1,
            ),
            prefs: const ReaderPreferences(),
            viewportController: viewportController,
            onTapAction: (action) => receivedAction = action,
          ),
        ),
      );

      await waitForViewerReady(tester, viewportController);

      final center = tester.getCenter(find.byType(PdfReaderView));
      await tester.tapAt(center);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(receivedAction, isNull);
    },
  );
}
