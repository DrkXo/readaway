import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_render/hyper_render.dart'
    show HyperSelectionOverlayState, HyperTextSelection;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart' show PaginationCoordinator;
import 'package:share_plus/share_plus.dart';

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../../annotations/domain/entity/reader_note.dart';
import '../../../../annotations/domain/services/annotation_anchor_resolver.dart';
import '../../../../annotations/domain/services/reader_note_operations.dart';
import '../../../../annotations/presentation/bloc/annotations_bloc.dart';
import '../../../../annotations/presentation/widgets/notes/reader_note_defaults.dart';
import '../../../../annotations/presentation/widgets/notes/reader_note_editor_sheet.dart';
import '../../bloc/reader_bloc.dart';
import '../../bloc/tts/reader_tts_bloc.dart';
import '../../controllers/reader_viewport_controller.dart';
import 'reader_lookup_sheet.dart';
import 'reader_selection_action.dart';
import 'reader_selection_context.dart';

/// Central registry managing available text selection actions in the reader.
///
/// Designed for extensibility: new tools (dictionaries, translation services,
/// search providers, LLM integrations) can register action handlers without
/// altering the core selection UI.
class ReaderSelectionActionRegistry {
  ReaderSelectionActionRegistry._();

  static final Map<String, SelectionActionCallback> _customHandlers = {};
  static final List<ReaderSelectionAction> _customActions = [];

  /// Registers or overrides an action callback for [actionId].
  static void registerHandler(
    String actionId,
    SelectionActionCallback handler,
  ) {
    _customHandlers[actionId] = handler;
  }

  /// Removes a custom action handler.
  static void unregisterHandler(String actionId) {
    _customHandlers.remove(actionId);
  }

  /// Registers an entirely new action item into the menu pipeline.
  static void registerAction(ReaderSelectionAction action) {
    _customActions.removeWhere((a) => a.id == action.id);
    _customActions.add(action);
  }

  /// Builds a [ReaderSelectionContext] from the active overlay state.
  static ReaderSelectionContext buildContext({
    required BuildContext context,
    required int chapterIndex,
    required PaginationCoordinator coordinator,
    required HyperSelectionOverlayState overlayState,
    ReaderViewportController? controller,
  }) {
    final sel = overlayState.selection;
    final selectedText = overlayState.selectedText ?? '';

    final anchor = _resolveAnchor(
      coordinator: coordinator,
      chapterIndex: chapterIndex,
      selection: sel,
    );

    final bloc = context.read<AnnotationsBloc>();
    final existing = anchor == null
        ? null
        : ReaderNoteOperations.identicalHighlight(bloc.state.notes, anchor);

    return ReaderSelectionContext(
      context: context,
      selectedText: selectedText,
      selection: sel ?? const HyperTextSelection(start: 0, end: 0),
      chapterIndex: chapterIndex,
      coordinator: coordinator,
      overlayState: overlayState,
      controller: controller,
      anchor: anchor,
      existingHighlight: existing,
    );
  }

