import 'package:injectable/injectable.dart';

import '../../../../core/services/storage/drift/daos/translation_dao.dart';
import '../../data/engines/deepl_translate_engine.dart';
import '../../data/engines/google_translate_engine.dart';
import '../../data/engines/openai_compatible_engine.dart';
import '../entity/custom_translator_config.dart';
import '../repositories/translation_engine.dart';

@lazySingleton
class TranslationEngineRegistry {
  TranslationEngineRegistry(this._dao) {
    _initDefaultEngines();
  }

  final TranslationDao _dao;
  final Map<String, TranslationEngine> _engines = {};
  String? _deepLApiKey;

  void _initDefaultEngines() {
    _engines['google'] = GoogleTranslateEngine();
    if (_deepLApiKey != null && _deepLApiKey!.isNotEmpty) {
      _engines['deepl'] = DeepLTranslateEngine(apiKey: _deepLApiKey!);
    }
  }

  void configureDeepL(String apiKey) {
    _deepLApiKey = apiKey;
    if (apiKey.isNotEmpty) {
      _engines['deepl'] = DeepLTranslateEngine(apiKey: apiKey);
    } else {
      _engines.remove('deepl');
    }
  }

  Future<void> loadCustomEngines() async {
    final rows = await _dao.getCustomTranslators();
    for (final row in rows) {
      if (row.isEnabled) {
        final config = CustomTranslatorConfig(
          id: row.id,
          name: row.name,
          baseUrl: row.baseUrl,
          apiKey: row.apiKey,
          model: row.model,
          temperature: row.temperature,
          thinkingMode: row.thinkingMode,
          promptTemplate: row.promptTemplate,
          isEnabled: row.isEnabled,
        );
        _engines[row.id] = OpenAICompatibleEngine(config: config);
      } else {
        _engines.remove(row.id);
      }
    }
  }

  void registerCustomEngine(CustomTranslatorConfig config) {
    if (config.isEnabled) {
      _engines[config.id] = OpenAICompatibleEngine(config: config);
    } else {
      _engines.remove(config.id);
    }
  }

  TranslationEngine getEngine(String id) {
    return _engines[id] ?? _engines['google']!;
  }

  List<TranslationEngine> get availableEngines => _engines.values.toList();
}
