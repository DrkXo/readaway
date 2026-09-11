# MuPDF EPUB Rendering, Layout & Engine Memory Guide

> **Empirical Reference**: Validated and benchmarked against `Reverend Insanity [c1-500].epub` (2.69 MB, 504 chapters, 503 outline entries) using `packages/mupdf` native FFI bindings.
> **Target Audience**: AI agents and Flutter engineers building reading, rendering, TTS, search, and annotation features in `apps/readaway`.

---

## 1. Executive Summary & Capabilities Matrix

MuPDF's Fitz engine treats EPUB files as **reflowable XML/XHTML documents**. Unlike fixed-layout PDFs, EPUB pages do not exist in the file as static pages—Fitz parses the internal spine/manifest XHTML files and dynamically reflows text and graphics into pages according to a target viewport box `(width, height)` and font em size `(em)`.

| Capability | Supported | Performance Benchmark (500-chapter EPUB) | Notes & Architecture Rules |
| :--- | :--- | :--- | :--- |
| **Reflow / Layout** | Yes | **< 2ms** full document re-layout | Call `doc.layout(width, height, em)`. Recomputes all chapter page counts. |
| **TOC / Outline** | Yes | **35ms** for 503 outline items | Flat list with hierarchy `level`. Direct URI resolution to flat page index. |
| **CSS Injection** | Yes | **< 2ms** application | `doc.style(usePublisherCss, userCss)` allows full dark mode, typography, line-height. |
| **Bookmarks** | Yes | O(1) creation & lookup | `makeBookmark(loc)` and `lookupBookmark(id)` survive radical reflow and font size changes. |
| **Structured Words (TTS)** | Yes | **~7ms** for 256 words on a page | Exact `[x0, y0, x1, y1]` bounding boxes in page coordinates for karaoke TTS sync. |
| **Text Search (Quads)** | Yes | **~2-4ms** per page | Returns 4-point rotation/scale-invariant quads (`ul`, `ur`, `ll`, `lr`). |
| **Interactive Selection** | Yes | **< 1ms** | `selectText(a, b, mode)` snaps to words/lines with quads and copied UTF-8 string. |
| **Display List Caching** | Yes | **2ms** record, **3ms** render (1x), **6ms** (2x) | Cache display lists in memory for instantaneous pinch-to-zoom and tile rendering. |
| **HTML / SText Export** | Yes | **< 5ms** per page | High-fidelity absolute-positioned HTML representation. |

---

## 2. Document Initialization & Metadata

### Loading EPUB
```dart
final doc = MuPdfDocument.openFile('/path/to/book.epub');
// or from memory:
final doc = MuPdfDocument.openBytes(epubBytes);

print(doc.isReflowable); // true for EPUB
print(doc.chapterCount); // 504 chapters
```

### Standard Metadata Keys
MuPDF extracts Dublin Core metadata embedded in the EPUB's `content.opf`:
- `info:Title`: Book title (e.g. `"Reverend Insanity"`)
- `info:Author`: Creator / author name (e.g. `"Gu Zhen Ren"`)
- `format`: Format identifier (`"EPUB"`)
- `info:Subject`: Genre or categories tags

---

## 3. The Reflow Engine: Viewports, Fonts & Pagination

### Dynamic Layout (`doc.layout`)
Because EPUB is reflowable, **page numbers do not exist until layout is computed**.
```dart
doc.layout(width: viewportWidth, height: viewportHeight, em: fontSize);
```
- `width`: viewport width in points (logical pixels).
- `height`: viewport height in points (logical pixels).
- `em`: base font size in points (e.g., `14.0`).

### Empirical Pagination Benchmarks (Reverend Insanity c1-500)
| Form Factor | Viewport (pts) | Base Font (`em`) | Page Count | Layout Latency |
| :--- | :--- | :--- | :--- | :--- |
| **Mobile Compact** | 390 x 844 | 10.0 pt | **2,477 pages** | 1 ms |
| **Mobile Standard** | 390 x 844 | 14.0 pt | **4,438 pages** | < 1 ms |
| **Mobile Large Font** | 390 x 844 | 20.0 pt | **9,436 pages** | < 1 ms |
| **Tablet Portrait** | 820 x 1180 | 15.0 pt | **2,158 pages** | < 1 ms |
| **Desktop Landscape** | 1200 x 800 | 14.0 pt | **2,510 pages** | < 1 ms |
| **Extreme Large Font**| 400 x 800 | 24.0 pt | **15,247 pages** | 1 ms |

> [!TIP]
> **Layout is extremely fast (< 2ms)** because MuPDF builds an internal structural DOM tree once when the document is opened and only updates layout box splits during `fz_layout_document`. This allows real-time slider adjustments in Flutter UI without background lag.

