library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../domain/models/reader_lookup.dart';
import 'reader_selection_toolbar.dart';

/// Contextual (non-modal) text-selection menu for reflowable reader pages.
///
/// Wraps page content in Material's [SelectionArea]: paragraphs must be
/// [Text]/Text.rich widgets, which register with the ambient
/// `SelectionContainer` (a raw `RichText` never registers and is invisible
/// to selection). The native toolbar is suppressed; when a non-empty
/// selection survives pointer-up, a themed popup opens above the selection
/// band (flipping below when there is no room). It is a plain [OverlayEntry] —
/// no route push — dismissed by any tap outside it.
///
/// Built by hand instead of SelectionArea.contextMenuBuilder because Flutter
/// never shows that toolbar after a desktop mouse-drag selection and offers
/// no public API to force it (selectable_region.dart skips _showToolbar on
/// macOS/Linux/Windows drag end).
class ReaderSelectionArea extends StatefulWidget {
  const ReaderSelectionArea({super.key, required this.child});

  final Widget child;

  @override
  State<ReaderSelectionArea> createState() => _ReaderSelectionAreaState();
}

class _ReaderSelectionAreaState extends State<ReaderSelectionArea> {
  String _selectedText = '';
  Offset? _pointerDownPos;
  OverlayEntry? _menu;

  void _onSelectionChanged(SelectedContent? content) {
    _selectedText = content?.plainText ?? '';
  }

  void _onPointerUp(PointerUpEvent event) {
    final text = _selectedText.trim();
    if (_menu != null || text.isEmpty || !mounted) return;
    // Approximate the selection band with press->release pointers;
    // SelectionArea exposes no public selection-rect API.
    final band = Rect.fromPoints(
      _pointerDownPos ?? event.position,
      event.position,
    );
    _menu = OverlayEntry(
      builder: (_) => ReaderSelectionToolbar(
        band: band,
        text: text,
        onDismiss: _closeMenu,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Copied to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _closeMenu();
        },
        onLookup: (kind) {
          _closeMenu();
          context.push(
            appRoutes.readerLookup.path,
            extra: ReaderLookupRequest(kind: kind, text: text),
          );
        },
      ),
    );
    Overlay.of(context).insert(_menu!);
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPos = event.position;
  }

  void _closeMenu() {
    _menu?.remove();
    _menu = null;
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: SelectionArea(
        onSelectionChanged: _onSelectionChanged,
        contextMenuBuilder: (_, _) => const SizedBox.shrink(),
        child: DefaultSelectionStyle(
          selectionColor: context.appColors.scheme.primary.withValues(
            alpha: 0.25,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
