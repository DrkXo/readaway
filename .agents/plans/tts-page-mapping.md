# TTS ↔ page mapping: ground-up rewrite

Replace fuzzy text matching between the TTS chunk queue and the paginated
viewport with a single shared coordinate system, and add sentence-level
highlighting on top of it.

## Background

The reader has two independent pipelines over the same chapter HTML:

| | render | speech |
|---|---|---|
| source | `loadSectionHtml` | `loadSectionHtml` (same raw HTML) |
| transform | `TextTransformPipeline` → `HtmlAdapter.parse` → CSS → HyperRender fragments | `HtmlTextExtractor.extractSpeechText` → `TtsChunker` |
| positions | exact `offsetY` per fragment | **none** — only a fake offset space |

Because there was no shared coordinate space, every attempted mapping was a
guess: proportional pixel fractions, 80-char page samples, prefix-substring
search with four fallback tiers.

### Enabling discovery

`RenderHyperBox` already exposes the canonical character space used by text
selection and IME:

```dart
int get totalCharacterCount;                        // render_hyper_box.dart:638
int getCharacterPositionAtOffset(Offset position);  // render_hyper_box.dart:643
```

It is backed by `Fragment.globalOffset`, assigned as a running prefix-sum in
`_ensureFragments` (`render_hyper_box_layout.dart:37-47`):

- `text` / `ruby` fragment with non-null text → `+ text.length`
- `lineBreak` fragment → `+ 1`
- everything else → `+ 0`

The prefix-sum is reconstructible from the public `debugFragments()` output, so
no upstream package change is required.

## Rejected approach (was staged)

The staged implementation added `pageProgressions` / `pageTextSamples` to
`PaginationCoordinator` and did lookup in `ReaderBloc` via fuzzy matching.
Known defects:

1. **Offset-space mismatch (real bug).** `reader_bloc.dart:603` builds
   `fullSpeechText` as a `' '`-joined string, then `:684` compares that index
   against `queue[ci].endOffset`. `endOffset` lives in a *different* space —
   `tts_chunker.dart:169` charges `paraLen + 1` per kept paragraph, i.e. a
   `'\n'`-joined string that is never materialised. The two agree only when
   every paragraph maps to exactly one chunk; the oversized-paragraph branch
   (`tts_chunker.dart:113-114, 152`) joins sentence spans with `' '` while
   charging the original span length, so drift accumulates.
2. **`pageProgressions` was dead code** — only ever supplied by
   `pagination_coordinator_test.dart:129`. No production caller.
3. **Untrustworthy parallel arrays.** `_chapterPageOffsets[i]` /
   `_chapterPageProgressions[i]` / `_chapterPageTextSamples[i]` must be
   index-aligned, but are written under separate `!= null && isNotEmpty` guards
   that never clear stale values and compared under three different equality
   rules.
4. **Pill double-jump.** `reader_back_to_tts_pill.dart:148-152` calls
   `onJumpToTtsPage` *and* dispatches `jumpToTtsPage`, which re-enters
   `jumpToGlobalPage` via the `reader_page.dart:129` listener.
5. **Lost bounds check.** `_onJumpToTtsPage` dropped `target < state.pageCount`;
   `ttsTargetPage` is a *global* page while `pageCount` is *section* count for
   reflowable.
6. **Wrong direction.** It was a pull (fuzzy lookup per chunk tick) rather than
   a push (assign once at measure time).

## Target architecture

One coordinate system per chapter, owned by `PaginationCoordinator`:

```
ChapterTextLayout {
  spans:  [{charStart, charEnd, rect, nodeTag, type}]   // render fragments
  blocks: [{index, charStart, charEnd, startY, endY, tag, speakable}]
  pages:  [{index, startY, endY, startChar, endChar}]
}
```

Character offsets, Y positions and page boundaries all refer to the same space,
so `chunk → page` and `page → chunk` are both O(log n) binary searches with no
text comparison anywhere.

## Stages

### Stage 0 — Preserve, then clear

```bash
git branch wip/tts-page-follow-v1     # snapshot the staged tree
git restore --staged .
```

