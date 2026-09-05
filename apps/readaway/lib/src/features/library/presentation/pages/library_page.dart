import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../cubit/library_cubit.dart';
import '../cubit/library_state.dart';
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
      create: (context) => GetIt.I<LibraryCubit>()..loadRecentDocuments(),
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
    final cubit = context.read<LibraryCubit>();
    BookDetailsSheet.show(
      context,
      document: doc,
      onOpenReader: () => _navigateToReader(context, doc.path, doc.fileName),
      onToggleFavorite: () => cubit.toggleFavorite(doc.path),
      onUpdateStatus: (status) => cubit.updateReadingStatus(doc.path, status),
      onRemove: () => cubit.removeRecent(doc.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<LibraryCubit, LibraryState>(
      listenWhen: (prev, curr) =>
          curr.openedDocument != null &&
          prev.openedDocument != curr.openedDocument,
      listener: (context, state) {
        final doc = state.openedDocument;
        if (doc != null) {
          context.read<LibraryCubit>().clearOpened();
          _navigateToReader(context, doc.path, doc.fileName);
        }
      },
      builder: (context, state) {
        final cubit = context.read<LibraryCubit>();
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
                    onPressed: () => cubit.toggleSelectMode(),
                  )
                : null,
            actions: [
              if (state.isSelectMode) ...[
                TextButton(
                  onPressed: state.selectedPaths.length == documents.length
                      ? () => cubit.deselectAll()
                      : () => cubit.selectAll(),
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
                        cubit.setSearchQuery('');
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
                    onSortChanged: (sort) => cubit.setSortBy(sort),
                    onToggleAscending: () => cubit.toggleSortAscending(),
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
                    cubit.setViewMode(
                      state.viewMode == LibraryViewMode.grid
                          ? LibraryViewMode.list
                          : LibraryViewMode.grid,
                    );
                  },
                ),
                // Select mode button
                if (state.recentDocuments.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.checkSquare, size: 20),
                    tooltip: 'Select books',
                    onPressed: () => cubit.toggleSelectMode(),
                  ),
              ],
            ],
          ),
          body: Column(
            children: [
              if (state.failure != null)
                FailureBanner(
                  failure: state.failure!,
                  onRetry: () => cubit.loadRecentDocuments(),
                  onDismiss: () => cubit.loadRecentDocuments(),
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
                                cubit.setSearchQuery('');
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
                    onChanged: (val) => cubit.setSearchQuery(val),
                  ),
                ),

              // Filter Chips Bar
              if (state.recentDocuments.isNotEmpty)
                LibraryFilterBar(
                  selectedFilter: state.filterStatus,
                  state: state,
                  onSelectFilter: (filter) => cubit.setFilterStatus(filter),
                ),

              // Main Book Content
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isLoading && state.recentDocuments.isEmpty) {
                      return const AppLoadingView(label: 'Loading library...');
                    }

                    if (state.recentDocuments.isEmpty) {
                      return AppEmptyView(
                        icon: LucideIcons.bookOpen,
                        title: 'Your Library is Empty',
                        message:
                            'Open a book, PDF document, or comic to start reading.',
                        actionLabel: 'Open Document',
                        onAction: () => cubit.pickAndOpenDocument(),
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
                                  cubit.setSearchQuery('');
                                  cubit.setFilterStatus(
                                    ReadingStatusFilter.all,
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
                      return _buildGridView(context, documents, state, cubit);
                    }

                    // Render List View
                    return _buildListView(context, documents, state, cubit);
                  },
                ),
              ),

              // Select Mode Bottom Action Bar
              if (state.isSelectMode && state.selectedPaths.isNotEmpty)
                _buildSelectModeBar(context, state, cubit),
            ],
          ),
          floatingActionButton: state.isSelectMode
              ? null
              : FloatingActionButton.extended(
                  icon: const Icon(LucideIcons.folderOpen, size: 20),
                  label: const Text('Open File'),
                  onPressed: () => cubit.pickAndOpenDocument(),
                ),
        );
      },
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<RecentDocument> documents,
    LibraryState state,
    LibraryCubit cubit,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive columns: 2 on phone (<600), 3-4 on tablet (600-1000), 5-6 on desktop (>1000)
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
                  cubit.toggleSelectDocument(doc.path);
                } else {
                  _navigateToReader(context, doc.path, doc.fileName);
                }
              },
              onLongPress: () {
                if (state.isSelectMode) {
                  cubit.toggleSelectDocument(doc.path);
                } else {
                  _openDetailsSheet(context, doc);
                }
              },
              onToggleFavorite: () => cubit.toggleFavorite(doc.path),
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
    LibraryCubit cubit,
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
              cubit.toggleSelectDocument(doc.path);
            } else {
              _navigateToReader(context, doc.path, doc.fileName);
            }
          },
          onLongPress: () {
            if (state.isSelectMode) {
              cubit.toggleSelectDocument(doc.path);
            } else {
              _openDetailsSheet(context, doc);
            }
          },
          onToggleFavorite: () => cubit.toggleFavorite(doc.path),
          onOpenDetails: () => _openDetailsSheet(context, doc),
        );
      },
    );
  }

  Widget _buildSelectModeBar(
    BuildContext context,
    LibraryState state,
    LibraryCubit cubit,
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
                onPressed: () =>
                    cubit.batchUpdateStatusSelected(ReadingStatus.finished),
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
              onPressed: () => cubit.batchDeleteSelected(),
            ),
          ],
        ),
      ),
    );
  }
}
