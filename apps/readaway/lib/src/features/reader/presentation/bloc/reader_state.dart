part of 'reader_bloc.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(false) bool loading,
    Failure? failure,
    String? error,
    String? fileName,
    @Default(0) int pageCount,
    @Default(0) int currentPage,
    List<String?>? pageHtmls,
    List<List<ReaderLink>?>? pageLinks,
    @Default(<int>{}) Set<int> loadingPages,
    List<OutlineItem>? outline,
    String? bookTitle,
    String? author,
    String? documentPath,
    UiFeedback? transientFeedback,
    @Default(false) bool ttsActive,
    int? ttsCurrentPage,
    Duration? ttsSleepTimerRemaining,

    /// Character range of the speech currently being read, in the speech text
    /// of [ttsCurrentPage]'s chapter.
    ///
    /// Held in speech coordinates rather than rendered ones because that is the
    /// space the TTS engine reports in; the pagination coordinator converts.
    /// Null when nothing is being read, or when the chapter has no usable
    /// character mapping.
    ({int start, int end})? ttsSpeechRange,

    /// Global page the reader should be showing to follow the spoken text.
    ///
    /// Kept apart from [currentVirtualPage], which records where the reader
    /// actually is. Conflating them would scroll the reader back the moment
    /// they looked ahead, and would leave a stale target behind after playback
    /// stopped. Only updated when the target actually moves, so scrolling away
    /// mid-chunk is not undone until the speech does.
    int? ttsTargetVirtualPage,
    int? virtualPageCount,
    int? currentVirtualPage,
    ReadingAnchor? pendingRestoreAnchor,
    @Default(true) bool isReflowable,
    @Default('epub') String format,
    @Default(false) bool requiresPassword,
    @Default(false) bool isInvalidPassword,
  }) = _ReaderState;

  const ReaderState._();

  bool get hasDocument => documentPath != null && pageCount > 0;

  /// Effective page count to display in top bar, bottom scrubber, and page controls.
  int get displayPageCount =>
      (virtualPageCount != null) ? virtualPageCount! : pageCount;

  /// Effective current page to display in top bar, bottom scrubber, and page controls.
  int get displayCurrentPage => currentVirtualPage ?? currentPage;

  /// Whether the reader's viewport is currently looking at the page being read aloud by TTS.
  ///
  /// Only meaningful for documents whose page is the chapter itself; where the
  /// spoken text has been placed on a specific page, [canJumpToTtsPage] is the
  /// answer because the reader can be on the right chapter and the wrong page.
  bool get isViewingTtsPage =>
      ttsActive && ttsCurrentPage != null && currentPage == ttsCurrentPage;

  /// Global page the spoken text is on, or null before it has been placed.
  ///
  /// Null until a chunk resolves to a page, which happens only once the
  /// chapter has been measured. Until then the speech is known to be somewhere
  /// in [ttsCurrentPage] but not where.
  int? get ttsFollowPage => ttsTargetVirtualPage;

  /// Page number shown on the "back to audio" affordance, one-based.
  ///
  /// The placed page where there is one, so the label agrees with the page
  /// indicator, and the chapter otherwise.
  int? get ttsPageLabel {
    final page = ttsTargetVirtualPage ?? ttsCurrentPage;
    return page == null ? null : page + 1;
  }

  /// Whether the user has navigated away from the text being read aloud and can
  /// jump back to it.
  ///
  /// Compares placed pages where the speech has been placed. Falling back to
  /// comparing chapters would report the reader as lost while they sat on the
  /// right chapter and the wrong page, and would be the only option available
  /// for a document with no character mapping, which still needs offering.
  bool get canJumpToTtsPage {
    if (!ttsActive || ttsCurrentPage == null) return false;
    final follow = ttsTargetVirtualPage;
    if (follow == null) return currentPage != ttsCurrentPage;
    return (currentVirtualPage ?? currentPage) != follow;
  }

  /// Whether there is a spoken range precise enough to highlight.
  ///
  /// False while the chapter has no character mapping, which is the case until
  /// the page has been measured, so a highlight is never drawn at a guessed
  /// position.
  bool get hasTtsHighlight => ttsActive && ttsSpeechRange != null;

  /// The chapter the spoken text belongs to, or null when not reading aloud.
  int? get ttsChapterIndex => ttsActive ? ttsCurrentPage : null;
}