Re-apply from `wip/tts-page-follow-v1` the parts orthogonal to the mapping
problem:

- `ReaderBackToTtsPill` chapter-title label + `ReaderGestureArena.suppressNextTap()`
- the `jumpToPage` → `jumpToGlobalPage` / `jumpToChapter` split
- pill re-ordering above the chrome

Discard: `_recomputeTtsPageChunkBoundaries`, `_findChunkIndexForSample`,
`pageTextSamples`, `pageProgressions`.

### Stage 1 — `ChapterTextLayout` (pure data)

`packages/readaway_core/lib/src/pagination/chapter_text_layout.dart`

`TextSpanBox`, `TextBlock`, `PageSlice`, `ChapterTextLayout`. Depends only on
`dart:ui` geometry types — no render-object coupling.

### Stage 2 — `ChapterTextLayoutBuilder` (app layer)

`apps/readaway/lib/src/features/reader/presentation/widgets/viewport/reflowable/chapter_text_layout_builder.dart`

Replaces `reflowable_virtual_page.dart:159-181`. One pass over
`debugFragments()`:

- reconstruct `globalOffset` per fragment via the documented prefix-sum
- group into blocks: zero-text fragments whose `nodeTag` is a block tag
  (`p`, `div`, `li`, `h1-6`, `blockquote`, `pre`, `section`, `article`, `dt`,
  `dd`) are boundaries; `a`/`em`/`span` are inline and merge away
- derive `PageSlice`s via the existing `PageSlicer`; each page's `startChar`
  is the `charEnd` of the last span fully above `startY`
- **dev assertion**: prefix-sum total must equal `hyperBox.totalCharacterCount`.
  On mismatch, emit a layout with `pages == null` so callers degrade to the
  existing pixel-fraction path rather than producing wrong numbers.

### Stage 3 — Coordinator owns the layout

Replace `pageProgressions` + `pageTextSamples` + their equality helpers with a
single `Map<int, ChapterTextLayout>`:

```dart
void  registerChapterLayout(int chapterIndex, ChapterTextLayout layout);
int   pageForChar(int chapterIndex, int charOffset);
int?  charForPage(int chapterIndex, int pageInChapter);
List<Rect> rectsForCharRange(int chapterIndex, int start, int end);
```

### Stage 4 — A correspondence between the speech text and the rendered text

**The originally planned block-index alignment was abandoned as unsound.** After
tag stripping, `<p>a</p><p>b</p>` and `<p>a</p><div></div><p>b</p>` are the same
string but lay out as two and three blocks, so nothing in the text distinguishes
them. `debugFragments()` does not help either: it reports block starts, block
ends and inline boundaries identically, so a block cannot be told from its own
boundary.

A DOM-walk alignment was considered and rejected in turn. It would mean
mirroring `hyper_render_html`'s `_tokenizeBlock` internals — nesting, opaque
children of `pre`/`details`/flex/grid, conditionally elided block starts, and
list markers that inject speakable-looking text. A version bump could break it
silently, which is the same class of defect that killed the first attempt.

What is adopted instead is a **text diff**. The chapter's rendered text is
materialised alongside the character offsets it was built from, and matched
against the speech text:

```dart
SpeechCharMap.build(speechText, layout.flowText, lookahead: 48)
```

Where characters agree the correspondence is exact. Where they genuinely differ
the difference collapses into a span, and only inside that span is the answer an
estimate; `isExact` says which case an offset is in, so a caller can prefer
another strategy rather than trust an interpolated number.

This needs no change to how speech text is produced. Divergences introduced by
the transform pipeline — punctuation rotation becoming a localized substitution —
are absorbed by the diff, so nothing about what is read aloud changes.

`registerChapterLayout` is the re-stamp point, not a lazy retry.

### Stage 5 — The bloc consumes the correspondence directly

`extractSpeechText(pageIndex)` hands its result to the coordinator at playback
start, and `TtsChunk.startOffset` indexes exactly that string, so no rebasing is
needed in the chunker at all. Each chunk is then one lookup:

