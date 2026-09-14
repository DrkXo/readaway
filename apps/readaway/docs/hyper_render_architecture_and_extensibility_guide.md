# HyperRender (^1.9.1) Architecture & Extensibility Guide

> **Target Audience**: AI agents and Flutter engineers implementing rich document rendering, HTML styling, custom plugins, TTS karaoke, and e-book reader viewports in `readaway`.

---

## 1. Executive Summary & Architecture Philosophy

`hyper_render: ^1.9.1` is a high-performance content engine for Flutter. While conventional Flutter HTML libraries (such as `flutter_html` or `flutter_widget_from_html`) map HTML tags into hundreds of deeply nested Flutter widgets, HyperRender compiles documents into a **Unified Document Tree (UDT)** and renders them inside a **single custom `RenderObject` (`RenderHyperBox`)**.

### Why Single `RenderObject` Architecture Matters
1. **True CSS Float (`float: left / right`)**: Wrapping text around floated images requires the coordinates of every line fragment before adjacent text is composed. This is architecturally impossible in a standard Flutter widget tree where parent layout cannot inspect sibling fragment geometry.
2. **Crash-Free Continuous Selection**: Text selection spans seamlessly across headings, paragraphs, table cells, and floated elements within a single continuous span tree. Hit-testing is **$O(\log N)$** via pre-computed `_lineStartOffsets` binary search.
3. **CJK Typography & Ruby / Furigana**: Built-in Kinsoku line breaking and phonetic Ruby text (`<ruby>漢<rt>かん</rt></ruby>`).
4. **Massive Memory & Widget Reduction**: A 25,000-character article compiles into 3–5 chunks rather than 500+ widgets, running at a locked 60/120 FPS.

---

## 2. The Unified Document Tree (UDT) Model

All input formats (HTML, GFM Markdown, Quill Delta JSON) normalize into the **UDT**:

```
HTML / Markdown / Quill Delta
           │
           ▼
    [ContentAdapter]  ─── (HtmlAdapter, MarkdownAdapter, DeltaAdapter)
           │
           ▼
    [DocumentNode]   ─── Root node of UDT
           │
 ┌─────────┴────────────────────────────────────────┐
 ▼                   ▼                  ▼           ▼
[BlockNode]     [InlineNode]       [TextNode]   [AtomicNode]
(div, p, h1-6)  (span, a, strong)  (raw text)   (img, hr, br, svg)
 │                   │
[RubyNode]      [TableNode]
(ruby + rt)     (tr, td, th)
```

### Key Node Types
- `BlockNode`: Full-width block elements with margins, borders, and backgrounds.
- `InlineNode`: Text wrappers applying font variations, decorations, and link handlers.
- `TextNode`: Leaf text node carrying string content.
- `AtomicNode`: Replaced elements (`img`, `svg`, `audio`, `video`, `hr`, `br`).
- `RubyNode`: CJK annotations (base text + pronunciation gloss).
- `TableNode`, `TableRowNode`, `TableCellNode`: 2-pass W3C auto-layout tables supporting `colspan` and `rowspan`.

---

## 3. Extensibility Vectors & Customization APIs

HyperRender provides 7 distinct extension mechanisms depending on the level of customization required:

```
                  ┌──────────────────────────────────────────────┐
                  │          HyperRender Extensibility           │
                  └──────────────────────┬───────────────────────┘
                                         │
 ┌───────────────────────┬───────────────┴───────────────┬───────────────────────┐
 ▼                       ▼                               ▼                       ▼
1. Plugin Registry      2. Widget Builder               3. Custom Image Loader  4. Custom CSS Resolver
(Custom HTML tags)      (Granular node interception)    (EPUB/Memory streams)   (Design tokens & cascade)
```

---

### Extensibility Vector 1: Custom HTML Tag Plugins (`HyperPluginRegistry`)

Use when introducing custom domain-specific tags (e.g. `<callout>`, `<footnote>`, `<annotation>`, `<user-badge>`).

Plugins operate in two tiers:
- **Block Tier** (`isInline: false`): Full width, inherits container margins and padding.
- **Inline Tier** (`isInline: true`): Flows inline with text; measured as an inline fragment.

