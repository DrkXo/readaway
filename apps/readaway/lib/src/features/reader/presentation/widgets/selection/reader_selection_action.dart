import 'package:flutter/material.dart';

import 'reader_selection_context.dart';

/// Callback invoked when a selection action is triggered.
typedef SelectionActionCallback = void Function(ReaderSelectionContext context);

/// Describes a single action item available in the reader selection context menu.
@immutable
class ReaderSelectionAction {
  const ReaderSelectionAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isPrimary = false,
    this.customBuilder,
  });

  /// Unique identifier (e.g. 'highlight', 'note', 'copy', 'translate', 'define').
  final String id;

  /// Human-readable label displayed in menus and accessibility tags.
  final String label;

  /// Icon representing this action.
  final IconData icon;

  /// Optional accessibility tooltip; defaults to [label] if omitted.
  final String? tooltip;

  /// Whether this action appears on the primary floating bar or in the overflow sheet.
  final bool isPrimary;

  /// Invoked when the user executes this action.
  final SelectionActionCallback onTap;

  /// Optional custom widget to render in place of a standard icon button.
  final Widget Function(ReaderSelectionContext context)? customBuilder;
}
