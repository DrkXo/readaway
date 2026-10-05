import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:rxdart/rxdart.dart';

import '../models/models.dart';
import 'chapter_text_layout.dart';
import 'page_slicer.dart';
import 'speech_char_map.dart';

/// Reactive pagination coordinator for reflowable documents.
class PaginationCoordinator {
  final PageSlicer _slicer;
  final BehaviorSubject<PaginationState> _stateSubject;

  int _chapterCount = 0;
  double _viewportHeight = 0.0;
  final Map<int, double> _chapterHeights = {};
  final Map<int, int> _chapterPageCounts = {};
  final Map<int, List<double>> _chapterOffsets = {};
  final Map<int, List<({double top, double bottom})>?> _chapterLineBounds = {};
  final Map<int, ChapterTextLayout> _chapterLayouts = {};
  final Map<int, SpeechCharMap> _chapterSpeechMaps = {};
  final Map<int, String> _chapterSpeechTexts = {};
  ReadingAnchor _currentAnchor = const ReadingAnchor(
    chapterIndex: 0,
    progressionInChapter: 0.0,
  );
  int _totalPages = 0;

  PaginationCoordinator({this._slicer = const PageSlicer()})
    : _stateSubject = BehaviorSubject.seeded(const PaginationState());

  ValueStream<PaginationState> get state => _stateSubject.stream;
  PaginationState get currentState => _stateSubject.value;
  int get chapterCount => _chapterCount;
  ReadingAnchor get currentAnchor => _currentAnchor;

  void initialize({
    required int chapterCount,
    required double viewportHeight,
    required double contentHeight,
  }) {
    _chapterCount = chapterCount;
    _viewportHeight = viewportHeight;
    _chapterHeights.clear();
    _chapterPageCounts.clear();
    _chapterOffsets.clear();
    _chapterLineBounds.clear();
    _chapterLayouts.clear();
    _chapterSpeechMaps.clear();
    _chapterSpeechTexts.clear();
    _currentAnchor = const ReadingAnchor(
      chapterIndex: 0,
      progressionInChapter: 0.0,
    );
    _totalPages = 0;
    registerChapterHeight(chapterIndex: 0, contentHeight: contentHeight);
  }

  void updateViewport({
    required double viewportHeight,
    required double contentHeight,
  }) {
    _viewportHeight = viewportHeight;
    if (_chapterHeights.isNotEmpty) {
      _chapterHeights[0] = contentHeight;
    }
    _recomputeAll();
    _emit();
  }

  void registerChapterHeight({
    required int chapterIndex,
    required double contentHeight,
    List<({double top, double bottom})>? lineBounds,
  }) {
    // Skip redundant re-registrations (e.g. a page turn that re-measures the
    // same full chapter) so we don't recompute slices and wake every listener
    // when nothing changed.
    final prevHeight = _chapterHeights[chapterIndex];
    if (prevHeight == contentHeight &&
        _lineBoundsEqual(_chapterLineBounds[chapterIndex], lineBounds)) {
      return;
    }
    _chapterHeights[chapterIndex] = contentHeight;
    _chapterLineBounds[chapterIndex] = lineBounds;
    // A height change without a layout invalidates any character mapping built
    // from the previous geometry.
    // An unmeasured height change means any layout built for this chapter came
    // from stale geometry. Matching heights can still mean stale line bounds
    // (for example after a font change that reflows without altering total
    // height), so callers that re-measure should prefer
    // [registerChapterLayout].
    _chapterLayouts.remove(chapterIndex);
    _chapterSpeechMaps.remove(chapterIndex);
    _chapterSpeechTexts.remove(chapterIndex);
    _recomputeChapter(chapterIndex);
    _recomputeTotalPages();
    _emit();
  }

