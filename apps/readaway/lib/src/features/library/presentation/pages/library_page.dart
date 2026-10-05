import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/toast/toast_service.dart';
import '../../../../core/services/window_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../bloc/library_bloc.dart';
import '../widgets/book_details_sheet.dart';
import '../widgets/book_grid_card.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/library_actions_fab.dart';
import '../widgets/library_sliver_app_bar.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GetIt.I<LibraryBloc>()..add(const LibraryEvent.loadRequested()),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _areActionsExpanded = false;
  late final AnimationController _headerExpansion;

  @override
  void initState() {
    super.initState();
    _headerExpansion = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerExpansion.dispose();
    super.dispose();
  }

  void _navigateToReader(BuildContext context, String path, String fileName) {
    final route =
        '${appRoutes.reader.path}?path=${Uri.encodeComponent(path)}&fileName=${Uri.encodeComponent(fileName)}';
    GoRouter.of(context).push(route);
  }

  void _openDetailsSheet(BuildContext context, RecentDocument doc) {
    final bloc = context.read<LibraryBloc>();
    BookDetailsSheet.show(
      context,
      document: doc,
      bloc: bloc,
      onOpenReader: () => _navigateToReader(context, doc.path, doc.fileName),
      onToggleFavorite: () => bloc.add(LibraryEvent.toggleFavorite(doc.path)),
      onUpdateStatus: (status) =>
          bloc.add(LibraryEvent.updateReadingStatus(doc.path, status)),
      onResetProgress: () => bloc.add(LibraryEvent.resetProgress(doc.path)),
      onRemove: () => bloc.add(LibraryEvent.removeDocument(doc.path)),
    );
  }

  void _closeActions() {
    if (_areActionsExpanded) {
      setState(() => _areActionsExpanded = false);
    }
  }

  void _toggleLibraryTools(AppMotion motion) {
    _closeActions();
    if (_scrollController.hasClients && _scrollController.position.pixels > 1) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: motion.standard,
        curve: motion.enter,
      );
      return;
    }

    _headerExpansion.animateTo(
      _headerExpansion.value > 0.5 ? 0 : 1,
      duration: motion.standard,
      curve: motion.enter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final platform = defaultTargetPlatform;
    final isDesktop =
        !kIsWeb &&
        (platform == TargetPlatform.linux ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.windows);
    final windowService = GetIt.I.isRegistered<WindowService>()
        ? GetIt.I<WindowService>()
        : null;
    final toolbarHeight = isDesktop
        ? AppTopBar.desktopHeight
        : AppTopBar.mobileHeight;

    return PopScope(
      canPop: !_areActionsExpanded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _areActionsExpanded) {
          _closeActions();
        }
      },
      child: BlocConsumer<LibraryBloc, LibraryState>(
        listenWhen: (prev, curr) =>
            (curr.openedDocument != null &&
                prev.openedDocument != curr.openedDocument) ||
            (curr.directOpenDocument != null &&
                prev.directOpenDocument != curr.directOpenDocument) ||
            (curr.noticeMessage != null &&
                prev.noticeMessage != curr.noticeMessage),
        listener: (context, state) {
          final doc = state.openedDocument;
          if (doc != null) {
            _closeActions();
            context.read<LibraryBloc>().add(const LibraryEvent.clearOpened());
            _navigateToReader(context, doc.path, doc.fileName);
          }

          final directDoc = state.directOpenDocument;
          if (directDoc != null) {
            _closeActions();
            context.read<LibraryBloc>().add(
              const LibraryEvent.clearDirectOpen(),
            );
            _navigateToReader(context, directDoc.path, directDoc.fileName);
          }

          final notice = state.noticeMessage;
          if (notice != null) {
            context.showSuccessToast(notice);
            context.read<LibraryBloc>().add(const LibraryEvent.clearNotice());
          }
        },
        builder: (context, state) {
          final bloc = context.read<LibraryBloc>();
          final documents = state.filteredDocuments;
          final motion = context.appMotion;

          return Scaffold(
            bottomNavigationBar:
                state.isSelectMode && state.selectedPaths.isNotEmpty
                ? _buildSelectModeBar(context, state, bloc)
                : null,
            body: Stack(
              children: [
                ListenableBuilder(
                  listenable: _headerExpansion,
                  builder: (context, _) => CustomScrollView(
                    key: const ValueKey('library-scroll-view'),
                    controller: _scrollController,
                    slivers: [
                      LibrarySliverAppBar(
                        toolbarHeight: toolbarHeight,
                        headerExpansion: _headerExpansion,
                        isSelectMode: state.isSelectMode,
                        selectedCount: state.selectedPaths.length,
                        totalDocumentsCount: documents.length,
                        isDesktop: isDesktop,
                        state: state,
                        searchController: _searchController,
                        scrollController: _scrollController,
                        onToggleLibraryTools: () => _toggleLibraryTools(motion),
                        onSelectModeToggled: () => bloc.add(
                          const LibraryEvent.selectModeToggled(),
                        ),
                        onSelectAll: () => bloc.add(
                          const LibraryEvent.selectAll(),
                        ),
                        onDeselectAll: () => bloc.add(
                          const LibraryEvent.deselectAll(),
                        ),
                        onSearchChanged: (query) => bloc.add(
                          LibraryEvent.searchQueryChanged(query),
                        ),
                        onFilterChanged: (filter) => bloc.add(
                          LibraryEvent.filterChanged(filter),
                        ),
                        onSortChanged: (sort) => bloc.add(
                          LibraryEvent.sortByChanged(sort),
                        ),
                        onSortOrderToggled: () => bloc.add(
                          const LibraryEvent.sortOrderToggled(),
                        ),
                        onViewModeChanged: (mode) => bloc.add(
                          LibraryEvent.viewModeChanged(mode),
                        ),
                        onReset: () {
                          _searchController.clear();
                          bloc.add(
                            const LibraryEvent.searchQueryChanged(''),
                          );
                          bloc.add(
                            const LibraryEvent.filterChanged(
                              ReadingStatusFilter.all,
                            ),
                          );
                        },
                        titleDragHandler: isDesktop && windowService != null
                            ? (_) => windowService.startDragging()
                            : null,
                        titleDoubleTapHandler:
                            isDesktop && windowService != null
                            ? windowService.toggleMaximize
                            : null,
                        windowControls: isDesktop
                            ? WindowCaptionControls(service: windowService)
                            : null,
                        settingsButton: const SettingsButton(),
                      ),
                      if (state.failure != null)
                        SliverToBoxAdapter(
                          child: FailureBanner(
                            failure: state.failure!,
                            onRetry: () =>
                                bloc.add(const LibraryEvent.loadRequested()),
                            onDismiss: () =>
                                bloc.add(const LibraryEvent.loadRequested()),
                          ),
                        ),
                      if (state.isLoading && state.recentDocuments.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppLoadingView(label: 'Loading library...'),
                        )
                      else if (state.recentDocuments.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmptyView(
                            icon: LucideIcons.bookOpen,
                            title: 'Your Library is Empty',
                            message: 'Add books to your library or open a document directly using the bar below.',
                          ),
                        )
                      else if (documents.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildNoMatchingBooks(context, bloc),
                        )
                      else if (state.viewMode == LibraryViewMode.grid)
                        _buildGridSliver(context, documents, state, bloc)
                      else
                        _buildListSliver(context, documents, state, bloc),
                    ],
                  ),
                ),

                // Dismiss barrier when speed dial is open
                IgnorePointer(
                  ignoring: !_areActionsExpanded,
                  child: AnimatedOpacity(
                    opacity: _areActionsExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: GestureDetector(
                      key: const ValueKey('library-speed-dial-barrier'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeActions,
                      child: Container(
                        color: scheme.scrim.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: state.isSelectMode
                ? null
                : LibraryActionsFab(
                    isLoading: state.isLoading,
                    isExpanded: _areActionsExpanded,
                    onToggle: () => setState(
                      () => _areActionsExpanded = !_areActionsExpanded,
                    ),
                    onAddBooks: () {
                      _closeActions();
                      bloc.add(const LibraryEvent.addDocuments());
                    },
                    onOpenBook: () {
                      _closeActions();
                      bloc.add(const LibraryEvent.openDirectly());
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildNoMatchingBooks(BuildContext context, LibraryBloc bloc) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.filterX, size: 48, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'No matching books found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try clearing your search query or changing filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                _searchController.clear();
                bloc.add(const LibraryEvent.searchQueryChanged(''));
                bloc.add(
                  const LibraryEvent.filterChanged(ReadingStatusFilter.all),
                );
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSliver(
    BuildContext context,
    List<RecentDocument> documents,
    LibraryState state,
    LibraryBloc bloc,
  ) {
    final bottomInset = 88.0 + MediaQuery.paddingOf(context).bottom;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final crossAxisCount = (width / 184).floor().clamp(2, 6);
        final gutter = breakpointFromWidth(width).resolve(
          compact: 12.0,
          medium: 20.0,
          expanded: 28.0,
          wide: 40.0,
        );

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, bottomInset),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: width < 380 ? 0.52 : 0.56,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final isSelected = state.selectedPaths.contains(doc.path);

              return BookGridCard(
                document: doc,
                isSelectMode: state.isSelectMode,
                isSelected: isSelected,
                onTap: () {
                  if (state.isSelectMode) {
                    bloc.add(LibraryEvent.selectDocumentToggled(doc.path));
                  } else {
                    _navigateToReader(context, doc.path, doc.fileName);
                  }
                },
                onLongPress: () {
                  if (state.isSelectMode) {
                    bloc.add(LibraryEvent.selectDocumentToggled(doc.path));
                  } else {
                    _openDetailsSheet(context, doc);
                  }
                },
                onToggleFavorite: () =>
                    bloc.add(LibraryEvent.toggleFavorite(doc.path)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListSliver(
    BuildContext context,
    List<RecentDocument> documents,
    LibraryState state,
    LibraryBloc bloc,
  ) {
    final bottomInset = 88.0 + MediaQuery.paddingOf(context).bottom;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final gutter = breakpointFromWidth(width).resolve(
          compact: 12.0,
          medium: 20.0,
          expanded: 28.0,
          wide: 40.0,
        );
        final dividerIndent = BookListTile.contentIndentFor(width);

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 6, gutter, bottomInset),
          sliver: SliverList.separated(
            itemCount: documents.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, indent: dividerIndent),
            itemBuilder: (context, index) {
              final doc = documents[index];
              final isSelected = state.selectedPaths.contains(doc.path);

              return BookListTile(
                document: doc,
                isSelectMode: state.isSelectMode,
                isSelected: isSelected,
                onTap: () {
                  if (state.isSelectMode) {
                    bloc.add(LibraryEvent.selectDocumentToggled(doc.path));
                  } else {
                    _navigateToReader(context, doc.path, doc.fileName);
                  }
                },
                onLongPress: () {
                  if (state.isSelectMode) {
                    bloc.add(LibraryEvent.selectDocumentToggled(doc.path));
                  } else {
                    _openDetailsSheet(context, doc);
                  }
                },
                onToggleFavorite: () =>
                    bloc.add(LibraryEvent.toggleFavorite(doc.path)),
                onOpenDetails: () => _openDetailsSheet(context, doc),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectModeBar(
    BuildContext context,
    LibraryState state,
    LibraryBloc bloc,
  ) {
    final appColors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final count = state.selectedPaths.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: appColors.bottombarBackground,
        border: Border(
          top: BorderSide(
            color: appColors.bottombarBorder,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: appColors.buttonBackground,
                  foregroundColor: appColors.buttonForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: const Icon(LucideIcons.circleCheck, size: 15),
                label: const Text('Mark Finished'),
                onPressed: () => bloc.add(
                  const LibraryEvent.batchUpdateStatusSelected(
                    ReadingStatus.finished,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                icon: const Icon(LucideIcons.clock, size: 15),
                label: const Text('Mark Unread'),
                onPressed: () => bloc.add(
                  const LibraryEvent.batchUpdateStatusSelected(
                    ReadingStatus.unread,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: appColors.error,
                foregroundColor: appColors.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              icon: const Icon(LucideIcons.trash2, size: 16),
              tooltip: 'Delete selected',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      count == 1
                          ? 'Remove 1 Book from Library?'
                          : 'Remove $count Books from Library?',
                    ),
                    content: Text(
                      count == 1
                          ? 'Are you sure you want to remove the selected book from your library?\n\nReading progress and preferences will be cleared. The book file on your device will NOT be deleted.'
                          : 'Are you sure you want to remove $count selected books from your library?\n\nReading progress and preferences will be cleared. The book files on your device will NOT be deleted.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  bloc.add(const LibraryEvent.batchDeleteSelected());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
