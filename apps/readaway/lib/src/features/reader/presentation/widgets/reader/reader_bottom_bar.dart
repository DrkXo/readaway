import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../reader.dart';

/// Fixed-height reader control bar (page navigation, outline, TTS toggle).
///
/// The TTS mini/full player itself now lives in [ReaderTtsPlayerOverlay],
/// which floats above this bar so it can expand to fill the screen.
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

  /// Height of the fixed control row. Shared with [ReaderTtsPlayerOverlay]
  /// so the collapsed mini player sits flush above these controls.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.hasDocument != curr.hasDocument,
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

        return Container(
          height: height,
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
        );
      },
    );
  }
}
