import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              avatar: Icon(
                icon,
                size: 14,
                color: isSelected
                    ? scheme.onPrimary
                    : scheme.onSecondary,
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
                          : FontWeight.normal,
                      color: isSelected
                          ? scheme.onPrimary
                          : scheme.onSecondary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.onPrimary.withValues(alpha: 0.2)
                          : scheme.onSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? scheme.onPrimary
                            : scheme.onSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: isSelected
                  ? scheme.primary
                  : scheme.secondary,
              onSelected: (_) => onSelectFilter(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}
