import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/translation_context.dart';
import '../../domain/entity/translation_models.dart';
import '../../domain/repositories/translation_cache_repository.dart';
import '../../domain/services/translation_engine_registry.dart';

part 'translation_bloc.freezed.dart';
part 'translation_event.dart';
part 'translation_state.dart';

@injectable
class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  TranslationBloc({
    required this.engineRegistry,
    required this.cacheRepository,
  }) : super(const TranslationState()) {
    on<_TranslateSelection>(_onTranslateSelection);
    on<_TranslateChapter>(_onTranslateChapter);
    on<_ClearSelection>(_onClearSelection);
    on<_CancelOngoing>(_onCancelOngoing);
  }

  final TranslationEngineRegistry engineRegistry;
  final TranslationCacheRepository cacheRepository;

  CancelToken? _selectionCancelToken;
  CancelToken? _chapterCancelToken;

  Future<void> _onTranslateSelection(
    _TranslateSelection event,
    Emitter<TranslationState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;

    _selectionCancelToken?.cancel();
    _selectionCancelToken = CancelToken();

    emit(
      state.copyWith(
        isTranslatingSelection: true,
        selectedOriginal: text,
        selectedSourceLang: event.sourceLang,
        selectedTargetLang: event.targetLang,
        selectedEngineId: event.engineId,
        selectionError: null,
      ),
    );

    // 1. Check cache first
    final key = cacheRepository.buildKey(
      engineId: event.engineId,
      sourceLang: event.sourceLang,
      targetLang: event.targetLang,
      text: text,
    );

    final cached = await cacheRepository.get(key);
    if (cached != null) {
      emit(
        state.copyWith(
          isTranslatingSelection: false,
          selectedTranslation: cached.translatedText,
        ),
      );
      return;
    }

    // 2. Fetch from engine
    try {
      final engine = engineRegistry.getEngine(event.engineId);
      final translated = await engine.translateText(
        text: text,
        sourceLang: event.sourceLang,
        targetLang: event.targetLang,
        context: event.context,
        cancelToken: _selectionCancelToken,
      );

      final result = TranslationResult(
        originalText: text,
        translatedText: translated,
        sourceLang: event.sourceLang,
        targetLang: event.targetLang,
        engineId: event.engineId,
      );

      await cacheRepository.put(result);

      emit(
        state.copyWith(
          isTranslatingSelection: false,
          selectedTranslation: translated,
        ),
      );
    } catch (e) {
      if (_selectionCancelToken?.isCancelled == true) return;
      emit(
        state.copyWith(
          isTranslatingSelection: false,
          selectionError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTranslateChapter(
    _TranslateChapter event,
    Emitter<TranslationState> emit,
  ) async {
    _chapterCancelToken?.cancel();
    _chapterCancelToken = CancelToken();

    emit(
      state.copyWith(
        isTranslatingChapter: true,
        chapterProgress: 0.0,
        chapterError: null,
      ),
    );

    try {
      // 1. Read existing cached translations for this chapter
      final cached = await cacheRepository.getChapterTranslations(
        bookHash: event.bookHash,
        chapterIndex: event.chapterIndex,
        targetLang: event.targetLang,
      );

      final currentMap = Map<String, String>.from(cached);
      final uncachedTexts = <String>[];

      for (final p in event.paragraphs) {
        final trimmed = p.trim();
        if (trimmed.isNotEmpty && !currentMap.containsKey(trimmed)) {
          uncachedTexts.add(trimmed);
        }
      }

      if (uncachedTexts.isEmpty) {
        emit(
          state.copyWith(
            isTranslatingChapter: false,
            chapterProgress: 1.0,
            chapterTranslations: currentMap,
          ),
        );
        return;
      }

      final total = event.paragraphs.length;
      final cachedCount = total - uncachedTexts.length;
      emit(
        state.copyWith(
          chapterProgress: total > 0 ? (cachedCount / total) : 0.0,
          chapterTranslations: currentMap,
        ),
      );

      // 2. Translate uncached paragraphs in batches
      final engine = engineRegistry.getEngine(event.engineId);
      const batchSize = 6;
      final newResults = <TranslationResult>[];

      for (var i = 0; i < uncachedTexts.length; i += batchSize) {
        if (_chapterCancelToken?.isCancelled == true) return;

        final end = (i + batchSize < uncachedTexts.length)
            ? i + batchSize
            : uncachedTexts.length;
        final slice = uncachedTexts.sublist(i, end);

        final translatedSlice = await engine.translateBatch(
          texts: slice,
          sourceLang: event.sourceLang,
          targetLang: event.targetLang,
          context: event.context,
          cancelToken: _chapterCancelToken,
        );

        for (var j = 0; j < slice.length; j++) {
          final orig = slice[j];
          final trans = j < translatedSlice.length ? translatedSlice[j] : orig;
          currentMap[orig] = trans;
          newResults.add(
            TranslationResult(
              originalText: orig,
              translatedText: trans,
              sourceLang: event.sourceLang,
              targetLang: event.targetLang,
              engineId: event.engineId,
            ),
          );
        }

        final done = cachedCount + i + slice.length;
        emit(
          state.copyWith(
            chapterProgress: total > 0 ? (done / total).clamp(0.0, 1.0) : 1.0,
            chapterTranslations: Map.unmodifiable(currentMap),
          ),
        );
      }

      // 3. Persist new translations
      await cacheRepository.putBatch(
        newResults,
        bookHash: event.bookHash,
        chapterIndex: event.chapterIndex,
      );

      emit(
        state.copyWith(
          isTranslatingChapter: false,
          chapterProgress: 1.0,
          chapterTranslations: Map.unmodifiable(currentMap),
        ),
      );
    } catch (e) {
      if (_chapterCancelToken?.isCancelled == true) return;
      emit(
        state.copyWith(
          isTranslatingChapter: false,
          chapterError: e.toString(),
        ),
      );
    }
  }

  void _onClearSelection(
    _ClearSelection event,
    Emitter<TranslationState> emit,
  ) {
    _selectionCancelToken?.cancel();
    emit(
      state.copyWith(
        isTranslatingSelection: false,
        selectedOriginal: null,
        selectedTranslation: null,
        selectionError: null,
      ),
    );
  }

  void _onCancelOngoing(_CancelOngoing event, Emitter<TranslationState> emit) {
    _selectionCancelToken?.cancel();
    _chapterCancelToken?.cancel();
    emit(
      state.copyWith(
        isTranslatingSelection: false,
        isTranslatingChapter: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _selectionCancelToken?.cancel();
    _chapterCancelToken?.cancel();
    return super.close();
  }
}
