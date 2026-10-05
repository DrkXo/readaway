import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../bloc/library_bloc.dart';
import 'library_tools_panel.dart';

/// A production-grade [SliverAppBar] with an animated [FlexibleSpaceBar]
/// for library tools, filters, search, and selection state.
class LibrarySliverAppBar extends StatelessWidget {
  const LibrarySliverAppBar({
    super.key,
    required this.toolbarHeight,
    required this.headerExpansion,
    required this.isSelectMode,
    required this.selectedCount,
    required this.totalDocumentsCount,
    required this.isDesktop,
    required this.state,
    required this.searchController,
    required this.scrollController,
    required this.onToggleLibraryTools,
    required this.onSelectModeToggled,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onSortOrderToggled,
    required this.onViewModeChanged,
    required this.onReset,
    this.titleDragHandler,
    this.titleDoubleTapHandler,
    this.windowControls,
    this.settingsButton,
  });

  final double toolbarHeight;
  final Animation<double> headerExpansion;
  final bool isSelectMode;
  final int selectedCount;
  final int totalDocumentsCount;
  final bool isDesktop;
  final LibraryState state;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final VoidCallback onToggleLibraryTools;
  final VoidCallback onSelectModeToggled;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ReadingStatusFilter> onFilterChanged;
  final ValueChanged<LibrarySortBy> onSortChanged;
  final VoidCallback onSortOrderToggled;
  final ValueChanged<LibraryViewMode> onViewModeChanged;
  final VoidCallback onReset;
  final GestureDragStartCallback? titleDragHandler;
  final GestureTapCallback? titleDoubleTapHandler;
  final Widget? windowControls;
  final Widget? settingsButton;

  static const double panelExpandedHeight = 424.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    final titleText = isSelectMode ? '$selectedCount selected' : 'Library';

    final titleWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: titleDragHandler,
      onDoubleTap: titleDoubleTapHandler,
      child: Text(
        titleText,
        maxLines: 1,
        style: TextStyle(color: appColors.topbarForeground),
      ),
    );

    return SliverAppBar(
      pinned: true,
      collapsedHeight: toolbarHeight,
      expandedHeight:
          toolbarHeight + panelExpandedHeight * headerExpansion.value,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: appColors.topbarBackground,
      foregroundColor: appColors.topbarForeground,
      surfaceTintColor: Colors.transparent,
      title: headerExpansion.value == 0 ? titleWidget : null,
      leading: isSelectMode
          ? IconButton(
              icon: const Icon(LucideIcons.x),
              tooltip: 'Cancel selection',
              onPressed: onSelectModeToggled,
            )
          : null,
      actions: [
        if (isSelectMode)
          TextButton(
            onPressed: selectedCount == totalDocumentsCount
                ? onDeselectAll
                : onSelectAll,
            child: Text(
              selectedCount == totalDocumentsCount
                  ? 'Deselect All'
                  : 'Select All',
            ),
          )
        else
          AnimatedBuilder(
            animation: Listenable.merge([
              scrollController,
              headerExpansion,
            ]),
            builder: (context, _) {
              final toolsExpanded =
                  headerExpansion.value > 0.5 &&
                  (!scrollController.hasClients ||
                      scrollController.position.pixels <= 1);
              final hasActiveFilters =
                  state.searchQuery.isNotEmpty ||
                  state.filterStatus != ReadingStatusFilter.all;

              return IconButton(
                key: const ValueKey('library-tools-toggle'),
                icon: Icon(
                  toolsExpanded
                      ? LucideIcons.panelTopClose
                      : LucideIcons.slidersHorizontal,
                  size: 20,
                  color: hasActiveFilters ? scheme.primary : null,
                ),
                tooltip: toolsExpanded
                    ? 'Hide library tools'
                    : 'Show library tools',
                onPressed: onToggleLibraryTools,
              );
            },
          ),
        ?settingsButton,
        ?windowControls,
      ],
      flexibleSpace: headerExpansion.value == 0
          ? null
          : FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              titlePadding: EdgeInsetsDirectional.only(
                start: isDesktop ? 14 : 16,
                bottom: 12,
              ),
              title: titleWidget,
              background: ColoredBox(
                color: scheme.surfaceContainerLow,
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top:
                          MediaQuery.paddingOf(context).top + toolbarHeight + 4,
                      bottom: 60,
                    ),
                    child: RepaintBoundary(
                      child: LibraryToolsPanel(
                        key: const ValueKey('library-tools-panel'),
                        state: state,
                        searchController: searchController,
                        selecting: isSelectMode,
                        onSearchChanged: onSearchChanged,
                        onFilterChanged: onFilterChanged,
                        onSortChanged: onSortChanged,
                        onSortOrderToggled: onSortOrderToggled,
                        onViewModeChanged: onViewModeChanged,
                        onReset: onReset,
                        onSelectMode: onSelectModeToggled,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
