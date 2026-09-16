import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core_rust/readaway_core_rust.dart';

void main() {
  group('generated copyWith smoke tests', () {
    test('DocumentMetadata copyWith works (normalized ctor path)', () {
      final meta = DocumentMetadata.normalized(
        title: 'T',
        author: 'A',
        identifier: 'I',
      );
      final updated = meta.copyWith(title: 'T2', language: 'en');
      expect(updated.title, 'T2');
      expect(updated.author, 'A');
      expect(updated.creator, 'A');
      expect(updated.identifier, 'I');
      expect(updated.language, 'en');
      expect(updated, isNot(equals(meta)));
      expect(updated.toString(), contains('T2'));
    });

    test('TtsChunk copyWith works (derived id path)', () {
      final chunk = TtsChunk.withDerivedId(
        sectionIndex: 1,
        sentenceIndex: 2,
        text: 'Hello',
        startOffset: 0,
        endOffset: 5,
      );
      expect(chunk.id, '1:2:0');
      final updated = chunk.copyWith(text: 'World', isParagraphEnd: true);
      expect(updated.id, '1:2:0');
      expect(updated.text, 'World');
      expect(updated.isParagraphEnd, isTrue);
      expect(updated.sectionIndex, 1);
    });

    test('PaginationState copyWith works', () {
      const state = PaginationState(globalPage: 3, totalPages: 10);
      final updated = state.copyWith(globalPage: 4);
      expect(updated.globalPage, 4);
      expect(updated.totalPages, 10);
    });

    test('ReadingAnchor copyWith works', () {
      const anchor = ReadingAnchor(chapterIndex: 1, progressionInChapter: 0.5);
      final updated = anchor.copyWith(progressionInChapter: 0.75);
      expect(updated.chapterIndex, 1);
      expect(updated.progressionInChapter, 0.75);
    });

    test('TransformContext copyWith works', () {
      const ctx = TransformContext(content: 'a', vertical: true);
      final updated = ctx.copyWith(content: 'b', language: 'zh');
      expect(updated.content, 'b');
      expect(updated.vertical, isTrue);
      expect(updated.language, 'zh');
    });

    test('Equatable equality + stringify', () {
      const a = DocumentSection(id: '1', index: 0, href: 'x.html');
      const b = DocumentSection(id: '1', index: 0, href: 'x.html');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('x.html'));
    });
  });
}
