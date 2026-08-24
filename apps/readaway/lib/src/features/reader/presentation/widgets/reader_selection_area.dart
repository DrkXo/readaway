import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/theme/theme.dart';
import '../pages/reader_lookup_sheet.dart';

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
/// ponytail: built by hand instead of SelectionArea.contextMenuBuilder
/// because Flutter never shows that toolbar after a desktop mouse-drag
/// selection and offers no public API to force it (selectable_region.dart
/// skips _showToolbar on macOS/linux/windows drag end).
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
    // ponytail: approximate the selection band with press->release pointers;
    // SelectionArea exposes no public selection-rect API.
    final band = Rect.fromPoints(
      _pointerDownPos ?? event.position,
      event.position,
    );
    _menu = OverlayEntry(
      builder: (_) => _SelectionMenu(
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

class _SelectionMenu extends StatelessWidget {
  const _SelectionMenu({
    required this.band,
    required this.text,
    required this.onDismiss,
    required this.onCopy,
    required this.onLookup,
  });

  final Rect band;
  final String text;
  final VoidCallback onDismiss;
  final VoidCallback onCopy;
  final void Function(ReaderLookupKind kind) onLookup;

  // ponytail: fixed estimate for clamping; measure the card if it ever clips.
  static const _size = Size(216, 132);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scheme = context.appColors.scheme;
    final left = (band.center.dx - _size.width / 2).clamp(
      8.0,
      screen.width - _size.width - 8,
    );
    var top = band.top - _size.height - 10;
    if (top < 8) top = band.bottom + 10;

    return Stack(
      children: [
        // Full-screen catcher: the first tap anywhere just closes the menu.
        Positioned.fill(
          child: GestureDetector(onTap: onDismiss),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: _size.width,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                boxShadow: context.appColors.shadowLg,
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Copy',
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded),
                      ),
                      // Dictionary lookup only makes sense for one word.
                      if (!text.trim().contains(RegExp(r'\s')))
                        IconButton.filledTonal(
                          tooltip: 'Dictionary',
                          onPressed: () =>
                              onLookup(ReaderLookupKind.dictionary),
                          icon: const Icon(Icons.menu_book_rounded),
                        ),
                      IconButton.filledTonal(
                        tooltip: 'Translate',
                        onPressed: () => onLookup(ReaderLookupKind.translate),
                        icon: const Icon(Icons.translate_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
