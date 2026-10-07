import 'dart:convert';
import 'dart:math' as math;

import 'package:cacherine/cacherine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway/src/features/reader/presentation/widgets/overlay/reader_footnote_sheet.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../../core/theme/theme.dart';
import '../../../../../../features/settings/domain/entity/reader_preferences.dart';
import '../../../../../annotations/presentation/widgets/painting/reader_annotation_layer.dart';
import '../../../../../annotations/presentation/widgets/selection/annotation_selection_menu.dart';
import '../../../../domain/repositories/reader_repository.dart';
import '../../../bloc/reader_bloc.dart';
import '../../../controllers/reader_viewport_controller.dart';
import '../../tts/reader_tts_mini_player_bar.dart';
import 'chapter_layout_measurement.dart';
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
    required this.coordinator,
    required this.controller,
    required this.onPageChangeRequested,
    this.isContinuous = false,
    this.onScrollBoundaryChanged,
  });

  final int index;
  final ReaderState state;
  final ReaderPreferences prefs;

  /// Supplies the chapter geometry the annotation layer resolves against, and
  /// receives this chapter's measurement.
  final PaginationCoordinator coordinator;

  /// Receives the annotation layer's tap handler, so a tap on a highlight can
  /// open it.
  final ReaderViewportController controller;

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
  final SimpleLRUCache<String, List<int>> _assetCache = SimpleLRUCache(30);

  /// Single-flight guard for [_resolveAssetBytes].
  ///
  /// Plain map by design — entries are transient by definition (they vanish
  /// when the request settles) and they wrap slow async work, which
  /// cacherine's `getOrCompute` would serialise behind a per-instance lock
  /// while also caching the result permanently.
  final Map<String, Future<List<int>?>> _inFlightAssetRequests = {};

  /// Marks the chapter content, so its measured geometry can be read back.
  final GlobalKey _contentKey = GlobalKey();

  /// The last content width measured, so a reflow re-measures exactly once.
  double? _lastMeasuredWidth;

  /// Guards against queueing more than one measurement per frame.
  bool _measureScheduled = false;

  /// Reads this chapter's laid-out geometry into
  /// [ReflowableReaderPage.coordinator].
  ///
  /// Continuous reading never slices a chapter, so nothing else would measure
  /// it and the annotation layer would have no geometry to resolve against.
  /// Deferred to after the frame because the render object has no size until
  /// layout has run.
  void _scheduleMeasurement() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      registerChapterLayoutFromRenderObject(
        coordinator: widget.coordinator,
        chapterIndex: widget.index,
        root: _contentKey.currentContext?.findRenderObject(),
      );
    });
  }

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
    _scheduleMeasurement();
  }

  @override
  void didUpdateWidget(ReflowableReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollCoordinator.update(
      index: widget.index,
      pageCount: widget.state.pageCount,
      direction: widget.prefs.scrollDirection,
    );
    // A preference change reflows the chapter, and its HTML can be loaded or
    // replaced; either way the measured geometry no longer describes what is
    // on screen.
    if (widget.prefs != oldWidget.prefs ||
        !identical(widget.state.pageHtmls, oldWidget.state.pageHtmls)) {
      _scheduleMeasurement();
    }
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

    if (html == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: widget.index));
          }
        }
      });
      return Center(
        child: SpinKitPulsingGrid(
          color: Theme.of(context).colorScheme.primary,
          size: 28.0,
        ),
      );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // A width change reflows the chapter, so the geometry the
              // annotations were resolved against is no longer valid.
              if (_lastMeasuredWidth != constraints.maxWidth) {
                _lastMeasuredWidth = constraints.maxWidth;
                _scheduleMeasurement();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Continuous reading never slices a chapter, so the content is
                  // not translated and no slice offset applies: chapter
                  // coordinates are already this widget's coordinates.
                  ReaderAnnotationLayer(
                    chapterIndex: widget.index,
                    coordinator: widget.coordinator,
                    controller: widget.controller,
                    sliceTop: 0,
                    child: KeyedSubtree(
                      key: _contentKey,
                      child: HyperPageContent(
                        html: html,
                        prefs: widget.prefs,
                        chapterIndex: widget.index,
                        cacheNamespace:
                            widget.state.documentPath ??
                            widget.state.fileName ??
                            '',
                        availableWidth: constraints.maxWidth,
                        availableHeight: constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : null,
                        onImageDecoded: _scheduleMeasurement,
                        onResolveAssetBytes: _resolveAssetBytes,
                        onLinkTap: (url) => _onTapUrl(context, url),
                        menuActionsBuilder: (overlayState) {
                          widget.controller.setSelectionActive(
                            overlayState.hasSelection,
                          );
                          return AnnotationSelectionMenu.actions(
                            context,
                            chapterIndex: widget.index,
                            coordinator: widget.coordinator,
                            state: overlayState,
                            controller: widget.controller,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    final Color bgColor = context.appColors.readerBackground;

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

  Future<List<int>?> _resolveAssetBytes(String src) async {
    if (src.isEmpty) return null;

    final cached = _assetCache.get(src);
    if (cached != null) return cached;

    // 1. Inline data URI (e.g. data:image/png;base64,...)
    if (src.startsWith('data:')) {
      final commaIndex = src.indexOf(',');
      if (commaIndex != -1) {
        try {
          final decoded = base64Decode(src.substring(commaIndex + 1));
          _assetCache.set(src, decoded);
          return decoded;
        } catch (_) {}
      }
      return null;
    }

    // 2. HTTP / HTTPS external URLs (handled by default Flutter network loaders if permitted)
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return null;
    }

    // 3. Deduplicate concurrent in-flight requests for the same asset
    if (_inFlightAssetRequests.containsKey(src)) {
      return await _inFlightAssetRequests[src];
    }

    final future = _loadAssetBytes(src);
    _inFlightAssetRequests[src] = future;
    try {
      final bytes = await future;
      if (bytes != null && bytes.isNotEmpty) {
        _assetCache.set(src, bytes);
      }
      return bytes;
    } finally {
      _inFlightAssetRequests.remove(src);
    }
  }

  Future<List<int>?> _loadAssetBytes(String src) async {
    final res = await GetIt.I<ReaderRepository>().loadAssetBytes(
      src,
      pageIndex: widget.index,
    );
    return res.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint(
            '[ReflowableReaderPage] Failed to load asset "$src" for page ${widget.index}: $failure',
          );
        }
        return null;
      },
      (bytes) => bytes,
    );
  }

  void _onTapUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;

    final match = RegExp(r'^#page=(\d+)$').firstMatch(url);
    if (match != null) {
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      widget.onPageChangeRequested(
        int.parse(match.group(1)!).clamp(0, maxIndex),
      );
      return;
    }

    // Check if the link target is a footnote or note
    final footnoteRes = await GetIt.I<ReaderRepository>().resolveFootnote(
      url,
      currentChapterIndex: widget.index,
    );
    final footnote = footnoteRes.dataOrNull;
    if (footnote != null && context.mounted) {
      // Resolve optional cross-chapter jump target
      VoidCallback? onJump;
      if (!url.startsWith('#')) {
        final reflowRes = await GetIt.I<ReaderRepository>()
            .resolveReflowableLink(url);
        final targetSection = reflowRes.dataOrNull;
        if (targetSection != null &&
            targetSection >= 0 &&
            targetSection != widget.index) {
          onJump = () {
            final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
            widget.onPageChangeRequested(targetSection.clamp(0, maxIndex));
          };
        }
      }
      if (!context.mounted) return;
      ReaderFootnoteSheet.show(
        context: context,
        footnote: footnote,
        onJumpToNote: onJump,
      );
      return;
    }

    if (url.startsWith('#')) {
      // Intra-chapter anchor: handled in-page
      return;
    }

    // Try resolving cross-chapter link in reflowable document
    final reflowRes = await GetIt.I<ReaderRepository>().resolveReflowableLink(
      url,
    );
    final targetSection = reflowRes.dataOrNull;
    if (targetSection != null && targetSection >= 0) {
      if (!context.mounted) return;
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      widget.onPageChangeRequested(targetSection.clamp(0, maxIndex));
    }
  }
}
