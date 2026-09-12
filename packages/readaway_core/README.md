# readaway_core

Pure-Dart document reading engine for ReadAway — no native dependencies.

`readaway_core` provides a unified, extensible abstraction over reflowable
(EPUB, HTML, plain text) and fixed-layout (PDF) documents, plus a reactive
pagination engine. It is designed to be **performant, future-proof, and
extensible**: new formats plug in via a handler registry, and reading position
survives reflow changes via stable anchors.

## Why this package?

The ReadAway app previously relied on a single native MuPDF binding for every
document type. That forced manual control of the reader layer and coupled
reflowable formats to a fixed-layout engine. `readaway_core` moves the
reflowable reading pipeline into pure Dart:

- **EPUB** — ZIP container, OPF package, NCX (EPUB 2) and `<nav>` (EPUB 3)
  outlines, spine, metadata, and embedded assets, all parsed in Dart.
- **HTML / TXT** — standalone files exposed as single-section reflowable docs.
- **PDF** — a clean `PdfDocumentReader` interface (rendering, text extraction,
  search, links) that a native backend can implement without touching the rest
  of the pipeline.

## Architecture

```
lib/
  readaway_core.dart          # public barrel
  src/
    errors/                   # DocumentException hierarchy
    models/                   # freezed + json_serializable value types
      epub/                   # EPUB-specific models (OpfData)
    pagination/               # PageSlicer, PaginationCoordinator
    abstracts/                # public contracts (interfaces)
      document_reader.dart            # unified interface
      reflowable_document_reader.dart # section-based interface
      pdf_document_reader.dart        # page-based interface
      document_format_handler.dart    # pluggable format detection
    readers/                  # concrete implementations
      document_reader_factory.dart    # registry + auto-detection
      builtin_handlers.dart           # EPUB / HTML / TXT handlers
      epub/                           # container + OPF/NCX/nav parsers + reader
      html/                           # SingleHtmlDocumentReader
      text/                           # PlainTextDocumentReader
```

### Reader interfaces

| Interface                  | Purpose                                                     |
| -------------------------- | ----------------------------------------------------------- |
| `DocumentReader`           | Common surface: format, metadata, outline, assets, dispose. |
| `ReflowableDocumentReader` | Ordered sections of semantic HTML/XHTML.                    |
| `PdfDocumentReader`        | Fixed pages: render, extract text/HTML, search, links.      |

### Pagination

`PaginationCoordinator` (rxdart) tracks per-chapter heights, computes page
counts with `PageSlicer`, and exposes a `ValueStream<PaginationState>`. The
current position is stored as a `ReadingAnchor` (chapter + progression), so
font-size or window changes reflow without losing your place.

## Performance

Opening a document never blocks the UI isolate. `EpubDocumentReader.fromBytes`
/ `fromFile` keep the lazy ZIP container on the main isolate but offload the
expensive XML work — OPF package parsing and NCX/`<nav>` outline parsing — to a
background isolate via `Isolate.run`. Only cheap, sendable values (bytes and
plain data objects) cross the boundary, and `DocumentParseException` propagates
back intact. Per-section HTML and asset loading remain synchronous and cached
(LRU, 256 entries) for fast page turns.

## Usage

```dart
import 'package:readaway_core/readaway_core.dart';

// Auto-detect and open any supported format.
final factory = DocumentReaderFactory();
final reader = await factory.open('/path/to/book.epub');

if (reader is ReflowableDocumentReader) {
  print('${reader.sectionCount} sections');
  final html = reader.loadSectionHtml(0);
  final asset = reader.loadAsset(reader.resolveAssetPath(0, 'images/x.png'));
}

// Reactive pagination.
final coordinator = PaginationCoordinator();
coordinator.initialize(
  chapterCount: reader.sectionCount,
  viewportHeight: 800,
  contentHeight: 2400,
);
coordinator.state.listen((state) => print('page ${state.globalPage + 1}/${state.totalPages}'));

reader.dispose();
coordinator.dispose();
```

## Extending with new formats

Implement `DocumentFormatHandler` and register it:

```dart
class MyFormatHandler implements DocumentFormatHandler {
  @override
  String get format => 'myfmt';

  @override
  bool supports(String filePath, [Uint8List? bytes]) =>
      filePath.endsWith('.myfmt');

  @override
  Future<DocumentReader> open(String filePath) async => MyReader(filePath);
}

factory.register(MyFormatHandler());
```

## Development

```bash
dart pub get
dart run build_runner build   # regenerate freezed / json_serializable
dart analyze
dart test
dart run coverage:test_with_coverage
```

## License

MIT — see the repository root `LICENSE`.
