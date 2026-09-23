import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('SpeechNormalizer Tests', () {
    test('expands currency correctly', () {
      expect(
        SpeechNormalizer.expandNumbersAndCurrency('I paid \$42.50 for lunch.'),
        contains('forty-two dollars and fifty cents'),
      );
      expect(
        SpeechNormalizer.expandNumbersAndCurrency('It costs £10.25.'),
        contains('ten pounds and twenty-five pence'),
      );
      expect(
        SpeechNormalizer.expandNumbersAndCurrency('Price is €5.'),
        contains('five euros'),
      );
    });

    test('expands percentages correctly', () {
      expect(
        SpeechNormalizer.expandNumbersAndCurrency('Accuracy is 50%.'),
        contains('fifty percent'),
      );
      expect(
        SpeechNormalizer.expandNumbersAndCurrency('Growth of 3.5%.'),
        contains('three point five percent'),
      );
    });

    test('expands ordinals correctly', () {
      expect(
        SpeechNormalizer.expandNumbersAndCurrency('He finished in 1st place on his 21st birthday.'),
        'He finished in first place on his twenty-first birthday.',
      );
      expect(
        SpeechNormalizer.expandNumbersAndCurrency('The 3rd chapter of the 100th volume.'),
        'The third chapter of the one hundredth volume.',
      );
    });

    test('expands abbreviations correctly', () {
      expect(
        SpeechNormalizer.expandAbbreviations('Dr. Watson met Mr. Holmes & visited St. John.'),
        'Doctor Watson met Mister Holmes and visited Saint John.',
      );
      expect(
        SpeechNormalizer.expandAbbreviations('Apples, oranges, etc. vs. pears (e.g. Bartlett, i.e. green).'),
        'Apples, oranges, et cetera versus pears (for example Bartlett, that is green).',
      );
    });

    test('normalizes complex text for speech', () {
      final input = 'Dr. Smith bought 3 apples for \$5 on the 2nd day.';
      final normalized = SpeechNormalizer.normalizeForSpeech(input);
      expect(normalized, contains('Doctor Smith'));
      expect(normalized, contains('three apples'));
      expect(normalized, contains('five dollars'));
      expect(normalized, contains('second day'));
    });

    test('preserves non-Latin scripts', () {
      const cjk = 'こんにちは、世界！';
      expect(SpeechNormalizer.normalizeForSpeech(cjk), equals(cjk));

      const arabic = 'مرحبا بالعالم';
      expect(SpeechNormalizer.normalizeForSpeech(arabic), equals(arabic));
    });

    test('estimates speech duration properly', () {
      final duration = SpeechNormalizer.estimateDurationMs('Hello world, this is a test.');
      expect(duration, greaterThan(1000));
      expect(duration, lessThan(4000));
    });
  });
}
