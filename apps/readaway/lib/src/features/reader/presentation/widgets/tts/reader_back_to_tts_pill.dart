import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bloc/reader_bloc.dart';

/// A floating pill banner shown when the user has navigated away from the page
/// actively being read aloud by TTS.
///
/// Tapping the pill navigates the viewport directly to the active TTS page.
class ReaderBackToTtsPill extends StatefulWidget {
  const ReaderBackToTtsPill({
    super.key,
    required this.onJumpToTtsPage,
    this.topOffset = 76.0,
  });

  /// Callback executed when the user taps to return to the active TTS playback page.
  final void Function(int pageIndex) onJumpToTtsPage;

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

    final state = context.read<ReaderBloc>().state;
    if (state.canJumpToTtsPage) {
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

    return BlocConsumer<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) =>
          prev.canJumpToTtsPage != curr.canJumpToTtsPage ||
          prev.ttsCurrentPage != curr.ttsCurrentPage,
      listener: (context, state) {
        if (state.canJumpToTtsPage) {
          _animController.forward();
        } else {
          _animController.reverse();
        }
      },
      buildWhen: (prev, curr) =>
          prev.canJumpToTtsPage != curr.canJumpToTtsPage ||
          prev.ttsCurrentPage != curr.ttsCurrentPage,
      builder: (context, state) {
        final ttsPage = state.ttsCurrentPage;
        final visible = state.canJumpToTtsPage && ttsPage != null;

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
                              context.read<ReaderBloc>().add(
                                const ReaderEvent.jumpToTtsPage(),
                              );
                              widget.onJumpToTtsPage(ttsPage);
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
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.volume2,
                                size: 15,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Back to Audio • Page ${(ttsPage ?? 0) + 1}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 14,
                              color: scheme.primary,
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
      },
    );
  }
}