  /// Registers the full measured geometry for [chapterIndex].
  ///
  /// This is the preferred entry point: it carries the chapter's character
  /// space alongside its page geometry, which is what lets TTS map a speech
  /// offset onto an exact page instead of estimating from pixel fractions.
  void registerChapterLayout({
    required int chapterIndex,
    required ChapterTextLayout layout,
  }) {
    final previous = _chapterLayouts[chapterIndex];
    if (previous != null && previous.matches(layout)) return;

    _chapterLayouts[chapterIndex] = layout;
    // New geometry means a different flow text, so any existing
    // correspondence is stale. Rebuild it if the speech text is already known.
    _rebuildSpeechMap(chapterIndex);
    _chapterHeights[chapterIndex] = layout.contentHeight;
    _chapterLineBounds[chapterIndex] = layout.lineBounds.isEmpty
        ? null
        : layout.lineBounds;
    _recomputeChapter(chapterIndex);
    _recomputeTotalPages();
    _emit();
  }

  /// The measured layout for [chapterIndex], if it has been measured.
  ChapterTextLayout? getChapterLayout(int chapterIndex) =>
      _chapterLayouts[chapterIndex];

  /// Whether [chapterIndex] has a usable character-to-page mapping.
  ///
  /// False while a chapter is unmeasured, and false when its layout was built
  /// without usable geometry. Callers must fall back to proportional geometry
  /// in that case rather than trusting a zero.
  bool hasCharacterMapping(int chapterIndex) =>
      _chapterLayouts[chapterIndex]?.hasCharacterMapping ?? false;

  /// The page in [chapterIndex] containing [charOffset].
  ///
  /// Returns 0 when no character mapping is available; check
  /// [hasCharacterMapping] first if the distinction matters.
  int pageForChar(int chapterIndex, int charOffset) {
    return _chapterLayouts[chapterIndex]?.pageForChar(charOffset) ?? 0;
  }

  /// The global page for [charOffset] within [chapterIndex].
  int globalPageForChar(int chapterIndex, int charOffset) =>
      getGlobalPageForChapter(chapterIndex) +
      pageForChar(chapterIndex, charOffset);

  /// The character offset where [pageInChapter] of [chapterIndex] begins, or
  /// null when no character mapping is available.
  int? charForPage(int chapterIndex, int pageInChapter) =>
      _chapterLayouts[chapterIndex]?.charForPage(pageInChapter);

  /// Bounding boxes covering `[start, end)` of [chapterIndex]'s character space.
  List<Rect> rectsForCharRange(int chapterIndex, int start, int end) =>
      _chapterLayouts[chapterIndex]?.rectsForCharRange(start, end) ?? const [];

  /// Records the speech text for [chapterIndex] and builds its correspondence
  /// against the rendered layout.
  ///
  /// The two sides become available independently: a page measures as soon as
  /// it is built, while speech text is fetched asynchronously and can fail.
  /// Whichever arrives second triggers the alignment, so neither ordering has
  /// to be arranged by the caller.
  ///
  /// Returns the resulting map, or null when [chapterIndex] has no usable
  /// layout to compare against yet.
  SpeechCharMap? attachSpeechText(int chapterIndex, String speechText) {
    _chapterSpeechTexts[chapterIndex] = speechText;
    return _rebuildSpeechMap(chapterIndex);
  }

