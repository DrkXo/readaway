import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:readaway/src/features/settings/domain/models/reader_preferences.dart';
import '../../bloc/reader_bloc.dart';
import '../../controllers/reader_page_view_controller.dart';
import '../common/reader_error_view.dart';
import 'items/fixed_image_page_item.dart';
import 'items/reflowable_page_item.dart';
import 'reader_continuous_view.dart';
import 'reader_page_view.dart';

/// The main viewport widget that coordinates page viewing, transitions, and loading.
class ReaderViewport extends StatelessWidget {
  const ReaderViewport({
    super.key,
    required this.pageViewController,
    required this.prefs,
  });

  final ReaderPageViewController pageViewController;
  final ReaderPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount,
      listener: (context, state) {
        pageViewController.updatePageCount(state.pageCount);
        pageViewController.setCurrentPage(state.currentPage);
      },
      buildWhen: (prev, curr) =>
          prev.loading != curr.loading ||
          prev.error != curr.error ||
          prev.hasDocument != curr.hasDocument ||
          prev.pageCount != curr.pageCount ||
          prev.currentPage != curr.currentPage ||
          prev.isReflowable != curr.isReflowable ||
          prev.documentPages != curr.documentPages ||
          prev.pageImages != curr.pageImages,
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

        final isContinuous = prefs.scrollDirection == ReaderScrollDirection.vertical &&
            !prefs.pageSnap;

        final Widget view;
        if (isContinuous) {
          view = ReaderContinuousView(
            currentPage: state.currentPage,
            pageCount: state.pageCount,
            controller: pageViewController,
            itemBuilder: (ctx, idx) =>
                _buildPageItem(ctx, state, idx, isContinuous: true),
            onPageChangeRequested: (idx) => _onPageCommitted(context, idx),
          );
        } else {
          view = ReaderPageView(
            currentPage: state.currentPage,
            pageCount: state.pageCount,
            transition: prefs.pageTransition,
            direction: prefs.scrollDirection,
            controller: pageViewController,
            itemBuilder: (ctx, idx) =>
                _buildPageItem(ctx, state, idx, isContinuous: false),
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
  }) {
    if (state.isReflowable) {
      return ReflowablePageItem(
        index: index,
        state: state,
        prefs: prefs,
        isContinuous: isContinuous,
        onPageChangeRequested: (idx) => _onNavigateRequested(context, idx),
      );
    } else {
      return FixedImagePageItem(
        index: index,
        state: state,
        isContinuous: isContinuous,
        onPageChangeRequested: (idx) => _onNavigateRequested(context, idx),
      );
    }
  }

  void _onNavigateRequested(BuildContext context, int index) {
    final state = context.read<ReaderBloc>().state;
    if (state.pageCount <= 0) return;
    final clamped = index.clamp(0, state.pageCount - 1);
    if (clamped == state.currentPage) return;
    pageViewController.goToPage(clamped);
  }

  void _onPageCommitted(BuildContext context, int index) {
    final bloc = context.read<ReaderBloc>();
    if (bloc.state.pageCount <= 0) return;
    final clamped = index.clamp(0, bloc.state.pageCount - 1);
    if (clamped != bloc.state.currentPage) {
      bloc.add(ReaderEvent.pageChanged(index: clamped));
    }
    pageViewController.setCurrentPage(clamped);
  }
}
