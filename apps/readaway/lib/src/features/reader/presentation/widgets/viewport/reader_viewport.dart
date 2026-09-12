import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway/src/core/services/reader/reflowable_pagination_coordinator.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';

import '../../bloc/reader_bloc.dart';
import '../../controllers/reader_viewport_controller.dart';
import '../common/reader_error_view.dart';
import '../tts/reader_tts_mini_player_bar.dart';
import 'modes/continuous_reader_view.dart';
import 'modes/paged_reader_view.dart';
import 'page_content/fixed_reader_page.dart';
import 'page_content/reflowable_reader_page.dart';
import 'page_content/reflowable_virtual_page.dart';

/// The main viewport widget that coordinates page viewing, transitions, and loading.
class ReaderViewport extends StatefulWidget {
  const ReaderViewport({
    super.key,
    required this.viewportController,
    required this.prefs,
    this.onScrollBoundaryChanged,
  });

  final ReaderViewportController viewportController;
  final ReaderPreferences prefs;

  /// Notified when the current page's inner scroll view reaches or leaves a boundary.
  ///
  /// Only fires for reflowable pages in vertical snap-paging mode. The parent uses this
  /// to decide whether the gesture arena should claim a vertical drag for page-turning.
  final void Function({required bool atTop, required bool atBottom})?
  onScrollBoundaryChanged;

  @override
  State<ReaderViewport> createState() => _ReaderViewportState();
}

class _ReaderViewportState extends State<ReaderViewport> {
  late final ReflowablePaginationCoordinator _paginationCoordinator;
  int _currentGlobalPage = 0;
  int? _lastInitializedChapterCount;
  bool _isPaginationUpdateScheduled = false;
  final Map<String, List<int>> _assetCache = {};

  @override
  void initState() {
    super.initState();
    _paginationCoordinator =
        GetIt.I.isRegistered<ReflowablePaginationCoordinator>()
            ? GetIt.I<ReflowablePaginationCoordinator>()
            : ReflowablePaginationCoordinator();
    _paginationCoordinator.addListener(_onPaginationUpdated);
  }

