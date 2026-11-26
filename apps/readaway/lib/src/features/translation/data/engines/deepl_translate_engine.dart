import 'dart:async';

import 'package:dio/dio.dart';

import '../../domain/entity/translation_context.dart';
import '../../domain/repositories/translation_engine.dart';
import '../../domain/services/translation_polisher.dart';

/// Official DeepL API engine (Free & Pro).
class DeepLTranslateEngine implements TranslationEngine {
  DeepLTranslateEngine({
    required this.apiKey,
    Dio? dio,
    this.polisher = const TranslationPolisher(),
  }) : _dio = dio ?? Dio();

  final String apiKey;
  final Dio _dio;
  final TranslationPolisher polisher;

  @override
  String get id => 'deepl';

  @override
  String get displayName => 'DeepL';

  @override
  bool get preservesMarkup => false;

  @override
  bool get supportsStreaming => false;

  @override
  bool get requiresApiKey => true;

  @override
  bool get isLocal => false;

  @override
  int get maxConcurrentRequests => 5;

  String get _endpoint {
    if (apiKey.endsWith(':fx')) {
      return 'https://api-free.deepl.com/v2/translate';
    }
    return 'https://api.deepl.com/v2/translate';
  }

  String _toDeepLLang(String lang) {
    final parts = lang.split(RegExp(r'[-_]'));
    final primary = parts[0].toUpperCase();
    if (parts.length > 1) {
      // DeepL requires the script subtag to match its case format (e.g. ZH-HANS, EN-US)
      return '$primary-${parts[1].toUpperCase()}';
    }
    return primary;
  }

  @override
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  }) async {
    if (texts.isEmpty) return [];
    if (apiKey.isEmpty) {
      throw Exception('DeepL API key is required');
    }

    // Filter out non-empty texts to translate in a single batched call
    final target = _toDeepLLang(targetLang);
    final source = sourceLang.toLowerCase() == 'auto'
        ? null
        : _toDeepLLang(sourceLang);

    final payload = {
      'text': texts,
      'target_lang': target,
      'source_lang': ?source,
    };

    final response = await _dio.post<dynamic>(
      _endpoint,
      data: payload,
      options: Options(
        headers: {
          'Authorization': 'DeepL-Auth-Key $apiKey',
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
      ),
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is Map && data['translations'] is List) {
      final list = data['translations'] as List;
      final results = <String>[];
      for (var i = 0; i < texts.length; i++) {
        if (i < list.length && list[i] is Map && list[i]['text'] != null) {
          final translated = list[i]['text'].toString();
          results.add(polisher.polish(translated, targetLang));
        } else {
          results.add(texts[i]);
        }
      }
      return results;
    }

    return texts;
  }

  @override
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

  @override
  Stream<String> translateStream({
    required String text,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  }) async* {
    final result = await translateText(
      text: text,
      sourceLang: sourceLang,
      targetLang: targetLang,
      context: context,
      cancelToken: cancelToken,
    );
    yield result;
  }
}
