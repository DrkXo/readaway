import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_render/hyper_render.dart'
    show HyperSelectionOverlayState, SelectionMenuAction;
import 'package:readaway_core/readaway_core.dart' show PaginationCoordinator;

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../domain/services/annotation_anchor_resolver.dart';
import '../../../domain/services/reader_note_operations.dart';
import '../../bloc/annotations_bloc.dart';
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
  static List<SelectionMenuAction> actions(
    BuildContext context, {
    required int chapterIndex,
    required PaginationCoordinator coordinator,
    required HyperSelectionOverlayState state,
  }) {
    final bloc = context.read<AnnotationsBloc>();
    final selection = state.selection;

    final anchor = selection == null
        ? null
        : AnnotationAnchorResolver(coordinator).anchorForSelection(
            chapterIndex: chapterIndex,
            startChar: selection.start,
            endChar: selection.end,
          );

    // Whether this exact passage is already highlighted decides whether the
    // action adds a highlight or takes one away, so the label says which.
    final existing = anchor == null
        ? null
        : ReaderNoteOperations.identicalHighlight(bloc.state.notes, anchor);

    return [
      SelectionMenuAction(
        icon: Icons.format_color_fill,
        label: existing == null ? 'Highlight' : 'Unhighlight',
        onPressed: () {
          // The selection has served its purpose either way.
          state.clearSelection();

          if (anchor == null) {
            context.showToast(
              message: 'That selection cannot be highlighted in this document.',
              type: ToastType.warning,
            );
            return;
          }

          if (existing != null) {
            // Removing is itself a tombstone, so undo is its inverse.
            bloc.add(AnnotationsEvent.restoreNote(id: existing.id));
            context.showToast(
              message: 'Highlight removed',
              icon: Icons.format_color_fill,
              action: ToastAction(
                label: 'Undo',
                onPressed: () => bloc.add(
                  AnnotationsEvent.deleteNote(id: existing.id),
                ),
              ),
            );
            return;
          }

          bloc.add(
            AnnotationsEvent.addHighlight(
              anchor: anchor,
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
                  anchor,
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
          state.clearSelection();

          if (anchor == null) {
            context.showToast(
              message: 'That selection cannot be annotated in this document.',
              type: ToastType.warning,
            );
            return;
          }

          ReaderNoteEditorSheet.show(context: context, anchor: anchor);
        },
      ),
      // copySelection already clears the selection and reports success itself.
      SelectionMenuAction(
        icon: Icons.copy_rounded,
        label: 'Copy',
        onPressed: state.copySelection,
      ),
      SelectionMenuAction(
        icon: Icons.select_all_rounded,
        label: 'All',
        onPressed: state.selectAll,
      ),
      SelectionMenuAction(
        icon: Icons.close,
        label: 'Clear',
        onPressed: state.clearSelection,
      ),
    ];
  }
}
