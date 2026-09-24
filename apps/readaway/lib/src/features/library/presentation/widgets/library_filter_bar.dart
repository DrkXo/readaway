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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReadingStatusFilter.values.map((filter) {
            final isSelected = filter == selectedFilter;
            final count = state.countForFilter(filter);

            final icon = switch (filter) {
              ReadingStatusFilter.all => LucideIcons.layers,
              ReadingStatusFilter.reading => LucideIcons.bookOpen,
              ReadingStatusFilter.unread => LucideIcons.clock,
              ReadingStatusFilter.finished => LucideIcons.circleCheck,
              ReadingStatusFilter.onHold => LucideIcons.pauseCircle,
              ReadingStatusFilter.favorites => LucideIcons.star,
            };

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectFilter(filter),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? scheme.primary.withValues(alpha: 0.28)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: isSelected
                              ? scheme.primary
                              : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant.withValues(
                                    alpha: 0.8,
                                  ),
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
