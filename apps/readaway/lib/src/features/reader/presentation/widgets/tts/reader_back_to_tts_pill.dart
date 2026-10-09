import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bloc/reader_bloc.dart';
import '../../bloc/tts/reader_tts_bloc.dart';

/// A floating pill banner shown when the user has navigated away from the page
/// actively being read aloud by TTS.
///
/// Tapping the pill dispatches the jump to chapter/page on [ReaderBloc] and
/// clears the follow target on [ReaderTtsBloc].
class ReaderBackToTtsPill extends StatefulWidget {
  const ReaderBackToTtsPill({super.key, this.topOffset = 76.0});

  /// Top position in logical pixels.
  final double topOffset;

  @override
  State<ReaderBackToTtsPill> createState() => _ReaderBackToTtsPillState();
}

class _ReaderBackToTtsPillState extends State<ReaderBackToTtsPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -0.35),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    final ttsState = context.read<ReaderTtsBloc>().state;
    final readerState = context.read<ReaderBloc>().state;
    if (ttsState.canJumpToTtsPage(
      currentPage: readerState.currentPage,
      currentVirtualPage: readerState.currentVirtualPage,
    )) {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final ttsState = context.watch<ReaderTtsBloc>().state;
    final readerState = context.watch<ReaderBloc>().state;
    final canJump = ttsState.canJumpToTtsPage(
      currentPage: readerState.currentPage,
      currentVirtualPage: readerState.currentVirtualPage,
    );
    final pageLabel = ttsState.ttsPageLabel;
    final visible = canJump && pageLabel != null;

    if (visible) {
      if (_animController.status != AnimationStatus.forward &&
          _animController.status != AnimationStatus.completed) {
        _animController.forward();
      }
    } else {
      if (_animController.status != AnimationStatus.reverse &&
          _animController.status != AnimationStatus.dismissed) {
        _animController.reverse();
      }
    }

    return Positioned(
      top: widget.topOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                child: InkWell(
                  onTap: visible
                      ? () {
                          final chapter = ttsState.ttsCurrentPage;
                          if (chapter != null) {
                            context.read<ReaderBloc>().add(
                              ReaderEvent.jumpToChapter(
                                chapterIndex: chapter,
                                virtualPage: ttsState.ttsTargetVirtualPage,
                              ),
                            );
                            context.read<ReaderTtsBloc>().add(
                              const ReaderTtsEvent.clearFollowTarget(),
                            );
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.94,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.audioLines,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Audio (Page $pageLabel)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.arrowUpRight,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
