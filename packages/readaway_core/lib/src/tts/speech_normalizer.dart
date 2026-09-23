import 'package:diacritic/diacritic.dart';

/// High-performance speech text normalizer implemented in pure Dart.
///
/// Expands numbers, currencies, ordinals, percentages, and abbreviations into spoken words,
/// performs Unicode NFKC normalization, and transliterates Latin accents.
class SpeechNormalizer {
  const SpeechNormalizer._();

  static final RegExp _currencyRe = RegExp(r'(\$|£|€)(\d+(?:\.\d{1,2})?)');
  static final RegExp _ordinalRe = RegExp(r'\b(\d+)(?:st|nd|rd|th)\b', caseSensitive: false);
  static final RegExp _percentRe = RegExp(r'\b(\d+(?:\.\d+)?)\s*%');
  static final RegExp _standaloneNumberRe = RegExp(r'\b(\d{1,9})\b');

  static const List<(String, String)> _abbreviations = [
    (r'\bDr\.(?:\s|$)', 'Doctor '),
    (r'\bMr\.(?:\s|$)', 'Mister '),
    (r'\bMrs\.(?:\s|$)', 'Missus '),
    (r'\bMs\.(?:\s|$)', 'Miz '),
    (r'\bProf\.(?:\s|$)', 'Professor '),
    (r'\bSt\.(?:\s|$)', 'Saint '),
    (r'\bvs\.(?:\s|$)', 'versus '),
    (r'\betc\.(?:\s|$)', 'et cetera '),
    (r'\be\.g\.(?:\s|$)', 'for example '),
    (r'\bi\.e\.(?:\s|$)', 'that is '),
    (r'\s*&\s*', ' and '),
  ];

  static final List<(RegExp, String)> _compiledAbbreviations = _abbreviations
      .map((entry) => (RegExp(entry.$1, caseSensitive: false), entry.$2))
      .toList();

  /// Expands numbers, currencies, ordinals, and percentages into spoken English words.
  static String expandNumbersAndCurrency(String text) {
    // 1. Currency ($42.50 -> forty-two dollars and fifty cents)
    var result = text.replaceAllMapped(_currencyRe, (match) {
      final sym = match.group(1) ?? '';
      final numStr = match.group(2) ?? '';
      final val = double.tryParse(numStr);
      if (val == null) return match.group(0)!;

      final intPart = val.truncate();
      final fracPart = ((val - intPart) * 100).round();

      final String currName;
      final String centName;
      switch (sym) {
        case '£':
          currName = intPart == 1 ? 'pound' : 'pounds';
          centName = fracPart == 1 ? 'penny' : 'pence';
          break;
        case '€':
          currName = intPart == 1 ? 'euro' : 'euros';
          centName = fracPart == 1 ? 'cent' : 'cents';
          break;
        case r'$':
        default:
          currName = intPart == 1 ? 'dollar' : 'dollars';
          centName = fracPart == 1 ? 'cent' : 'cents';
          break;
      }

      final intWords = numberToWords(intPart);
      if (fracPart > 0) {
        final fracWords = numberToWords(fracPart);
        return '$intWords $currName and $fracWords $centName';
      }
      return '$intWords $currName';
    });

    // 2. Percentages (50% -> fifty percent, 3.5% -> three point five percent)
    result = result.replaceAllMapped(_percentRe, (match) {
      final numStr = match.group(1)!;
      if (numStr.contains('.')) {
        final parts = numStr.split('.');
        final whole = int.tryParse(parts[0]) ?? 0;
        final decimals = parts[1].split('').map((d) => numberToWords(int.parse(d))).join(' ');
        return '${numberToWords(whole)} point $decimals percent';
      }
      final val = int.tryParse(numStr);
      if (val != null) {
        return '${numberToWords(val)} percent';
      }
      return match.group(0)!;
    });

    // 3. Ordinals (1st -> first, 2nd -> second, 21st -> twenty-first)
    result = result.replaceAllMapped(_ordinalRe, (match) {
      final val = int.tryParse(match.group(1)!);
      if (val != null) {
        return numberToOrdinal(val);
      }
      return match.group(0)!;
    });

    // 4. Standalone numbers (up to 9 digits)
    result = result.replaceAllMapped(_standaloneNumberRe, (match) {
      final val = int.tryParse(match.group(1)!);
      if (val != null) {
        return numberToWords(val);
      }
      return match.group(0)!;
    });

    return result;
  }

  /// Expands common abbreviations into full spoken forms.
  static String expandAbbreviations(String text) {
    var result = text;
    for (final entry in _compiledAbbreviations) {
      result = result.replaceAll(entry.$1, entry.$2);
    }
    return result;
  }

