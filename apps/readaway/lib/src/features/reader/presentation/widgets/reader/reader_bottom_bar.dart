import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../reader.dart';

/// Bottom bar hosting reader controls and stacking the TTS mini-player above it when active.
class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSeekToPage,
    this.onOpenDrawer,
    this.onOutlineTap,
  });

  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onSeekToPage;
  final VoidCallback? onOutlineTap;
  final VoidCallback? onOpenDrawer;

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final mediaQuery = MediaQuery.of(bottomSheetContext);
        return Container(
          height: mediaQuery.size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(bottomSheetContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider.value(
            value: context.read<ReaderBloc>(),
            child: ReaderTtsFullPlayerView(
              onClose: () => Navigator.of(bottomSheetContext).pop(),
              onClosePlayer: () {
                Navigator.of(bottomSheetContext).pop();
                context.read<ReaderBloc>().add(const ReaderEvent.ttsClose());
              },
              onDragUpdate: (DragUpdateDetails details) {},
              onDragEnd: (DragEndDetails details) {},
            ),
          ),
        );
      },
    );
  }

  void _handleHorizontalDragEnd(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final tts = context.read<ReaderBloc>().ttsController;
    if (velocity < -200) {
      tts.skipToNextSentence();
    } else if (velocity > 200) {
      tts.skipToPreviousSentence();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.hasDocument != curr.hasDocument ||
          prev.ttsActive != curr.ttsActive,
      builder: (context, state) {
        if (!state.hasDocument) return const SizedBox.shrink();

        final pageCount = state.pageCount;
        final currentPage = state.currentPage;
        final percent = pageCount > 0
            ? ((currentPage / (pageCount - 1)) * 100).round()
            : 0;
        final maxSliderValue = (pageCount - 1)
            .clamp(1, double.infinity)
            .toDouble();
        final currentSliderValue = currentPage.toDouble().clamp(
          0.0,
          maxSliderValue,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Top Section: Interactive TTS Mini Player stacked above
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: state.ttsActive
                  ? Container(
                      key: const ValueKey('tts_mini_player_key'),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        clipBehavior: Clip.antiAlias,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openFullPlayer(context),
                          onHorizontalDragEnd: (details) =>
                              _handleHorizontalDragEnd(context, details),
                          child: ReaderTtsMiniPlayerBar(
                            onClosePlayer: () => context.read<ReaderBloc>().add(
                              const ReaderEvent.ttsClose(),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('tts_empty_key')),
            ),

            // 2. Bottom Section: Permanent Reader Controls
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.85),
                boxShadow: context.appColors.shadowMd,
              ),
              child: Row(
                children: [
                  AppIconButton(
                    icon: LucideIcons.panelLeft,
                    tooltip: 'Outline',
                    onPressed: onOpenDrawer ?? onOutlineTap,
                    size: AppIconButtonSize.small,
                  ),
                  AppIconButton(
                    icon: LucideIcons.chevronLeft,
                    tooltip: 'Previous page',
                    onPressed: currentPage > 0 ? onPreviousPage : null,
                    size: AppIconButtonSize.small,
                  ),
                  Expanded(
                    child: AppSlider(
                      value: currentSliderValue,
                      min: 0,
                      max: maxSliderValue,
                      compact: true,
                      onChanged: (v) => onSeekToPage(v.round()),
                    ),
                  ),
                  AppIconButton(
                    icon: LucideIcons.chevronRight,
                    tooltip: 'Next page',
                    onPressed: currentPage < pageCount - 1 ? onNextPage : null,
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 8),
                  AppCaption('${currentPage + 1} / $pageCount'),
                  const SizedBox(width: 8),
                  AppCaption('$percent%'),
                  AppIconButton(
                    icon: LucideIcons.audioLines,
                    tooltip: 'Listen (TTS player)',
                    onPressed: state.isReflowable
                        ? () => context.read<ReaderBloc>().add(
                            const ReaderEvent.ttsStart(),
                          )
                        : null,
                    size: AppIconButtonSize.small,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
