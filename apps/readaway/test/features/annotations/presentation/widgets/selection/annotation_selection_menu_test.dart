import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/annotations/presentation/widgets/selection/annotation_selection_menu.dart';
import 'package:readaway/src/features/reader/presentation/controllers/reader_viewport_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway/src/core/services/toast/toast_service.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../helpers/test_mocks.dart';

class MockHyperSelectionOverlayState extends Mock
    implements HyperSelectionOverlayState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      super.toString();
}

const _path = '/books/a.epub';
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
  late MockHyperSelectionOverlayState overlayState;

  setUp(() {
    repository = MockAnnotationsRepository();
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
    overlayState = MockHyperSelectionOverlayState();
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
    when(repository.getForDocument(_path)).thenAnswer((_) async {
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

  testWidgets(
    'Highlight action dynamically evaluates current handle selection and adds highlight',
    (tester) async {
      final bloc = await loadedBloc([]);

      // Initially selected 'The' (0..3)
      when(overlayState.selection)
          .thenReturn(const HyperTextSelection(start: 0, end: 3));

      late List<SelectionMenuAction> actions;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: Builder(
              builder: (context) {
                actions = AnnotationSelectionMenu.actions(
                  context,
                  chapterIndex: 0,
                  coordinator: coordinator,
                  state: overlayState,
                  controller: controller,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Now simulated: user drags handle to 'brown' (10..15)
      when(overlayState.selection)
          .thenReturn(const HyperTextSelection(start: 10, end: 15));

      final highlightAction = actions.firstWhere((a) => a.label == 'Highlight');
      highlightAction.onPressed();
      await tester.pumpAndSettle();

      // Verify clearSelection was called
      verify(overlayState.clearSelection()).called(1);

      // Verify note added with range 10..15 ('brown'), not 0..3 ('The')
      expect(bloc.state.notes.length, 1);
      expect(bloc.state.notes.first.anchor.startChar, 10);
      expect(bloc.state.notes.first.anchor.endChar, 15);
      expect(bloc.state.notes.first.anchor.text, 'brown');
    },
  );

  testWidgets(
    'Highlight action handles backward selection (start > end) and whitespace',
    (tester) async {
      final bloc = await loadedBloc([]);

      // User dragged backwards from 16 to 9 (' brown ')
      when(overlayState.selection)
          .thenReturn(const HyperTextSelection(start: 16, end: 9));

      late List<SelectionMenuAction> actions;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: Builder(
              builder: (context) {
                actions = AnnotationSelectionMenu.actions(
                  context,
                  chapterIndex: 0,
                  coordinator: coordinator,
                  state: overlayState,
                  controller: controller,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final highlightAction = actions.firstWhere((a) => a.label == 'Highlight');
      highlightAction.onPressed();
      await tester.pumpAndSettle();

      // Verify note added with trimmed range 10..15 ('brown')
      expect(bloc.state.notes.length, 1);
      expect(bloc.state.notes.first.anchor.startChar, 10);
      expect(bloc.state.notes.first.anchor.endChar, 15);
      expect(bloc.state.notes.first.anchor.text, 'brown');
    },
  );
}
