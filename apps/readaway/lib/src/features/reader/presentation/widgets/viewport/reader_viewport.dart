import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../settings/domain/models/reader_preferences.dart';
import '../../bloc/reader_bloc.dart';
import '../../controllers/reader_page_view_controller.dart';
import '../common/reader_error_view.dart';
import 'items/fixed_image_page_item.dart';
import 'items/reflowable_page_item.dart';
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
    return BlocBuilder<ReaderBloc, ReaderState>(
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
        pageViewController.setCurrentPage(state.currentPage);

        // Default ScrollBehavior excludes mouse from dragDevices (it fights
        // text selection), which leaves PageView unpageable by mouse. Opt
        // this PageView in: over text, SelectionArea's recognizer still wins
        // the arena; over images/margins mouse drag flips pages.
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.mouse,
            },
          ),
          child: ReaderPageView(
            currentPage: state.currentPage,
            pageCount: state.pageCount,
            transition: prefs.pageTransition,
            direction: prefs.scrollDirection,
            itemBuilder: state.isReflowable
                ? (context, index) => ReflowablePageItem(
                    index: index,
                    state: state,
                    prefs: prefs,
                    onPageChangeRequested: (index) =>
                        _onPageChangeRequested(context, index),
                  )
                : (context, index) => FixedImagePageItem(
                    index: index,
                    state: state,
                    onPageChangeRequested: (index) =>
                        _onPageChangeRequested(context, index),
                  ),
            onPageChangeRequested: (index) =>
                _onPageChangeRequested(context, index),
          ),
        );
      },
    );
  }

  void _onPageChangeRequested(BuildContext context, int index) {
    final state = context.read<ReaderBloc>().state;
    final clamped = index.clamp(0, state.pageCount - 1);
    if (clamped == state.currentPage) return;
    context.read<ReaderBloc>().add(ReaderEvent.pageChanged(index: clamped));
  }
}
