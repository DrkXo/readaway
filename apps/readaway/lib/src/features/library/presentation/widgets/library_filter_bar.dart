import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cubit/library_state.dart';

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
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
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
                          ? scheme.primary.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? scheme.primary : scheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: scheme.primaryContainer.withValues(alpha: 0.45),
              backgroundColor: scheme.surfaceContainerLow,
              side: BorderSide(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.4)
                    : scheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) => onSelectFilter(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}
