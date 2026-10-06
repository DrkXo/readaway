import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../../core/theme/theme.dart';
import '../../../../../../core/theme/tts_highlight_palette.dart';
import '../../../../../annotations/presentation/widgets/painting/reader_annotation_layer.dart';
import '../../../../../annotations/presentation/widgets/selection/annotation_selection_menu.dart';
import '../../../../../settings/domain/entity/reader_preferences.dart';
import '../../../../../settings/domain/entity/settings.dart';
import '../../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../../domain/repositories/reader_tts_repository.dart';
import '../../../bloc/reader_bloc.dart';
import '../../../controllers/reader_viewport_controller.dart';
import '../../chrome/reader_running_footer.dart';
import '../../chrome/reader_running_header.dart';
import '../../toc/reader_toc_content.dart';
import '../../tts/reader_tts_mini_player_bar.dart';
import 'chapter_layout_measurement.dart';
import 'html/hyper_page_content.dart';
import 'tts_speech_highlight.dart';

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
    required this.controller,
    required this.onResolveAssetBytes,
    required this.onLinkTap,
  });

  final int chapterIndex;
  final int pageInChapter;
  final int totalPagesInChapter;
  final int globalPageIndex;
  final ReaderState state;
  final ReaderPreferences prefs;
  final PaginationCoordinator coordinator;

  /// Receives the annotation layer's tap handler, so a tap on a highlight can
  /// open it.
  final ReaderViewportController controller;

  final Future<List<int>?> Function(String src)? onResolveAssetBytes;
  final void Function(String) onLinkTap;

  @override
  State<ReflowableVirtualPage> createState() => _ReflowableVirtualPageState();
}

class _ReflowableVirtualPageState extends State<ReflowableVirtualPage> {
  final GlobalKey _contentKey = GlobalKey();
  Size? _lastConstraints;
  StreamSubscription<PaginationState>? _coordinatorSubscription;
  List<double>? _lastOffsets;
  final ValueNotifier<({int start, int end})?> _activeWordNotifier =
      ValueNotifier(null);
  StreamSubscription<TtsWordProgress?>? _wordProgressSubscription;

  @override
  void initState() {
    super.initState();
    _lastOffsets = widget.coordinator.getChapterPageOffsets(
      widget.chapterIndex,
    );
    _coordinatorSubscription = widget.coordinator.state.listen(
      (_) => _onCoordinatorUpdated(),
    );
    if (GetIt.I.isRegistered<ReaderTtsRepository>()) {
      _wordProgressSubscription = GetIt.I<ReaderTtsRepository>()
          .wordProgressStream
          .listen(_onWordProgress);
    }
    _scheduleMeasurement();
  }

  void _onWordProgress(TtsWordProgress? progress) {
    if (!mounted) return;
    if (progress == null || progress.chapterIndex != widget.chapterIndex) {
      if (_activeWordNotifier.value != null) {
        _activeWordNotifier.value = null;
      }
      return;
    }
    _activeWordNotifier.value = progress.wordRange;
  }

  void _onCoordinatorUpdated() {
    if (!mounted) return;
    final currentOffsets = widget.coordinator.getChapterPageOffsets(
      widget.chapterIndex,
    );
    if (_lastOffsets == null || !_listEquals(_lastOffsets!, currentOffsets)) {
      _lastOffsets = currentOffsets;
      setState(() {});
    }
  }

