part of 'translation_bloc.dart';

@freezed
abstract class TranslationState with _$TranslationState {
  const factory TranslationState({
    @Default(false) bool isTranslatingSelection,
    String? selectedOriginal,
    String? selectedTranslation,
    @Default('auto') String selectedSourceLang,
    @Default('en') String selectedTargetLang,
    @Default('google') String selectedEngineId,
    String? selectionError,
    @Default(false) bool isTranslatingChapter,
    @Default(0.0) double chapterProgress,
    @Default(<String, String>{}) Map<String, String> chapterTranslations,
    String? chapterError,
  }) = _TranslationState;

  const TranslationState._();

  bool get hasSelectionTranslation =>
      selectedTranslation != null && selectedTranslation!.isNotEmpty;
}
