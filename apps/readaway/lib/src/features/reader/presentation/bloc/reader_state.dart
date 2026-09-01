part of 'reader_bloc.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(false) bool loading,
    String? error,
    String? fileName,
    @Default(false) bool isReflowable,
    @Default(0) int pageCount,
    @Default(0) int currentPage,
    List<String?>? htmlPages,
    List<ui.Image?>? pageImages,
    @Default(<int>{}) Set<int> loadingPages,
    List<OutlineItem>? outline,
    String? bookTitle,
    String? author,
    @Default(false) bool ttsActive,
  }) = _ReaderState;

  const ReaderState._();

  bool get hasDocument => htmlPages != null || pageImages != null;
}