  /// Builds the correspondence for [chapterIndex] from whatever the two sides
  /// have stored, or null if either is missing or the layout is unusable.
  ///
  /// The stored speech text is deliberately kept when no map can be built: it
  /// is still valid, and the layout may arrive later.
  SpeechCharMap? _rebuildSpeechMap(int chapterIndex) {
    final layout = _chapterLayouts[chapterIndex];
    final speechText = _chapterSpeechTexts[chapterIndex];
    if (layout == null || speechText == null || !layout.hasCharacterMapping) {
      _chapterSpeechMaps.remove(chapterIndex);
      return null;
    }
    // Prefer fragment geometry whenever the layout carries any. It is not
    // chosen for scoring better — it is chosen because it cannot claim a
    // correspondence it has not verified.
    //
    // `fromSpans` places a fragment only by finding its exact text, so every
    // offset it reports as exact was matched character for character, and text
    // the speech side skips leaves the next fragment to be found by identity
    // however long the skipped block was.
    //
    // `build` infers instead, and both of its failure modes report themselves as
    // success. Past its resynchronisation lookahead it walks both strings
    // forward in step through text with no counterpart; across a list marker it
    // resynchronises onto the marker's trailing space and accumulates the
    // wrong offset for the rest of the chapter. Measured on a chapter of
    // eight marked items, it reported exactFraction 1.0 while being wrong at
    // every offset past the first. An uncertainty a caller can see is worth
    // more than a certainty it cannot.
    //
    // Its one advantage is a chapter whose fragments are all decorated, where
    // no fragment is findable and `fromSpans` places nothing. That is recorded
    // as a limit of the fragment path rather than worked around here, because
    // the workaround would reintroduce the inference this avoids.
    final hasFragmentText = layout.spans.any((span) => span.isFlowText);
    final map = hasFragmentText
        ? SpeechCharMap.fromSpans(speech: speechText, layout: layout)
        : SpeechCharMap.build(speechText, layout.flowText);
    _chapterSpeechMaps[chapterIndex] = map;
    return map;
  }

  /// The speech-to-render correspondence for [chapterIndex], if both the
  /// chapter's layout and its speech text are available.
  ///
  /// Callers must handle null: speech text is fetched asynchronously and may
  /// not have arrived, or may fail, while the page that owns the layout has
  /// already measured.
  SpeechCharMap? speechMapFor(int chapterIndex) =>
      _chapterSpeechMaps[chapterIndex];

  /// The page in [chapterIndex] containing [speechOffset], where [speechOffset]
  /// indexes the chapter's speech text.
  ///
  /// Returns null when the chapter has no speech map yet, so a caller can
  /// distinguish "not known" from "page zero" and fall back rather than move
  /// the reader somewhere arbitrary.
  int? pageForSpeechOffset(int chapterIndex, int speechOffset) {
    final map = _chapterSpeechMaps[chapterIndex];
    if (map == null) return null;
    return pageForChar(chapterIndex, map.renderCharFor(speechOffset));
  }

  /// The speech offset corresponding to [charOffset] in [chapterIndex].
  ///
  /// The inverse of [pageForSpeechOffset], used to work out which spoken text
  /// is currently on screen.
  int? speechOffsetForChar(int chapterIndex, int charOffset) =>
      _chapterSpeechMaps[chapterIndex]?.speechCharFor(charOffset);

  /// Whether the mapping for [speechOffset] is exact rather than interpolated.
  ///
  /// False where the spoken and rendered text genuinely differ, such as inside
  /// a ruby annotation. Meaningless when no map exists, so callers should
  /// consult [speechMapFor] first.
  bool isSpeechOffsetExact(int chapterIndex, int speechOffset) =>
      _chapterSpeechMaps[chapterIndex]?.isExact(speechOffset) ?? false;

  /// The global page containing [speechOffset] within [chapterIndex].
  ///
  /// Null when no correspondence is available, so a caller can tell "not
  /// known yet" from page zero.
  int? globalPageForSpeechOffset(int chapterIndex, int speechOffset) {
    final page = pageForSpeechOffset(chapterIndex, speechOffset);
    if (page == null) return null;
    return getGlobalPageForChapter(chapterIndex) + page;
  }

  /// Bounding boxes covering the speech range `[start, end)` of [chapterIndex].
  ///
  /// Empty when no correspondence is available, so a caller painting a
  /// highlight simply paints nothing rather than guessing at a position.
  ///
  /// When the speech-to-render mapping collapses start and end onto the same
  /// render position — a predictable outcome inside a fuzzy span, and the
  /// common failure mode after many chunks where accumulated interpolation
  /// compresses a sentence to a single point — the result would be an empty
  /// range and therefore no rect. The fix is to expand the render window by
  /// at least one character in that case so that [rectsForCharRange] has
  /// something to intersect. One character is enough: spans are per-fragment
  /// (never sub-character), so any span overlapping the position is returned,
  /// and the returned rect is the correct line box for the spoken sentence.
  List<Rect> rectsForSpeechRange(int chapterIndex, int start, int end) {
    if (end <= start) return const [];
    final map = _chapterSpeechMaps[chapterIndex];
    if (map == null) return const [];
    var renderStart = map.renderCharFor(start);
    var renderEnd = map.renderCharFor(end);
    // Collapsed range: the fuzzy span mapped both endpoints to the same render
    // position. Widen by one so the char-range scan finds the enclosing span.
    if (renderEnd <= renderStart) renderEnd = renderStart + 1;
    return rectsForCharRange(chapterIndex, renderStart, renderEnd);
  }

