import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../../core/services/services.dart';
import '../../../../../../core/theme/theme.dart';
import '../../../../../settings/domain/models/reader_preferences.dart';
import '../../../bloc/reader_bloc.dart';
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
  });

  final int index;
  final ReaderState state;
  final ReaderPreferences prefs;
  final void Function(int) onPageChangeRequested;
  final bool isContinuous;

  @override
  State<ReflowablePageItem> createState() => _ReflowablePageItemState();
}

class _ReflowablePageItemState extends State<ReflowablePageItem> {
  late final ScrollController _scrollController;
  double _accumulatedBottomOverscroll = 0.0;
  double _accumulatedTopOverscroll = 0.0;
  bool _navigating = false;

  static const double _overscrollTriggerDistance = 48.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static FontWeight _resolveFontWeight(String weight) => switch (weight) {
    'lighter' => FontWeight.w300,
    'bold' => FontWeight.w700,
    _ => FontWeight.normal,
  };

  bool _onScrollNotification(ScrollNotification notification) {
    if (_navigating) return false;

    if (notification is OverscrollNotification) {
      if (notification.overscroll > 0) {
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
    } else if (notification is ScrollEndNotification) {
      _accumulatedBottomOverscroll = 0.0;
      _accumulatedTopOverscroll = 0.0;
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

    final hasNextPage = widget.index < widget.state.pageCount - 1;

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
              const SizedBox(height: 32),
              // Elegant end-of-page cue
              _EndOfPageIndicator(
                currentPage: widget.index + 1,
                totalPages: widget.state.pageCount,
                hasNextPage: hasNextPage,
                onNextPage: hasNextPage
                    ? () => widget.onPageChangeRequested(widget.index + 1)
                    : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    // In continuous scrolling mode (or unconstrained vertical parent), render directly
    if (widget.isContinuous) {
      return buildPageContent();
    }

    return LayoutBuilder(
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
    );
  }

  void _onTapUrl(BuildContext context, String url) {
    final match = RegExp(r'^#page=(\d+)$').firstMatch(url);
    if (match != null) {
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      widget.onPageChangeRequested(
        int.parse(match.group(1)!).clamp(0, maxIndex),
      );
      return;
    }
    logger.d('External link ignored: $url');
  }
}

class _EndOfPageIndicator extends StatelessWidget {
  const _EndOfPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    this.onNextPage,
  });

  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hintColor = colors.readerForeground.withValues(alpha: 0.5);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 1,
                  color: colors.readerForeground.withValues(alpha: 0.2),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    hasNextPage
                        ? '$currentPage / $totalPages'
                        : 'End of Document',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hintColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 1,
                  color: colors.readerForeground.withValues(alpha: 0.2),
                ),
              ],
            ),
            if (hasNextPage) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onNextPage,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue Reading',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hintColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: hintColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
