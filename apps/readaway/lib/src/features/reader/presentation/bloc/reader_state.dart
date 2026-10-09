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
}
