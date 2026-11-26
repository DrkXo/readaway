part of 'translation_bloc.dart';

@freezed
abstract class TranslationEvent with _$TranslationEvent {
  const factory TranslationEvent.translateSelection({
    required String text,
    required String sourceLang,
    required String targetLang,
    required String engineId,
    TranslationContext? context,
  }) = _TranslateSelection;

  const factory TranslationEvent.translateChapter({
    required String bookHash,
    required int chapterIndex,
    required List<String> paragraphs,
    required String sourceLang,
    required String targetLang,
    required String engineId,
    TranslationContext? context,
  }) = _TranslateChapter;

  const factory TranslationEvent.clearSelection() = _ClearSelection;
  const factory TranslationEvent.cancelOngoing() = _CancelOngoing;
}