  /// Resolves an anchor dynamically from selection bounds.
  static ReaderNoteAnchor? _resolveAnchor({
    required PaginationCoordinator coordinator,
    required int chapterIndex,
    required HyperTextSelection? selection,
  }) {
    if (selection == null || selection.isCollapsed) return null;
    var s = math.min(selection.start, selection.end);
    var e = math.max(selection.start, selection.end);

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

  /// Retrieves the list of primary actions (displayed inline on the capsule bar).
  static List<ReaderSelectionAction> getPrimaryActions(
    ReaderSelectionContext ctx,
  ) {
    return [
      ReaderSelectionAction(
        id: 'note',
        label: 'Note',
        icon: LucideIcons.filePenLine,
        isPrimary: true,
        onTap: (c) => _handleNoteAction(c),
      ),
      ReaderSelectionAction(
        id: 'copy',
        label: 'Copy',
        icon: LucideIcons.copy,
        isPrimary: true,
        onTap: (c) {
          c.controller?.setSelectionActive(false);
          c.overlayState.copySelection();
        },
      ),
    ];
  }

  /// Retrieves the list of secondary actions (displayed in the overflow sheet/menu).
  static List<ReaderSelectionAction> getSecondaryActions(
    ReaderSelectionContext ctx,
  ) {
    final actions = <ReaderSelectionAction>[
      ReaderSelectionAction(
        id: 'define',
        label: 'Define',
        icon: LucideIcons.bookOpen,
        tooltip: 'Look up in dictionary',
        onTap: (c) {
          final handler = _customHandlers['define'];
          if (handler != null) {
            handler(c);
          } else {
            ReaderLookupSheet.show(
              context: c.context,
              selectedText: c.selectedText,
              initialMode: ReaderLookupMode.definition,
            );
          }
        },
      ),
      ReaderSelectionAction(
        id: 'translate',
        label: 'Translate',
        icon: LucideIcons.languages,
        tooltip: 'Translate selected text',
        onTap: (c) {
          final handler = _customHandlers['translate'];
          if (handler != null) {
            handler(c);
          } else {
            ReaderLookupSheet.show(
              context: c.context,
              selectedText: c.selectedText,
              initialMode: ReaderLookupMode.translation,
            );
          }
        },
      ),
      ReaderSelectionAction(
        id: 'tts',
        label: 'Speak',
        icon: LucideIcons.volume2,
        tooltip: 'Read aloud',
        onTap: (c) {
          final handler = _customHandlers['tts'];
          if (handler != null) {
            handler(c);
          } else {
            _handleTtsAction(c);
          }
        },
      ),
      ReaderSelectionAction(
        id: 'share',
        label: 'Share',
        icon: LucideIcons.share2,
        tooltip: 'Share excerpt',
        onTap: (c) {
          SharePlus.instance.share(ShareParams(text: c.selectedText));
          c.clearSelection();
        },
      ),
      ReaderSelectionAction(
        id: 'select_all',
        label: 'Select All',
        icon: LucideIcons.checkCheck,
        tooltip: 'Select entire chapter',
        onTap: (c) => c.overlayState.selectAll(),
      ),
      ..._customActions.where((a) => !a.isPrimary),
    ];

    return actions;
  }

  /// Executes highlight application with a specific color key.
  static void applyHighlight(ReaderSelectionContext ctx, String colorKey) {
    final targetAnchor = ctx.anchor;
    ctx.clearSelection();

    if (targetAnchor == null) {
      ctx.context.showToast(
        message: 'That selection cannot be highlighted in this document.',
        type: ToastType.warning,
      );
      return;
    }

    final bloc = ctx.context.read<AnnotationsBloc>();
    final liveExisting = ReaderNoteOperations.identicalHighlight(
      bloc.state.notes,
      targetAnchor,
    );

    if (liveExisting != null && liveExisting.colorValue == colorKey) {
      // Tapping the same color again toggles it off
      bloc.add(AnnotationsEvent.restoreNote(id: liveExisting.id));
      ctx.context.showToast(
        message: 'Highlight removed',
        icon: LucideIcons.highlighter,
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
        colorValue: colorKey,
      ),
    );

    ctx.context.showToast(
      message: 'Highlighted',
      type: ToastType.success,
      icon: LucideIcons.highlighter,
      action: ToastAction(
        label: 'Undo',
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
  }

  /// Removes an existing highlight on the selection.
  static void removeHighlight(ReaderSelectionContext ctx) {
    final targetAnchor = ctx.anchor;
    ctx.clearSelection();

    if (targetAnchor == null) return;
    final bloc = ctx.context.read<AnnotationsBloc>();
    final liveExisting = ReaderNoteOperations.identicalHighlight(
      bloc.state.notes,
      targetAnchor,
    );

    if (liveExisting != null) {
      bloc.add(AnnotationsEvent.restoreNote(id: liveExisting.id));
      ctx.context.showToast(
        message: 'Highlight removed',
        icon: LucideIcons.highlighter,
        action: ToastAction(
          label: 'Undo',
          onPressed: () => bloc.add(
            AnnotationsEvent.deleteNote(id: liveExisting.id),
          ),
        ),
      );
    }
  }

  static void _handleNoteAction(ReaderSelectionContext ctx) {
    final targetAnchor = ctx.anchor;
    ctx.clearSelection();

    if (targetAnchor == null) {
      ctx.context.showToast(
        message: 'That selection cannot be annotated in this document.',
        type: ToastType.warning,
      );
      return;
    }

    final bloc = ctx.context.read<AnnotationsBloc>();
    final existingNote =
        ctx.existingHighlight ??
        bloc.state.notes.cast<ReaderNote?>().firstWhere(
          (n) =>
              n != null &&
              !n.isDeleted &&
              n.anchor.chapterIndex == targetAnchor.chapterIndex &&
              n.anchor.startChar == targetAnchor.startChar &&
              n.anchor.endChar == targetAnchor.endChar,
          orElse: () => null,
        );

    ReaderNoteEditorSheet.show(
      context: ctx.context,
      anchor: targetAnchor,
      note: existingNote,
    );
  }

  static void _handleTtsAction(ReaderSelectionContext ctx) {
    final anchor = ctx.anchor;
    ctx.clearSelection();

    if (anchor == null) {
      ctx.context.showToast(
        message: 'Cannot read selected text.',
        type: ToastType.info,
      );
      return;
    }

    final readerState = ctx.context.read<ReaderBloc>().state;
    final ttsBloc = ctx.context.read<ReaderTtsBloc>();
    ttsBloc.add(
      ReaderTtsEvent.start(
        documentPath: readerState.documentPath ?? '',
        pageIndex: readerState.currentPage,
        pageCount: readerState.pageCount,
        fileName: readerState.fileName,
        bookTitle: readerState.bookTitle,
        author: readerState.author,
        isReflowable: readerState.isReflowable,
        currentVirtualPage: readerState.currentVirtualPage,
      ),
    );
  }
}
