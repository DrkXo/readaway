import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../core/services/services.dart';
import '../../../../../../core/theme/theme.dart';
import '../../../../../../core/utils/reader/reader_html_utils.dart';
import '../../../../domain/repositories/reader_repository.dart';
import '../../../bloc/reader_bloc.dart';
import '../../../gestures/reader_gesture_arena.dart';
import '../../tts/reader_tts_mini_player_bar.dart';
import 'html/hyper_page_content.dart';
import 'reflowable_scroll_coordinator.dart';

/// A reflowable document page item widget that lazily loads and renders page content.
///
/// Features:
/// - Intelligent overscroll detection (pulling up at page end navigates to next page;
///   pulling down at top navigates to previous page).
/// - Physics-based overscroll handling with cross-platform consistency.
/// - End-of-chapter footer cue for immediate visual feedback.
class ReflowableReaderPage extends StatefulWidget {
  const ReflowableReaderPage({
    super.key,
    required this.index,
    required this.state,
    required this.prefs,
    required this.onPageChangeRequested,
    this.isContinuous = false,
    this.onScrollBoundaryChanged,
  });

  final int index;
  final ReaderState state;
  final ReaderPreferences prefs;
  final void Function(int) onPageChangeRequested;
  final bool isContinuous;

  /// Called whenever the inner scroll view's boundary state changes.
  ///
  /// [atTop] is true when the scroll position is at (or before) `minScrollExtent`.
  /// [atBottom] is true when the scroll position is at (or beyond) `maxScrollExtent`.
  /// Also fires with `atTop: true, atBottom: true` when content is shorter than the viewport.
  final void Function({required bool atTop, required bool atBottom})?
  onScrollBoundaryChanged;

  @override
  State<ReflowableReaderPage> createState() => _ReflowableReaderPageState();
}

class _ReflowableReaderPageState extends State<ReflowableReaderPage> {
  late final ScrollController _scrollController;
  late final ReflowableScrollCoordinator _scrollCoordinator;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollCoordinator = ReflowableScrollCoordinator(
      scrollController: _scrollController,
      index: widget.index,
      pageCount: widget.state.pageCount,
      direction: widget.prefs.scrollDirection,
      onPageChangeRequested: widget.onPageChangeRequested,
      onScrollBoundaryChanged: widget.onScrollBoundaryChanged,
    );
    // Seed the boundary state once layout is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollCoordinator.reportBoundary();
    });
  }

  @override
  void didUpdateWidget(ReflowableReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollCoordinator.update(
      index: widget.index,
      pageCount: widget.state.pageCount,
      direction: widget.prefs.scrollDirection,
    );
    if (widget.state.ttsActive != oldWidget.state.ttsActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollCoordinator.reportBoundary();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final html =
        widget.state.pageHtmls != null &&
            widget.index < widget.state.pageHtmls!.length
        ? widget.state.pageHtmls![widget.index]
        : null;
    final links =
        widget.state.pageLinks != null &&
            widget.index < widget.state.pageLinks!.length
        ? widget.state.pageLinks![widget.index]
        : null;

    if (html == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: widget.index));
          }
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    final double extraBottom = (!widget.isContinuous && widget.state.ttsActive)
        ? (ReaderTtsMiniPlayerBar.height + 12.0)
        : 0.0;

    Widget buildPageContent() {
      return Padding(
        padding: EdgeInsets.only(
          top: widget.prefs.marginTop,
          bottom: widget.prefs.marginBottom + extraBottom,
          left: widget.prefs.marginHorizontal,
          right: widget.prefs.marginHorizontal,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HyperPageContent(
                html: injectLinksIntoHtml(
                  html,
                  links ?? const [],
                  linkColor: context.appColors.scheme.primary,
                ),
                prefs: widget.prefs,
                onLinkTap: (url) => _onTapUrl(context, url),
              ),
            ],
          ),
        ),
      );
    }

    final Color bgColor =
        Theme.of(context).extension<AppColors>()?.readerBackground ??
        context.appColors.readerBackground;

    // In continuous scrolling mode (or unconstrained vertical parent), render directly
    if (widget.isContinuous) {
      return ColoredBox(
        color: bgColor,
        child: buildPageContent(),
      );
    }

    return ColoredBox(
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.maxHeight.isFinite) {
            return buildPageContent();
          }

          return NotificationListener<ScrollNotification>(
            onNotification: _scrollCoordinator.handleNotification,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              clipBehavior: Clip.none,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(
                    0.0,
                    constraints.maxHeight,
                  ),
                ),
                child: buildPageContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTapUrl(BuildContext context, String url) async {
    ReaderGestureArena.suppressNextTap();
    final match = RegExp(r'^#page=(\d+)$').firstMatch(url);
    if (match != null) {
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      widget.onPageChangeRequested(
        int.parse(match.group(1)!).clamp(0, maxIndex),
      );
      return;
    }

    // Resolve internal EPUB/document destination link via ReaderRepository
    final res = await GetIt.I<ReaderRepository>().resolveLink(url).run();
    res.fold(
      (failure) => logger.d('Could not resolve link: $url ($failure)'),
      (page) {
        if (page >= 0) {
          if (!context.mounted) return;
          final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
          widget.onPageChangeRequested(page.clamp(0, maxIndex));
        } else {
          logger.d('Link resolved to invalid page $page: $url');
        }
      },
    );
  }
}
