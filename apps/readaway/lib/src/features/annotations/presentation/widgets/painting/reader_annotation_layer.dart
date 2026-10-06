import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../core/theme/tts_highlight_palette.dart';
import '../../../../reader/presentation/controllers/reader_viewport_controller.dart';
import '../../../domain/services/annotation_anchor_resolver.dart';
import '../../bloc/annotations_bloc.dart';
import '../notes/reader_note_editor_sheet.dart';
import 'reader_annotation_painter.dart';

/// Paints the open document's highlights behind a page's text.
///
/// Wrap the page content in this. The layer resolves each of the chapter's live
/// notes to rectangles and hands them to [ReaderAnnotationPainter] as the
/// [CustomPaint] painter, so highlights sit beneath the text and a highlighted
/// passage reads as marked rather than tinted.
///
/// It re-resolves in two situations, which is why it watches two things:
/// - the notes change, when one is added, restyled or deleted;
/// - the chapter re-measures, because a font or margin change discards the
///   chapter's geometry and the page re-registers it without rebuilding this
///   subtree.
///
/// Notes whose anchors cannot be resolved are skipped rather than approximated:
/// a highlight is never drawn in the wrong place.
class ReaderAnnotationLayer extends StatefulWidget {
  const ReaderAnnotationLayer({
    super.key,
    required this.chapterIndex,
    required this.coordinator,
    required this.controller,
    required this.sliceTop,
    required this.child,
  });

  /// The chapter the child renders, whose notes this layer paints.
  final int chapterIndex;

  /// Supplies the chapter's character geometry.
  final PaginationCoordinator coordinator;

  /// Receives this layer's tap handler, so a tap on a highlight can open it.
  ///
  /// This layer is the only thing that knows where the painted highlights are,
  /// but the page decides what a tap means; the controller is where those two
  /// meet.
  final ReaderViewportController controller;

  /// Chapter-local Y coordinate of the top of this page.
  final double sliceTop;

  /// The page content to paint behind.
  final Widget child;

  @override
  State<ReaderAnnotationLayer> createState() => _ReaderAnnotationLayerState();
}

class _ReaderAnnotationLayerState extends State<ReaderAnnotationLayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.annotationTapDelegate = _handleTap;
  }

  @override
  void didUpdateWidget(ReaderAnnotationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.annotationTapDelegate = null;
      widget.controller.annotationTapDelegate = _handleTap;
    }
  }

  @override
  void dispose() {
    // Only clear what is still ours: a replacement layer may already have
    // registered, and clearing blindly would silently break tapping.
    if (widget.controller.annotationTapDelegate == _handleTap) {
      widget.controller.annotationTapDelegate = null;
    }
    super.dispose();
  }

  /// Opens the annotation under [globalPosition] when one is there.
  ///
  /// Returns whether the tap was consumed, so the page falls through to its own
  /// tap zones when it was not.
  bool _handleTap(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;

    final bloc = context.read<AnnotationsBloc>();
    final paints = _paintsFor(context, bloc.state);
    if (paints.isEmpty) return false;

    final id = ReaderAnnotationPainter(
      paints: paints,
      sliceTop: widget.sliceTop,
      // Hit testing reads only the boxes, so neither of these matters here.
      brightness: Brightness.light,
      highContrast: false,
    ).noteAt(box.globalToLocal(globalPosition));

    if (id == null) return false;

    for (final note in bloc.state.notes) {
      if (note.id != id) continue;
      ReaderNoteEditorSheet.show(
        context: context,
        anchor: note.anchor,
        note: note,
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnotationsBloc, AnnotationsState>(
      // Rebuild only when this chapter's notes change. `byChapter` holds one
      // unmodifiable list per chapter and is preserved across unrelated emits,
      // so identity is a precise test: a filter change, a page turn or a TTS
      // update leaves it identical and costs nothing.
      buildWhen: (previous, current) => !identical(
        previous.notesForChapter(widget.chapterIndex),
        current.notesForChapter(widget.chapterIndex),
      ),
      // The structure around the page content is deliberately unconditional.
      //
      // Wrapping it only when there is something to paint moved the entire
      // chapter subtree — the render box and the selection overlay included —
      // to a different depth whenever an annotation appeared, changed chapter,
      // or stopped resolving. Reparenting that subtree while a frame is
      // flushing semantics is what produces the framework's
      // "!child.attached" and "node.built" assertions, so this keeps one shape
      // at all times and varies only what the painter draws. An empty painter
      // costs a single no-op paint.
      builder: (context, state) => StreamBuilder<PaginationState>(
        stream: widget.coordinator.state,
        initialData: widget.coordinator.currentState,
        builder: (context, snapshot) => CustomPaint(
          painter: ReaderAnnotationPainter(
            paints: _paintsFor(context, state),
            sliceTop: widget.sliceTop,
            brightness: Theme.of(context).brightness,
            highContrast: MediaQuery.highContrastOf(context),
          ),
          child: widget.child,
        ),
      ),
    );
  }

  /// Resolves this chapter's live notes into the geometry to paint.
  ///
  /// Returns an empty list rather than letting the caller skip the painter, so
  /// that the tree above the page content never changes shape.
  List<AnnotationPaint> _paintsFor(
    BuildContext context,
    AnnotationsState state,
  ) {
    final notes = state.notesForChapter(widget.chapterIndex);
    if (notes.isEmpty) return const [];

    final resolver = AnnotationAnchorResolver(widget.coordinator);
    final scheme = Theme.of(context).colorScheme;
    final paints = <AnnotationPaint>[];

    for (final note in notes) {
      if (!note.isPainted) continue;
      final resolved = resolver.resolve(note);
      if (!resolved.isPaintable) continue;

      paints.add(
        AnnotationPaint(
          id: note.id,
          rects: resolved.rects,
          style: note.style,
          // The palette is the single source of truth for what a colour value
          // means, and it follows the theme for the "primary" preset.
          baseColor: resolveTtsHighlightColor(note.colorValue, scheme),
        ),
      );
    }

    return paints;
  }
}
