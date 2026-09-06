import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/toast/toast_service.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../bloc/library_bloc.dart';
import '../widgets/book_details_sheet.dart';
import '../widgets/book_grid_card.dart';
import '../widgets/book_list_tile.dart';
import '../widgets/library_filter_bar.dart';
import '../widgets/library_sort_sheet.dart';

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

class _LibraryViewState extends State<_LibraryView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
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
      onOpenReader: () => _navigateToReader(context, doc.path, doc.fileName),
      onToggleFavorite: () => bloc.add(LibraryEvent.toggleFavorite(doc.path)),
      onUpdateStatus: (status) =>
          bloc.add(LibraryEvent.updateReadingStatus(doc.path, status)),
      onRemove: () => bloc.add(LibraryEvent.removeDocument(doc.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<LibraryBloc, LibraryState>(
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
          context.read<LibraryBloc>().add(const LibraryEvent.clearOpened());
          _navigateToReader(context, doc.path, doc.fileName);
        }

        final directDoc = state.directOpenDocument;
        if (directDoc != null) {
          context.read<LibraryBloc>().add(const LibraryEvent.clearDirectOpen());
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

        return Scaffold(
          appBar: AppTopBar(
            titleText: state.isSelectMode
                ? '${state.selectedPaths.length} selected'
                : 'ReadAway',
            leading: state.isSelectMode
                ? IconButton(
                    icon: const Icon(LucideIcons.x),
                    tooltip: 'Cancel selection',
                    onPressed: () =>
                        bloc.add(const LibraryEvent.selectModeToggled()),
                  )
                : null,
            actions: [
              if (state.isSelectMode) ...[
                TextButton(
                  onPressed: state.selectedPaths.length == documents.length
                      ? () => bloc.add(const LibraryEvent.deselectAll())
                      : () => bloc.add(const LibraryEvent.selectAll()),
                  child: Text(
                    state.selectedPaths.length == documents.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ] else ...[
                // Search toggle
                IconButton(
                  icon: Icon(
                    _isSearchVisible ? LucideIcons.searchX : LucideIcons.search,
                    size: 20,
                  ),
                  tooltip: 'Search books',
                  onPressed: () {
                    setState(() {
                      _isSearchVisible = !_isSearchVisible;
                      if (!_isSearchVisible) {
                        _searchController.clear();
                        bloc.add(const LibraryEvent.searchQueryChanged(''));
                      }
                    });
                  },
                ),
                // Sort Menu
                IconButton(
                  icon: const Icon(LucideIcons.arrowDownUp, size: 20),
                  tooltip: 'Sort library',
                  onPressed: () => LibrarySortSheet.show(
                    context,
                    currentSortBy: state.sortBy,
                    sortAscending: state.sortAscending,
                    onSortChanged: (sort) =>
                        bloc.add(LibraryEvent.sortByChanged(sort)),
                    onToggleAscending: () =>
                        bloc.add(const LibraryEvent.sortOrderToggled()),
                  ),
                ),
                // View Mode switcher
                IconButton(
                  icon: Icon(
                    state.viewMode == LibraryViewMode.grid
                        ? LucideIcons.layoutList
                        : LucideIcons.layoutGrid,
                    size: 20,
                  ),
                  tooltip: state.viewMode == LibraryViewMode.grid
                      ? 'Switch to List view'
                      : 'Switch to Grid view',
                  onPressed: () {
                    bloc.add(
                      LibraryEvent.viewModeChanged(
                        state.viewMode == LibraryViewMode.grid
                            ? LibraryViewMode.list
                            : LibraryViewMode.grid,
                      ),
                    );
                  },
                ),
                // Select mode button
                if (state.recentDocuments.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.checkSquare, size: 20),
                    tooltip: 'Select books',
                    onPressed: () =>
                        bloc.add(const LibraryEvent.selectModeToggled()),
                  ),
              ],
            ],
          ),
          body: Column(
            children: [
              if (state.failure != null)
                FailureBanner(
                  failure: state.failure!,
                  onRetry: () =>
                      bloc.add(const LibraryEvent.loadRequested()),
                  onDismiss: () =>
                      bloc.add(const LibraryEvent.loadRequested()),
                ),

              // Search Bar (expandable)
              if (_isSearchVisible)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by title, author, or format...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                bloc.add(
                                  const LibraryEvent.searchQueryChanged(''),
                                );
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) =>
                        bloc.add(LibraryEvent.searchQueryChanged(val)),
                  ),
                ),

              // Filter Chips Bar
              if (state.recentDocuments.isNotEmpty)
                LibraryFilterBar(
                  selectedFilter: state.filterStatus,
                  state: state,
                  onSelectFilter: (filter) =>
                      bloc.add(LibraryEvent.filterChanged(filter)),
                ),

              // Main Book Content
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isLoading && state.recentDocuments.isEmpty) {
                      return const AppLoadingView(label: 'Loading library...');
                    }

                    if (state.recentDocuments.isEmpty) {
                      return const AppEmptyView(
                        icon: LucideIcons.bookOpen,
                        title: 'Your Library is Empty',
                        message:
                            'Add books to your library or open a document directly using the bar below.',
                      );
                    }

                    if (documents.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.filterX,
                                size: 48,
                                color: scheme.outline,
                              ),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.tonal(
                                onPressed: () {
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
                                child: const Text('Reset Filters'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Render Grid View
                    if (state.viewMode == LibraryViewMode.grid) {
                      return _buildGridView(context, documents, state, bloc);
                    }

                    // Render List View
                    return _buildListView(context, documents, state, bloc);
                  },
                ),
              ),

              // Select Mode Bottom Action Bar
              if (state.isSelectMode && state.selectedPaths.isNotEmpty)
                _buildSelectModeBar(context, state, bloc),
            ],
          ),
          floatingActionButton:
              state.isSelectMode ? null : _buildFabBar(context, bloc),
        );
      },
    );
  }

  Widget _buildFabBar(BuildContext context, LibraryBloc bloc) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primaryContainer,
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Book to Library
            Tooltip(
              message: 'Add books to library',
              child: InkWell(
                onTap: () => bloc.add(const LibraryEvent.addDocuments()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.bookPlus,
                        size: 19,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Book',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.2),
            ),
            // Open Book directly without adding to library
            Tooltip(
              message: 'Open book directly without adding to library',
              child: InkWell(
                onTap: () => bloc.add(const LibraryEvent.openDirectly()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.bookOpen,
                        size: 19,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open Book',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<RecentDocument> documents,
    LibraryState state,
    LibraryBloc bloc,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive columns: 2 on phone (<450), 3-4 on tablet (450-1000), 5-6 on desktop (>1000)
        final crossAxisCount = width < 450
            ? 2
            : width < 700
                ? 3
                : width < 1000
                    ? 4
                    : width < 1300
                        ? 5
                        : 6;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.52,
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
        );
      },
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<RecentDocument> documents,
    LibraryState state,
    LibraryBloc bloc,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
      itemCount: documents.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 70),
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
    );
  }

  Widget _buildSelectModeBar(
    BuildContext context,
    LibraryState state,
    LibraryBloc bloc,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: const Icon(LucideIcons.circleCheck, size: 16),
                label: const Text('Mark Finished'),
                onPressed: () => bloc.add(
                  const LibraryEvent.batchUpdateStatusSelected(
                    ReadingStatus.finished,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
              ),
              icon: const Icon(LucideIcons.trash2, size: 18),
              tooltip: 'Delete selected',
              onPressed: () =>
                  bloc.add(const LibraryEvent.batchDeleteSelected()),
            ),
          ],
        ),
      ),
    );
  }
}
