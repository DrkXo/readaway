part of 'reader_bloc.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(false) bool loading,
    String? error,
    String? fileName,
    @Default(0) int pageCount,
    @Default(0) int currentPage,
    List<String?>? htmlPages,
    @Default(<int>{}) Set<int> loadingPages,
  }) = _ReaderState;
}
