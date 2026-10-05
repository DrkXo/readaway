import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../bloc/library_bloc.dart';
import 'library_tools_panel.dart';

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

  /// Space reserved for the leading button in select mode. Matches Material's
  /// default (56 leading width + 16 gap). [FlexibleSpaceBar] does not lay out
  /// around `leading` the way [AppBar.title] does, so we do it by hand.
  static const double _leadingInset = 72.0;

  Widget _dragArea({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: titleDragHandler,
      onDoubleTap: titleDoubleTapHandler,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final topInset = MediaQuery.paddingOf(context).top;
    final expanded = headerExpansion.value > 0;

    final titleText = isSelectMode ? '$selectedCount selected' : 'Library';

    // FlexibleSpaceBar lays the title out as:
    //   Padding -> Transform(scale) -> Align -> SizedBox(maxWidth / scale)
    //   -> Align(title)
    // so the title always receives *loose* constraints and would shrink to the
    // text width. `width: double.infinity` clamps to the maximum, i.e. the full
    // padded row, and because the max is already divided by the scale, the
    // scaled result spans exactly the available width. Hit testing goes
    // through the Transform, so the scaled title is draggable too.
    final titleWidget = _dragArea(
      child: SizedBox(
        width: double.infinity,
        child: Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: appColors.topbarForeground),
        ),
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
      // The title lives in the FlexibleSpaceBar only (single source of truth),
      // so it never jumps between two different widgets.
      title: null,
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
      // AppBar stacks the toolbar (leading/actions) *above* flexibleSpace, so
      // buttons keep their taps and only empty toolbar space reaches the drag
      // strip below.
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            // Defaults to true on iOS/macOS, which would center the title.
            centerTitle: false,
            titlePadding: EdgeInsetsDirectional.only(
              start: isSelectMode ? _leadingInset : (isDesktop ? 14 : 16),
              bottom: 12,
            ),
            title: titleWidget,
            // No background when fully collapsed: nothing to paint or hit-test.
            background: expanded
                ? ColoredBox(
                    color: scheme.surfaceContainerLow,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: topInset + toolbarHeight + 4,
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
                  )
                : null,
          ),
          // Full-width drag strip over the toolbar row (status-bar inset
          // included). Pinned to the top so it never scrolls with the panel.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + toolbarHeight,
            child: _dragArea(child: const SizedBox.expand()),
          ),
        ],
      ),
    );
  }
}
