import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart'
    show HyperSelectionOverlayState, HyperTextSelection;
import 'package:readaway_core/readaway_core.dart' show PaginationCoordinator;

import '../../../../annotations/domain/entity/reader_note.dart';
import '../../controllers/reader_viewport_controller.dart';

/// Encapsulates the runtime context for an active text selection in the reader.
@immutable
class ReaderSelectionContext {
  const ReaderSelectionContext({
    required this.context,
    required this.selectedText,
    required this.selection,
    required this.chapterIndex,
    required this.coordinator,
    required this.overlayState,
    this.controller,
    this.anchor,
    this.existingHighlight,
  });

  /// The build context of the selection overlay.
  final BuildContext context;

  /// The exact characters currently selected.
  final String selectedText;

  /// Raw text selection bounds from HyperRender.
  final HyperTextSelection selection;

  /// Chapter index this selection belongs to.
  final int chapterIndex;

  /// Coordinator containing laid-out chapter geometry and character mapping.
  final PaginationCoordinator coordinator;

  /// State controller of the selection overlay (controls clear/copy/selectAll).
  final HyperSelectionOverlayState overlayState;

  /// Optional reader controller, notified to pause gesture page turns while selected.
  final ReaderViewportController? controller;

  /// Validated note anchor corresponding to this selection, if resolvable.
  final ReaderNoteAnchor? anchor;

  /// Existing highlight covering this passage, if any.
  final ReaderNote? existingHighlight;

  /// Whether this selection already has an active highlight note.
  bool get isHighlighted => existingHighlight != null;

  /// Clears the selection and updates the reader viewport controller.
  void clearSelection() {
    controller?.setSelectionActive(false);
    overlayState.clearSelection();
  }
}