  static bool _listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(ReflowableVirtualPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      _coordinatorSubscription?.cancel();
      _coordinatorSubscription = widget.coordinator.state.listen(
        (_) => _onCoordinatorUpdated(),
      );
    }
    if (oldWidget.chapterIndex != widget.chapterIndex) {
      _lastOffsets = widget.coordinator.getChapterPageOffsets(
        widget.chapterIndex,
      );
      _activeWordNotifier.value = null;
      _scheduleMeasurement();
    } else if (oldWidget.prefs != widget.prefs ||
        oldWidget.state.pageHtmls?[widget.chapterIndex] !=
            widget.state.pageHtmls?[widget.chapterIndex]) {
      _scheduleMeasurement();
    }
  }

  @override
  void dispose() {
    _coordinatorSubscription?.cancel();
    _wordProgressSubscription?.cancel();
    _activeWordNotifier.dispose();
    super.dispose();
  }

  void _scheduleMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureAndRegister();
    });
  }

  void _measureAndRegister() {
    final contentContext = _contentKey.currentContext;
    if (contentContext == null) return;
    registerChapterLayoutFromRenderObject(
      coordinator: widget.coordinator,
      chapterIndex: widget.chapterIndex,
      root: contentContext.findRenderObject(),
    );
  }

  /// The highlight for the text being read aloud on this page, or null.
  ///
  /// Returns null when nothing is being read, when the spoken range belongs to
  /// another chapter, or when this chapter has no character mapping. Each of
  /// those means the same thing: there is no position known well enough to
  /// draw, so nothing is drawn.
  TtsSpeechHighlightPainter? _buildSpeechHighlight(
    double sliceTop,
    GlobalViewSettings? gvs,
  ) {
    final state = widget.state;
    final range = state.ttsSpeechRange;
    if (!state.ttsActive || range == null) return null;
    if (state.ttsChapterIndex != widget.chapterIndex) return null;

    final rects = widget.coordinator.rectsForSpeechRange(
      widget.chapterIndex,
      range.start,
      range.end,
    );

    final wordFocusEnabled = gvs?.ttsHighlightWordFocus ?? true;
    List<Rect>? wordRects;
    if (wordFocusEnabled) {
      final wordRange = _activeWordNotifier.value;
      if (wordRange != null) {
        wordRects = widget.coordinator.rectsForSpeechRange(
          widget.chapterIndex,
          wordRange.start,
          wordRange.end,
        );
      }
    }

    if (rects.isEmpty && (wordRects == null || wordRects.isEmpty)) return null;

    final style = switch (gvs?.ttsHighlightStyle) {
      'underline' => TtsHighlightStyle.underline,
      'squiggly' => TtsHighlightStyle.squiggly,
      'outline' => TtsHighlightStyle.outline,
      _ => TtsHighlightStyle.highlight,
    };

    final baseColor = resolveTtsHighlightColor(
      gvs?.ttsHighlightColor,
      Theme.of(context).colorScheme,
    );
    final sentenceAlpha = gvs?.ttsHighlightSentenceOpacity ?? 0.18;
    final wordAlpha = gvs?.ttsHighlightWordOpacity ?? 0.38;

    return TtsSpeechHighlightPainter(
      rects: rects,
      wordRects: wordRects,
      sliceTop: sliceTop,
      color: baseColor.withValues(alpha: sentenceAlpha),
      wordColor: baseColor.withValues(alpha: wordAlpha),
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    GlobalViewSettings? gvs;
    try {
      gvs = context.select<SettingsBloc, GlobalViewSettings>(
        (bloc) => bloc.state.appSettings.globalViewSettings,
      );
    } catch (_) {
      gvs = null;
    }

    final html =
        (widget.state.pageHtmls != null &&
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
      return Center(
        child: SpinKitPulsingGrid(
          color: Theme.of(context).colorScheme.primary,
          size: 28.0,
        ),
      );
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
          if (_lastConstraints != null &&
              _lastConstraints != currentConstraints) {
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
          final offsets = widget.coordinator.getChapterPageOffsets(
            widget.chapterIndex,
          );
          final sliceTop = (widget.pageInChapter < offsets.length)
              ? offsets[widget.pageInChapter]
              : (widget.pageInChapter * availableHeight);

          final sliceBottom = (widget.pageInChapter + 1 < offsets.length)
              ? offsets[widget.pageInChapter + 1]
              : null;
          final sliceHeight = (sliceBottom != null)
              ? math.max(0.0, math.min(availableHeight, sliceBottom - sliceTop))
              : availableHeight;

          final double extraBottom = widget.state.ttsActive
              ? (ReaderTtsMiniPlayerBar.height + 16.0)
              : 0.0;

          final pageContent = OverflowBox(
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
                  chapterIndex: widget.chapterIndex,
                  cacheNamespace:
                      widget.state.documentPath ?? widget.state.fileName ?? '',
                  onResolveAssetBytes: widget.onResolveAssetBytes,
                  onLinkTap: widget.onLinkTap,
                  menuActionsBuilder: (overlayState) =>
                      AnnotationSelectionMenu.actions(
                        context,
                        chapterIndex: widget.chapterIndex,
                        coordinator: widget.coordinator,
                        state: overlayState,
                      ),
                ),
              ),
            ),
          );

          final contentWidget = Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: availableWidth,
              height: sliceHeight,
              child: ClipRect(
                child: ListenableBuilder(
                  listenable: _activeWordNotifier,
                  builder: (context, child) {
                    final highlight = _buildSpeechHighlight(sliceTop, gvs);
                    return CustomPaint(
                      // Behind the text, so a highlighted passage reads as marked
                      // rather than tinted.
                      painter: highlight,
                      child: child,
                    );
                  },
                  // Reader highlights paint beneath the spoken-text highlight,
                  // so following along with TTS still reads correctly.
                  child: ReaderAnnotationLayer(
                    chapterIndex: widget.chapterIndex,
                    coordinator: widget.coordinator,
                    controller: widget.controller,
                    sliceTop: sliceTop,
                    child: pageContent,
                  ),
                ),
              ),
            ),
          );

          final currentPath =
              widget.state.outline != null && widget.state.outline!.isNotEmpty
              ? tocCurrentPath(widget.state.outline!, widget.chapterIndex)
              : null;
          final chapterTitle =
              currentPath?.$1.title ??
              widget.state.bookTitle ??
              widget.state.fileName ??
              '';

          final totalGlobalPages = widget.coordinator.currentState.totalPages;

          return Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: widget.prefs.marginTop,
                  bottom: widget.prefs.marginBottom,
                  left: widget.prefs.marginHorizontal,
                  right: widget.prefs.marginHorizontal,
                ),
                child: SizedBox(
                  width: availableWidth,
                  height: availableHeight,
                  child: extraBottom > 0
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: extraBottom),
                            child: contentWidget,
                          ),
                        )
                      : contentWidget,
                ),
              ),

              // Running Header
              if (widget.prefs.showHeader && widget.prefs.marginTop >= 16.0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReaderRunningHeader(
                    title: chapterTitle,
                    alignment: widget.prefs.headerAlignment,
                    fontSize: widget.prefs.headerFontSize,
                    height: widget.prefs.marginTop,
                    horizontalPadding: widget.prefs.marginHorizontal,
                  ),
                ),

              // Running Footer
              if (widget.prefs.showFooter && widget.prefs.marginBottom >= 16.0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ReaderRunningFooter(
                    pageInChapter: widget.pageInChapter,
                    totalPagesInChapter: widget.totalPagesInChapter,
                    globalPageIndex: widget.globalPageIndex,
                    totalGlobalPages: totalGlobalPages,
                    progressStyle: widget.prefs.footerProgressStyle,
                    showRemainingPages: widget.prefs.showRemainingPages,
                    showCurrentTime: widget.prefs.showCurrentTime,
                    showBatteryStatus: widget.prefs.showBatteryStatus,
                    showProgressBar: widget.prefs.showFooterProgressBar,
                    fontSize: widget.prefs.footerFontSize,
                    height: widget.prefs.marginBottom,
                    horizontalPadding: widget.prefs.marginHorizontal,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
