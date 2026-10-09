part of 'reader_tts_bloc.dart';

@freezed
abstract class ReaderTtsEvent with _$ReaderTtsEvent {
  const factory ReaderTtsEvent.start({
    required String documentPath,
    required int pageIndex,
    required int pageCount,
    String? fileName,
    String? bookTitle,
    String? author,
    required bool isReflowable,
    int? currentVirtualPage,
  }) = _TtsStart;

  const factory ReaderTtsEvent.close() = _TtsClose;
  const factory ReaderTtsEvent.consumeFeedback() = _ConsumeFeedback;
  const factory ReaderTtsEvent.errorOccurred(String message) =
      _TtsErrorOccurred;
  const factory ReaderTtsEvent.pageAdvanced({required int pageIndex}) =
      _TtsPageAdvanced;

  /// The speech engine began reading a new chunk.
  ///
  /// [startOffset] and [endOffset] index the chapter's speech text, the same
  /// space the pagination coordinator holds a correspondence for.
  const factory ReaderTtsEvent.chunkAdvanced({
    required int chapterIndex,
    required int startOffset,
    required int endOffset,
  }) = _TtsChunkAdvanced;

  const factory ReaderTtsEvent.clearFollowTarget() = _ClearFollowTarget;
  const factory ReaderTtsEvent.setSleepTimer(Duration duration) =
      _SetSleepTimer;
  const factory ReaderTtsEvent.sleepTimerFired() = _TtsSleepTimerFired;
  const factory ReaderTtsEvent.sleepTimerTick() = _TtsSleepTimerTick;
}