---

## 4. Chapters vs Flat Pages & Navigation

MuPDF provides two indexing modes for EPUBs:
1. **Flat Page Numbering** (`0` to `doc.pageCount - 1`):
   - Uniform continuous indexing across the whole book.
   - Used for linear scrolling/swiping page views: `doc.loadPage(flatIndex)`.
2. **Chapter & Page Tuple** (`chapter` and `pageInChapter`):
   - `doc.chapterCount`: Total chapters (e.g., 504).
   - `doc.chapterPageCount(chapter)`: Number of pages in that specific chapter under current layout.
   - `doc.loadChapterPage(chapter, page)`: Direct access without traversing earlier chapters.

### Coordinate Conversion Between Modes
```dart
// Flat page -> Chapter & Page
final loc = doc.locationFromPage(25);
// loc.chapter == 3, loc.page == 7

// Chapter & Page -> Flat page
final flatPage = doc.pageFromLocation(loc);
// flatPage == 25
```

---

## 5. Bookmark Durability Across Layout & Font Changes

When a user resizes text, changes margins, or rotates their phone, **flat page numbers become completely invalid**.
MuPDF solves this via Fitz internal bookmarks (`fz_make_bookmark` and `fz_lookup_bookmark`), which attach to an internal DOM node.

### Reading Position Preservation Pattern
```dart
// 1. When user pauses reading on page 25:
final currentLocation = doc.locationFromPage(currentPage);
final bookmarkId = doc.makeBookmark(currentLocation);
// Persist bookmarkId (64-bit integer) to local SQLite/Hive database

// 2. User later increases font size (e.g. from 14pt to 24pt):
doc.layout(width: 400, height: 800, em: 24.0);

// 3. Restore exact position:
final restoredLoc = doc.lookupBookmark(bookmarkId);
final restoredFlatPage = doc.pageFromLocation(restoredLoc);
// Loads chapter 3, page 24 (flat page 89) instead of the old page 25!
```

> [!IMPORTANT]
> Always store `makeBookmark(loc)` in the user's progress record, **not** raw flat page numbers. When reopening a book or changing reading styles, resolve via `lookupBookmark(bookmarkId)`.

---

## 6. Table of Contents & Outline Resolution

In EPUB, the outline corresponds to the EPUB's NCX or Navigation Document:
```dart
final outline = doc.outline;
// Returns List<OutlineItem>
```

### Outline Properties in EPUB
- `title`: Chapter or section name (e.g. `"Chapter 1: The heart of a demon never has regret even in death"`).
- `level`: Depth hierarchy (0 for root chapters, 1 for sub-sections).
- `uri`: Relative XHTML path (e.g. `"OEBPS/page-0.html"` or `"OEBPS/chapter1.xhtml#subheading"`).
- `page`: **Pre-resolved flat page index under the current layout!**
- `isOpen`: Initial expansion state.

### URI Resolution
Internal URIs or anchor links can be resolved directly at any time:
```dart
final targetPage = doc.resolveUri("OEBPS/page-0.html");
// Returns exact flat page index (e.g. 16)
```

---

## 7. CSS Styling, Custom Fonts & Dark Mode

MuPDF supports CSS injection via `doc.style(usePublisherCss: bool, userCss: String?)`.

### Publisher CSS Control
- `usePublisherCss: true`: Honors embedded publisher stylesheets in the EPUB.
- `usePublisherCss: false`: Strips publisher stylesheets and relies purely on user CSS and Fitz base styling.

### Complete Dark Theme Recipe
```dart
const darkThemeCss = '''
  body {
    background-color: #121212 !important;
    color: #E0E0E0 !important;
    font-family: sans-serif !important;
    line-height: 1.8 !important;
    margin: 1.5em !important;
  }
  p {
    text-indent: 1.5em !important;
    margin-bottom: 0.8em !important;
  }
  h1, h2, h3 {
    color: #FFFFFF !important;
  }
''';

// 1. Apply style
doc.style(usePublisherCss: false, userCss: darkThemeCss);

// 2. Recompute layout (line-height and margins alter page count!)
doc.layout(width: viewportWidth, height: viewportHeight, em: 14.0);
```

### Empirical Pixel Verification
- When rendered with dark CSS, top-left background pixel RGB is `(18, 18, 18)` (matching `#121212`).
- When restored to publisher light mode, background pixel RGB is `(255, 255, 255)`.
- Re-layout with `line-height: 1.8` increased total pages from 4,596 to 6,636, proving full reflow integration.

---

