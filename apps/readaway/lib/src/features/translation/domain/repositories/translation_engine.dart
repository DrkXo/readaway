import 'package:dio/dio.dart';

import '../entity/translation_context.dart';

/// Contract for translation engine implementations (Google, DeepL, OpenAI, etc.).
abstract class TranslationEngine {
  /// Unique machine identifier (e.g. 'google', 'deepl', 'custom:deepseek').
  String get id;

  /// Human-readable label displayed in the UI.
  String get displayName;

  /// Whether the upstream API carries inline HTML tags through translation,
  /// preserving formatting on semantically matching words.
  bool get preservesMarkup;

  /// Whether this engine supports real-time text streaming.
  bool get supportsStreaming;

  /// Whether an API token or key must be provided in Settings.
  bool get requiresApiKey;

  /// Whether this engine runs locally on-device without network calls.
  bool get isLocal;

  /// Maximum recommended concurrent HTTP requests to prevent rate-limiting (429).
  int get maxConcurrentRequests;

  /// Translates a single text string.
  Future<String> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  }) async {
    final results = await translateBatch(
      texts: [text],
      sourceLang: sourceLang,
      targetLang: targetLang,
      context: context,
      cancelToken: cancelToken,
    );
    return results.isNotEmpty ? results.first : text;
  }

  /// Translates a batch of texts.
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  });

  /// Streams token-by-token output for a single text when [supportsStreaming] is true.
  Stream<String> translateStream({
    required String text,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  });
}
