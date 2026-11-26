/// Cleans and polishes translated text according to target language typographic conventions.
class TranslationPolisher {
  const TranslationPolisher();

  /// Performs basic whitespace and punctuation polish on any language.
  String basicPolish(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([.,!?;:])'), (m) => m.group(1)!)
        .trim();
  }

  /// Polishes text specifically tailored for [targetLang].
  String polish(String text, String targetLang) {
    final base = basicPolish(text);
    final langCode = targetLang.split(RegExp(r'[-_]'))[0].toLowerCase();

    switch (langCode) {
      case 'zh':
        // Chinese: fix em-dash, remove space before/after Chinese punctuation
        return base
            .replaceAll('--', '⸺')
            .replaceAllMapped(
              RegExp(r'\s+([。、！？，；：“”‘’（）《》])'),
              (m) => m.group(1)!,
            )
            .replaceAllMapped(
              RegExp(r'([。、！？，；：“”‘’（）《》])\s+'),
              (m) => m.group(1)!,
            );

      case 'ja':
        // Japanese: remove space around Japanese punctuation
        return base
            .replaceAllMapped(
              RegExp(r'\s+([。、！？「」『』])'),
              (m) => m.group(1)!,
            )
            .replaceAllMapped(
              RegExp(r'([。、！？「」『』])\s+'),
              (m) => m.group(1)!,
            );

      case 'es':
        // Spanish: ensure space after inverted punctuation and question marks
        return base
            .replaceAllMapped(
              RegExp(r'\?([A-ZÁÉÍÓÚÑÜ])'),
              (m) => '? ${m.group(1)}',
            )
            .replaceAllMapped(
              RegExp(r'!([A-ZÁÉÍÓÚÑÜ])'),
              (m) => '! ${m.group(1)}',
            );

      case 'fr':
        // French: ensure appropriate spacing before high punctuation
        return base
            .replaceAllMapped(
              RegExp(r'\s*([!?:;])'),
              (m) => ' ${m.group(1)}',
            )
            .replaceAllMapped(
              RegExp(r'([!?:;])\s*'),
              (m) => '${m.group(1)} ',
            )
            .trim();

      default:
        return base;
    }
  }

  /// Batched polish for a list of translated texts.
  List<String> polishBatch(List<String> texts, String targetLang) {
    return texts.map((t) => polish(t, targetLang)).toList();
  }
}