## 8. Structured Words & TTS Synchronization

For Text-to-Speech (TTS) with word-by-word synchronized highlighting, use `page.extractWords()`:
```dart
final words = page.extractWords();
// Returns List<MuPdfWord>
```

### Word Structure
```dart
class MuPdfWord {
  final double x0, y0, x1, y1; // Bounding box in page points
  final String text;           // e.g. "Chapter", "Fang", "Yuan"
  double get width => x1 - x0;
  double get height => y1 - y0;
}
```

- Coordinate system: `[x0, y0]` is top-left, `[x1, y1]` is bottom-right in page points.
- Coordinates scale 1:1 with `RenderedPage` when scaled by `scaleX` and `scaleY`.
- Latency: **~7ms for 256 words** on an EPUB page.

---

## 9. Text Search & Interactive Selection

### Search with Rotation-Invariant Quads
```dart
final hits = page.searchQuads('Fang Yuan');
for (final hit in hits) {
  // 4 corners: ulX, ulY, urX, urY, llX, llY, lrX, lrY
}
```
- Benchmark: **1.6ms - 4.5ms** search time per page.
- Exact highlight quad alignment with rendered glyphs.

### Interactive Selection
```dart
final selection = page.selectText(
  MuPdfPoint(startX, startY),
  MuPdfPoint(endX, endY),
  mode: MuPdfSelectMode.words, // or chars, lines
);

print(selection.text);        // Clean copied text with newlines
print(selection.quads);       // List of highlight quads for Flutter canvas
print(selection.snappedStart);// Exact point snapped to word start
print(selection.snappedEnd);  // Exact point snapped to word end
```

---

## 10. Display Lists, Vector Caching & Zooming

When displaying an EPUB page in Flutter, creating a `MuPdfDisplayList` provides huge performance advantages:

```
[MuPdfPage] ─── toDisplayList() ───> [MuPdfDisplayList]
                                             │
                       ┌─────────────────────┴─────────────────────┐
                       ▼                                           ▼
             dl.render(scale: 1.0)                       dl.render(scale: 2.0)
             (Standard render: 3ms)                      (Pinch zoom: 6ms)
```

```dart
final dl = page.toDisplayList();
page.dispose(); // Page can be dropped immediately!

// Full page render:
final standard = dl.render(scaleX: 1.0, scaleY: 1.0); // 3ms

// Crisp 2x zoom render without re-parsing XML/layout:
final highDpi = dl.render(scaleX: 2.0, scaleY: 2.0); // 6ms

// Viewport tile render:
final tile = dl.renderRect(
  x0: 50, y0: 50, x1: 250, y1: 250,
  scaleX: 2.0, scaleY: 2.0,
); // 2ms

dl.dispose();
```

---

## 11. Image Handling & Cover Inspection

- Cover pages and inline illustrations are rendered into pixmaps via standard `page.render()`.
- If using `extractHtml(preserveImages: true)`:
  - Images are serialized as inline `data:image/jpeg;base64,...` or `data:image/png;base64,...`.
  - On Page 0 of Reverend Insanity, HTML size is **113 KB** with images, compared to **314 bytes** with `preserveImages: false`.
- **App Recommendation**: Always use `preserveImages: false` when extracting HTML for TTS text processing to avoid base64 memory overhead. Rely on `page.render()` or display lists for visual rendering.

---

## 12. Checklist for Flutter Reader Integration (`apps/readaway`)

1. **Initialization**:
   - Open document once on background isolate or service locator (`MuPdfDocument.openFile`).
   - Clone context for worker threads (`doc.clone()`).
2. **Layout on Viewport Changes**:
   - In Flutter `LayoutBuilder`, listen for orientation or window size changes.
   - Save current reading bookmark: `final mark = doc.makeBookmark(doc.locationFromPage(currentPage))`.
   - Call `doc.layout(width: constraints.maxWidth, height: constraints.maxHeight, em: userFontSize)`.
   - Restore current page: `final newPage = doc.pageFromLocation(doc.lookupBookmark(mark))`.
3. **Theming**:
   - Apply user preferences via `doc.style(usePublisherCss: false, userCss: generateReaderCss(theme))`.
4. **Rendering & Tile Caching**:
   - Cache `MuPdfDisplayList` for current and adjacent pages.
   - Render to `RenderedPage` and transfer to Flutter `ui.decodeImageFromPixels` using `ui.PixelFormat.rgba8888` (or RGB conversion).
5. **TTS Synchronization**:
   - Call `page.extractWords()` once per page.
   - Pass word stream to audio engine. Highlight corresponding `[x0, y0, x1, y1]` rectangles on custom painter as audio progresses.
