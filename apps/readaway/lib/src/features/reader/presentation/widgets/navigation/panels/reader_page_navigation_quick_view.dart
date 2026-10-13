import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/theme/theme.dart';
import '../../../../../../core/widgets/core_widgets.dart';
import '../../../bloc/reader_bloc.dart';

/// Page navigation panel with scrubber slider, prev/next steppers, and flat jump controls.
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
    final appColors = context.appColors;

    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.displayCurrentPage != curr.displayCurrentPage ||
          prev.displayPageCount != curr.displayPageCount,
      builder: (context, readerState) {
        final pageCount = readerState.displayPageCount;
        final currentPage = readerState.displayCurrentPage;
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
                    color: appColors.buttonBackground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'page navigation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: appColors.readerForeground,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.editorWidgetBackground,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: appColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '${currentPage + 1} / $pageCount  ($percent%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: appColors.readerForeground.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Close panel',
                    child: Semantics(
                      label: 'Close panel',
                      button: true,
                      child: MetroPressable(
                        onTap: onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: appColors.readerForeground.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Slider row: Prev + Slider + Next
              Row(
                children: [
                  Tooltip(
                    message: 'Previous page',
                    child: Semantics(
                      label: 'Previous page',
                      button: true,
                      child: MetroPressable(
                        enabled: currentPage > 0,
                        onTap: currentPage > 0 ? onPreviousPage : null,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 18,
                            color: currentPage > 0
                                ? appColors.readerForeground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ),
                      ),
                    ),
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
                  Tooltip(
                    message: 'Next page',
                    child: Semantics(
                      label: 'Next page',
                      button: true,
                      child: MetroPressable(
                        enabled: currentPage < pageCount - 1,
                        onTap: currentPage < pageCount - 1 ? onNextPage : null,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: currentPage < pageCount - 1
                                ? appColors.readerForeground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Quick jump buttons: Start / End
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MetroPressable(
                    enabled: currentPage > 0,
                    onTap: currentPage > 0 ? () => onSeekToPage(0) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.chevronsLeft,
                            size: 14,
                            color: currentPage > 0
                                ? appColors.readerForeground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'start',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: currentPage > 0
                                  ? appColors.readerForeground
                                  : appColors.readerForeground.withValues(
                                      alpha: 0.35,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  MetroPressable(
                    enabled: currentPage < pageCount - 1,
                    onTap: currentPage < pageCount - 1
                        ? () => onSeekToPage(pageCount - 1)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'end',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: currentPage < pageCount - 1
                                  ? appColors.readerForeground
                                  : appColors.readerForeground.withValues(
                                      alpha: 0.35,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronsRight,
                            size: 14,
                            color: currentPage < pageCount - 1
                                ? appColors.readerForeground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ],
                      ),
                    ),
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
