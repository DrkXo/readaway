import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/translation/data/engines/deepl_translate_engine.dart';
import 'package:readaway/src/features/translation/data/engines/google_translate_engine.dart';
import 'package:readaway/src/features/translation/data/engines/openai_compatible_engine.dart';
import 'package:readaway/src/features/translation/domain/entity/custom_translator_config.dart';

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

void main() {
  group('GoogleTranslateEngine', () {
    test('parses nested segment JSON and preserves punctuation', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeDioAdapter((options) async {
        expect(options.queryParameters['client'], equals('gtx'));
        expect(options.queryParameters['sl'], equals('es'));
        expect(options.queryParameters['tl'], equals('en'));

        // Standard Google translate_a/single payload
        final json =
            '[[["Hello world. ","Hola mundo. ",null,null,1]],null,"es"]';
        return ResponseBody.fromString(
          json,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final engine = GoogleTranslateEngine(dio: dio);
      final result = await engine.translateText(
        text: 'Hola mundo.',
        sourceLang: 'es',
        targetLang: 'en',
      );

      expect(result, equals('Hello world.'));
    });
  });

  group('DeepLTranslateEngine', () {
    test('sends batched request and parses translations array', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeDioAdapter((options) async {
        expect(
          options.headers['Authorization'],
          equals('DeepL-Auth-Key test-key:fx'),
        );
        expect(
          options.uri.toString(),
          equals('https://api-free.deepl.com/v2/translate'),
        );

        final json = '{"translations":[{"text":"Hello"},{"text":"World"}]}';
        return ResponseBody.fromString(
          json,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final engine = DeepLTranslateEngine(apiKey: 'test-key:fx', dio: dio);
      final results = await engine.translateBatch(
        texts: ['Hola', 'Mundo'],
        sourceLang: 'es',
        targetLang: 'en',
      );

      expect(results, equals(['Hello', 'World']));
    });
  });

  group('OpenAICompatibleEngine', () {
    test('strips reasoning <think> tags from model response', () {
      final output =
          '<think>\nI am thinking about translating this.\n</think>\n\nTranslated text here.';
      expect(
        OpenAICompatibleEngine.stripReasoning(output),
        equals('Translated text here.'),
      );
    });

    test('parses numbered blocks batch', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeDioAdapter((options) async {
        final json = '''{
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "[1] First block translated\\n\\n[2] Second block translated"
              }
            }
          ]
        }''';
        return ResponseBody.fromString(
          json,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      const config = CustomTranslatorConfig(
        id: 'test',
        name: 'Test LLM',
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-4o',
      );
      final engine = OpenAICompatibleEngine(config: config, dio: dio);
      final results = await engine.translateBatch(
        texts: ['First block', 'Second block'],
        sourceLang: 'en',
        targetLang: 'es',
      );

      expect(
        results,
        equals(['First block translated', 'Second block translated']),
      );
    });
  });
}
