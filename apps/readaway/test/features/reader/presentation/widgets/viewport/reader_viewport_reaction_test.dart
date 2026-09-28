import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reader_viewport.dart';

/// The viewport's reaction predicate gates both its listener and its builder.
///
/// The listener records the page to turn to, but the page is read again during
/// build and handed to the paged view that actually turns. A field that reaches
/// the listener but not the builder therefore updates state and moves no page,
/// and nothing reports an error: the speech is on the next page and the reader
/// is not. These tests exist to keep the two from drifting apart.
void main() {
  const base = ReaderState(
    loading: false,
    pageCount: 10,
    currentPage: 0,
    ttsActive: true,
    ttsCurrentPage: 0,
  );

  bool reacts(ReaderState to) => ReaderViewport.reactsTo(base, to);

  group('must reach the builder', () {
    test('the follow target moving to another page', () {
      // The case this file is about: the speech moved on, the reader did not.
      expect(reacts(base.copyWith(ttsTargetVirtualPage: 4)), isTrue);
    });

    test('the follow target being dropped', () {
      // Reaching null has to rebuild too: playback stopping clears the target,
      // and a page left pinned to it would not release.
      const following = ReaderState(
        loading: false,
        pageCount: 10,
        currentPage: 0,
        ttsActive: true,
        ttsCurrentPage: 0,
        ttsTargetVirtualPage: 4,
      );
      expect(ReaderViewport.reactsTo(following, base), isTrue);
    });

    test('the spoken range moving', () {
      expect(
        reacts(base.copyWith(ttsSpeechRange: (start: 10, end: 40))),
        isTrue,
      );
    });

    test('the reader moving', () {
      expect(reacts(base.copyWith(currentVirtualPage: 3)), isTrue);
      expect(reacts(base.copyWith(currentPage: 1)), isTrue);
    });

    test('the chapter of the speech moving', () {
      // The highlight is only drawn for the chapter being read, so a page
      // widget has to rebuild when playback moves to another chapter, or it
      // would keep painting the old chapter's highlight.
      expect(reacts(base.copyWith(ttsCurrentPage: 2)), isTrue);
      expect(
        reacts(base.copyWith(ttsActive: false, ttsCurrentPage: 2)),
        isTrue,
      );
    });

    test('playback starting and stopping', () {
      expect(reacts(base.copyWith(ttsActive: false)), isTrue);
    });

    test('the document being loaded', () {
      expect(reacts(const ReaderState(loading: true)), isTrue);
      expect(reacts(base.copyWith(pageHtmls: ['<p>a</p>'])), isTrue);
      expect(reacts(base.copyWith(isReflowable: false)), isTrue);
    });
  });

  group('quiet when nothing the viewport shows has changed', () {
    test('an unchanged state', () {
      expect(reacts(base), isFalse);
    });

    test('a change with no bearing on the page', () {
      // The sleep timer ticks every second while a long passage plays. It must
      // not rebuild the page tree on each tick.
      expect(
        reacts(
          base.copyWith(ttsSleepTimerRemaining: const Duration(minutes: 5)),
        ),
        isFalse,
      );
      expect(reacts(base.copyWith(bookTitle: 'A Book')), isFalse);
      expect(reacts(base.copyWith(outline: const [])), isFalse);
    });

    test('a chunk that did not move to another page', () {
      // Every chunk updates the range, so this is the common case: the highlight
      // must move without the page being turned.
      expect(
        reacts(
          base.copyWith(
            ttsTargetVirtualPage: 4,
            ttsSpeechRange: (start: 100, end: 140),
          ),
        ),
        isTrue,
      );
      expect(
        reacts(base.copyWith(ttsSpeechRange: (start: 200, end: 240))),
        isTrue,
      );
    });
  });
}
