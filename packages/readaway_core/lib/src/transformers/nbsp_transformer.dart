import '../models/models.dart';
import 'text_transformer.dart';

/// Glues hanging prepositions, conjunctions, and short words to the next word
/// using non-breaking spaces (`\u00A0`), eliminating typographic orphans.
class NbspTransformer implements TextTransformer {
  const NbspTransformer();

  @override
  String get name => 'nbsp';

  Map<String, _NbspLanguageConfig> get _languages => {
    'ru': const _NbspLanguageConfig(
      script: 'Cyrillic',
      shortWords: [
        'без',
        'для',
        'близ',
        'под',
        'над',
        'про',
        'при',
        'ради',
        'сквозь',
        'среди',
        'через',
        'около',
        'перед',
        'после',
        'между',
        'кроме',
        'вокруг',
        'против',
        'вместо',
        'внутри',
        'возле',
        'или',
        'либо',
        'ибо',
        'если',
        'едва',
        'дабы',
        'чтобы',
        'чтоб',
        'хотя',
        'пока',
        'зато',
        'тоже',
        'также',
        'итак',
        'как',
        'что',
        'чем',
        'так',
        'даже',
        'лишь',
        'ведь',
        'вот',
        'вон',
        'уже',
        'хоть',
        'разве',
        'только',
        'именно',
        'неужели',
      ],
    ),
    'en': const _NbspLanguageConfig(
      script: 'Latin',
      shortWords: ['the', 'and', 'for', 'but', 'nor', 'out', 'off', 'via'],
    ),
  };

  RegExp get _textOrSkipPattern => RegExp(
    r'<(style|script)\b[^>]*>[\s\S]*?<\/\1>|>([^<]+)<',
    caseSensitive: false,
  );

  @override
  String transform(TransformContext context) {
    final langCode = _normalizeLangCode(context.language);
    final config = _languages[langCode];
    if (config == null) return context.content;

    final regex = _buildGlueRegex(config);

    if (context.content.contains('<') && context.content.contains('>')) {
      return context.content.replaceAllMapped(_textOrSkipPattern, (match) {
        final text = match.group(2);
        if (text == null) return match.group(0)!;
        return '>${_glueShortWords(text, regex)}<';
      });
    }

    return _glueShortWords(context.content, regex);
  }

  RegExp _buildGlueRegex(_NbspLanguageConfig config) {
    final words = config.shortWords.join('|');
    return RegExp(
      r'(^|[^\p{L}])(' +
          words +
          r'|\p{Script=' +
          config.script +
          r'}{1,2})\u0020(?=[\p{Script=' +
          config.script +
          r'}\p{N}])',
      caseSensitive: false,
      unicode: true,
    );
  }

  String _glueShortWords(String text, RegExp regex) {
    if (!text.contains(' ')) return text;
    var result = text;
    String prev;
    do {
      prev = result;
      result = result.replaceAllMapped(regex, (m) {
        return '${m[1]}${m[2]}\u00A0';
      });
    } while (result != prev);
    return result;
  }

  String _normalizeLangCode(String? language) {
    if (language == null || language.isEmpty) return 'en';
    final clean = language.trim().toLowerCase();
    final dash = clean.indexOf('-');
    if (dash != -1) return clean.substring(0, dash);
    final underscore = clean.indexOf('_');
    if (underscore != -1) return clean.substring(0, underscore);
    return clean;
  }
}

class _NbspLanguageConfig {
  final String script;
  final List<String> shortWords;

  const _NbspLanguageConfig({required this.script, required this.shortWords});
}
