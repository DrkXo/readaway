part of '../reader_widgets.dart';

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
                        icon: const Icon(LucideIcons.copy),
                      ),
                      // Dictionary lookup only makes sense for one word.
                      if (!text.trim().contains(RegExp(r'\s')))
                        IconButton.filledTonal(
                          tooltip: 'Dictionary',
                          onPressed: () =>
                              onLookup(ReaderLookupKind.dictionary),
                          icon: const Icon(LucideIcons.bookOpen),
                        ),
                      IconButton.filledTonal(
                        tooltip: 'Translate',
                        onPressed: () => onLookup(ReaderLookupKind.translate),
                        icon: const Icon(LucideIcons.languages),
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
