import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../core/theme/theme.dart';
import '../../../../../../features/settings/domain/entity/reader_preferences.dart';
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
  final Map<String, List<int>> _assetCache = {};
  final Map<String, Future<List<int>?>> _inFlightAssetRequests = {};

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
                html: html,
                prefs: widget.prefs,
                onResolveAssetBytes: _resolveAssetBytes,
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

  Future<List<int>?> _resolveAssetBytes(String src) async {
    if (src.isEmpty) return null;

    if (_assetCache.containsKey(src)) {
      return _assetCache[src];
    }

    // 1. Inline data URI (e.g. data:image/png;base64,...)
    if (src.startsWith('data:')) {
      final commaIndex = src.indexOf(',');
      if (commaIndex != -1) {
        try {
          final decoded = base64Decode(src.substring(commaIndex + 1));
          _assetCache[src] = decoded;
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
        _assetCache[src] = bytes;
      }
      return bytes;
    } finally {
      _inFlightAssetRequests.remove(src);
    }
  }

  Future<List<int>?> _loadAssetBytes(String src) async {
    final res = await GetIt.I<ReaderRepository>()
        .loadAssetBytes(src, pageIndex: widget.index)
        .run();
    return res.fold(
      (failure) {
        debugPrint(
          '[ReflowableReaderPage] Failed to load asset "$src" for page ${widget.index}: $failure',
        );
        return null;
      },
      (bytes) {
        if (bytes != null && bytes.isNotEmpty) {
          debugPrint(
            '[ReflowableReaderPage] Successfully loaded asset "$src" (${bytes.length} bytes)',
          );
        } else {
          debugPrint(
            '[ReflowableReaderPage] Asset "$src" returned null or empty for page ${widget.index}',
          );
        }
        return bytes;
      },
    );
  }

  void _onTapUrl(BuildContext context, String url) async {
    ReaderGestureArena.suppressNextTap();
    if (url.isEmpty) return;

    final match = RegExp(r'^#page=(\d+)$').firstMatch(url);
    if (match != null) {
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      widget.onPageChangeRequested(
        int.parse(match.group(1)!).clamp(0, maxIndex),
      );
      return;
    }

    if (url.startsWith('#')) {
      // Intra-chapter anchor: handled in-page
      return;
    }

    // Try resolving cross-chapter link in reflowable document
    final reflowRes = await GetIt.I<ReaderRepository>()
        .resolveReflowableLink(url)
        .run();
    final targetSection = reflowRes.getRight().toNullable();
    if (targetSection != null && targetSection >= 0) {
      if (!context.mounted) return;
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      widget.onPageChangeRequested(targetSection.clamp(0, maxIndex));
    }
  }
}
