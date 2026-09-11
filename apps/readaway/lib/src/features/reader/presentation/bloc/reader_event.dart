part of 'reader_bloc.dart';

@freezed
abstract class ReaderEvent with _$ReaderEvent {
  const factory ReaderEvent.openDocument({
    required String path,
    String? fileName,
    @Default(ReaderEngineMode.customFlow) ReaderEngineMode engineMode,
  }) = _OpenDocument;
  const factory ReaderEvent.engineModeChanged({
    required ReaderEngineMode newMode,
  }) = _EngineModeChanged;
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
}
