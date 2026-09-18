import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../bloc/library_bloc.dart';

class LibraryFilterBar extends StatelessWidget {
  const LibraryFilterBar({
    super.key,
    required this.selectedFilter,
    required this.state,
    required this.onSelectFilter,
  });

  final ReadingStatusFilter selectedFilter;
  final LibraryState state;
  final ValueChanged<ReadingStatusFilter> onSelectFilter;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appColors.borderSubtle,
            width: 0.8,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: ReadingStatusFilter.values.map((filter) {
            final isSelected = filter == selectedFilter;
            final count = state.countForFilter(filter);

            final icon = switch (filter) {
              ReadingStatusFilter.all => LucideIcons.layers,
              ReadingStatusFilter.reading => LucideIcons.bookOpen,
              ReadingStatusFilter.unread => LucideIcons.clock,
              ReadingStatusFilter.finished => LucideIcons.circleCheck,
              ReadingStatusFilter.favorites => LucideIcons.star,
            };

            final fgColor = isSelected
                ? appColors.buttonForeground
                : appColors.buttonSecondaryForeground;
            final bgColor = isSelected
                ? appColors.buttonBackground
                : appColors.buttonSecondaryBackground;

            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: FilterChip(
                avatar: Icon(
                  icon,
                  size: 13,
                  color: fgColor,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: fgColor.withValues(alpha: isSelected ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: fgColor,
                        ),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: bgColor,
                selectedColor: bgColor,
                side: BorderSide(
                  color: isSelected ? Colors.transparent : appColors.borderSubtle,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => onSelectFilter(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
