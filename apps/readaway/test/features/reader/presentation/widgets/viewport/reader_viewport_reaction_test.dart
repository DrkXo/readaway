import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reader_viewport.dart';

/// The viewport's reaction predicate gates both its listener and its builder.
///
/// Reacts to document and page changes while ignoring non-viewport properties
/// such as book metadata or outline.
void main() {
  const base = ReaderState(
    loading: false,
    pageCount: 10,
    currentPage: 0,
    currentVirtualPage: 0,
    virtualPageCount: 10,
    isReflowable: true,
  );

  bool reacts(ReaderState to) => ReaderViewport.reactsTo(base, to);

  group('must reach the builder', () {
    test('the reader moving page', () {
      expect(reacts(base.copyWith(currentPage: 1)), isTrue);
    });

    test('the virtual page moving', () {
      expect(reacts(base.copyWith(currentVirtualPage: 3)), isTrue);
    });

    test('virtual page count changing', () {
      expect(reacts(base.copyWith(virtualPageCount: 20)), isTrue);
    });

    test('the document loading state changing', () {
      expect(reacts(base.copyWith(loading: true)), isTrue);
    });

    test('the document page htmls changing', () {
      expect(reacts(base.copyWith(pageHtmls: ['<p>a</p>'])), isTrue);
    });

    test('the reflowable layout changing', () {
      expect(reacts(base.copyWith(isReflowable: false)), isTrue);
    });

    test('the document path changing', () {
      expect(reacts(base.copyWith(documentPath: '/path/to/book.epub')), isTrue);
    });

    test('page count changing', () {
      expect(reacts(base.copyWith(pageCount: 15)), isTrue);
    });

    test('document format changing', () {
      expect(reacts(base.copyWith(format: 'pdf')), isTrue);
    });
  });

  group('quiet when nothing the viewport shows has changed', () {
    test('an unchanged state', () {
      expect(reacts(base), isFalse);
    });

    test('a change with no bearing on the viewport', () {
      expect(reacts(base.copyWith(bookTitle: 'A Book')), isFalse);
      expect(reacts(base.copyWith(outline: const [])), isFalse);
    });
  });
}