#### Implementation Example
```dart
// 1. Define Block Plugin
class CalloutPlugin extends HyperNodePlugin {
  @override
  List<String> get tagNames => ['callout', 'aside-note'];

  @override
  bool get isInline => false;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    final type = node.attributes['type'] ?? 'info';
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: type == 'warning' ? Colors.amber.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        node.textContent,
        style: ctx.baseStyle.copyWith(color: Colors.black87),
      ),
    );
  }
}

// 2. Define Inline Plugin
class BadgePlugin extends HyperNodePlugin {
  @override
  List<String> get tagNames => ['badge', 'pill'];

  @override
  bool get isInline => true;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        node.textContent,
        style: ctx.baseStyle.copyWith(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

// 3. Register with HyperViewer
final pluginRegistry = HyperPluginRegistry()
  ..register(CalloutPlugin())
  ..register(BadgePlugin());

HyperViewer(
  html: '<p>Note: <callout type="warning">Danger!</callout></p>',
  pluginRegistry: pluginRegistry,
)
```

> [!TIP]
> Tags registered in `HyperPluginRegistry` are automatically whitelisted and bypass `HtmlSanitizer` stripping.

---

### Extensibility Vector 2: Granular Node Interception (`widgetBuilder`)

Use when intercepting standard HTML elements without creating a formal plugin class (e.g., swapping `<img>` for `CachedNetworkImage` or `<audio>` for a custom audio player):

```dart
HyperViewer(
  html: articleHtml,
  widgetBuilder: (node) {
    if (node is AtomicNode && node.tagName == 'audio') {
      final src = node.attributes['src'] ?? '';
      return CustomAudioPill(audioUrl: src);
    }
    if (node is AtomicNode && node.tagName == 'img') {
      final src = node.src;
      if (src != null && src.startsWith('http')) {
        return CachedNetworkImage(imageUrl: src);
      }
    }
    return null; // Return null to fall back to HyperRender default
  },
)
```

---

### Extensibility Vector 3: Custom Image Loading (`HyperImageLoader`)

By default, HyperRender resolves image URLs over network via `NetworkImage`. When rendering EPUB chapters, images reside in-memory inside the zip archive (`data:` URIs or `epub://` scheme).

```dart
typedef HyperImageLoader = void Function(
  String src,
  void Function(ui.Image image) onLoad,
  void Function(Object error) onError,
);
```

#### Custom EPUB Image Loader
```dart
void epubImageLoader(
  String src,
  void Function(ui.Image image) onLoad,
  void Function(Object error) onError,
) async {
  try {
    final Uint8List imageBytes = await resolveImageBytesFromEpub(src);
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    onLoad(frame.image);
  } catch (e) {
    onError(e);
  }
}

// Pass to HyperViewer:
HyperViewer(
  html: chapterHtml,
  imageLoader: epubImageLoader,
)
```

---

### Extensibility Vector 4: CSS Resolver & Styling Engine

The `StyleResolver` is an industrial-grade CSS cascade engine:
1. **O(1) Rule Indexing**: Rules partitioned by rightmost selector key (`_rulesByTag`, `_rulesByClass`, `_rulesById`, `_universalRules`).
2. **Specificity Calculation**: Standard W3C specificity `[ID: 100, Class/Attr/Pseudo: 10, Element: 1]`.
3. **CSS Variables**: Real-time evaluation of `var(--token, fallback)`.
4. **Calculations & Units**: Evaluates `calc()`, `em`, `rem`, `pt`, `px`, `vh`, `vw`, `%`.
5. **`!important` Cascade**: Properly ordered after inline styles.

#### Injecting Custom Styles
```dart
HyperViewer(
  html: content,
  customCss: '''
    body {
      font-family: 'Charis SIL', serif;
      font-size: 16px;
      line-height: 1.8;
      color: var(--reader-foreground);
      background-color: var(--reader-background);
    }
    p {
      text-indent: 1.5em;
      margin-bottom: 0.8em;
    }
  ''',
)
```

---

### Extensibility Vector 5: Controllers & Navigation

#### 1. `HyperViewerController` (Continuous Scroll & Anchors)
- Programmatic scrolling: `controller.scrollToId('section-2')` or `controller.scrollToOffset(1200)`.
- Heading Extraction for TOC: Inspects `controller.headings` (`List<HeadingAnchor>`) populated with `level`, `text`, `cssId`, and `yOffset`.

