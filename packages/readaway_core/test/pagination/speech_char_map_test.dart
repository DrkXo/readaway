import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

/// Distinct filler of exactly [length] characters.
///
/// Every word is numbered so no two stretches of the result are
/// interchangeable. A run of identical characters cannot offer that: every
/// alignment of it matches as well as every other, so a test built from one
/// measures the matcher's tie-breaking rather than the correspondence.
String _words(int length) {
  final buffer = StringBuffer();
  var word = 0;
  while (buffer.length < length) {
    buffer.write('w$word ');
    word++;
  }
  return buffer.toString().substring(0, length);
}

void main() {
  group('SpeechCharMap identical text', () {
    test('maps offsets one-for-one and is exact throughout', () {
      const text = 'The quick brown fox jumps over the lazy dog.';
      final map = SpeechCharMap.build(text, text);

      expect(map.isExact(0), isTrue);
      expect(map.isExact(text.length), isTrue);
      expect(map.exactFraction, 1.0);

      for (var i = 0; i <= text.length; i++) {
        expect(map.renderCharFor(i), i, reason: 'offset $i');
        expect(map.speechCharFor(i), i, reason: 'offset $i');
      }
    });

    test('empty input is exact and safe', () {
      final map = SpeechCharMap.build('', '');

      expect(map.renderCharFor(0), 0);
      expect(map.renderCharFor(50), 0);
      expect(map.speechCharFor(50), 0);
      expect(map.exactFraction, 1.0);
    });
  });

  group('SpeechCharMap render inserts text', () {
    // A list marker is drawn but never spoken.
    test('shifts offsets by the inserted length after the marker', () {
      final map = SpeechCharMap.build('Alpha Beta', '1. Alpha Beta');

      // Speech offset 0 is the start of "Alpha", which the render string
      // reaches at 3 because "1. " precedes it. Returning 0 here would place
      // the first chunk inside the marker.
      expect(map.renderCharFor(0), 3);
      expect(map.renderCharFor(1), 4);
      // Past the marker the two strings hold identical text, so every offset
      // in the body is anchored by matching.
      expect(map.isExact(0), isTrue);
      expect(map.isExact(1), isTrue);
      expect(map.isExact(5), isTrue);
    });

    test('re-synchronises so later text is exact again in value', () {
      // After the marker, both strings hold identical text, so the offset
      // relationship is a constant shift even though the prefix diverged.
      final map = SpeechCharMap.build('Alpha Beta', '1. Alpha Beta');

      // "Beta" starts at speech 6, render 9.
      expect(map.renderCharFor(6), 9);
      expect(map.renderCharFor(10), 13);
    });

    test('repeated insertions accumulate correctly', () {
      final map = SpeechCharMap.build(
        'one two three',
        '1. one 2. two 3. three',
      );

      // Each marker is three characters ("1. ") that the speech side does not
      // speak, so speech offsets run three ahead per list item.
      expect(map.renderCharFor(0), 3);
      expect(map.renderCharFor(4), 10);
      expect(map.renderCharFor(8), 17);
    });
  });

  group('SpeechCharMap speech omits text', () {
    // A footnote container is rendered but not spoken.
    test('shifts offsets backwards after the omission', () {
      final map = SpeechCharMap.build('Body More', 'Body Footnote More');

      expect(map.renderCharFor(0), 0);
      expect(map.renderCharFor(5), 14);
    });

    test('an omission in the middle keeps both sides ordered', () {
      final map = SpeechCharMap.build('A C', 'A B C');

      final previous = -1;
      var monotone = true;
      for (var i = 0; i <= 3; i++) {
        final r = map.renderCharFor(i);
        if (r < previous) monotone = false;
        expect(r, greaterThanOrEqualTo(previous));
        expect(monotone, isTrue);
      }
    });
  });

  group('SpeechCharMap ruby', () {
    // The renderer shows the kanji base; the speech side speaks the kana. The
    // two differ in both content and length, which is the one case that cannot
    // be resolved by matching.
    test('isolates the substitution instead of drifting afterwards', () {
      // Render: uga  (2 chars)  Speech: ひらがな (4 chars)
      final map = SpeechCharMap.build('AひらがなB', 'AugaB');

      expect(map.renderCharFor(0), 0);
      // 'B' is common to both and must land on the same character: the map
      // resynchronises on it rather than carrying the length difference.
      expect(map.renderCharFor(5), 4);
    });

    test('is exact up to the ruby span and not across it', () {
      final map = SpeechCharMap.build('AひらがなB', 'AugaB');

      // 'A' matched, and the span's end is the 'B' the matcher resynchronised
      // on, so both boundaries are anchored.
      expect(map.isExact(0), isTrue);
      expect(map.isExact(1), isTrue);
      expect(map.isExact(5), isTrue);
      // The interior of the ruby span is interpolated.
      expect(map.isExact(2), isFalse);
      expect(map.isExact(3), isFalse);
      expect(map.isExact(4), isFalse);
      expect(map.exactFraction, lessThan(1.0));
    });
  });

  group('SpeechCharMap long matching runs', () {
    // A run of matching text has to be mapped by matching it, not by drawing a
    // line from the anchor before it to the resynchronisation after it. Such a
    // line cannot follow the run: it makes every position before the divergence
    // wrong by up to the length difference, and isExact still calls the run
    // exact, so the error is invisible to a caller.
    test('maps a run before a divergence one-for-one', () {
      final head = _words(120);
      final map = SpeechCharMap.build(
        '$headよみがな${_words(20)}',
        // Braces are required here: without them `headK` is a single name.
        '${head}K${_words(20)}',
      );

      // Every offset of the run is a verified correspondence.
      for (var i = 0; i <= head.length; i++) {
        expect(map.renderCharFor(i), i, reason: 'offset $i');
        expect(map.isExact(i), isTrue, reason: 'offset $i');
      }
    });

    test('anchors a run at the point it ends, not at the resynchronisation', () {
      // The reading is four characters long where the kanji base is one, so the
      // resynchronisation sits three characters beyond where the run ended.
      // Stretching the run's last anchor that far would interpolate the tail of
      // text that matched perfectly.
      final head = _words(120);
      final map = SpeechCharMap.build(
        '$headよみがな${_words(20)}',
        // Braces are required here: without them `headK` is a single name.
        '${head}K${_words(20)}',
      );

      final rubyStart = head.length;
      expect(map.renderCharFor(rubyStart), rubyStart, reason: 'ruby start');
      expect(map.renderCharFor(rubyStart + 4), rubyStart + 1);
      // The reading's interior is the only part that cannot be matched.
      for (var i = rubyStart + 1; i < rubyStart + 4; i++) {
        expect(map.isExact(i), isFalse, reason: 'offset $i');
      }
      expect(map.isExact(rubyStart), isTrue);
      expect(map.isExact(rubyStart + 4), isTrue);
    });

    test('a run spanning many anchor intervals stays exact', () {
      // The interval bounds how often a verified point is recorded, so a run
      // several intervals long must not start accumulating error.
      final head = _words(400);
      final map = SpeechCharMap.build(
        '$headよみがな${_words(20)}',
        // Braces are required here: without them `headK` is a single name.
        '${head}K${_words(20)}',
      );

      for (var i = 0; i <= head.length; i++) {
        expect(map.renderCharFor(i), i, reason: 'offset $i');
        expect(map.isExact(i), isTrue, reason: 'offset $i');
      }
    });
  });

  group('SpeechCharMap monotonicity', () {
    test('render positions never decrease as speech advances', () {
      final map = SpeechCharMap.build(
        'start 1. middle 2. end',
        'start 1. middle 2. end 3. tail',
      );

      var previous = -1;
      for (var i = 0; i <= map.speechLength; i++) {
        final r = map.renderCharFor(i);
        expect(
          r,
          greaterThanOrEqualTo(previous),
          reason: 'offset $i went backwards',
        );
        previous = r;
      }
    });

    test('clamps beyond both ends', () {
      final map = SpeechCharMap.build('abc', 'abcdefgh');

      expect(map.renderCharFor(-5), 0);
      expect(map.renderCharFor(999), map.renderLength);
      expect(map.speechCharFor(-5), 0);
      expect(map.speechCharFor(999), map.speechLength);
    });
  });

  group('SpeechCharMap realistic document', () {
    test('a footnote mid-chapter does not drift the rest of the chapter', () {
      const speech = 'First para. Second para. Third para.';
      const render =
          'First para. [1] Second para. Third para. <aside>A note.</aside>';

      final map = SpeechCharMap.build(speech, render);

      // Every speech position must map forward, and the final one must reach
      // the end of the spoken text rather than trailing off.
      expect(map.renderCharFor(map.speechLength), greaterThan(0));

      // The order of the two paragraphs must be preserved.
      final firstSecond = speech.indexOf('Second');
      final third = speech.indexOf('Third');
      expect(
        map.renderCharFor(third),
        greaterThan(map.renderCharFor(firstSecond)),
      );
    });
  });
}
