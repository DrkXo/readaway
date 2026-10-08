import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/services/toast/toast_service.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/reader/presentation/controllers/reader_viewport_controller.dart';
import 'package:readaway/src/features/reader/presentation/widgets/selection/reader_selection_action.dart';
import 'package:readaway/src/features/reader/presentation/widgets/selection/reader_selection_action_registry.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../helpers/test_mocks.dart';

class MockHyperSelectionOverlayState extends Mock
    implements HyperSelectionOverlayState {
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
    'buildContext resolves anchor and identifies existing highlight',
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

      when(overlayState.selection)
          .thenReturn(const HyperTextSelection(start: 4, end: 9));
      when(overlayState.selectedText).thenReturn('quick');

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: Builder(
              builder: (context) {
                final selCtx = ReaderSelectionActionRegistry.buildContext(
                  context: context,
                  chapterIndex: 0,
                  coordinator: coordinator,
                  overlayState: overlayState,
                  controller: controller,
                );

                expect(selCtx.selectedText, 'quick');
                expect(selCtx.isHighlighted, isTrue);
                expect(selCtx.existingHighlight?.id, 'h1');
                expect(selCtx.anchor?.startChar, 4);
                expect(selCtx.anchor?.endChar, 9);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    },
  );

  testWidgets('getPrimaryActions contains note and copy actions', (
    tester,
  ) async {
    final bloc = await loadedBloc([]);

    when(overlayState.selection)
        .thenReturn(const HyperTextSelection(start: 4, end: 9));
    when(overlayState.selectedText).thenReturn('quick');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              final selCtx = ReaderSelectionActionRegistry.buildContext(
                context: context,
                chapterIndex: 0,
                coordinator: coordinator,
                overlayState: overlayState,
                controller: controller,
              );

              final primary = ReaderSelectionActionRegistry.getPrimaryActions(
                selCtx,
              );
              expect(primary.map((a) => a.id), containsAll(['note', 'copy']));
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  testWidgets(
    'getSecondaryActions contains define, translate, tts, share, and select_all',
    (tester) async {
      final bloc = await loadedBloc([]);

      when(overlayState.selection)
          .thenReturn(const HyperTextSelection(start: 4, end: 9));
      when(overlayState.selectedText).thenReturn('quick');

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: Builder(
              builder: (context) {
                final selCtx = ReaderSelectionActionRegistry.buildContext(
                  context: context,
                  chapterIndex: 0,
                  coordinator: coordinator,
                  overlayState: overlayState,
                  controller: controller,
                );

                final secondary =
                    ReaderSelectionActionRegistry.getSecondaryActions(selCtx);
                expect(
                  secondary.map((a) => a.id),
                  containsAll([
                    'define',
                    'translate',
                    'tts',
                    'share',
                    'select_all',
                  ]),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    },
  );

  testWidgets('custom action handler registration overrides execution', (
    tester,
  ) async {
    final bloc = await loadedBloc([]);

    when(overlayState.selection)
        .thenReturn(const HyperTextSelection(start: 4, end: 9));
    when(overlayState.selectedText).thenReturn('quick');

    var customHandlerFired = false;
    ReaderSelectionActionRegistry.registerHandler('define', (ctx) {
      customHandlerFired = true;
    });
    addTearDown(
      () => ReaderSelectionActionRegistry.unregisterHandler('define'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              final selCtx = ReaderSelectionActionRegistry.buildContext(
                context: context,
                chapterIndex: 0,
                coordinator: coordinator,
                overlayState: overlayState,
                controller: controller,
              );

              final secondary =
                  ReaderSelectionActionRegistry.getSecondaryActions(selCtx);
              final defineAction = secondary.firstWhere(
                (a) => a.id == 'define',
              );
              defineAction.onTap(selCtx);
              expect(customHandlerFired, isTrue);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  testWidgets('registerAction adds dynamic action to secondary actions', (
    tester,
  ) async {
    final bloc = await loadedBloc([]);

    when(overlayState.selection)
        .thenReturn(const HyperTextSelection(start: 4, end: 9));
    when(overlayState.selectedText).thenReturn('quick');

    final customAction = ReaderSelectionAction(
      id: 'custom_lookup',
      label: 'Custom Lookup',
      icon: Icons.search,
      onTap: (_) {},
    );
    ReaderSelectionActionRegistry.registerAction(customAction);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              final selCtx = ReaderSelectionActionRegistry.buildContext(
                context: context,
                chapterIndex: 0,
                coordinator: coordinator,
                overlayState: overlayState,
                controller: controller,
              );

              final secondary =
                  ReaderSelectionActionRegistry.getSecondaryActions(selCtx);
              expect(
                secondary.any((a) => a.id == 'custom_lookup'),
                isTrue,
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  testWidgets('applyHighlight dispatches addHighlight and clears selection', (
    tester,
  ) async {
    final bloc = await loadedBloc([]);

    when(overlayState.selection)
        .thenReturn(const HyperTextSelection(start: 4, end: 9));
    when(overlayState.selectedText).thenReturn('quick');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              final selCtx = ReaderSelectionActionRegistry.buildContext(
                context: context,
                chapterIndex: 0,
                coordinator: coordinator,
                overlayState: overlayState,
                controller: controller,
              );

              ReaderSelectionActionRegistry.applyHighlight(selCtx, 'yellow');
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await tester.pump();
    verify(overlayState.clearSelection()).called(1);
    expect(bloc.state.notes.length, 1);
    expect(bloc.state.notes.first.colorValue, 'yellow');
  });
}
