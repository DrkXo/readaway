import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/services/toast/toast_service.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/reader/presentation/controllers/reader_viewport_controller.dart';
import 'package:readaway/src/features/reader/presentation/widgets/selection/reader_selection_context_menu.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../helpers/test_mocks.dart';

class FakeHyperSelectionOverlayState extends Mock
    implements HyperSelectionOverlayState {
  HyperTextSelection? currentSelection;
  String? currentSelectedText;
  int clearSelectionCount = 0;
  int copySelectionCount = 0;
  int selectAllCount = 0;

  @override
  HyperTextSelection? get selection => currentSelection;

  @override
  String? get selectedText => currentSelectedText;

  @override
  Future<void> copySelection() async {
    copySelectionCount++;
  }

  @override
  void clearSelection() {
    clearSelectionCount++;
  }

  @override
  void selectAll() {
    selectAllCount++;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      super.toString();
}

const _path = '/books/test.epub';
final _at = DateTime(2026, 1, 1);
const _flow = 'The quick brown fox jumps over the lazy dog.';

ChapterTextLayout _layout() => ChapterTextLayout(
  contentHeight: 1000,
  viewportHeight: 500,
  lineBounds: const [(top: 0.0, bottom: 20.0)],
  spans: [
    TextSpanBox(
      charStart: 0,
      charEnd: _flow.length,
      rect: const Rect.fromLTWH(0, 0, 100, 20),
      nodeTag: 'p',
      type: 'text',
    ),
  ],
  pages: [
    PageSlice(
      index: 0,
      startY: 0,
      endY: 500,
      startChar: 0,
      endChar: _flow.length,
    ),
  ],
  flowText: _flow,
  totalCharacterCount: _flow.length,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerMockitoDummies);

  late MockAnnotationsRepository repository;
  late PaginationCoordinator coordinator;
  late ReaderViewportController controller;
  late FakeHyperSelectionOverlayState overlayState;

  setUp(() {
    repository = MockAnnotationsRepository();
    when(repository.getForDocument(any)).thenAnswer((_) async {
      return Success(
        DocumentNotes(
          documentPath: _path,
          schemaVersion: kDocumentNotesSchemaVersion,
          notes: const [],
          updatedAt: _at,
        ),
      );
    });
    when(repository.save(any)).thenAnswer((invocation) async {
      return Success(invocation.positionalArguments.first as DocumentNotes);
    });

    coordinator = PaginationCoordinator();
    coordinator.initialize(
      chapterCount: 3,
      viewportHeight: 500,
      contentHeight: 1000,
    );
    coordinator.registerChapterLayout(chapterIndex: 0, layout: _layout());

    controller = ReaderViewportController();
    overlayState = FakeHyperSelectionOverlayState();

    if (!GetIt.I.isRegistered<ToastService>()) {
      GetIt.I.registerSingleton<ToastService>(ToastService());
    }
  });

  tearDown(() {
    coordinator.dispose();
    controller.dispose();
    if (GetIt.I.isRegistered<ToastService>()) {
      GetIt.I.unregister<ToastService>();
    }
  });

  Future<AnnotationsBloc> loadedBloc(List<ReaderNote> notes) async {
    when(repository.getForDocument(any)).thenAnswer((_) async {
      return Success(
        DocumentNotes(
          documentPath: _path,
          schemaVersion: kDocumentNotesSchemaVersion,
          notes: notes,
          updatedAt: _at,
        ),
      );
    });
    final bloc = AnnotationsBloc(repository);
    addTearDown(bloc.close);
    final ready = bloc.stream
        .firstWhere((state) => state.status == AnnotationsStatus.ready)
        .timeout(const Duration(seconds: 5));
    bloc.add(const AnnotationsEvent.loadForDocument(documentPath: _path));
    await ready;
    return bloc;
  }

  Widget buildMenuWidget(AnnotationsBloc bloc) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: ReaderSelectionContextMenu(
            chapterIndex: 0,
            coordinator: coordinator,
            overlayState: overlayState,
            controller: controller,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders color swatches, note button, copy button, and more button',
    (tester) async {
      final bloc = await loadedBloc([]);

      overlayState.currentSelection = const HyperTextSelection(
        start: 4,
        end: 9,
      );
      overlayState.currentSelectedText = 'quick';

      await tester.pumpWidget(buildMenuWidget(bloc));
      await tester.pump();

      // Verify icons present
      expect(find.byIcon(LucideIcons.filePenLine), findsOneWidget); // Note
      expect(find.byIcon(LucideIcons.copy), findsOneWidget); // Copy
      expect(find.byIcon(LucideIcons.ellipsis), findsOneWidget); // More

      // Verify at least 5 color dots rendered
      expect(find.byTooltip('Highlight: Primary'), findsOneWidget);
      expect(find.byTooltip('Highlight: Amber'), findsOneWidget);
      expect(find.byTooltip('Highlight: Emerald'), findsOneWidget);
      expect(find.byTooltip('Highlight: Sky'), findsOneWidget);
      expect(find.byTooltip('Highlight: Violet'), findsOneWidget);
    },
  );

  testWidgets('tapping color swatch applies highlight and clears selection', (
    tester,
  ) async {
    final bloc = await loadedBloc([]);

    overlayState.currentSelection = const HyperTextSelection(start: 4, end: 9);
    overlayState.currentSelectedText = 'quick';

    await tester.pumpWidget(buildMenuWidget(bloc));
    await tester.pump();

    await tester.tap(find.byTooltip('Highlight: Amber'));
    await tester.pump();

    expect(overlayState.clearSelectionCount, 1);
    expect(bloc.state.notes.length, 1);
    expect(bloc.state.notes.first.colorValue, 'amber');
  });

  testWidgets('tapping copy action invokes copySelection on overlayState', (
    tester,
  ) async {
    final bloc = await loadedBloc([]);

    overlayState.currentSelection = const HyperTextSelection(start: 4, end: 9);
    overlayState.currentSelectedText = 'quick';

    await tester.pumpWidget(buildMenuWidget(bloc));
    await tester.pump();

    await tester.tap(find.byIcon(LucideIcons.copy));
    await tester.pump();

    expect(overlayState.copySelectionCount, 1);
  });

  testWidgets('tapping more opens overflow bottom sheet with secondary tools', (
    tester,
  ) async {
    final bloc = await loadedBloc([]);

    overlayState.currentSelection = const HyperTextSelection(start: 4, end: 9);
    overlayState.currentSelectedText = 'quick';

    await tester.pumpWidget(buildMenuWidget(bloc));
    await tester.pump();

    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.text('Define'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);
  });

  testWidgets(
    'shows unhighlight button when selection is already highlighted',
    (tester) async {
      final bloc = await loadedBloc([
        ReaderNote(
          id: 'h1',
          anchor: const ReaderNoteAnchor(
            kind: NoteAnchorKind.reflowable,
            chapterIndex: 0,
            startChar: 4,
            endChar: 9,
            text: 'quick',
          ),
          type: ReaderNoteType.highlight,
          style: HighlightStyle.highlight,
          colorValue: 'yellow',
          createdAt: _at,
          updatedAt: _at,
        ),
      ]);

      overlayState.currentSelection = const HyperTextSelection(
        start: 4,
        end: 9,
      );
      overlayState.currentSelectedText = 'quick';

      await tester.pumpWidget(buildMenuWidget(bloc));
      await tester.pump();

      expect(find.byIcon(LucideIcons.eraser), findsOneWidget);
    },
  );
}
