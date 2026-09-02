import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import 'reader_toc_content.dart';

const double _panelWidth = 300;
const double _peekStripWidth = 24;
const Duration _peekDuration = Duration(milliseconds: 200);

/// Docked TOC panel shown on wide screens while pinned.
class ReaderTocSidePanel extends StatelessWidget {
  const ReaderTocSidePanel({
    super.key,
    required this.onUnpin,
    required this.onJumpToPage,
  });

  final VoidCallback onUnpin;
  final void Function(int page) onJumpToPage;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return SizedBox(
      width: _panelWidth,
      child: Material(
        color: appColors.readerBackground,
        child: DecoratedBox(
          decoration: BoxDecoration(boxShadow: appColors.shadowLg),
          child: SafeArea(
            child: ReaderTocContent(
              onJumpToPage: onJumpToPage,
              headerAction: PinButton(pinned: true, onTap: onUnpin),
            ),
          ),
        ),
      ),
    );
  }
}

/// Invisible left-edge strip that reveals a floating TOC panel on hover.
/// Hides when the pointer leaves; pinning is handled by the parent.
class ReaderTocPeek extends StatefulWidget {
  const ReaderTocPeek({
    super.key,
    required this.onPin,
    required this.onJumpToPage,
  });

  final VoidCallback onPin;
  final void Function(int page) onJumpToPage;

  @override
  State<ReaderTocPeek> createState() => _ReaderTocPeekState();
}

class _ReaderTocPeekState extends State<ReaderTocPeek> {
  bool _visible = false;

  void _show() {
    if (!_visible) setState(() => _visible = true);
  }

  void _hide() {
    if (_visible) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Stack(
        children: [
          MouseRegion(
            opaque: false,
            onEnter: (_) => _show(),
            child: const SizedBox(
              width: _peekStripWidth,
              height: double.infinity,
            ),
          ),
          IgnorePointer(
            ignoring: !_visible,
            child: MouseRegion(
              onExit: (_) => _hide(),
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(-1, 0),
                duration: _peekDuration,
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: _peekDuration,
                  curve: Curves.easeOut,
                  child: Material(
                    color: appColors.readerBackground,
                    elevation: 8,
                    child: SizedBox(
                      width: _panelWidth,
                      height: double.infinity,
                      child: SafeArea(
                        child: ReaderTocContent(
                          onJumpToPage: (page) {
                            widget.onJumpToPage(page);
                            _hide();
                          },
                          headerAction: PinButton(
                            pinned: false,
                            onTap: widget.onPin,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
