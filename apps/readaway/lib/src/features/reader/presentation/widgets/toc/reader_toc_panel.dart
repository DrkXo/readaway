import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../annotations/domain/entity/reader_note.dart';
import 'reader_side_panel.dart';

const double _panelWidth = 300;
const double _peekStripWidth = 24;
const Duration _peekDuration = Duration(milliseconds: 200);

/// Docked TOC panel shown on wide screens while pinned.
class ReaderTocSidePanel extends StatelessWidget {
  const ReaderTocSidePanel({
    super.key,
    required this.onUnpin,
    required this.onJumpToPage,
    required this.onJumpToNote,
  });

  final VoidCallback onUnpin;
  final void Function(int page) onJumpToPage;
  final void Function(ReaderNote note) onJumpToNote;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return SizedBox(
      width: _panelWidth,
      child: Material(
        color: appColors.sheetBackground,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: appColors.borderSubtle,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: ReaderSidePanel(
              onJumpToChapter: onJumpToPage,
              onJumpToNote: onJumpToNote,
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
    required this.onJumpToNote,
  });

  final VoidCallback onPin;
  final void Function(int page) onJumpToPage;
  final void Function(ReaderNote note) onJumpToNote;

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
                    color: appColors.sheetBackground,
                    elevation: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: appColors.borderSubtle,
                            width: 1.0,
                          ),
                        ),
                      ),
                      width: _panelWidth,
                      height: double.infinity,
                      child: SafeArea(
                        child: ReaderSidePanel(
                          onJumpToChapter: (chapter) {
                            widget.onJumpToPage(chapter);
                            _hide();
                          },
                          onJumpToNote: (note) {
                            widget.onJumpToNote(note);
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
