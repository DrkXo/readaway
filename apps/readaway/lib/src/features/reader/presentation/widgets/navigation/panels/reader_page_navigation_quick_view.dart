import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/widgets/core_widgets.dart';
import '../../../bloc/reader_bloc.dart';

/// Page navigation panel with scrubber slider, prev/next buttons, and quick jump controls.
class ReaderPageNavigationQuickView extends StatelessWidget {
  const ReaderPageNavigationQuickView({
    super.key,
    required this.onClose,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSeekToPage,
  });

  final VoidCallback onClose;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onSeekToPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount,
      builder: (context, readerState) {
        final pageCount = readerState.pageCount;
        final currentPage = readerState.currentPage;
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

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Page position & Close
              Row(
                children: [
                  Icon(
                    LucideIcons.slidersHorizontal,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Page Navigation',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentPage + 1} / $pageCount  ($percent%)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: LucideIcons.x,
                    tooltip: 'Close panel',
                    size: AppIconButtonSize.small,
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Slider row: Prev + Slider + Next
              Row(
                children: [
                  AppIconButton(
                    icon: LucideIcons.chevronLeft,
                    tooltip: 'Previous page',
                    size: AppIconButtonSize.small,
                    onPressed: currentPage > 0 ? onPreviousPage : null,
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
                    size: AppIconButtonSize.small,
                    onPressed: currentPage < pageCount - 1 ? onNextPage : null,
                  ),
                ],
              ),

              // Quick jump buttons: Start / End
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(LucideIcons.chevronsLeft, size: 14),
                    label: const Text('Start'),
                    onPressed: currentPage > 0 ? () => onSeekToPage(0) : null,
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(LucideIcons.chevronsRight, size: 14),
                    label: const Text('End'),
                    onPressed: currentPage < pageCount - 1
                        ? () => onSeekToPage(pageCount - 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
