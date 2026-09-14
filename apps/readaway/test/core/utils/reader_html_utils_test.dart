import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/utils/reader/reader_html_utils.dart';

void main() {
  group('reader_html_utils - precacheCandidates', () {
    test('computes surrounding page candidates correctly within bounds', () {
      expect(precacheCandidates(0, 5), equals([0, 1]));
      expect(precacheCandidates(2, 5), equals([2, 3, 1]));
      expect(precacheCandidates(4, 5), equals([4, 3]));
      expect(precacheCandidates(0, 1), equals([0]));
    });
  });
}
