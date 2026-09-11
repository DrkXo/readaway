import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_render/hyper_render.dart';

import '../../../../../../core/services/reader/reflowable_pagination_coordinator.dart';
import '../../../../../../core/theme/theme.dart';
import '../../../../../settings/domain/entity/reader_preferences.dart';
import '../../../bloc/reader_bloc.dart';
import 'html/hyper_page_content.dart';

/// Renders a single discrete virtual screen page of a reflowable chapter.
///
/// Uses vertical translation and viewport clipping snapped to line boundaries,
/// ensuring text lines and images are never sliced in half across page turns.
class ReflowableVirtualPage extends StatefulWidget {
  const ReflowableVirtualPage({
    super.key,
    required this.chapterIndex,
    required this.pageInChapter,
    required this.totalPagesInChapter,
    required this.globalPageIndex,
    required this.state,
    required this.prefs,
    required this.coordinator,
    required this.onResolveAssetBytes,
    required this.onLinkTap,
  });

  final int chapterIndex;
  final int pageInChapter;
  final int totalPagesInChapter;
  final int globalPageIndex;
  final ReaderState state;
  final ReaderPreferences prefs;
  final ReflowablePaginationCoordinator coordinator;
  final Future<List<int>?> Function(String src)? onResolveAssetBytes;
  final void Function(String) onLinkTap;

  @override
  State<ReflowableVirtualPage> createState() => _ReflowableVirtualPageState();
}

class _ReflowableVirtualPageState extends State<ReflowableVirtualPage> {
  final GlobalKey _contentKey = GlobalKey();
  Size? _lastConstraints;

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_onCoordinatorUpdated);
    _scheduleMeasurement();
  }

  void _onCoordinatorUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ReflowableVirtualPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_onCoordinatorUpdated);
      widget.coordinator.addListener(_onCoordinatorUpdated);
    }
    if (oldWidget.chapterIndex != widget.chapterIndex ||
        oldWidget.prefs != widget.prefs ||
        oldWidget.state.pageHtmls?[widget.chapterIndex] !=
            widget.state.pageHtmls?[widget.chapterIndex]) {
      _scheduleMeasurement();
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordinatorUpdated);
    super.dispose();
  }

  void _scheduleMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureAndRegister();
    });
  }

  void _measureAndRegister() {
    final context = _contentKey.currentContext;
    if (context == null) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final contentHeight = renderObject.size.height;
    if (contentHeight <= 0.0) return;

    // Search for RenderHyperBox in the render subtree to extract exact line bounds
    final hyperBox = _findHyperBox(renderObject);
    List<({double top, double bottom})>? lineBounds;

    if (hyperBox != null) {
      try {
        final debugLines = hyperBox.debugLines();
        if (debugLines.isNotEmpty) {
          lineBounds = debugLines.map((l) {
            final top = (l['top'] as num).toDouble();
            final height = (l['height'] as num).toDouble();
            return (top: top, bottom: top + height);
          }).toList();
        }
      } catch (_) {}
    }

    widget.coordinator.registerChapterHeight(
      widget.chapterIndex,
      contentHeight,
      lineBounds: lineBounds,
    );
  }

  RenderHyperBox? _findHyperBox(RenderObject? root) {
    if (root == null) return null;
    if (root is RenderHyperBox) return root;

    RenderHyperBox? found;
    root.visitChildren((child) {
      found ??= _findHyperBox(child);
    });
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final html = (widget.state.pageHtmls != null &&
            widget.chapterIndex < widget.state.pageHtmls!.length)
        ? widget.state.pageHtmls![widget.chapterIndex]
        : null;

    if (html == null) {
      // Lazy load chapter HTML if not yet present in bloc state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: widget.chapterIndex));
          }
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    final Color bgColor =
        Theme.of(context).extension<AppColors>()?.readerBackground ??
            context.appColors.readerBackground;

    return ColoredBox(
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;

          final currentConstraints = Size(viewportWidth, viewportHeight);
          if (_lastConstraints != null && _lastConstraints != currentConstraints) {
            _lastConstraints = currentConstraints;
            _scheduleMeasurement();
          } else {
            _lastConstraints = currentConstraints;
          }

          final availableWidth = math.max(
            0.0,
            viewportWidth - (widget.prefs.marginHorizontal * 2),
          );
          final availableHeight = math.max(
            0.0,
            viewportHeight -
                (widget.prefs.marginTop + widget.prefs.marginBottom),
          );

          // Get calculated page offsets from the coordinator
          final offsets =
              widget.coordinator.getChapterPageOffsets(widget.chapterIndex);
          final sliceTop = (widget.pageInChapter < offsets.length)
              ? offsets[widget.pageInChapter]
              : (widget.pageInChapter * availableHeight);

          final sliceBottom = (widget.pageInChapter + 1 < offsets.length)
              ? offsets[widget.pageInChapter + 1]
              : null;
          final sliceHeight = (sliceBottom != null)
              ? math.max(0.0, math.min(availableHeight, sliceBottom - sliceTop))
              : availableHeight;

          return Padding(
            padding: EdgeInsets.only(
              top: widget.prefs.marginTop,
              bottom: widget.prefs.marginBottom,
              left: widget.prefs.marginHorizontal,
              right: widget.prefs.marginHorizontal,
            ),
            child: SizedBox(
              width: availableWidth,
              height: availableHeight,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: availableWidth,
                  height: sliceHeight,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minWidth: availableWidth,
                      maxWidth: availableWidth,
                      minHeight: 0.0,
                      maxHeight: double.infinity,
                      child: Transform.translate(
                        offset: Offset(0.0, -sliceTop),
                        child: KeyedSubtree(
                          key: _contentKey,
                          child: HyperPageContent(
                            html: html,
                            prefs: widget.prefs,
                            onResolveAssetBytes: widget.onResolveAssetBytes,
                            onLinkTap: widget.onLinkTap,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
