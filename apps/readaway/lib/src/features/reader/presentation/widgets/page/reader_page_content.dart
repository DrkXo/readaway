import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/services.dart';
import '../../../../settings/domain/models/reader_preferences.dart';
import '../../bloc/reader_bloc.dart';
import '../../controllers/auto_scroll_controller.dart';
import '../../controllers/reader_page_view_controller.dart';
import '../widgets.dart';

/// The page content widget that wraps the reader's page view.
class ReaderPageContent extends StatelessWidget {
  const ReaderPageContent({
    super.key,
    required this.pageViewController,
    required this.prefs,
    this.autoScrollController,
  });

  final ReaderPageViewController pageViewController;
  final ReaderPreferences prefs;

  /// Optional controller that drives auto-scroll. When provided, each
  /// reflowable page registers its vertical [ScrollController] with it.
  final AutoScrollController? autoScrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
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
        autoScrollController?.setPageCount(state.pageCount);
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
                ? (context, index) => ReaderHtmlPage(
                    index: index,
                    state: state,
                    prefs: prefs,
                    autoScrollController: autoScrollController,
                    onPageChangeRequested: (index) =>
                        _onPageChangeRequested(context, index),
                  )
                : (context, index) => ReaderImagePage(
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
    autoScrollController?.setCurrentPage(clamped);
  }
}

/// A reflowable HTML page widget that lazily loads page content and renders
/// it with auto-scroll support.
class ReaderHtmlPage extends StatelessWidget {
  const ReaderHtmlPage({
    super.key,
    required this.index,
    required this.state,
    required this.prefs,
    required this.autoScrollController,
    required this.onPageChangeRequested,
  });

  final int index;
  final ReaderState state;
  final ReaderPreferences prefs;
  final AutoScrollController? autoScrollController;
  final void Function(int) onPageChangeRequested;

  @override
  Widget build(BuildContext context) {
    final doc = state.documentPages != null && index < state.documentPages!.length
        ? state.documentPages![index]
        : null;

    if (doc == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: index));
          }
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    return AutoScrollableHtmlPage(
      index: index,
      document: doc,
      prefs: prefs,
      autoScrollController: autoScrollController,
      onTapUrl: (url) => _onTapUrl(context, url),
    );
  }

  void _onTapUrl(BuildContext context, String url) {
    final match = RegExp(r'^#page=(\d+)$').firstMatch(url);
    if (match != null) {
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      onPageChangeRequested(
        int.parse(match.group(1)!).clamp(0, maxIndex),
      );
      return;
    }
    logger.d('External link ignored: $url');
  }
}

/// An image page widget that lazily loads page content.
class ReaderImagePage extends StatelessWidget {
  const ReaderImagePage({
    super.key,
    required this.index,
    required this.state,
    required this.onPageChangeRequested,
  });

  final int index;
  final ReaderState state;
  final void Function(int) onPageChangeRequested;

  @override
  Widget build(BuildContext context) {
    final image = state.pageImages != null && index < state.pageImages!.length
        ? state.pageImages![index]
        : null;

    if (image == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: index));
          }
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: RawImage(image: image, fit: BoxFit.contain),
    );
  }
}