  void _onPaginationUpdated() {
    if (!mounted) return;
    if (_isPaginationUpdateScheduled) return;
    _isPaginationUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPaginationUpdateScheduled = false;
      if (!mounted) return;
      final bloc = context.read<ReaderBloc>();
      final state = bloc.state;
      final isContinuous =
          widget.prefs.scrollDirection == ReaderScrollDirection.vertical &&
              !widget.prefs.pageSnap;

      if (state.isReflowable && !isContinuous) {
        widget.viewportController.updatePageCount(
          _paginationCoordinator.totalPageCount,
        );
        final coord = _paginationCoordinator.coordinateFromGlobalPage(
          _currentGlobalPage,
        );
        bloc.add(
          ReaderEvent.virtualPageChanged(
            globalPage: _currentGlobalPage,
            totalPages: _paginationCoordinator.totalPageCount,
            chapterIndex: coord.chapterIndex,
          ),
        );
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(ReaderViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasContinuous =
        oldWidget.prefs.scrollDirection == ReaderScrollDirection.vertical &&
            !oldWidget.prefs.pageSnap;
    final nowContinuous =
        widget.prefs.scrollDirection == ReaderScrollDirection.vertical &&
            !widget.prefs.pageSnap;

    if (wasContinuous != nowContinuous) {
      final bloc = context.read<ReaderBloc>();
      final state = bloc.state;
      if (nowContinuous) {
        // Switched from paged to continuous mode.
        widget.viewportController.updatePageCount(state.pageCount);
        widget.viewportController.setCurrentPage(state.currentPage);
        bloc.add(ReaderEvent.pageChanged(index: state.currentPage));
      } else if (state.isReflowable) {
        // Switched from continuous to paged mode.
        final targetGlobal =
            _paginationCoordinator.getGlobalPageForChapter(state.currentPage);
        _currentGlobalPage = targetGlobal;
        widget.viewportController.updatePageCount(
          _paginationCoordinator.totalPageCount,
        );
        widget.viewportController.setCurrentPage(targetGlobal);
        final coord = _paginationCoordinator.coordinateFromGlobalPage(targetGlobal);
        bloc.add(
          ReaderEvent.virtualPageChanged(
            globalPage: targetGlobal,
            totalPages: _paginationCoordinator.totalPageCount,
            chapterIndex: coord.chapterIndex,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _paginationCoordinator.removeListener(_onPaginationUpdated);
    _assetCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.currentVirtualPage != curr.currentVirtualPage ||
          prev.virtualPageCount != curr.virtualPageCount,
      listener: (context, state) {
        final isContinuous =
            widget.prefs.scrollDirection == ReaderScrollDirection.vertical &&
                !widget.prefs.pageSnap;

        if (state.isReflowable && !isContinuous) {
          final targetPage = state.currentVirtualPage ?? _currentGlobalPage;
          _currentGlobalPage = targetPage;
          widget.viewportController.updatePageCount(
            _paginationCoordinator.totalPageCount,
          );
          widget.viewportController.setCurrentPage(targetPage);
        } else {
          widget.viewportController.updatePageCount(state.pageCount);
          widget.viewportController.setCurrentPage(state.currentPage);
        }
      },
      buildWhen: (prev, curr) =>
          prev.loading != curr.loading ||
          prev.error != curr.error ||
          prev.hasDocument != curr.hasDocument ||
          prev.pageCount != curr.pageCount ||
          prev.currentPage != curr.currentPage ||
          prev.currentVirtualPage != curr.currentVirtualPage ||
          prev.virtualPageCount != curr.virtualPageCount ||
          prev.isReflowable != curr.isReflowable ||
          prev.pageHtmls != curr.pageHtmls ||
          prev.pageImages != curr.pageImages ||
          prev.ttsActive != curr.ttsActive,
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return const ReaderErrorView();
        }
        if (!state.hasDocument) {
          return const Center(child: Text('No document open'));
        }

        // Opt mouse and pointer devices in for responsive gestures
        final scrollConfig = ScrollConfiguration.of(context).copyWith(
          dragDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.mouse,
          },
        );

        final isContinuous =
            widget.prefs.scrollDirection == ReaderScrollDirection.vertical &&
                !widget.prefs.pageSnap;

        final isVerticalSnap =
            widget.prefs.scrollDirection == ReaderScrollDirection.vertical &&
                widget.prefs.pageSnap;

        final double miniPlayerPadding = state.ttsActive
            ? (ReaderTtsMiniPlayerBar.height + 12.0)
            : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Update pagination coordinator with latest viewport geometry
            if (state.isReflowable) {
              final viewportSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final contentMargins = EdgeInsets.only(
                top: widget.prefs.marginTop,
                bottom: widget.prefs.marginBottom,
                left: widget.prefs.marginHorizontal,
                right: widget.prefs.marginHorizontal,
              );

              if (_lastInitializedChapterCount != state.pageCount) {
                _lastInitializedChapterCount = state.pageCount;
                _paginationCoordinator.initialize(
                  chapterCount: state.pageCount,
                  viewportSize: viewportSize,
                  contentMargins: contentMargins,
                  notify: false,
                );
              } else {
                _paginationCoordinator.updateViewport(
                  viewportSize: viewportSize,
                  contentMargins: contentMargins,
                  currentAnchor: _paginationCoordinator.createAnchor(
                    _currentGlobalPage,
                  ),
                  notify: false,
                );
              }
            }

            final Widget view;
            if (isContinuous) {
              view = ContinuousReaderView(
                currentPage: state.currentPage,
                pageCount: state.pageCount,
                controller: widget.viewportController,
                bottomPadding: miniPlayerPadding,
                itemBuilder: (ctx, idx) =>
                    _buildPageItem(ctx, state, idx, isContinuous: true),
                onPageChangeRequested: (idx) =>
                    _onPageCommitted(context, state, idx, isContinuous: true),
              );
            } else {
              final effectivePageCount = state.isReflowable
                  ? math.max(1, _paginationCoordinator.totalPageCount)
                  : state.pageCount;

              final effectiveCurrentPage = state.isReflowable
                  ? _currentGlobalPage.clamp(0, effectivePageCount - 1)
                  : state.currentPage;

              view = PagedReaderView(
                currentPage: effectiveCurrentPage,
                pageCount: effectivePageCount,
                transition: widget.prefs.pageTransition,
                direction: widget.prefs.scrollDirection,
                controller: widget.viewportController,
                backgroundColor: context.appColors.readerBackground,
                itemBuilder: (ctx, idx) => _buildPageItem(
                  ctx,
                  state,
                  idx,
                  isContinuous: false,
                  onScrollBoundaryChanged: isVerticalSnap
                      ? widget.onScrollBoundaryChanged
                      : null,
                ),
                onPageChangeRequested: (idx) =>
                    _onPageCommitted(context, state, idx, isContinuous: false),
              );
            }

            return ScrollConfiguration(
              behavior: scrollConfig,
              child: view,
            );
          },
        );
      },
    );
  }

