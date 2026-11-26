import 'dart:async';

import 'package:dio/dio.dart';

import '../../domain/entity/translation_context.dart';
import '../../domain/repositories/translation_engine.dart';
import '../../domain/services/translation_polisher.dart';

/// Free reverse-engineered Google Translate engine with HTML markup preservation
/// and client-side concurrency rate-limiting.
class GoogleTranslateEngine implements TranslationEngine {
  GoogleTranslateEngine({
    Dio? dio,
    this.polisher = const TranslationPolisher(),
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final TranslationPolisher polisher;

  static const String _endpoint =
      'https://translate.googleapis.com/translate_a/single';

  @override
  String get id => 'google';

  @override
  String get displayName => 'Google Translate';

  @override
  bool get preservesMarkup => true;

  @override
  bool get supportsStreaming => false;

  @override
  bool get requiresApiKey => false;

  @override
  bool get isLocal => false;

  @override
  int get maxConcurrentRequests => 4;

  int _activeRequests = 0;
  final List<Completer<void>> _queue = [];

  Future<void> _acquireSlot() async {
    if (_activeRequests < maxConcurrentRequests) {
      _activeRequests++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void _releaseSlot() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.complete();
    } else {
      _activeRequests--;
    }
  }

  String _normalizeLang(String lang) {
    if (lang.isEmpty || lang.toLowerCase() == 'auto') return 'auto';
    final parts = lang.split(RegExp(r'[-_]'));
    if (parts.length > 1 && parts[0].toLowerCase() == 'zh') {
      return lang.toLowerCase().contains('hant') ||
              lang.toLowerCase().contains('tw')
          ? 'zh-TW'
          : 'zh-CN';
    }
    return parts[0].toLowerCase();
  }

  @override
  Future<String> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    await _acquireSlot();
    try {
      final response = await _dio.get<dynamic>(
        _endpoint,
        queryParameters: {
          'client': 'gtx',
          'dt': 't',
          'sl': _normalizeLang(sourceLang),
          'tl': _normalizeLang(targetLang),
          'q': text,
        },
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is List && data.isNotEmpty && data[0] is List) {
        final segments = data[0] as List;
        final buffer = StringBuffer();
        for (final segment in segments) {
          if (segment is List && segment.isNotEmpty && segment[0] != null) {
            buffer.write(segment[0].toString());
          }
        }
        final result = buffer.toString();
        return result.isNotEmpty ? polisher.polish(result, targetLang) : text;
      }
      return text;
    } finally {
      _releaseSlot();
    }
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

    final futures = texts.map((t) async {
      if (t.trim().isEmpty) return t;
      return translateText(
        text: t,
        sourceLang: sourceLang,
        targetLang: targetLang,
        context: context,
        cancelToken: cancelToken,
      );
    });

    return Future.wait(futures);
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
