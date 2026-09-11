import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

import '../../bloc/reader_bloc.dart';
import '../../controllers/reader_viewport_controller.dart';
import '../common/reader_error_view.dart';
import '../tts/reader_tts_mini_player_bar.dart';
import 'modes/continuous_reader_view.dart';
import 'modes/paged_reader_view.dart';
import 'page_content/fixed_reader_page.dart';
import 'page_content/reflowable_reader_page.dart';

/// The main viewport widget that coordinates page viewing, transitions, and loading.
class ReaderViewport extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocConsumer<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount,
      listener: (context, state) {
        viewportController.updatePageCount(state.pageCount);
        viewportController.setCurrentPage(state.currentPage);
      },
      buildWhen: (prev, curr) =>
          prev.loading != curr.loading ||
          prev.error != curr.error ||
          prev.hasDocument != curr.hasDocument ||
          prev.pageCount != curr.pageCount ||
          prev.currentPage != curr.currentPage ||
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
            prefs.scrollDirection == ReaderScrollDirection.vertical &&
            !prefs.pageSnap;

        // The scroll boundary callback is only meaningful in vertical snap-paging mode.
        // In continuous mode the inner scroll view IS the primary scroller.
        final isVerticalSnap =
            prefs.scrollDirection == ReaderScrollDirection.vertical &&
            prefs.pageSnap;

        final double miniPlayerPadding = state.ttsActive
            ? (ReaderTtsMiniPlayerBar.height + 12.0)
            : 0.0;

        final Widget view;
        if (isContinuous) {
          view = ContinuousReaderView(
            currentPage: state.currentPage,
            pageCount: state.pageCount,
            controller: viewportController,
            bottomPadding: miniPlayerPadding,
            itemBuilder: (ctx, idx) =>
                _buildPageItem(ctx, state, idx, isContinuous: true),
            onPageChangeRequested: (idx) => _onPageCommitted(context, idx),
          );
        } else {
          view = PagedReaderView(
            currentPage: state.currentPage,
            pageCount: state.pageCount,
            transition: prefs.pageTransition,
            direction: prefs.scrollDirection,
            controller: viewportController,
            backgroundColor: context.appColors.readerBackground,
            itemBuilder: (ctx, idx) => _buildPageItem(
              ctx,
              state,
              idx,
              isContinuous: false,
              // Only pass boundary callback in vertical snap mode.
              onScrollBoundaryChanged: isVerticalSnap
                  ? onScrollBoundaryChanged
                  : null,
            ),
            onPageChangeRequested: (idx) => _onPageCommitted(context, idx),
          );
        }

        return ScrollConfiguration(
          behavior: scrollConfig,
          child: view,
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
    final isCustomFlow =
        state.isReflowable && prefs.engineMode == ReaderEngineMode.customFlow;

    if (isCustomFlow) {
      return ReflowableReaderPage(
        index: index,
        state: state,
        prefs: prefs,
        isContinuous: isContinuous,
        onPageChangeRequested: (idx) => _onNavigateRequested(context, idx),
        onScrollBoundaryChanged: onScrollBoundaryChanged,
      );
    } else {
      return FixedReaderPage(
        index: index,
        state: state,
        isContinuous: isContinuous,
        onPageChangeRequested: (idx) => _onNavigateRequested(context, idx),
      );
    }
  }

  void _onNavigateRequested(BuildContext context, int index) {
    final bloc = context.read<ReaderBloc>();
    if (bloc.state.pageCount <= 0) return;
    final clamped = index.clamp(0, bloc.state.pageCount - 1);
    if (clamped == bloc.state.currentPage) return;

    if ((clamped - bloc.state.currentPage).abs() > 1) {
      bloc.add(ReaderEvent.pageChanged(index: clamped));
      viewportController.jumpToPage(clamped);
    } else {
      viewportController.goToPage(clamped);
    }
  }

  void _onPageCommitted(BuildContext context, int index) {
    final bloc = context.read<ReaderBloc>();
    if (bloc.state.pageCount <= 0) return;
    final clamped = index.clamp(0, bloc.state.pageCount - 1);
    if (clamped != bloc.state.currentPage) {
      bloc.add(ReaderEvent.pageChanged(index: clamped));
    }
    viewportController.setCurrentPage(clamped);
  }
}
