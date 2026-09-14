import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

import '../fixtures/epub_fixture.dart';

void main() {
  group('EpubContainer', () {
    test('opens a valid EPUB and lists entries', () {
      final container = EpubContainer.openBytes(EpubFixture.build());

      expect(container.hasEntry('META-INF/container.xml'), isTrue);
      expect(container.hasEntry('OEBPS/content.opf'), isTrue);
      expect(container.hasEntry('OEBPS/chapter1.xhtml'), isTrue);
      expect(container.hasEntry('missing.txt'), isFalse);
      expect(container.listEntries(), contains('OEBPS/images/cover.png'));

      container.dispose();
    });

    test('reads entry bytes and normalizes paths', () {
      final container = EpubContainer.openBytes(EpubFixture.build());

      final bytes = container.readEntry('OEBPS/chapter1.xhtml');
      expect(bytes, isNotNull);
      expect(decodeUtf8(bytes!), contains('Chapter 1'));

      // Backslash and leading-slash variants resolve to the same entry.
      expect(container.readEntry(r'OEBPS\chapter1.xhtml'), isNotNull);
      expect(container.readEntry('/OEBPS/chapter1.xhtml'), isNotNull);

      container.dispose();
    });

    test('returns null for missing entries', () {
      final container = EpubContainer.openBytes(EpubFixture.build());
      expect(container.readEntry('nope.bin'), isNull);
      container.dispose();
    });

    test('throws DocumentParseException for invalid bytes', () {
      expect(
        () => EpubContainer.openBytes(Uint8List.fromList([1, 2, 3, 4, 5])),
        throwsA(isA<DocumentParseException>()),
      );
    });

    test('throws DocumentDisposedException after dispose', () {
      final container = EpubContainer.openBytes(EpubFixture.build());
      container.dispose();
      expect(
        () => container.readEntry('META-INF/container.xml'),
        throwsA(isA<DocumentDisposedException>()),
      );
    });
  });
}
