part of 'reader_tts_bloc.dart';

@freezed
abstract class ReaderTtsState with _$ReaderTtsState {
  const factory ReaderTtsState({
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
    /// Kept apart from reader's current page so scrolling away mid-chunk
    /// is not undone until the speech target moves.
    int? ttsTargetVirtualPage,
    UiFeedback? transientFeedback,
  }) = _ReaderTtsState;

  const ReaderTtsState._();

  /// Whether the reader's viewport is currently looking at the page being read aloud by TTS.
  bool isViewingTtsPage(int currentPage) =>
      ttsActive && ttsCurrentPage != null && currentPage == ttsCurrentPage;

  /// Global page the spoken text is on, or null before it has been placed.
  int? get ttsFollowPage => ttsTargetVirtualPage;

  /// Page number shown on the "back to audio" affordance, one-based.
  int? get ttsPageLabel {
    final page = ttsTargetVirtualPage ?? ttsCurrentPage;
    return page == null ? null : page + 1;
  }

  /// Whether the user has navigated away from the text being read aloud and can
  /// jump back to it.
  bool canJumpToTtsPage({
    required int currentPage,
    int? currentVirtualPage,
  }) {
    if (!ttsActive || ttsCurrentPage == null) return false;
    final follow = ttsTargetVirtualPage;
    if (follow == null) return currentPage != ttsCurrentPage;
    return (currentVirtualPage ?? currentPage) != follow;
  }

  /// Whether there is a spoken range precise enough to highlight.
  bool get hasTtsHighlight => ttsActive && ttsSpeechRange != null;

  /// The chapter the spoken text belongs to, or null when not reading aloud.
  int? get ttsChapterIndex => ttsActive ? ttsCurrentPage : null;
}