#### 2. `HyperPageController` (Paged Reader Mode)
- Configured via `mode: HyperRenderMode.paged`.
- Paginates into swipeable sections via `PageView.builder`.
- Navigation methods:
  - `pageCtrl.nextPage()`
  - `pageCtrl.previousPage()`
  - `pageCtrl.jumpToPage(int page)`
  - `pageCtrl.animateToPage(int page, duration, curve)`
  - Observable `pageCtrl.currentPage` (`ValueNotifier<int>`).

---

### Extensibility Vector 6: AI / LLM Streaming (`HyperStreamingController`)

Introduced in v1.8.0, HyperViewer supports live token streaming:
- **Adaptive Frame Throttling**: Batches incoming stream chunks to 60 FPS frame boundaries.
- **Transient Syntax Repair**: Auto-repairs incomplete unclosed tokens (e.g. `**bold`, ````code`, `$$math$$`) on the fly while streaming.
- **Typing Caret**: Pulsing cursor (`bar`, `block`, `underscore`).
- **Stick-to-bottom Auto-scroll**: Smoothly tracks the stream tail.

```dart
final controller = HyperStreamingController();
controller.bindStream(geminiTokenStream);

HyperViewer.streaming(
  streamingController: controller,
  contentType: HyperContentType.markdown,
  showTypingCaret: true,
  autoRepairSyntax: true,
  autoScrollToBottom: true,
)
```

---

### Extensibility Vector 7: Security & Heuristics

#### 1. `HtmlSanitizer`
XSS protection is **enabled by default** (`sanitize: true`):
- Strips `<script>`, inline event handlers (`onload`, `onerror`, `onclick`), and `javascript:` URIs.
- Configurable allowlist: `allowedTags: ['p', 'b', 'i', 'img', 'a']`.
- Custom scheme authorization: `allowedCustomSchemes: ['readaway', 'myapp']`.

#### 2. `HtmlHeuristics`
Fast regex-based complexity scanner without full DOM overhead:
- `HtmlHeuristics.hasForms(html)`: Detects `<form>`, `<input>`, `<select>`, `<textarea>`.
- `HtmlHeuristics.hasUnsupportedCss(html)`: Detects `position: absolute / fixed`, `z-index`, `clip-path`, `column-count`.
- `HtmlHeuristics.hasComplexTables(html)`: Detects `colspan >= 3` or `rowspan >= 3`.
- `HtmlHeuristics.isComplex(html)`: Combines all checks to determine whether to render via HyperRender or route to a WebView fallback.

---

## 4. HyperRender & MuPDF Synergy in Readaway

| Feature Area | MuPDF Role (`packages/mupdf`) | HyperRender Role (`hyper_render: ^1.9.1`) |
| :--- | :--- | :--- |
| **Fixed Layout PDF** | High-performance rasterization to pixmaps and vector display lists. | Not used for PDF page rendering. |
| **Reflowable EPUB** | Computes document-level pagination, TOC, search quads, TTS word coordinates (`[x0, y0, x1, y1]`), and reflow bookmarks. | Renders interactive HTML chapters in Flutter with custom themes, plugins, gestures, and text selection. |
| **Theming & Fonts** | Native C styling via `fz_style_document`. | Fluid UI theming with Flutter themes, Google Fonts, and custom widgets. |
| **Images** | Extracts native image stream from EPUB zip. | Decodes via `epubImageLoader` and wraps text with CSS float. |
| **Text-to-Speech** | `page.extractWords()` provides exact bounding boxes for synchronization. | Custom inline plugins or overlay highlights can visually animate words during playback. |

> [!WARNING]
> **MuPDF HTML Quirks with HyperRender**:
> MuPDF's `page.extractHtml()` uses `p { position: absolute; }` to position text identically to the native PDF/EPUB pixmap. `HtmlHeuristics.hasUnsupportedCss()` flags `position: absolute` because HyperRender's BFC flow is designed for reflowable content rather than hardcoded absolute coordinates.
> 
> **Architecture Decision for `readaway`**:
> - When rendering reflowable e-book pages with HyperRender, **use the raw chapter XHTML** or stripped semantic HTML, **not** the absolute-positioned MuPDF stext HTML.
> - Alternatively, transform the UDT tree using `apps/readaway/lib/src/features/reader/presentation/extensions/hyper_html_extensions.dart` (`applyTextColor`) and `HyperSelectionOverlay`.
