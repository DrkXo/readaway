import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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

/// The root Library screen refactored into the Lumia Inspired
/// Metro Design System.
///
/// Features:
/// - Strictly flat, zero-elevation, zero-shadow, zero-outline aesthetic.
/// - Horizon-stretching [MetroPivot] hub with sections: all, reading, favorites, finished.
/// - Featured Wide Live Flip Tile with 3D perspective flip animation.
/// - Lumia bottom [MetroAppBar] with flat circular action buttons and expandable "more" menu.
/// - Turnstile entrance animations via [MetroTurnstileAnimationX].
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
  bool _isSearchActive = false;
  late final MetroPivotController _pivotController;

  @override
  void initState() {
    super.initState();
    _pivotController = MetroPivotController(
      length: 4,
      initialIndex: 0,
    );
  }

  @override
  void dispose() {
    _pivotController.dispose();
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
      bloc: bloc,
      onOpenReader: () => _navigateToReader(context, doc.path, doc.fileName),
      onToggleFavorite: () => bloc.add(LibraryEvent.toggleFavorite(doc.path)),
      onUpdateStatus: (status) =>
          bloc.add(LibraryEvent.updateReadingStatus(doc.path, status)),
      onResetProgress: () => bloc.add(LibraryEvent.resetProgress(doc.path)),
      onRemove: () => bloc.add(LibraryEvent.removeDocument(doc.path)),
    );
  }

  void _toggleSearch(LibraryBloc bloc) {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        bloc.add(const LibraryEvent.searchQueryChanged(''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final platform = defaultTargetPlatform;
    final isDesktop =
        !kIsWeb &&
        (platform == TargetPlatform.linux ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.windows);
    final windowService = GetIt.I.isRegistered<WindowService>()
        ? GetIt.I<WindowService>()
        : null;

    return PopScope(
      canPop: !_isSearchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearchActive) {
          _toggleSearch(context.read<LibraryBloc>());
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
            context.read<LibraryBloc>().add(const LibraryEvent.clearOpened());
            _navigateToReader(context, doc.path, doc.fileName);
          }

          final directDoc = state.directOpenDocument;
          if (directDoc != null) {
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
          final allDocuments = state.filteredDocuments;
          final readingDocuments = <RecentDocument>[];
          final favoriteDocuments = <RecentDocument>[];
          final finishedDocuments = <RecentDocument>[];
          for (final document in allDocuments) {
            if (document.readingStatus == ReadingStatus.reading ||
                (document.progressPercent > 0 && !document.isFinished)) {
              readingDocuments.add(document);
            }
            if (document.isFavorite) favoriteDocuments.add(document);
            if (document.isFinished) finishedDocuments.add(document);
          }

          return Scaffold(
            backgroundColor: appColors.readerBackground,
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Desktop Window Caption & Drag Area
                  if (isDesktop)
                    SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: windowService == null
                                  ? null
                                  : (_) => windowService.startDragging(),
                              onDoubleTap: windowService?.toggleMaximize,
                              child: const SizedBox.expand(),
                            ),
                          ),
                          if (windowService != null)
                            WindowCaptionControls(
                              service: windowService,
                              height: 32,
                            ),
                        ],
                      ),
                    ),

                  // 2. Search Bar Header (if active)
                  if (_isSearchActive)
                    Container(
                      color: appColors.editorWidgetBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              cursorColor: appColors.buttonBackground,
                              style: TextStyle(
                                fontSize: 16,
                                color: appColors.readerForeground,
                              ),
                              decoration: InputDecoration(
                                hintText: 'search library…',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: appColors.readerForeground.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (query) => bloc.add(
                                LibraryEvent.searchQueryChanged(query),
                              ),
                            ),
                          ),
                          MetroPressable(
                            onTap: () => _toggleSearch(bloc),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                'cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: appColors.buttonBackground,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 3. Error Banner
                  if (state.failure != null)
                    FailureBanner(
                      failure: state.failure!,
                      onRetry: () =>
                          bloc.add(const LibraryEvent.loadRequested()),
                      onDismiss: () =>
                          bloc.add(const LibraryEvent.loadRequested()),
                    ),

                  // 4. Main Panoramic Pivot Hub
                  Expanded(
                    child: state.isLoading && state.recentDocuments.isEmpty
                        ? const Center(
                            child: AppLoadingView(label: 'Loading library...'),
                          )
                        : MetroPivot(
                            controller: _pivotController,
                            title: 'library',
                            keepPagesAlive: false,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MetroPressable(
                                  onTap: () => _toggleSearch(bloc),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      _isSearchActive ? 'close' : 'search',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: _isSearchActive
                                            ? appColors.buttonBackground
                                            : appColors.readerForeground
                                                  .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ),
                                MetroPressable(
                                  onTap: () =>
                                      GoRouter.of(context)
                                          .push(appRoutes.settings.path),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'settings',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: appColors.readerForeground
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            items: [
                              MetroPivotItem(
                                label: 'all books',
                                count: '${allDocuments.length}',
                                content: _buildDocumentView(
                                  context: context,
                                  documents: allDocuments,
                                  state: state,
                                  bloc: bloc,
                                ),
                              ),
                              MetroPivotItem(
                                label: 'reading',
                                count: '${readingDocuments.length}',
                                content: _buildDocumentView(
                                  context: context,
                                  documents: readingDocuments,
                                  state: state,
                                  bloc: bloc,
                                  emptyMessage:
                                      'No books currently in progress.',
                                ),
                              ),
                              MetroPivotItem(
                                label: 'favorites',
                                count: '${favoriteDocuments.length}',
                                content: _buildDocumentView(
                                  context: context,
                                  documents: favoriteDocuments,
                                  state: state,
                                  bloc: bloc,
                                  emptyMessage: 'No favorite books marked yet.',
                                ),
                              ),
                              MetroPivotItem(
                                label: 'finished',
                                count: '${finishedDocuments.length}',
                                content: _buildDocumentView(
                                  context: context,
                                  documents: finishedDocuments,
                                  state: state,
                                  bloc: bloc,
                                  emptyMessage: 'No completed books yet.',
                                ),
                              ),
                            ],
                          ),
                  ),

                  // 5. Bottom Action Bar or Selection Bar
                  if (state.isSelectMode)
                    _buildSelectionBar(context, state, bloc)
                  else
                    Container(
                      color: appColors.readerBackground,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        8 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MetroPressable(
                            onTap: () =>
                                bloc.add(const LibraryEvent.openDirectly()),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: MetroText.bottomAction(
                                'open',
                                color: appColors.readerForeground.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MetroPressable(
                            onTap: () =>
                                bloc.add(const LibraryEvent.addDocuments()),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: MetroText.bottomAction(
                                'add',
                                color: appColors.buttonBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentView({
    required BuildContext context,
    required List<RecentDocument> documents,
    required LibraryState state,
    required LibraryBloc bloc,
    String emptyMessage = 'No matching books found.',
  }) {
    final appColors = context.appColors;

    if (documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: appColors.readerForeground.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    // Uniform flat grid where all book cards share the exact same 0.58 aspect ratio.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = (width / 170).floor().clamp(2, 6);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  final isSelected = state.selectedPaths.contains(doc.path);

                  final card = BookGridCard(
                    document: doc,
                    isSelectMode: state.isSelectMode,
                    isSelected: isSelected,
                    onTap: () {
                      if (state.isSelectMode) {
                        bloc.add(
                          LibraryEvent.selectDocumentToggled(doc.path),
                        );
                      } else {
                        _navigateToReader(context, doc.path, doc.fileName);
                      }
                    },
                    onLongPress: () {
                      if (state.isSelectMode) {
                        bloc.add(
                          LibraryEvent.selectDocumentToggled(doc.path),
                        );
                      } else {
                        _openDetailsSheet(context, doc);
                      }
                    },
                    onToggleFavorite: () =>
                        bloc.add(LibraryEvent.toggleFavorite(doc.path)),
                  );

                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: card,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    LibraryState state,
    LibraryBloc bloc,
  ) {
    final appColors = context.appColors;
    final count = state.selectedPaths.length;

    return Container(
      color: appColors.bottombarBackground,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Text(
            '$count selected',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: appColors.readerForeground,
            ),
          ),
          const Spacer(),
          Builder(
            builder: (context) {
              final allSelected =
                  state.filteredDocuments.isNotEmpty &&
                  state.selectedPaths.length == state.filteredDocuments.length;
              return MetroPressable(
                onTap: () => bloc.add(
                  allSelected
                      ? const LibraryEvent.deselectAll()
                      : const LibraryEvent.selectAll(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    allSelected ? 'deselect all' : 'select all',
                    style: TextStyle(
                      color: appColors.buttonBackground,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            MetroPressable(
              onTap: () => bloc.add(
                const LibraryEvent.batchUpdateStatusSelected(
                  ReadingStatus.finished,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'finish',
                  style: TextStyle(
                    color: appColors.buttonBackground,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            MetroPressable(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    title: Text(
                      count == 1
                          ? 'Remove 1 Book from Library?'
                          : 'Remove $count Books from Library?',
                    ),
                    content: Text(
                      count == 1
                          ? 'Are you sure you want to remove the selected book from your library?'
                          : 'Are you sure you want to remove $count selected books from your library?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: appColors.buttonBackground,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'delete',
                  style: TextStyle(
                    color: appColors.readerForeground.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          MetroPressable(
            onTap: () => bloc.add(const LibraryEvent.selectModeToggled()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                'cancel',
                style: TextStyle(
                  color: appColors.readerForeground.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