  Widget _buildPageItem(
    BuildContext context,
    ReaderState state,
    int index, {
    bool isContinuous = false,
    void Function({required bool atTop, required bool atBottom})?
    onScrollBoundaryChanged,
  }) {
    if (state.isReflowable) {
      if (isContinuous) {
        return ReflowableReaderPage(
          key: ValueKey('reflow_continuous_$index'),
          index: index,
          state: state,
          prefs: widget.prefs,
          isContinuous: true,
          onPageChangeRequested: (idx) =>
              _onNavigateRequested(context, state, idx, isContinuous: true),
          onScrollBoundaryChanged: onScrollBoundaryChanged,
        );
      } else {
        final coord = _paginationCoordinator.coordinateFromGlobalPage(index);
        return ReflowableVirtualPage(
          key: ValueKey('reflow_virtual_${coord.chapterIndex}_${coord.pageInChapter}'),
          chapterIndex: coord.chapterIndex,
          pageInChapter: coord.pageInChapter,
          totalPagesInChapter: coord.totalPagesInChapter,
          globalPageIndex: index,
          state: state,
          prefs: widget.prefs,
          coordinator: _paginationCoordinator,
          onResolveAssetBytes: (src) => _resolveAssetBytes(coord.chapterIndex, src),
          onLinkTap: (url) => _onLinkTap(context, url),
        );
      }
    } else {
      return FixedReaderPage(
        key: ValueKey('fixed_page_$index'),
        index: index,
        state: state,
        isContinuous: isContinuous,
        onPageChangeRequested: (idx) =>
            _onNavigateRequested(context, state, idx, isContinuous: isContinuous),
      );
    }
  }

  Future<List<int>?> _resolveAssetBytes(int chapterIndex, String src) async {
    final cacheKey = '$chapterIndex:$src';
    if (_assetCache.containsKey(cacheKey)) {
      return _assetCache[cacheKey];
    }
    final res = await GetIt.I<ReaderRepository>()
        .loadAssetBytes(src, pageIndex: chapterIndex)
        .run();
    final bytes = res.getRight().toNullable();
    if (bytes != null) {
      _assetCache[cacheKey] = bytes;
    }
    return bytes;
  }

  Future<void> _onLinkTap(BuildContext context, String url) async {
    final res = await GetIt.I<ReaderRepository>()
        .resolveReflowableLink(url)
        .run();
    final targetChapter = res.getRight().toNullable();
    if (targetChapter != null && targetChapter >= 0 && context.mounted) {
      final isContinuous =
          widget.prefs.scrollDirection == ReaderScrollDirection.vertical &&
              !widget.prefs.pageSnap;
      if (isContinuous) {
        _onNavigateRequested(
          context,
          context.read<ReaderBloc>().state,
          targetChapter,
          isContinuous: true,
        );
      } else {
        final targetGlobal =
            _paginationCoordinator.getGlobalPageForChapter(targetChapter);
        _onNavigateRequested(
          context,
          context.read<ReaderBloc>().state,
          targetGlobal,
          isContinuous: false,
        );
      }
    }
  }

  void _onNavigateRequested(
    BuildContext context,
    ReaderState state,
    int index, {
    required bool isContinuous,
  }) {
    final bloc = context.read<ReaderBloc>();
    if (state.isReflowable && !isContinuous) {
      final total = _paginationCoordinator.totalPageCount;
      if (total <= 0) return;
      final clamped = index.clamp(0, total - 1);
      if (clamped == _currentGlobalPage) return;

      final oldGlobal = _currentGlobalPage;
      _currentGlobalPage = clamped;
      final coord = _paginationCoordinator.coordinateFromGlobalPage(clamped);
      bloc.add(
        ReaderEvent.virtualPageChanged(
          globalPage: clamped,
          totalPages: total,
          chapterIndex: coord.chapterIndex,
        ),
      );

      if ((clamped - oldGlobal).abs() > 1) {
        widget.viewportController.jumpToPage(clamped);
      } else {
        widget.viewportController.goToPage(clamped);
      }
    } else {
      if (state.pageCount <= 0) return;
      final clamped = index.clamp(0, state.pageCount - 1);
      if (clamped == state.currentPage) return;

      if ((clamped - state.currentPage).abs() > 1) {
        bloc.add(ReaderEvent.pageChanged(index: clamped));
        widget.viewportController.jumpToPage(clamped);
      } else {
        widget.viewportController.goToPage(clamped);
      }
    }
  }

  void _onPageCommitted(
    BuildContext context,
    ReaderState state,
    int index, {
    required bool isContinuous,
  }) {
    final bloc = context.read<ReaderBloc>();
    if (state.isReflowable && !isContinuous) {
      final total = _paginationCoordinator.totalPageCount;
      if (total <= 0) return;
      final clamped = index.clamp(0, total - 1);
      _currentGlobalPage = clamped;
      final coord = _paginationCoordinator.coordinateFromGlobalPage(clamped);
      bloc.add(
        ReaderEvent.virtualPageChanged(
          globalPage: clamped,
          totalPages: total,
          chapterIndex: coord.chapterIndex,
        ),
      );
      widget.viewportController.setCurrentPage(clamped);
    } else {
      if (state.pageCount <= 0) return;
      final clamped = index.clamp(0, state.pageCount - 1);
      if (clamped != state.currentPage) {
        bloc.add(ReaderEvent.pageChanged(index: clamped));
      }
      widget.viewportController.setCurrentPage(clamped);
    }
  }
}
