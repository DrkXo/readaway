import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../core/services/services.dart';
import '../../../../../../core/theme/theme.dart';
import '../../../../../settings/domain/entity/reader_preferences.dart';
import '../../../../domain/repositories/reader_repository.dart';
import '../../../bloc/reader_bloc.dart';
import '../../../gestures/reader_gesture_arena.dart';
import '../reader_document_view.dart';
import '../reader_selection_area.dart';

/// A reflowable document page item widget that lazily loads and renders page content.
///
/// Features:
/// - Intelligent overscroll detection (pulling up at page end navigates to next page;
///   pulling down at top navigates to previous page).
/// - Physics-based overscroll handling with cross-platform consistency.
/// - End-of-chapter footer cue for immediate visual feedback.
class ReflowablePageItem extends StatefulWidget {
  const ReflowablePageItem({
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
  State<ReflowablePageItem> createState() => _ReflowablePageItemState();
}

class _ReflowablePageItemState extends State<ReflowablePageItem> {
  late final ScrollController _scrollController;
  double _accumulatedBottomOverscroll = 0.0;
  double _accumulatedTopOverscroll = 0.0;
  bool _navigating = false;

  // Boundary state reported to the gesture arena so it knows whether to claim
  // a vertical drag for page-turning or let the inner scroll view handle it.
  bool _atTop = true;
  bool _atBottom = false;

  static const double _overscrollTriggerDistance = 48.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Seed the boundary state once layout is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportBoundary());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Reports the current top/bottom boundary state to the parent.
  void _reportBoundary() {
    if (!mounted) return;
    final bool atTop;
    final bool atBottom;
    if (_scrollController.hasClients) {
      final pos = _scrollController.position;
      // Content shorter than viewport: both boundaries are true.
      atTop = pos.pixels <= pos.minScrollExtent;
      atBottom = pos.pixels >= pos.maxScrollExtent;
    } else {
      // No scroll clients yet (e.g. content not scrollable) — treat as both boundaries.
      atTop = true;
      atBottom = true;
    }

    if (atTop != _atTop || atBottom != _atBottom) {
      _atTop = atTop;
      _atBottom = atBottom;
      widget.onScrollBoundaryChanged?.call(atTop: atTop, atBottom: atBottom);
    }
  }

  static FontWeight _resolveFontWeight(String weight) => switch (weight) {
    'lighter' => FontWeight.w300,
    'bold' => FontWeight.w700,
    _ => FontWeight.normal,
  };

  bool _onScrollNotification(ScrollNotification notification) {
    if (_navigating) return false;

    // Overscroll-to-navigate only applies in vertical paging modes.
    // In horizontal paging the inner scroll view scrolls freely and stops at
    // its boundary without triggering a page flip.
    final isVerticalPaging =
        widget.prefs.scrollDirection == ReaderScrollDirection.vertical;

    if (notification is OverscrollNotification) {
      if (!isVerticalPaging) {
        // No-op: let the scroll view handle its own bounce.
      } else if (notification.overscroll > 0) {
        // User is at the bottom dragging upwards (seeking next page)
        _accumulatedBottomOverscroll += notification.overscroll;
        if (_accumulatedBottomOverscroll > _overscrollTriggerDistance) {
          if (widget.index < widget.state.pageCount - 1) {
            _navigating = true;
            widget.onPageChangeRequested(widget.index + 1);
          }
        }
      } else if (notification.overscroll < 0) {
        // User is at the top dragging downwards (seeking previous page)
        _accumulatedTopOverscroll += notification.overscroll.abs();
        if (_accumulatedTopOverscroll > _overscrollTriggerDistance) {
          if (widget.index > 0) {
            _navigating = true;
            widget.onPageChangeRequested(widget.index - 1);
          }
        }
      }
    } else if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final delta = notification.scrollDelta ?? 0.0;
      if (isVerticalPaging) {
        // When at the bottom and scrolling down further (touch drag or mouse wheel)
        if (metrics.pixels >= metrics.maxScrollExtent && delta > 0) {
          _accumulatedBottomOverscroll += delta;
          if (_accumulatedBottomOverscroll > _overscrollTriggerDistance) {
            if (widget.index < widget.state.pageCount - 1) {
              _navigating = true;
              widget.onPageChangeRequested(widget.index + 1);
            }
          }
        } else if (metrics.pixels <= metrics.minScrollExtent && delta < 0) {
          _accumulatedTopOverscroll += delta.abs();
          if (_accumulatedTopOverscroll > _overscrollTriggerDistance) {
            if (widget.index > 0) {
              _navigating = true;
              widget.onPageChangeRequested(widget.index - 1);
            }
          }
        }
      }
      // Keep boundary state fresh so the arena always has accurate info.
      _reportBoundary();
    } else if (notification is ScrollEndNotification) {
      _accumulatedBottomOverscroll = 0.0;
      _accumulatedTopOverscroll = 0.0;
      _reportBoundary();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final doc =
        widget.state.documentPages != null &&
            widget.index < widget.state.documentPages!.length
        ? widget.state.documentPages![widget.index]
        : null;

    if (doc == null) {
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

    Widget buildPageContent() {
      return Padding(
        padding: EdgeInsets.only(
          top: widget.prefs.marginTop,
          bottom: widget.prefs.marginBottom,
          left: widget.prefs.marginHorizontal,
          right: widget.prefs.marginHorizontal,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReaderSelectionArea(
                child: ReaderDocumentView(
                  document: doc,
                  appColors: context.appColors,
                  baseFontSize: widget.prefs.fontSize,
                  lineHeight: widget.prefs.lineHeight,
                  letterSpacing: widget.prefs.letterSpacing,
                  fontFamily: widget.prefs.fontFamily,
                  fontWeight: _resolveFontWeight(widget.prefs.fontWeight),
                  wordSpacing: widget.prefs.wordSpacing,
                  textIndent: widget.prefs.textIndent,
                  fullJustification: widget.prefs.fullJustification,
                  paragraphMargin: widget.prefs.paragraphMargin,
                  serifFont: widget.prefs.serifFont,
                  sansSerifFont: widget.prefs.sansSerifFont,
                  monospaceFont: widget.prefs.monospaceFont,
                  overrideFont: widget.prefs.overrideFont,
                  onTapUrl: (url) => _onTapUrl(context, url),
                ),
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
            onNotification: _onScrollNotification,
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