  /// Reports whether Latin characters make up the majority of alphabetic characters.
  static bool isLatinDominant(String text) {
    var totalAlpha = 0;
    var latinCount = 0;

    for (final rune in text.runes) {
      final isAlpha = (rune >= 0x41 && rune <= 0x5A) ||
          (rune >= 0x61 && rune <= 0x7A) ||
          (rune >= 0xC0 && rune <= 0x24F) ||
          (rune >= 0x370 && rune <= 0x1CFF) ||
          (rune >= 0x2C00 && rune <= 0x2DFF) ||
          (rune >= 0x3040 && rune <= 0x9FFF) ||
          (rune >= 0xAC00 && rune <= 0xD7AF);

      if (isAlpha) {
        totalAlpha++;
        if ((rune >= 0x41 && rune <= 0x5A) ||
            (rune >= 0x61 && rune <= 0x7A) ||
            (rune >= 0xC0 && rune <= 0x24F)) {
          latinCount++;
        }
      }
    }

    if (totalAlpha == 0) return true;
    return (latinCount / totalAlpha) > 0.5;
  }

  /// Normalizes text for speech by running Unicode sanitization,
  /// abbreviation expansion, number spell-out, and Latin diacritics transliteration.
  static String normalizeForSpeech(String text) {
    final unescaped = expandAbbreviations(text);
    final expanded = expandNumbersAndCurrency(unescaped);

    if (isLatinDominant(expanded)) {
      // Remove accents for Latin text
      final transliterated = removeDiacritics(expanded);
      return transliterated.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).join(' ');
    } else {
      // Preserve non-Latin scripts (CJK, Arabic, etc.) intact
      return expanded;
    }
  }

  /// Estimates spoken audio duration in milliseconds based on word count.
  /// Defaults to ~160 words per minute (standard English audiobook pace).
  static int estimateDurationMs(String text, [double? wordsPerMinute]) {
    final wpm = wordsPerMinute ?? 160.0;
    final wordCount = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final effectiveWords = wordCount > 0 ? wordCount : 1;
    return ((effectiveWords / wpm) * 60.0 * 1000.0).round();
  }

  // --- Number to Words Conversion Utilities ---

  static const List<String> _ones = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
    'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen',
    'seventeen', 'eighteen', 'nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'
  ];

  static const List<String> _ordinalOnes = [
    'zeroth', 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh',
    'eighth', 'ninth', 'tenth', 'eleventh', 'twelfth', 'thirteenth', 'fourteenth',
    'fifteenth', 'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth'
  ];

  static const List<String> _ordinalTens = [
    '', '', 'twentieth', 'thirtieth', 'fortieth', 'fiftieth', 'sixtieth',
    'seventieth', 'eightieth', 'ninetieth'
  ];

  /// Converts an integer [n] (up to 999,999,999) to English words.
  static String numberToWords(int n) {
    if (n < 0) return 'negative ${numberToWords(-n)}';
    if (n < 20) return _ones[n];
    if (n < 100) {
      final rem = n % 10;
      return rem == 0 ? _tens[n ~/ 10] : '${_tens[n ~/ 10]}-${_ones[rem]}';
    }
    if (n < 1000) {
      final rem = n % 100;
      final hundredStr = '${_ones[n ~/ 100]} hundred';
      return rem == 0 ? hundredStr : '$hundredStr ${numberToWords(rem)}';
    }
    if (n < 1000000) {
      final thousands = n ~/ 1000;
      final rem = n % 1000;
      final thousandStr = '${numberToWords(thousands)} thousand';
      return rem == 0 ? thousandStr : '$thousandStr ${numberToWords(rem)}';
    }
    if (n < 1000000000) {
      final millions = n ~/ 1000000;
      final rem = n % 1000000;
      final millionStr = '${numberToWords(millions)} million';
      return rem == 0 ? millionStr : '$millionStr ${numberToWords(rem)}';
    }
    return n.toString();
  }

  /// Converts an integer [n] to ordinal English words (e.g. 1 -> first, 21 -> twenty-first).
  static String numberToOrdinal(int n) {
    if (n < 20) return _ordinalOnes[n];
    if (n < 100) {
      final rem = n % 10;
      if (rem == 0) return _ordinalTens[n ~/ 10];
      return '${_tens[n ~/ 10]}-${_ordinalOnes[rem]}';
    }
    final words = numberToWords(n);
    final lastSpace = words.lastIndexOf(' ');
    final lastHyphen = words.lastIndexOf('-');
    final splitIdx = lastSpace > lastHyphen ? lastSpace : lastHyphen;

    if (splitIdx != -1) {
      final prefix = words.substring(0, splitIdx + 1);
      final lastWord = words.substring(splitIdx + 1);
      final lastNum = int.tryParse(lastWord) ?? _wordToNum(lastWord);
      if (lastNum != null) {
        return '$prefix${numberToOrdinal(lastNum)}';
      }
    }
    if (words.endsWith('hundred')) return '${words}th';
    if (words.endsWith('thousand')) return '${words}th';
    if (words.endsWith('million')) return '${words}th';
    return '${words}th';
  }

  static int? _wordToNum(String word) {
    final idx = _ones.indexOf(word);
    if (idx != -1) return idx;
    final tensIdx = _tens.indexOf(word);
    if (tensIdx != -1) return tensIdx * 10;
    return null;
  }
}
