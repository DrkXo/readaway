part of 'reader_bloc.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(false) bool loading,
    Failure? failure,
    String? error,
    String? fileName,
    @Default(false) bool isReflowable,
    @Default(0) int pageCount,
    @Default(0) int currentPage,
    List<String?>? pageHtmls,
    List<List<ReaderLink>?>? pageLinks,
    List<ui.Image?>? pageImages,
    @Default(<int>{}) Set<int> loadingPages,
    List<OutlineItem>? outline,
    String? bookTitle,
    String? author,
    String? documentPath,
    UiFeedback? transientFeedback,
    @Default(false) bool ttsActive,
    int? ttsCurrentPage,
  }) = _ReaderState;

  const ReaderState._();

  bool get hasDocument => pageHtmls != null || pageImages != null;

  /// Whether the reader's viewport is currently looking at the page being read aloud by TTS.
  bool get isViewingTtsPage =>
      ttsActive && ttsCurrentPage != null && currentPage == ttsCurrentPage;

  /// Whether the user has navigated away from the active TTS playback page and can jump back to it.
  bool get canJumpToTtsPage =>
      ttsActive && ttsCurrentPage != null && currentPage != ttsCurrentPage;
}
