import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cubit/library_state.dart';

class LibrarySortSheet extends StatelessWidget {
  const LibrarySortSheet({
    super.key,
    required this.currentSortBy,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onToggleAscending,
  });

  final LibrarySortBy currentSortBy;
  final bool sortAscending;
  final ValueChanged<LibrarySortBy> onSortChanged;
  final VoidCallback onToggleAscending;

  static Future<void> show(
    BuildContext context, {
    required LibrarySortBy currentSortBy,
    required bool sortAscending,
    required ValueChanged<LibrarySortBy> onSortChanged,
    required VoidCallback onToggleAscending,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LibrarySortSheet(
        currentSortBy: currentSortBy,
        sortAscending: sortAscending,
        onSortChanged: onSortChanged,
        onToggleAscending: onToggleAscending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort Library',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                ActionChip(
                  avatar: Icon(
                    sortAscending
                        ? LucideIcons.arrowUpNarrowWide
                        : LucideIcons.arrowDownWideNarrow,
                    size: 16,
                    color: scheme.primary,
                  ),
                  label: Text(
                    sortAscending ? 'Ascending' : 'Descending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                  backgroundColor:
                      scheme.primaryContainer.withValues(alpha: 0.35),
                  side: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.3),
                  ),
                  onPressed: onToggleAscending,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 6),
            ...LibrarySortBy.values.map((sort) {
              final isSelected = sort == currentSortBy;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                dense: true,
                leading: Icon(
                  _iconForSort(sort),
                  size: 18,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                title: Text(
                  sort.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: isSelected ? scheme.primary : scheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: scheme.primary,
                        size: 20,
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: isSelected
                    ? scheme.primaryContainer.withValues(alpha: 0.25)
                    : Colors.transparent,
                onTap: () {
                  onSortChanged(sort);
                  Navigator.of(context).pop();
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  IconData _iconForSort(LibrarySortBy sort) => switch (sort) {
        LibrarySortBy.dateOpened => LucideIcons.clock,
        LibrarySortBy.dateAdded => LucideIcons.calendarPlus,
        LibrarySortBy.title => LucideIcons.aArrowDown,
        LibrarySortBy.author => LucideIcons.user,
        LibrarySortBy.progress => LucideIcons.percent,
        LibrarySortBy.fileSize => LucideIcons.hardDrive,
      };
}
