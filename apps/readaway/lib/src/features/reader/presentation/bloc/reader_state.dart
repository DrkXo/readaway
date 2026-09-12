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
    int? virtualPageCount,
    int? currentVirtualPage,
  }) = _ReaderState;

  const ReaderState._();

  bool get hasDocument => pageHtmls != null;

  /// Effective page count to display in top bar, bottom scrubber, and page controls.
  int get displayPageCount =>
      (virtualPageCount != null) ? virtualPageCount! : pageCount;

  /// Effective current page to display in top bar, bottom scrubber, and page controls.
  int get displayCurrentPage => currentVirtualPage ?? currentPage;

  /// Whether the reader's viewport is currently looking at the page being read aloud by TTS.
  bool get isViewingTtsPage =>
      ttsActive && ttsCurrentPage != null && currentPage == ttsCurrentPage;

  /// Whether the user has navigated away from the active TTS playback page and can jump back to it.
  bool get canJumpToTtsPage =>
      ttsActive && ttsCurrentPage != null && currentPage != ttsCurrentPage;
}
