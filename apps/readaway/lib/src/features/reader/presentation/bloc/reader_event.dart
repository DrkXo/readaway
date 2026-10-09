part of 'reader_bloc.dart';

@freezed
abstract class ReaderEvent with _$ReaderEvent {
  const factory ReaderEvent.openDocument({
    required String path,
    String? fileName,
    String? password,
  }) = _OpenDocument;
  const factory ReaderEvent.unlockDocument({
    required String password,
  }) = _UnlockDocument;
  const factory ReaderEvent.pageChanged({required int index}) = _PageChanged;
  const factory ReaderEvent.jumpToChapter({
    required int chapterIndex,
    int? virtualPage,
  }) = _JumpToChapter;
  const factory ReaderEvent.loadPage({required int index}) = _LoadPage;
  const factory ReaderEvent.closeDocument() = _CloseDocument;
  const factory ReaderEvent.consumeFeedback() = _ConsumeFeedback;
  const factory ReaderEvent.virtualPageChanged({
    required int globalPage,
    required int totalPages,
    required int chapterIndex,
  }) = _VirtualPageChanged;
  const factory ReaderEvent.clearPendingRestore() = _ClearPendingRestore;
}