  static bool _lineBoundsEqual(
    List<({double top, double bottom})>? a,
    List<({double top, double bottom})>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].top != b[i].top || a[i].bottom != b[i].bottom) return false;
    }
    return true;
  }

  void setCurrentGlobalPage(int globalPage) {
    final coordinate = coordinateFromGlobalPage(globalPage);
    _currentAnchor = createAnchor(coordinate);
    _emit();
  }

  void setCurrentAnchor(ReadingAnchor anchor) {
    _currentAnchor = anchor;
    _emit();
  }

  PageCoordinate coordinateFromGlobalPage(int globalPage) {
    var remaining = globalPage;
    for (var chapter = 0; chapter < _chapterCount; chapter++) {
      final pages = _chapterPageCounts[chapter] ?? 1;
      if (remaining < pages) {
        return PageCoordinate(
          chapterIndex: chapter,
          pageInChapter: remaining,
          totalPagesInChapter: pages,
          globalPage: globalPage,
        );
      }
      remaining -= pages;
    }
    final lastChapter = math.max(0, _chapterCount - 1);
    final lastPages = _chapterPageCounts[lastChapter] ?? 1;
    return PageCoordinate(
      chapterIndex: lastChapter,
      pageInChapter: lastPages - 1,
      totalPagesInChapter: lastPages,
      globalPage: math.max(0, _totalPages - 1),
    );
  }

  int globalPageFromCoordinate(PageCoordinate coordinate) {
    var global = 0;
    for (var chapter = 0; chapter < coordinate.chapterIndex; chapter++) {
      final pages = _chapterPageCounts[chapter] ?? 1;
      global += pages;
    }
    return global + coordinate.pageInChapter;
  }

  int getGlobalPageForChapter(int chapterIndex) {
    final clamped = chapterIndex
        .clamp(0, math.max(0, _chapterCount - 1))
        .toInt();
    return globalPageFromCoordinate(
      PageCoordinate(
        chapterIndex: clamped,
        pageInChapter: 0,
        totalPagesInChapter: _chapterPageCounts[clamped] ?? 1,
        globalPage: 0,
      ),
    );
  }

  List<double> getChapterPageOffsets(int chapterIndex) {
    final cached = _chapterOffsets[chapterIndex];
    if (cached != null) return cached;
    return const [0.0];
  }

  double? getChapterHeight(int chapterIndex) => _chapterHeights[chapterIndex];

  ReadingAnchor createAnchor(PageCoordinate coordinate) => ReadingAnchor(
    chapterIndex: coordinate.chapterIndex,
    progressionInChapter: coordinate.progressionInChapter,
  );

  double? offsetForAnchor(ReadingAnchor anchor) {
    final chapter = anchor.chapterIndex.clamp(
      0,
      math.max(0, _chapterCount - 1),
    );
    final height = _chapterHeights[chapter];
    if (height == null) return null;
    var offset = 0.0;
    for (var i = 0; i < chapter; i++) {
      offset += _chapterHeights[i] ?? 0.0;
    }
    return offset + anchor.progressionInChapter * height;
  }

  ReadingAnchor anchorForOffset(int chapterIndex, double offsetInChapter) {
    final chapter = chapterIndex
        .clamp(0, math.max(0, _chapterCount - 1))
        .toInt();
    final height = _chapterHeights[chapter];
    final progression = (height == null || height <= 0)
        ? 0.0
        : (offsetInChapter / height).clamp(0.0, 1.0);
    return ReadingAnchor(
      chapterIndex: chapter,
      progressionInChapter: progression,
    );
  }

  PageCoordinate restoreFromAnchor(ReadingAnchor anchor) {
    final chapter = math.min(
      anchor.chapterIndex,
      math.max(0, _chapterCount - 1),
    );
    final pages = _chapterPageCounts[chapter] ?? 1;
    final page = math.min(
      (anchor.progressionInChapter * (pages - 1)).round(),
      pages - 1,
    );
    return PageCoordinate(
      chapterIndex: chapter,
      pageInChapter: page,
      totalPagesInChapter: pages,
      globalPage: globalPageFromCoordinate(
        PageCoordinate(
          chapterIndex: chapter,
          pageInChapter: page,
          totalPagesInChapter: pages,
          globalPage: 0,
        ),
      ),
    );
  }

  /// Invalidates measurements that depend on font/layout metrics after a
  /// reader-preference change. Cached [contentHeight] values are retained for
  /// continuity so page counts don't collapse; chapters re-measure on their
  /// next mount (each [ReflowableVirtualPage] re-registers after a prefs
  /// change), at which point offsets/counts for that chapter are recomputed.
  void invalidate() {
    _chapterOffsets.clear();
    _chapterPageCounts.clear();
    _chapterLineBounds.clear();
    // Layouts embed stale font metrics, so their character-to-page mapping is
    // no longer trustworthy until the chapter re-measures.
    _chapterLayouts.clear();
    _chapterSpeechMaps.clear();
    _chapterSpeechTexts.clear();
    _recomputeAll();
    _emit();
  }

  void reset() {
    _chapterCount = 0;
    _viewportHeight = 0.0;
    _chapterHeights.clear();
    _chapterPageCounts.clear();
    _chapterOffsets.clear();
    _chapterLineBounds.clear();
    _chapterLayouts.clear();
    _chapterSpeechMaps.clear();
    _chapterSpeechTexts.clear();
    _currentAnchor = const ReadingAnchor(
      chapterIndex: 0,
      progressionInChapter: 0.0,
    );
    _totalPages = 0;
    _emit();
  }

  void dispose() {
    _chapterHeights.clear();
    _chapterPageCounts.clear();
    _chapterOffsets.clear();
    _chapterLineBounds.clear();
    _chapterLayouts.clear();
    _chapterSpeechMaps.clear();
    _chapterSpeechTexts.clear();
    _stateSubject.close();
  }

  void _recomputeChapter(int chapterIndex) {
    final height = _chapterHeights[chapterIndex];
    if (height == null) return;
    final offsets = _slicer.computePageOffsets(
      contentHeight: height,
      viewportHeight: _viewportHeight,
      lineBounds: _chapterLineBounds[chapterIndex],
    );
    _chapterOffsets[chapterIndex] = offsets;
    _chapterPageCounts[chapterIndex] = offsets.length;
  }

  void _recomputeAll() {
    for (var chapter = 0; chapter < _chapterCount; chapter++) {
      _recomputeChapter(chapter);
    }
    _recomputeTotalPages();
  }

  void _recomputeTotalPages() {
    var total = 0;
    for (var chapter = 0; chapter < _chapterCount; chapter++) {
      total += _chapterPageCounts[chapter] ?? 1;
    }
    _totalPages = total;
  }

  void _emit() {
    final coordinate = restoreFromAnchor(_currentAnchor);
    _stateSubject.add(
      PaginationState(
        chapterIndex: coordinate.chapterIndex,
        pageInChapter: coordinate.pageInChapter,
        totalPagesInChapter: coordinate.totalPagesInChapter,
        globalPage: coordinate.globalPage,
        totalPages: _totalPages,
        viewportHeight: _viewportHeight,
        chapterHeights: Map.unmodifiable(_chapterHeights),
        chapterPageCounts: Map.unmodifiable(_chapterPageCounts),
      ),
    );
  }
}
