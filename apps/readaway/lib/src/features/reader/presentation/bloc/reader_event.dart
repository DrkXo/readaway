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
  const factory ReaderEvent.loadPage({required int index}) = _LoadPage;
  const factory ReaderEvent.closeDocument() = _CloseDocument;
  const factory ReaderEvent.ttsStart() = _TtsStart;
  const factory ReaderEvent.ttsClose() = _TtsClose;
  const factory ReaderEvent.consumeFeedback() = _ConsumeFeedback;
  const factory ReaderEvent.ttsErrorOccurred(String message) =
      _TtsErrorOccurred;
  const factory ReaderEvent.jumpToTtsPage() = _JumpToTtsPage;
  const factory ReaderEvent.ttsPageAdvanced({required int pageIndex}) =
      _TtsPageAdvanced;

  /// The speech engine began reading a new chunk.
  ///
  /// [startOffset] and [endOffset] index the chapter's speech text, the same
  /// space the pagination coordinator holds a correspondence for.
  const factory ReaderEvent.ttsChunkAdvanced({
    required int chapterIndex,
    required int startOffset,
    required int endOffset,
  }) = _TtsChunkAdvanced;
  const factory ReaderEvent.setSleepTimer(Duration duration) = _SetSleepTimer;
  const factory ReaderEvent.ttsSleepTimerFired() = _TtsSleepTimerFired;
  const factory ReaderEvent.ttsSleepTimerTick() = _TtsSleepTimerTick;
  const factory ReaderEvent.virtualPageChanged({
    required int globalPage,
    required int totalPages,
    required int chapterIndex,
  }) = _VirtualPageChanged;
  const factory ReaderEvent.clearPendingRestore() = _ClearPendingRestore;
}
