import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../bloc/library_bloc.dart';

/// Production-grade controls and filters panel for the Library screen.
///
/// Provides keyword searching, reading status filter chips, sorting criteria
/// and order toggling, view layout switching, and batch selection controls.
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

    return Semantics(
      container: true,
      label: 'Library tools and filters',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 17,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selecting ? 'Selecting books' : 'Library tools',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selecting) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Results are frozen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
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
            _ChipRow(
              children: [
                for (final filter in ReadingStatusFilter.values)
                  _PressableChip(
                    child: ChoiceChip(
                      key: ValueKey('library-filter-${filter.name}'),
                      selected: state.filterStatus == filter,
                      onSelected: selecting
                          ? null
                          : (_) => onFilterChanged(filter),
                      avatar: Icon(_filterIcon(filter), size: 16),
                      label: Text(
                        '${filter.label} (${state.countForFilter(filter)})',
                        maxLines: 1,
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _ChipGroup(
              label: 'Sort by',
              icon: LucideIcons.arrowDownUp,
              trailing: _PressableChip(
                child: ActionChip(
                  key: const ValueKey('library-sort-order'),
                  avatar: Icon(
                    state.sortAscending
                        ? LucideIcons.arrowUpNarrowWide
                        : LucideIcons.arrowDownWideNarrow,
                    size: 16,
                  ),
                  label: Text(
                    state.sortAscending ? 'Ascending' : 'Descending',
                    maxLines: 1,
                  ),
                  onPressed: selecting ? null : onSortOrderToggled,
                  tooltip: state.sortAscending
                      ? 'Switch to descending order'
                      : 'Switch to ascending order',
                ),
              ),
              children: [
                for (final sort in LibrarySortBy.values)
                  _PressableChip(
                    child: ChoiceChip(
                      key: ValueKey('library-sort-${sort.name}'),
                      selected: state.sortBy == sort,
                      onSelected: selecting ? null : (_) => onSortChanged(sort),
                      avatar: Icon(_sortIcon(sort), size: 16),
                      label: Text(sort.label, maxLines: 1),
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _ChipGroup(
              label: 'View',
              icon: LucideIcons.panelsTopLeft,
              children: [
                for (final mode in LibraryViewMode.values)
                  _PressableChip(
                    child: ChoiceChip(
                      key: ValueKey('library-view-${mode.name}'),
                      selected: state.viewMode == mode,
                      onSelected: selecting
                          ? null
                          : (_) => onViewModeChanged(mode),
                      avatar: Icon(_viewIcon(mode), size: 16),
                      label: Text(mode.label, maxLines: 1),
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ],
        ),
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
      mainAxisSize: MainAxisSize.min,
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
        _ChipRow(children: children),
      ],
    );
  }
}

/// A single-line, horizontally scrollable strip of chips.
///
/// Chips never reflow onto a second row; when the group is wider than the
/// available width the strip scrolls so every value stays reachable.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Adds a scale-down press response without altering layout bounds, so
/// neighbouring chips never shift while this one is held.
class _PressableChip extends StatefulWidget {
  const _PressableChip({required this.child});

  final Widget child;

  @override
  State<_PressableChip> createState() => _PressableChipState();
}

class _PressableChipState extends State<_PressableChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.appMotion;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: motion.fast,
        curve: motion.enter,
        child: widget.child,
      ),
    );
  }
}

IconData _filterIcon(ReadingStatusFilter filter) => switch (filter) {
  ReadingStatusFilter.all => LucideIcons.layers,
  ReadingStatusFilter.reading => LucideIcons.bookOpen,
  ReadingStatusFilter.unread => LucideIcons.clock,
  ReadingStatusFilter.finished => LucideIcons.circleCheck,
  ReadingStatusFilter.onHold => LucideIcons.pauseCircle,
  ReadingStatusFilter.favorites => LucideIcons.star,
};

IconData _sortIcon(LibrarySortBy sort) => switch (sort) {
  LibrarySortBy.dateOpened => LucideIcons.clock,
  LibrarySortBy.dateAdded => LucideIcons.calendarPlus,
  LibrarySortBy.title => LucideIcons.aArrowDown,
  LibrarySortBy.author => LucideIcons.user,
  LibrarySortBy.progress => LucideIcons.percent,
  LibrarySortBy.fileSize => LucideIcons.hardDrive,
};

IconData _viewIcon(LibraryViewMode mode) => switch (mode) {
  LibraryViewMode.grid => LucideIcons.layoutGrid,
  LibraryViewMode.list => LucideIcons.layoutList,
};
