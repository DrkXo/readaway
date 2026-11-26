import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/entity/custom_translator_config.dart';
import '../../domain/entity/translation_context.dart';
import '../../domain/repositories/translation_engine.dart';
import '../../domain/services/translation_polisher.dart';

/// Translation engine that interfaces with any OpenAI-compatible `/v1/chat/completions`
/// endpoint (OpenAI, DeepSeek, OpenRouter, Groq, SiliconFlow).
class OpenAICompatibleEngine implements TranslationEngine {
  OpenAICompatibleEngine({
    required this.config,
    Dio? dio,
    this.polisher = const TranslationPolisher(),
  }) : _dio = dio ?? Dio();

  final CustomTranslatorConfig config;
  final Dio _dio;
  final TranslationPolisher polisher;

  @override
  String get id => config.id;

  @override
  String get displayName => config.name;

  @override
  bool get preservesMarkup => false;

  @override
  bool get supportsStreaming => true;

  @override
  bool get requiresApiKey => config.apiKey != null && config.apiKey!.isNotEmpty;

  @override
  bool get isLocal => false;

  @override
  int get maxConcurrentRequests => 3;

  String get _endpoint {
    final base = config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/chat/completions')) return base;
    if (base.endsWith('/v1')) return '$base/chat/completions';
    return '$base/v1/chat/completions';
  }

  /// Removes leading `<think>...</think>` blocks emitted by reasoning models.
  static String stripReasoning(String text) {
    return text.replaceAll(RegExp(r'^\s*<think>[\s\S]*?<\/think>'), '').trim();
  }

  String _renderPrompt({
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
  }) {
    final template = config.promptTemplate?.isNotEmpty == true
        ? config.promptTemplate!
        : CustomTranslatorConfig.defaultPrompt;

    return template
        .replaceAll('{{sourceLang}}', sourceLang)
        .replaceAll('{{targetLang}}', targetLang)
        .replaceAll('{{bookTitle}}', context?.bookTitle ?? '')
        .replaceAll('{{bookAuthor}}', context?.bookAuthor ?? '');
  }

  Map<String, dynamic> _buildThinkingParams() {
    if (config.thinkingMode != 'off') return {};

    final url = config.baseUrl.toLowerCase();
    if (url.contains('openrouter.ai')) {
      return {
        'reasoning': {'effort': 'none'},
      };
    }
    if (url.contains('deepseek.com') ||
        url.contains('bigmodel.cn') ||
        url.contains('volces.com')) {
      return {
        'thinking': {'type': 'disabled'},
      };
    }
    if (url.contains('siliconflow')) {
      return {'enable_thinking': false};
    }

    // Default OpenAI format
    return {'reasoning_effort': 'none'};
  }

