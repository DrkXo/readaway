import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../bloc/library_bloc.dart';

class LibraryToolsPanel extends StatelessWidget {
  const LibraryToolsPanel({
    super.key,
    required this.state,
    required this.searchController,
    required this.selecting,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onSortOrderToggled,
    required this.onViewModeChanged,
    required this.onReset,
    required this.onSelectMode,
  });

  final LibraryState state;
  final TextEditingController searchController;
  final bool selecting;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ReadingStatusFilter> onFilterChanged;
  final ValueChanged<LibrarySortBy> onSortChanged;
  final VoidCallback onSortOrderToggled;
  final ValueChanged<LibraryViewMode> onViewModeChanged;
  final VoidCallback onReset;
  final VoidCallback onSelectMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final hasCriteria =
        state.searchQuery.trim().isNotEmpty ||
        state.filterStatus != ReadingStatusFilter.all;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: appColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.slidersHorizontal,
                    size: 17,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selecting ? 'Selecting books' : 'Library tools',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (selecting)
                Text(
                  'Results are frozen',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (hasCriteria)
                TextButton.icon(
                  key: const ValueKey('library-tools-reset'),
                  onPressed: selecting ? null : onReset,
                  icon: const Icon(LucideIcons.rotateCcw, size: 15),
                  label: const Text('Reset'),
                ),
              if (!selecting && state.recentDocuments.isNotEmpty)
                TextButton.icon(
                  key: const ValueKey('library-tools-select'),
                  onPressed: selecting ? null : onSelectMode,
                  icon: const Icon(LucideIcons.checkSquare, size: 15),
                  label: const Text('Select'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('library-search-field'),
            controller: searchController,
            enabled: !selecting,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: appColors.inputForeground),
            decoration: InputDecoration(
              hintText: 'Search titles, authors, or formats',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: state.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: selecting
                          ? null
                          : () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                      icon: const Icon(LucideIcons.x, size: 17),
                    ),
              filled: true,
              fillColor: appColors.inputBackground,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: appColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: appColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: appColors.focusBorder,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ReadingStatusFilter.values.map((filter) {
              final icon = switch (filter) {
                ReadingStatusFilter.all => LucideIcons.layers,
                ReadingStatusFilter.reading => LucideIcons.bookOpen,
                ReadingStatusFilter.unread => LucideIcons.clock,
                ReadingStatusFilter.finished => LucideIcons.circleCheck,
                ReadingStatusFilter.onHold => LucideIcons.pauseCircle,
                ReadingStatusFilter.favorites => LucideIcons.star,
              };
              return ChoiceChip(
                key: ValueKey('library-filter-${filter.name}'),
                selected: state.filterStatus == filter,
                onSelected: selecting ? null : (_) => onFilterChanged(filter),
                avatar: Icon(icon, size: 16),
                label: Text(
                  '${filter.label} (${state.countForFilter(filter)})',
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _ChipGroup(
            label: 'Sort by',
            icon: LucideIcons.arrowDownUp,
            trailing: ActionChip(
              key: const ValueKey('library-sort-order'),
              avatar: Icon(
                state.sortAscending
                    ? LucideIcons.arrowUpNarrowWide
                    : LucideIcons.arrowDownWideNarrow,
                size: 16,
              ),
              label: Text(state.sortAscending ? 'Ascending' : 'Descending'),
              onPressed: selecting ? null : onSortOrderToggled,
              tooltip: state.sortAscending
                  ? 'Switch to descending order'
                  : 'Switch to ascending order',
            ),
            children: LibrarySortBy.values.map((sort) {
              final icon = switch (sort) {
                LibrarySortBy.dateOpened => LucideIcons.clock,
                LibrarySortBy.dateAdded => LucideIcons.calendarPlus,
                LibrarySortBy.title => LucideIcons.aArrowDown,
                LibrarySortBy.author => LucideIcons.user,
                LibrarySortBy.progress => LucideIcons.percent,
                LibrarySortBy.fileSize => LucideIcons.hardDrive,
              };
              return ChoiceChip(
                key: ValueKey('library-sort-${sort.name}'),
                selected: state.sortBy == sort,
                onSelected: selecting ? null : (_) => onSortChanged(sort),
                avatar: Icon(icon, size: 16),
                label: Text(sort.label),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _ChipGroup(
            label: 'View',
            icon: LucideIcons.panelsTopLeft,
            children: LibraryViewMode.values.map((mode) {
              final icon = switch (mode) {
                LibraryViewMode.grid => LucideIcons.layoutGrid,
                LibraryViewMode.list => LucideIcons.layoutList,
              };
              return ChoiceChip(
                key: ValueKey('library-view-${mode.name}'),
                selected: state.viewMode == mode,
                onSelected: selecting ? null : (_) => onViewModeChanged(mode),
                avatar: Icon(icon, size: 16),
                label: Text(mode.label),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 4, children: children),
      ],
    );
  }
}
