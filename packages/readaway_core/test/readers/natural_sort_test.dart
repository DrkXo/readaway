import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('naturalCompare', () {
    test('sorts numeric runs numerically', () {
      final sorted = ['page10.png', 'page2.png', 'page1.png']
        ..sort(naturalCompare);
      expect(sorted, ['page1.png', 'page2.png', 'page10.png']);
    });

    test('treats leading zeros as equal', () {
      expect(naturalCompare('page02', 'page2'), 0);
    });

    test('compares case-insensitively with a case tiebreak', () {
      expect(naturalCompare('A', 'a'), lessThan(0));
      expect(naturalCompare('a', 'b'), lessThan(0));
    });

    test('handles mixed alphanumeric', () {
      final sorted = ['img10a', 'img2b', 'img2a']..sort(naturalCompare);
      expect(sorted, ['img2a', 'img2b', 'img10a']);
    });

    test('is reflexive', () {
      expect(naturalCompare('same', 'same'), 0);
    });

    test('orders by prefix length', () {
      expect(naturalCompare('page', 'page1'), lessThan(0));
      expect(naturalCompare('page1', 'page'), greaterThan(0));
    });
  });
}
