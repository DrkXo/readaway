import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../settings/domain/entity/reader_preferences.dart';
import 'chapter_layout_measurement.dart';
import 'html/hyper_page_content.dart';

/// Lays out one chapter offscreen purely to measure its page geometry.
///
/// Renders the chapter's full content at the width the visible page uses, then
/// registers the resulting layout with [coordinator]. It is meant to be hosted
/// inside an [Offstage], which Flutter lays out as if it were in the tree while
/// skipping paint, hit testing, and semantics.
///
/// This exists so a backward step into a chapter that has never been shown can
/// wait for its real page count instead of landing on its first page: the count
/// is unknowable until the chapter has been laid out, and the visible page only
/// measures itself once it is already on screen.
class ChapterLayoutProbe extends StatefulWidget {
  const ChapterLayoutProbe({
    super.key,
    required this.chapterIndex,
    required this.html,
    required this.prefs,
    required this.coordinator,
    required this.availableWidth,
    required this.cacheNamespace,
    this.onResolveAssetBytes,
  });

  final int chapterIndex;
  final String html;
  final ReaderPreferences prefs;
  final PaginationCoordinator coordinator;

  /// Width the chapter's text is laid out in, i.e. the viewport minus the
  /// horizontal margins. Must match what the visible page uses.
  final double availableWidth;

  final String cacheNamespace;
  final Future<List<int>?> Function(String src)? onResolveAssetBytes;

  @override
  State<ChapterLayoutProbe> createState() => _ChapterLayoutProbeState();
}

class _ChapterLayoutProbeState extends State<ChapterLayoutProbe> {
  /// Content can settle over more than one frame (async assets, deferred text
  /// shaping), so measurement is retried a bounded number of times rather than
  /// re-registering on every frame a chapter stays unmeasured.
  static const int _maxAttempts = 4;

  final GlobalKey _contentKey = GlobalKey();
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _scheduleMeasurement();
  }

  @override
  void didUpdateWidget(ChapterLayoutProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterIndex != widget.chapterIndex ||
        oldWidget.html != widget.html ||
        oldWidget.prefs != widget.prefs ||
        oldWidget.availableWidth != widget.availableWidth) {
      _attempts = 0;
      _scheduleMeasurement();
    }
  }

  void _scheduleMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
    });
  }

  void _measure() {
    final contentContext = _contentKey.currentContext;
    if (contentContext == null) return;

    registerChapterLayoutFromRenderObject(
      coordinator: widget.coordinator,
      chapterIndex: widget.chapterIndex,
      root: contentContext.findRenderObject(),
    );

    if (widget.coordinator.isChapterMeasured(widget.chapterIndex)) return;
    if (_attempts++ >= _maxAttempts) return;
    _scheduleMeasurement();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.availableWidth,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: widget.availableWidth,
        maxWidth: widget.availableWidth,
        minHeight: 0.0,
        maxHeight: double.infinity,
        child: KeyedSubtree(
          key: _contentKey,
          child: HyperPageContent(
            html: widget.html,
            prefs: widget.prefs,
            chapterIndex: widget.chapterIndex,
            cacheNamespace: widget.cacheNamespace,
            onResolveAssetBytes: widget.onResolveAssetBytes,
            onLinkTap: _ignoreLink,
          ),
        ),
      ),
    );
  }

  static void _ignoreLink(String _) {}
}

/// Lays [ChapterLayoutProbe] out without ever showing it.
///
/// Sizing matches the reader viewport so the measured geometry is the geometry
/// the visible page would produce. The probe is ignored for input and excluded
/// from semantics by [Offstage] itself; [IgnorePointer] is belt and braces for
/// the brief window between mount and the offstage layout.
class OffscreenChapterMeasurer extends StatelessWidget {
  const OffscreenChapterMeasurer({
    super.key,
    required this.chapterIndex,
    required this.html,
    required this.prefs,
    required this.coordinator,
    required this.viewportWidth,
    required this.cacheNamespace,
    this.onResolveAssetBytes,
  });

  final int chapterIndex;
  final String html;
  final ReaderPreferences prefs;
  final PaginationCoordinator coordinator;
  final double viewportWidth;
  final String cacheNamespace;
  final Future<List<int>?> Function(String src)? onResolveAssetBytes;

  @override
  Widget build(BuildContext context) {
    final availableWidth = math.max(
      0.0,
      viewportWidth - (prefs.marginHorizontal * 2),
    );

    return Offstage(
      offstage: true,
      child: IgnorePointer(
        child: SizedBox(
          width: viewportWidth,
          child: ChapterLayoutProbe(
            chapterIndex: chapterIndex,
            html: html,
            prefs: prefs,
            coordinator: coordinator,
            availableWidth: availableWidth,
            cacheNamespace: cacheNamespace,
            onResolveAssetBytes: onResolveAssetBytes,
          ),
        ),
      ),
    );
  }
}