```dart
coordinator.globalPageForSpeechOffset(chapterIndex, chunk.startOffset)
coordinator.rectsForSpeechRange(chapterIndex, chunk.startOffset, chunk.endOffset)
```

The follow target is held apart from `currentVirtualPage`, which records where
the reader actually is. Conflating them would scroll the reader back the moment
they looked ahead. The viewport acts on the target only when the spoken text
moves to a different page, so scrolling away mid-chunk is not undone until the
speech itself moves on.

`pageForSpeechOffset` returns `null` rather than 0 when no correspondence
exists, so "not known yet" is distinguishable from "page zero". The first
chunks routinely arrive before the page has been measured, and those emit
nothing rather than guessing.

### Stage 6 — Highlight

`ReaderState.ttsSpeechRange` flows to `ReflowableVirtualPage`, which asks the
coordinator for bounding boxes and paints them behind the text. The painter
works in chapter-local coordinates and is told where the visible page begins, so
it stays independent of the viewport. Ranges belonging to another page are
skipped rather than clipped away.

Nothing is drawn unless the range belongs to the chapter on screen and the
coordinator can place it, so the highlight is absent rather than wrong.

Word-level karaoke is **out of scope**: `TtsChunk.words` is never populated by
any chunker, and real word alignment needs engine timestamps.

### Stage 7 — "Back to audio"

The pill dispatches the jump and the viewport scrolls from the resulting state.
The jump goes to the page the speech was last placed on rather than to the top
of its chapter, falling back to the chapter when nothing has been placed. One
navigation, one place deciding where the reader lands.

Whether the shortcut is offered compares placed pages where they exist;
comparing chapters alone reports the reader as lost while they sit on the right
chapter and the wrong page.

## Coverage

Paged reflowable only. `registerChapterLayout` is called from
`ReflowableVirtualPage` alone, so the continuous viewport has no character
mapping: it has no discrete page to follow and nothing to place a highlight
against. Fixed layout likewise has no mapping, and falls back to chapter
comparison.

## Verification

| Gate | How |
|---|---|
| No fuzzy matching remains | `grep -rn "pageTextSamples\|findChunkIndexForSample\|_ttsPageChunkBoundaries" apps packages` → empty (`fullSpeechText` remains, but only as the cache key in the synthesis pipeline) |
| Prefix-sum rule still valid | dev assertion vs `totalCharacterCount`, unit test over an EPUB fixture |
| Boundaries are exact | core test: synthetic layout with known char offsets at page breaks; assert `pageForChar` round-trips |
| Page-follow behaviour | `reader_bloc_tts_follow_test.dart` — page from offset, unchanged within a page, moving across a break, and no emission before a correspondence exists |
| Ruby | `pagination_coordinator_speech_map_test.dart` — a reading immediately before a page boundary; the break moves by the length the reading adds |
| Highlight alignment | `tts_speech_highlight_test.dart` — placement, clipping at both page edges, colour, and repaint triggers, asserted on rendered pixels |
| Regression | `pagination_coordinator_test.dart` and `chapter_text_layout_test.dart` green throughout |

## Risks

1. **Ruby.** The renderer draws the kanji base while the speech side reads the
   kana, and `debugFragments()` does not expose the reading, so the kana are
   unrecoverable from the render side. Offsets inside a reading are
   interpolated; `isExact` reports them. A reading sits within one line, so page
   assignment is unaffected, and the fixture covers a reading immediately before
   a page boundary to prove it.
2. **Interpolation over long matching runs.** A run of identical text used to be
   covered by a single straight line between the anchor before it and the
   resynchronisation after it, which made every offset in the run wrong by up to
   the length difference while `isExact` still called the run exact. Fixed by
   anchoring inside a run and closing a run where it actually ends; covered by
   `speech_char_map_test.dart`.
3. **Measurement timing.** The layout is measured on the UI thread while chunks
   arrive from the speech engine, so early chunks routinely precede the
   correspondence. Handled by emitting nothing rather than a guess, and by
   rebuilding the correspondence in `registerChapterLayout` on relayout.