  @override
  Future<String> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  }) async {
    final systemPrompt = _renderPrompt(
      sourceLang: sourceLang,
      targetLang: targetLang,
      context: context,
    );

    final payload = {
      'model': config.model,
      'temperature': config.temperature,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content':
              'Translate the following text into $targetLang. Output ONLY the translation without explanations, commentary, or quotes:\n\n$text',
        },
      ],
      ..._buildThinkingParams(),
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (config.apiKey?.isNotEmpty == true)
        'Authorization': 'Bearer ${config.apiKey}',
    };

    final response = await _dio.post<dynamic>(
      _endpoint,
      data: payload,
      options: Options(
        headers: headers,
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 15),
      ),
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is Map &&
        data['choices'] is List &&
        (data['choices'] as List).isNotEmpty) {
      final choice = data['choices'][0];
      if (choice is Map && choice['message'] is Map) {
        final content = choice['message']['content']?.toString() ?? '';
        final stripped = stripReasoning(content);
        return polisher.polish(stripped, targetLang);
      }
    }

    return text;
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
    if (texts.length == 1) {
      final res = await translateText(
        text: texts.first,
        sourceLang: sourceLang,
        targetLang: targetLang,
        context: context,
        cancelToken: cancelToken,
      );
      return [res];
    }

    // Pack into numbered blocks: [1] text1\n\n[2] text2
    final buffer = StringBuffer();
    for (var i = 0; i < texts.length; i++) {
      buffer.writeln('[${i + 1}] ${texts[i]}\n');
    }

    final systemPrompt = _renderPrompt(
      sourceLang: sourceLang,
      targetLang: targetLang,
      context: context,
    );

    final userInstruction =
        "The following text contains ${texts.length} numbered blocks, each starting with a marker line like [n]. "
        "Translate every block and output exactly ${texts.length} blocks in the exact same order, each starting with its original [n] marker line. "
        "Output ONLY the translations, without explanations or notes:\n\n${buffer.toString()}";

    try {
      final payload = {
        'model': config.model,
        'temperature': config.temperature,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userInstruction},
        ],
        ..._buildThinkingParams(),
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (config.apiKey?.isNotEmpty == true)
          'Authorization': 'Bearer ${config.apiKey}',
      };

      final response = await _dio.post<dynamic>(
        _endpoint,
        data: payload,
        options: Options(
          headers: headers,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 15),
        ),
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is Map &&
          data['choices'] is List &&
          (data['choices'] as List).isNotEmpty) {
        final choice = data['choices'][0];
        if (choice is Map && choice['message'] is Map) {
          final content = choice['message']['content']?.toString() ?? '';
          final stripped = stripReasoning(content);

          final parsed = _parseNumberedBlocks(stripped, texts.length);
          if (parsed != null) {
            return polisher.polishBatch(parsed, targetLang);
          }
        }
      }
    } catch (_) {
      // If batch fails or model rejects formatting, fall back to individual translation
    }

    // Fallback: translate individual items
    final futures = texts.map(
      (t) => translateText(
        text: t,
        sourceLang: sourceLang,
        targetLang: targetLang,
        context: context,
        cancelToken: cancelToken,
      ),
    );
    return Future.wait(futures);
  }

  List<String>? _parseNumberedBlocks(String text, int expectedCount) {
    final matches = RegExp(r'\[(\d+)\][ \t]*([\s\S]*?)(?=(?:\[\d+\]|$))')
        .allMatches(text);
    final blocks = <String>[];
    for (final m in matches) {
      blocks.add(m.group(2)?.trim() ?? '');
    }

    return blocks.length == expectedCount ? blocks : null;
  }

  @override
  Stream<String> translateStream({
    required String text,
    required String sourceLang,
    required String targetLang,
    TranslationContext? context,
    CancelToken? cancelToken,
  }) async* {
    final systemPrompt = _renderPrompt(
      sourceLang: sourceLang,
      targetLang: targetLang,
      context: context,
    );

    final payload = {
      'model': config.model,
      'temperature': config.temperature,
      'stream': true,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content':
              'Translate the following text into $targetLang. Output ONLY the translation without explanations or notes:\n\n$text',
        },
      ],
      ..._buildThinkingParams(),
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (config.apiKey?.isNotEmpty == true)
        'Authorization': 'Bearer ${config.apiKey}',
    };

    final response = await _dio.post<ResponseBody>(
      _endpoint,
      data: payload,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 15),
      ),
      cancelToken: cancelToken,
    );

    final stream = response.data?.stream;
    if (stream == null) return;

    final buffer = StringBuffer();
    await for (final line
        in stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        if (jsonStr == '[DONE]') break;
        try {
          final json = jsonDecode(jsonStr);
          if (json is Map &&
              json['choices'] is List &&
              (json['choices'] as List).isNotEmpty) {
            final delta = json['choices'][0]['delta'];
            if (delta is Map && delta['content'] != null) {
              final piece = delta['content'].toString();
              buffer.write(piece);
              yield stripReasoning(buffer.toString());
            }
          }
        } catch (_) {}
      }
    }
  }
}
