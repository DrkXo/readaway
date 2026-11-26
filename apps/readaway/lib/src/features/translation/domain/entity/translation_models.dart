import 'package:equatable/equatable.dart';

/// Supported presentation modes for reader translation.
enum TranslationMode {
  /// Translation is turned off.
  disabled,

  /// Bilingual interlinear flow: the translated paragraph appears directly below
  /// the source paragraph in an elegant secondary hierarchy.
  bilingualInterlinear,

  /// Pure translated replacement: the text renders in the target language,
  /// with tap/long-press available to peek the original.
  translatedOnly,

  /// Side-by-side spread on wide tablet/desktop viewports: left column shows
  /// original, right column shows translated text.
  sideBySideSpread,
}

/// A translated segment or passage.
class TranslationResult extends Equatable {
  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.engineId,
    this.isCacheHit = false,
  });

  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String engineId;
  final bool isCacheHit;

  @override
  List<Object?> get props => [
    originalText,
    translatedText,
    sourceLang,
    targetLang,
    engineId,
    isCacheHit,
  ];
}

/// Supported reading translation languages metadata.
class TranslationLanguage extends Equatable {
  const TranslationLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  final String code;
  final String name;
  final String nativeName;

  @override
  List<Object?> get props => [code, name, nativeName];
}

/// Standardized set of major translation languages with native display names.
const List<TranslationLanguage> kSupportedLanguages = [
  TranslationLanguage(
    code: 'auto',
    name: 'Auto Detect',
    nativeName: 'Auto Detect',
  ),
  TranslationLanguage(code: 'en', name: 'English', nativeName: 'English'),
  TranslationLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
  TranslationLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
  TranslationLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
  TranslationLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano'),
  TranslationLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
  TranslationLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
  TranslationLanguage(
    code: 'zh-Hans',
    name: 'Chinese (Simplified)',
    nativeName: '简体中文',
  ),
  TranslationLanguage(
    code: 'zh-Hant',
    name: 'Chinese (Traditional)',
    nativeName: '繁體中文',
  ),
  TranslationLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
  TranslationLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
  TranslationLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
  TranslationLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  TranslationLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
  TranslationLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
  TranslationLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
  TranslationLanguage(code: 'pl', name: 'Polish', nativeName: 'Polski'),
  TranslationLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
  TranslationLanguage(code: 'uk', name: 'Ukrainian', nativeName: 'Українська'),
  TranslationLanguage(
    code: 'id',
    name: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
  ),
  TranslationLanguage(code: 'th', name: 'Thai', nativeName: 'ไทย'),
  TranslationLanguage(code: 'sv', name: 'Swedish', nativeName: 'Svenska'),
];
