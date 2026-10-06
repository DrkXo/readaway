import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_render/hyper_render.dart'
    show HyperSelectionOverlayState, HyperTextSelection, SelectionMenuAction;
import 'package:readaway_core/readaway_core.dart' show PaginationCoordinator;

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../domain/entity/reader_note.dart';
import '../../../domain/services/annotation_anchor_resolver.dart';
import '../../../domain/services/reader_note_operations.dart';
import '../../bloc/annotations_bloc.dart';
import '../../../../reader/presentation/controllers/reader_viewport_controller.dart';
import '../notes/reader_note_defaults.dart';
import '../notes/reader_note_editor_sheet.dart';

/// The actions offered for a text selection in the reader.
///
/// The selection overlay already positions, animates and dismisses its own
/// menu; this supplies only the actions and what they do, so the reader's own
/// actions appear in the affordance the platform would have shown anyway rather
/// than in a second, competing menu.
///
/// Icons are Material rather than Lucide to match the overlay's built-in
/// buttons, which these replace.
abstract final class AnnotationSelectionMenu {
  /// Builds the actions for the selection [state] currently holds.
  ///
  /// [coordinator] is needed because a selection arrives as character offsets
  /// and an annotation has to be stored as a validated anchor.
  ///
  /// [controller] optionally receives selection activity updates so the reader
  /// gesture arena does not initiate page turns while text is selected.
  static List<SelectionMenuAction> actions(
    BuildContext context, {
    required int chapterIndex,
    required PaginationCoordinator coordinator,
    required HyperSelectionOverlayState state,
    ReaderViewportController? controller,
  }) {
    final bloc = context.read<AnnotationsBloc>();

    /// Resolves an anchor dynamically from [sel], normalizing reversed bounds
    /// and trimming leading/trailing whitespace to match rendered text boxes.
    ReaderNoteAnchor? resolveAnchor(HyperTextSelection? sel) {
      if (sel == null || sel.isCollapsed) return null;
      var s = math.min(sel.start, sel.end);
      var e = math.max(sel.start, sel.end);

      final layout = coordinator.getChapterLayout(chapterIndex);
      if (layout != null && layout.hasCharacterMapping) {
        final flow = layout.flowText;
        s = s.clamp(0, flow.length);
        e = e.clamp(0, flow.length);
        while (s < e && flow.codeUnitAt(s) <= 32) {
          s++;
        }
        while (e > s && flow.codeUnitAt(e - 1) <= 32) {
          e--;
        }
      }

      if (e <= s) return null;

      return AnnotationAnchorResolver(coordinator).anchorForSelection(
        chapterIndex: chapterIndex,
        startChar: s,
        endChar: e,
      );
    }

    final initialAnchor = resolveAnchor(state.selection);

    // Whether this exact passage is already highlighted decides whether the
    // action adds a highlight or takes one away, so the label says which.
    final existing = initialAnchor == null
        ? null
        : ReaderNoteOperations.identicalHighlight(
            bloc.state.notes,
            initialAnchor,
          );

    return [
      SelectionMenuAction(
        icon: Icons.format_color_fill,
        label: existing == null ? 'Highlight' : 'Unhighlight',
        onPressed: () {
          // Re-evaluate from live state before clearing, in case handles moved.
          final targetAnchor = resolveAnchor(state.selection) ?? initialAnchor;

          // The selection has served its purpose either way.
          state.clearSelection();
          controller?.setSelectionActive(false);

          if (targetAnchor == null) {
            context.showToast(
              message: 'That selection cannot be highlighted in this document.',
              type: ToastType.warning,
            );
            return;
          }

          final liveExisting = ReaderNoteOperations.identicalHighlight(
            bloc.state.notes,
            targetAnchor,
          );

          if (liveExisting != null) {
            // Removing is itself a tombstone, so undo is its inverse.
            bloc.add(AnnotationsEvent.restoreNote(id: liveExisting.id));
            context.showToast(
              message: 'Highlight removed',
              icon: Icons.format_color_fill,
              action: ToastAction(
                label: 'Undo',
                onPressed: () => bloc.add(
                  AnnotationsEvent.deleteNote(id: liveExisting.id),
                ),
              ),
            );
            return;
          }

          bloc.add(
            AnnotationsEvent.addHighlight(
              anchor: targetAnchor,
              style: kDefaultHighlightStyle,
              colorValue: kDefaultHighlightColorValue,
            ),
          );
          context.showToast(
            message: 'Highlighted',
            type: ToastType.success,
            icon: Icons.format_color_fill,
            action: ToastAction(
              label: 'Undo',
              // The note's id is minted inside the bloc, so it is looked up
              // when Undo is actually pressed rather than predicted here. The
              // lookup uses the same rule that decided to create it.
              onPressed: () {
                final created = ReaderNoteOperations.identicalHighlight(
                  bloc.state.notes,
                  targetAnchor,
                );
                if (created != null) {
                  bloc.add(AnnotationsEvent.deleteNote(id: created.id));
                }
              },
            ),
          );
        },
      ),
      // Writing a note is the other half of annotating: a highlight marks the
      // passage, a note says what about it.
      SelectionMenuAction(
        icon: Icons.edit_note,
        label: 'Note',
        onPressed: () {
          final targetAnchor = resolveAnchor(state.selection) ?? initialAnchor;

          state.clearSelection();
          controller?.setSelectionActive(false);

          if (targetAnchor == null) {
            context.showToast(
              message: 'That selection cannot be annotated in this document.',
              type: ToastType.warning,
            );
            return;
          }

          ReaderNoteEditorSheet.show(context: context, anchor: targetAnchor);
        },
      ),
      // copySelection already clears the selection and reports success itself.
      SelectionMenuAction(
        icon: Icons.copy_rounded,
        label: 'Copy',
        onPressed: () {
          controller?.setSelectionActive(false);
          state.copySelection();
        },
      ),
      SelectionMenuAction(
        icon: Icons.select_all_rounded,
        label: 'All',
        onPressed: state.selectAll,
      ),
      SelectionMenuAction(
        icon: Icons.close,
        label: 'Clear',
        onPressed: () {
          controller?.setSelectionActive(false);
          state.clearSelection();
        },
      ),
    ];
  }
}
