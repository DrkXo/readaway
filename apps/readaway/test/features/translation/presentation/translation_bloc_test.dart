import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/translation/domain/entity/translation_models.dart';
import 'package:readaway/src/features/translation/domain/repositories/translation_cache_repository.dart';
import 'package:readaway/src/features/translation/domain/repositories/translation_engine.dart';
import 'package:readaway/src/features/translation/domain/services/translation_engine_registry.dart';
import 'package:readaway/src/features/translation/presentation/bloc/translation_bloc.dart';

class _FakeEngine implements TranslationEngine {
  @override
  String get id => 'fake';

  @override
  String get displayName => 'Fake Engine';

  @override
  bool get preservesMarkup => true;

  @override
  bool get supportsStreaming => false;

  @override
  bool get requiresApiKey => false;

  @override
  bool get isLocal => false;

  @override
  int get maxConcurrentRequests => 2;

  @override
  Future<String> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
    dynamic context,
    dynamic cancelToken,
  }) async {
    return 'Translated: $text';
  }

  @override
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String sourceLang,
    required String targetLang,
    dynamic context,
    dynamic cancelToken,
  }) async {
    return texts.map((t) => 'Translated: $t').toList();
  }

  @override
  Stream<String> translateStream({
    required String text,
    required String sourceLang,
    required String targetLang,
    dynamic context,
    dynamic cancelToken,
  }) async* {
    yield 'Translated: $text';
  }
}

class _FakeCacheRepository implements TranslationCacheRepository {
  final Map<String, TranslationResult> _cache = {};

  @override
  String buildKey({
    required String engineId,
    required String sourceLang,
    required String targetLang,
    required String text,
  }) {
    return '$engineId:$sourceLang:$targetLang:$text';
  }

  @override
  Future<TranslationResult?> get(String key) async => _cache[key];

  @override
  Future<void> put(
    TranslationResult result, {
    String? bookHash,
    int? chapterIndex,
  }) async {
    final key = buildKey(
      engineId: result.engineId,
      sourceLang: result.sourceLang,
      targetLang: result.targetLang,
      text: result.originalText,
    );
    _cache[key] = result;
  }

  @override
  Future<void> putBatch(
    List<TranslationResult> results, {
    String? bookHash,
    int? chapterIndex,
  }) async {
    for (final r in results) {
      await put(r, bookHash: bookHash, chapterIndex: chapterIndex);
    }
  }

  @override
  Future<Map<String, String>> getChapterTranslations({
    required String bookHash,
    required int chapterIndex,
    required String targetLang,
  }) async {
    return {};
  }

  @override
  Future<void> clearAll() async => _cache.clear();
}

class _FakeRegistry implements TranslationEngineRegistry {
  final _engine = _FakeEngine();

  @override
  TranslationEngine getEngine(String id) => _engine;

  @override
  List<TranslationEngine> get availableEngines => [_engine];

  @override
  void configureDeepL(String apiKey) {}

  @override
  Future<void> loadCustomEngines() async {}

  @override
  void registerCustomEngine(dynamic config) {}
}

void main() {
  group('TranslationBloc', () {
    late _FakeRegistry registry;
    late _FakeCacheRepository cacheRepo;

    setUp(() {
      registry = _FakeRegistry();
      cacheRepo = _FakeCacheRepository();
    });

    blocTest<TranslationBloc, TranslationState>(
      'emits translating then translated on translateSelection',
      build: () => TranslationBloc(
        engineRegistry: registry,
        cacheRepository: cacheRepo,
      ),
      act: (bloc) => bloc.add(
        const TranslationEvent.translateSelection(
          text: 'Hello world',
          sourceLang: 'en',
          targetLang: 'es',
          engineId: 'fake',
        ),
      ),
      expect: () => [
        const TranslationState(
          isTranslatingSelection: true,
          selectedOriginal: 'Hello world',
          selectedSourceLang: 'en',
          selectedTargetLang: 'es',
          selectedEngineId: 'fake',
        ),
        const TranslationState(
          isTranslatingSelection: false,
          selectedOriginal: 'Hello world',
          selectedTranslation: 'Translated: Hello world',
          selectedSourceLang: 'en',
          selectedTargetLang: 'es',
          selectedEngineId: 'fake',
        ),
      ],
    );

    blocTest<TranslationBloc, TranslationState>(
      'returns immediately from cache on repeat translateSelection',
      build: () => TranslationBloc(
        engineRegistry: registry,
        cacheRepository: cacheRepo,
      ),
      seed: () => const TranslationState(),
      setUp: () async {
        await cacheRepo.put(
          const TranslationResult(
            originalText: 'Cached phrase',
            translatedText: 'Frase en caché',
            sourceLang: 'en',
            targetLang: 'es',
            engineId: 'fake',
          ),
        );
      },
      act: (bloc) => bloc.add(
        const TranslationEvent.translateSelection(
          text: 'Cached phrase',
          sourceLang: 'en',
          targetLang: 'es',
          engineId: 'fake',
        ),
      ),
      expect: () => [
        const TranslationState(
          isTranslatingSelection: true,
          selectedOriginal: 'Cached phrase',
          selectedSourceLang: 'en',
          selectedTargetLang: 'es',
          selectedEngineId: 'fake',
        ),
        const TranslationState(
          isTranslatingSelection: false,
          selectedOriginal: 'Cached phrase',
          selectedTranslation: 'Frase en caché',
          selectedSourceLang: 'en',
          selectedTargetLang: 'es',
          selectedEngineId: 'fake',
        ),
      ],
    );
  });
}
