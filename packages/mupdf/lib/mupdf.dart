import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/library.dart';
import 'src/mupdf_bindings_generated.dart';

/// Colorspace constants for [MuPdfPage.render] and [MuPdfDisplayList.render].
const int csRgb = 0;
const int csGray = 1;
const int csCmyk = 2;

/// Permission flags for [MuPdfDocument.hasPermission].
const int permPrint = 0x70; // 'p'
const int permCopy = 0x63; // 'c'
const int permEdit = 0x65; // 'e'
const int permAnnotate = 0x6E; // 'n'

/// A flattened outline item from the document's table of contents.
class OutlineItem {
  final String? title;
  final String? uri;
  final int chapter;
  final int page;
  final int level;
  final bool isOpen;

  const OutlineItem({
    this.title,
    this.uri,
    required this.chapter,
    required this.page,
    required this.level,
    required this.isOpen,
  });
}

/// A bounding box returned by [MuPdfPage.boundBox].
class PageBoundBox {
  final double width;
  final double height;
  const PageBoundBox({required this.width, required this.height});
}

/// A search hit quad (4 corners of a highlighted region).
class SearchHit {
  final double ulX, ulY, urX, urY, llX, llY, lrX, lrY;
  const SearchHit({
    required this.ulX,
    required this.ulY,
    required this.urX,
    required this.urY,
    required this.llX,
    required this.llY,
    required this.lrX,
    required this.lrY,
  });
}

/// An interactive link hot zone on a page.
class PageLink {
  /// Hot zone in page coordinates — the same space as the stext HTML
  /// `top`/`left` styles.
  final double x0, y0, x1, y1;

  /// Original URI: external URL or internal destination string.
  final String uri;

  /// Resolved internal destination (flat page index), or -1 when [uri] is
  /// external or could not be resolved.
  final int pageNumber;

  const PageLink({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.uri,
    required this.pageNumber,
  });

  bool get isInternal => pageNumber >= 0;
}

/// A document location identifying a specific chapter and page within that chapter.
class MuPdfLocation {
  final int chapter;
  final int page;
  const MuPdfLocation({required this.chapter, required this.page});

  @override
  String toString() => 'MuPdfLocation(chapter: $chapter, page: $page)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuPdfLocation &&
          runtimeType == other.runtimeType &&
          chapter == other.chapter &&
          page == other.page;

  @override
  int get hashCode => Object.hash(chapter, page);
}

/// Selection modes for [MuPdfPage.selectText].
enum MuPdfSelectMode {
  chars(0),
  words(1),
  lines(2);

  final int value;
  const MuPdfSelectMode(this.value);
}

/// A 2D point with coordinates in page space.
class MuPdfPoint {
  final double x;
  final double y;
  const MuPdfPoint(this.x, this.y);

  @override
  String toString() => 'MuPdfPoint($x, $y)';
}

/// The result of an interactive text selection on a page.
class MuPdfTextSelection {
  final String text;
  final List<SearchHit> quads;
  final MuPdfPoint snappedStart;
  final MuPdfPoint snappedEnd;

  const MuPdfTextSelection({
    required this.text,
    required this.quads,
    required this.snappedStart,
    required this.snappedEnd,
  });

  bool get isEmpty => text.isEmpty;
  bool get isNotEmpty => text.isNotEmpty;
}

/// A single extracted word with its bounding box in page coordinates.
class MuPdfWord {
  final double x0, y0, x1, y1;
  final String text;

  const MuPdfWord({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.text,
  });

  double get width => x1 - x0;
  double get height => y1 - y0;

  @override
  String toString() => 'MuPdfWord("$text" at [$x0, $y0, $x1, $y1])';
}

/// Cancellation cookie to abort ongoing rendering from another thread or isolate.
class MuPdfCookie {
  final mupdf_cookie _cookie;
  bool _disposed = false;

  MuPdfCookie() : _cookie = _lib.mupdf_new_cookie();

  /// Set the abort flag. Any rendering call using this cookie will abort as soon as possible.
  void abort() {
    if (!_disposed) {
      _lib.mupdf_abort_cookie(_cookie);
    }
  }

  void dispose() {
    if (!_disposed) {
      _lib.mupdf_drop_cookie(_cookie);
      _disposed = true;
    }
  }

  mupdf_cookie get pointer => _cookie;
}

/// Pre-recorded vector display list for high-performance zooming, panning, and tile rendering.
class MuPdfDisplayList {
  final mupdf_context _ctx;
  final mupdf_display_list _list;
  bool _disposed = false;

  MuPdfDisplayList._(this._ctx, this._list);

  mupdf_display_list get pointer => _list;

  /// Render the entire display list into a pixmap.
  RenderedPage render({
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool alpha = false,
    int cs = csRgb,
    MuPdfCookie? cookie,
  }) {
    final pix = _lib.mupdf_render_display_list(
      _ctx,
      _list,
      scaleX,
      scaleY,
      alpha ? 1 : 0,
      cs,
      cookie?.pointer ?? nullptr,
    );
    if (pix == nullptr) throw MuPdfException(_lastErrorCtx(_ctx));

    try {
      return _buildRenderedPage(_ctx, pix);
    } finally {
      _lib.mupdf_drop_pixmap(_ctx, pix);
    }
  }

  /// Render a sub-rectangle (tile) of the display list into a pixmap.
  /// Coordinates [x0, y0, x1, y1] are in page points.
  RenderedPage renderRect({
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool alpha = false,
    int cs = csRgb,
    MuPdfCookie? cookie,
  }) {
    final pix = _lib.mupdf_render_display_list_rect(
      _ctx,
      _list,
      scaleX,
      scaleY,
      x0,
      y0,
      x1,
      y1,
      alpha ? 1 : 0,
      cs,
      cookie?.pointer ?? nullptr,
    );
    if (pix == nullptr) throw MuPdfException(_lastErrorCtx(_ctx));

    try {
      return _buildRenderedPage(_ctx, pix);
    } finally {
      _lib.mupdf_drop_pixmap(_ctx, pix);
    }
  }

  void dispose() {
    if (!_disposed) {
      _lib.mupdf_drop_display_list(_ctx, _list);
      _disposed = true;
    }
  }
}

/// Renders a document page to raw pixel data via MuPDF.
class MuPdfPage {
  final mupdf_context _ctx;
  final mupdf_page _page;
  bool _disposed = false;

  MuPdfPage._(this._ctx, this._page);

  mupdf_page get pointer => _page;

  double get width => _lib.mupdf_page_width(_ctx, _page);
  double get height => _lib.mupdf_page_height(_ctx, _page);

  /// Rotation angle of the page in degrees (0, 90, 180, 270).
  int get rotation => _lib.mupdf_page_rotation(_ctx, _page);

  /// Returns width and height in a single native call.
  PageBoundBox get boundBox {
    final wPtr = calloc<Float>();
    final hPtr = calloc<Float>();
    try {
      final rc = _lib.mupdf_page_bound_box(_ctx, _page, wPtr, hPtr);
      if (rc != 0) throw MuPdfException(_lastErrorCtx(_ctx));
      return PageBoundBox(width: wPtr.value, height: hPtr.value);
    } finally {
      calloc.free(wPtr);
      calloc.free(hPtr);
    }
  }

  /// Create a vector display list from this page for fast zooming, tile rendering, and caching.
  MuPdfDisplayList toDisplayList() {
    final list = _lib.mupdf_new_display_list_from_page(_ctx, _page);
    if (list == nullptr) throw MuPdfException(_lastErrorCtx(_ctx));
    return MuPdfDisplayList._(_ctx, list);
  }

  /// Render the page at the given scale. Returns RGBA pixel data.
  ///
  /// [cs] selects the output colorspace: [csRgb], [csGray], or [csCmyk].
  /// [cookie] optional cancellation cookie.
  RenderedPage render({
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool alpha = false,
    int cs = csRgb,
    MuPdfCookie? cookie,
  }) {
    final pix = _lib.mupdf_new_pixmap_from_page_cookie(
      _ctx,
      _page,
      scaleX,
      scaleY,
      alpha ? 1 : 0,
      cs,
      cookie?.pointer ?? nullptr,
    );
    if (pix == nullptr) throw MuPdfException(_lastErrorCtx(_ctx));

    try {
      return _buildRenderedPage(_ctx, pix);
    } finally {
      _lib.mupdf_drop_pixmap(_ctx, pix);
    }
  }

  /// Extract plain text from the page.
  String? extractText() {
    final ptr = _lib.mupdf_extract_text(_ctx, _page);
    if (ptr == nullptr) return null;
    try {
      return ptr.cast<Utf8>().toDartString();
    } finally {
      _lib.mupdf_free_string(_ctx, ptr);
    }
  }

  /// Extract HTML from the page.
  ///
  /// If [preserveImages] is true (default), images on the page are serialized as
  /// base64 data URIs within the extracted HTML.
  String? extractHtml({bool preserveImages = true}) {
    final ptr = _lib.mupdf_extract_html_options(
      _ctx,
      _page,
      preserveImages ? 1 : 0,
    );
    if (ptr == nullptr) return null;
    try {
      return ptr.cast<Utf8>().toDartString();
    } finally {
      _lib.mupdf_free_string(_ctx, ptr);
    }
  }

  /// Get the page label (e.g. "iv", "12").
  String? get label {
    final buf = calloc.allocate<Char>(64);
    try {
      final len = _lib.mupdf_page_label(_ctx, _page, buf, 64);
      if (len < 0) return null;
      return buf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buf);
    }
  }

  /// Search the page and return hit bounding quads.
  List<SearchHit> searchQuads(String needle) {
    final needlePtr = needle.toNativeUtf8();
    final countPtr = calloc<Int>();
    try {
      final ptr = _lib.mupdf_search_page_quads(
        _ctx,
        _page,
        needlePtr.cast<Char>(),
        countPtr,
      );
      final count = countPtr.value;
      if (ptr == nullptr || count <= 0) return [];
      try {
        final hits = <SearchHit>[];
        for (var i = 0; i < count; i++) {
          final off = i * 8;
          hits.add(
            SearchHit(
              ulX: ptr[off],
              ulY: ptr[off + 1],
              urX: ptr[off + 2],
              urY: ptr[off + 3],
              llX: ptr[off + 4],
              llY: ptr[off + 5],
              lrX: ptr[off + 6],
              lrY: ptr[off + 7],
            ),
          );
        }
        return hits;
      } finally {
        _lib.mupdf_free_floats(ptr);
      }
    } finally {
      calloc.free(needlePtr);
      calloc.free(countPtr);
    }
  }

  /// Performs interactive text selection between two touch/mouse points.
  ///
  /// The coordinates [a] and [b] are snapped according to [mode] (characters,
  /// words, or lines). Returns the snapped endpoints, selection quads for
  /// rendering UI highlights, and the extracted UTF-8 text.
  MuPdfTextSelection selectText(
    MuPdfPoint a,
    MuPdfPoint b, {
    MuPdfSelectMode mode = MuPdfSelectMode.words,
  }) {
    final snappedAxPtr = calloc<Float>();
    final snappedAyPtr = calloc<Float>();
    final snappedBxPtr = calloc<Float>();
    final snappedByPtr = calloc<Float>();
    final quadsPtr = calloc<Pointer<Float>>();
    final quadCountPtr = calloc<Int>();
    final textPtr = calloc<Pointer<Char>>();

    try {
      final rc = _lib.mupdf_page_select_text(
        _ctx,
        _page,
        a.x,
        a.y,
        b.x,
        b.y,
        mode.value,
        snappedAxPtr,
        snappedAyPtr,
        snappedBxPtr,
        snappedByPtr,
        quadsPtr,
        quadCountPtr,
        textPtr,
      );
      if (rc != 0) throw MuPdfException(_lastErrorCtx(_ctx));

      final quadCount = quadCountPtr.value;
      final rawQuads = quadsPtr.value;
      final hits = <SearchHit>[];
      if (rawQuads != nullptr && quadCount > 0) {
        try {
          for (var i = 0; i < quadCount; i++) {
            final off = i * 8;
            hits.add(
              SearchHit(
                ulX: rawQuads[off],
                ulY: rawQuads[off + 1],
                urX: rawQuads[off + 2],
                urY: rawQuads[off + 3],
                llX: rawQuads[off + 4],
                llY: rawQuads[off + 5],
                lrX: rawQuads[off + 6],
                lrY: rawQuads[off + 7],
              ),
            );
          }
        } finally {
          _lib.mupdf_free_floats(rawQuads);
        }
      }

      String selectedText = '';
      final rawText = textPtr.value;
      if (rawText != nullptr) {
        try {
          selectedText = rawText.cast<Utf8>().toDartString();
        } finally {
          _lib.mupdf_free_string(_ctx, rawText);
        }
      }

      return MuPdfTextSelection(
        text: selectedText,
        quads: hits,
        snappedStart: MuPdfPoint(snappedAxPtr.value, snappedAyPtr.value),
        snappedEnd: MuPdfPoint(snappedBxPtr.value, snappedByPtr.value),
      );
    } finally {
      calloc.free(snappedAxPtr);
      calloc.free(snappedAyPtr);
      calloc.free(snappedBxPtr);
      calloc.free(snappedByPtr);
      calloc.free(quadsPtr);
      calloc.free(quadCountPtr);
      calloc.free(textPtr);
    }
  }

  /// Extracts structured words with individual bounding boxes from the page.
  ///
  /// Useful for text-to-speech (TTS) synchronized highlighting and single-tap
  /// dictionary lookups.
  List<MuPdfWord> extractWords() {
    final wordsPtr = calloc<Pointer<mupdf_word_item>>();
    final countPtr = calloc<Int>();
    try {
      final rc = _lib.mupdf_page_extract_words(_ctx, _page, wordsPtr, countPtr);
      if (rc != 0) throw MuPdfException(_lastErrorCtx(_ctx));
      final count = countPtr.value;
      final rawWords = wordsPtr.value;
      if (rawWords == nullptr || count <= 0) return [];
      try {
        final result = <MuPdfWord>[];
        for (var i = 0; i < count; i++) {
          final item = rawWords[i];
          final text = item.text != nullptr
              ? item.text.cast<Utf8>().toDartString()
              : '';
          result.add(
            MuPdfWord(
              x0: item.x0,
              y0: item.y0,
              x1: item.x1,
              y1: item.y1,
              text: text,
            ),
          );
        }
        return result;
      } finally {
        _lib.mupdf_free_words(rawWords, count);
      }
    } finally {
      calloc.free(wordsPtr);
      calloc.free(countPtr);
    }
  }

  void dispose() {
    if (!_disposed) {
      _lib.mupdf_drop_page(_ctx, _page);
      _disposed = true;
    }
  }
}

RenderedPage _buildRenderedPage(mupdf_context ctx, mupdf_pixmap pix) {
  final w = _lib.mupdf_pixmap_width(ctx, pix);
  final h = _lib.mupdf_pixmap_height(ctx, pix);
  final stride = _lib.mupdf_pixmap_stride(ctx, pix);
  final components = _lib.mupdf_pixmap_components(ctx, pix);
  final samples = _lib.mupdf_pixmap_samples(ctx, pix);

  final totalBytes = h * stride;
  final pixels = (totalBytes > 0 && samples != nullptr)
      ? Uint8List.fromList(samples.cast<Uint8>().asTypedList(totalBytes))
      : Uint8List(0);
  return RenderedPage(
    width: w,
    height: h,
    stride: stride,
    components: components,
    pixels: pixels,
  );
}

String _lastErrorCtx(mupdf_context ctx) {
  final ptr = _lib.mupdf_last_error(ctx);
  return ptr == nullptr ? 'Unknown error' : ptr.cast<Utf8>().toDartString();
}

/// A rendered page with raw pixel data.
class RenderedPage {
  final int width;
  final int height;
  final int stride;
  final int components;
  final Uint8List pixels;

  const RenderedPage({
    required this.width,
    required this.height,
    required this.stride,
    required this.components,
    required this.pixels,
  });
}

/// Opens and manages a document (PDF, XPS, EPUB, etc.).
class MuPdfDocument {
  final mupdf_context _ctx;
  final mupdf_document _doc;
  final bool _isClone;
  bool _disposed = false;

  MuPdfDocument._(this._ctx, this._doc, {this._isClone = false});

  /// Open a document from a file path.
  factory MuPdfDocument.openFile(String path) {
    final ctx = _lib.mupdf_new_context();
    if (ctx == nullptr) throw MuPdfException('Failed to create MuPDF context');

    final pathPtr = path.toNativeUtf8();
    try {
      final doc = _lib.mupdf_open_document(ctx, pathPtr.cast<Char>());
      if (doc == nullptr) throw MuPdfException(_lastErrorCtx(ctx));
      return MuPdfDocument._(ctx, doc);
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// Open a document from raw bytes.
  factory MuPdfDocument.openBytes(Uint8List data) {
    final ctx = _lib.mupdf_new_context();
    if (ctx == nullptr) throw MuPdfException('Failed to create MuPDF context');

    final dataPtr = calloc.allocate<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    try {
      final doc = _lib.mupdf_open_document_from_data(
        ctx,
        dataPtr,
        data.length,
      );
      if (doc == nullptr) throw MuPdfException(_lastErrorCtx(ctx));
      return MuPdfDocument._(ctx, doc);
    } finally {
      calloc.free(dataPtr);
    }
  }

  /// Creates a thread-safe cloned document handle sharing the underlying Store (caching).
  /// Perfect for passing to background worker isolates.
  MuPdfDocument clone() {
    final clonedCtx = _lib.mupdf_clone_context(_ctx);
    if (clonedCtx == nullptr) throw MuPdfException('Failed to clone context');
    return MuPdfDocument._(clonedCtx, _doc, isClone: true);
  }

  int get pageCount {
    final count = _lib.mupdf_count_pages(_ctx, _doc);
    if (count < 0) throw MuPdfException(_lastError());
    return count;
  }

  bool get needsPassword => _lib.mupdf_needs_password(_ctx, _doc) != 0;

  bool authenticatePassword(String password) {
    final pwdPtr = password.toNativeUtf8();
    try {
      return _lib.mupdf_authenticate_password(
            _ctx,
            _doc,
            pwdPtr.cast<Char>(),
          ) !=
          0;
    } finally {
      calloc.free(pwdPtr);
    }
  }

  String? metadata(String key) {
    final keyPtr = key.toNativeUtf8();
    try {
      final len = _lib.mupdf_lookup_metadata(
        _ctx,
        _doc,
        keyPtr.cast<Char>(),
        nullptr,
        0,
      );
      if (len < 0) return null;

      final buf = calloc.allocate<Char>(len + 1);
      try {
        _lib.mupdf_lookup_metadata(
          _ctx,
          _doc,
          keyPtr.cast<Char>(),
          buf,
          len + 1,
        );
        return buf.cast<Utf8>().toDartString();
      } finally {
        calloc.free(buf);
      }
    } finally {
      calloc.free(keyPtr);
    }
  }

  /// Whether the document is reflowable (EPUB, FB2, etc.).
  bool get isReflowable {
    final result = _lib.mupdf_is_reflowable(_ctx, _doc);
    if (result < 0) throw MuPdfException(_lastError());
    return result != 0;
  }

  /// Recomputes layout for reflowable documents (EPUB, HTML, FB2).
  /// [width] and [height] are in points. [em] is font size in points.
  void layout({required double width, required double height, double em = 12.0}) {
    final rc = _lib.mupdf_layout_document(_ctx, _doc, width, height, em);
    if (rc != 0) throw MuPdfException(_lastError());
  }

  /// Styles reflowable documents (EPUB, HTML, FB2).
  /// [usePublisherCss]: whether to respect the book's embedded styles.
  /// [userCss]: custom CSS rules to apply (e.g. font-family, line-height, colors, margins).
  void style({bool usePublisherCss = true, String? userCss}) {
    final cssPtr = userCss != null ? userCss.toNativeUtf8() : nullptr;
    try {
      final rc = _lib.mupdf_style_document(
        _ctx,
        _doc,
        usePublisherCss ? 1 : 0,
        cssPtr != nullptr ? cssPtr.cast<Char>() : nullptr,
      );
      if (rc != 0) throw MuPdfException(_lastError());
    } finally {
      if (cssPtr != nullptr) calloc.free(cssPtr);
    }
  }

  /// Sets global user CSS stylesheet on the context for HTML/EPUB rendering.
  void setUserCss(String css) {
    final cssPtr = css.toNativeUtf8();
    try {
      _lib.mupdf_set_user_css(_ctx, cssPtr.cast<Char>());
    } finally {
      calloc.free(cssPtr);
    }
  }

  /// Number of chapters in the document.
  int get chapterCount {
    final count = _lib.mupdf_count_chapters(_ctx, _doc);
    if (count < 0) throw MuPdfException(_lastError());
    return count;
  }

  /// Number of pages in a specific chapter.
  int chapterPageCount(int chapter) {
    final count = _lib.mupdf_count_chapter_pages(_ctx, _doc, chapter);
    if (count < 0) throw MuPdfException(_lastError());
    return count;
  }

  /// Load a page by chapter and page number.
  MuPdfPage loadChapterPage(int chapter, int page) {
    final pg = _lib.mupdf_load_chapter_page(_ctx, _doc, chapter, page);
    if (pg == nullptr) throw MuPdfException(_lastError());
    return MuPdfPage._(_ctx, pg);
  }

  /// Creates an opaque bookmark identifying the current location in the document.
  ///
  /// For reflowable documents (EPUB, FB2, HTML), bookmarks remain valid across
  /// [layout] and [style] changes (font size, margin, orientation), allowing
  /// the reader position to be faithfully restored via [lookupBookmark].
  int makeBookmark(MuPdfLocation loc) {
    final mark = _lib.mupdf_make_bookmark(_ctx, _doc, loc.chapter, loc.page);
    if (mark == 0) throw MuPdfException(_lastError());
    return mark;
  }

  /// Looks up a previously created bookmark and returns its resolved location.
  ///
  /// For reflowable documents, this resolves the bookmark to the new chapter
  /// and page after [layout] or [style] changes.
  MuPdfLocation lookupBookmark(int bookmark) {
    final chapterPtr = calloc<Int>();
    final pagePtr = calloc<Int>();
    try {
      final rc = _lib.mupdf_lookup_bookmark(
        _ctx,
        _doc,
        bookmark,
        chapterPtr,
        pagePtr,
      );
      if (rc != 0) throw MuPdfException(_lastError());
      return MuPdfLocation(chapter: chapterPtr.value, page: pagePtr.value);
    } finally {
      calloc.free(chapterPtr);
      calloc.free(pagePtr);
    }
  }

  /// Converts an absolute (flat) page number to a chapter and page location.
  MuPdfLocation locationFromPage(int pageNumber) {
    final chapterPtr = calloc<Int>();
    final pagePtr = calloc<Int>();
    try {
      final rc = _lib.mupdf_location_from_page(
        _ctx,
        _doc,
        pageNumber,
        chapterPtr,
        pagePtr,
      );
      if (rc != 0) throw MuPdfException(_lastError());
      return MuPdfLocation(chapter: chapterPtr.value, page: pagePtr.value);
    } finally {
      calloc.free(chapterPtr);
      calloc.free(pagePtr);
    }
  }

  /// Converts a chapter and page location to an absolute (flat) page number.
  int pageFromLocation(MuPdfLocation loc) {
    final page = _lib.mupdf_page_from_location(
      _ctx,
      _doc,
      loc.chapter,
      loc.page,
    );
    if (page < 0) throw MuPdfException(_lastError());
    return page;
  }

  /// Check if the document grants a specific permission.
  /// Use [permPrint], [permCopy], [permEdit], [permAnnotate].
  bool hasPermission(int permission) {
    final result = _lib.mupdf_has_permission(_ctx, _doc, permission);
    if (result < 0) throw MuPdfException(_lastError());
    return result != 0;
  }

  /// Get the flattened outline (table of contents).
  List<OutlineItem> get outline {
    final itemsPtr = calloc<Pointer<mupdf_outline_item>>();
    try {
      final count = _lib.mupdf_outline_flatten(_ctx, _doc, itemsPtr);
      if (count <= 0) return [];
      final items = itemsPtr.value;
      if (items == nullptr) return [];
      try {
        final result = <OutlineItem>[];
        for (var i = 0; i < count; i++) {
          final item = items[i];
          int flatPage = -1;
          if (item.uri.address != 0) {
            flatPage = _lib.mupdf_resolve_uri(_ctx, _doc, item.uri);
          }
          if (flatPage < 0) {
            flatPage = item.page >= 0 ? item.page : 0;
          }
          result.add(
            OutlineItem(
              title: item.title.address != 0
                  ? item.title.cast<Utf8>().toDartString()
                  : null,
              uri: item.uri.address != 0
                  ? item.uri.cast<Utf8>().toDartString()
                  : null,
              chapter: item.chapter,
              page: flatPage >= 0 ? flatPage : 0,
              level: item.level,
              isOpen: item.is_open != 0,
            ),
          );
        }
        return result;
      } finally {
        _lib.mupdf_outline_free(items, count);
      }
    } finally {
      calloc.free(itemsPtr);
    }
  }

  MuPdfPage loadPage(int number) {
    final page = _lib.mupdf_load_page(_ctx, _doc, number);
    if (page == nullptr) throw MuPdfException(_lastError());
    return MuPdfPage._(_ctx, page);
  }

  /// Loads the interactive links of page [number], resolving internal
  /// destinations to flat page numbers with full native exception safety.
  List<PageLink> pageLinks(int number) {
    final page = loadPage(number);
    try {
      final linksPtr = calloc<Pointer<mupdf_link_item>>();
      try {
        final count = _lib.mupdf_page_links(_ctx, _doc, page._page, linksPtr);
        if (count <= 0) return [];
        final items = linksPtr.value;
        if (items == nullptr) return [];
        try {
          final result = <PageLink>[];
          for (var i = 0; i < count; i++) {
            final item = items[i];
            final uri = item.uri.address != 0
                ? item.uri.cast<Utf8>().toDartString()
                : '';
            result.add(
              PageLink(
                x0: item.x0,
                y0: item.y0,
                x1: item.x1,
                y1: item.y1,
                uri: uri,
                pageNumber: item.page_number,
              ),
            );
          }
          return result;
        } finally {
          _lib.mupdf_free_links(items, count);
        }
      } finally {
        calloc.free(linksPtr);
      }
    } finally {
      page.dispose();
    }
  }

  /// Resolves an internal destination URI (e.g. from an EPUB table of contents or anchor)
  /// to a flat page index. Returns -1 if the URI is external or could not be resolved.
  int resolveUri(String uri) {
    if (uri.isEmpty) return -1;
    final uriNative = uri.toNativeUtf8();
    try {
      return _lib.mupdf_resolve_uri(_ctx, _doc, uriNative.cast<Char>());
    } finally {
      calloc.free(uriNative);
    }
  }

  void dispose() {
    if (!_disposed) {
      if (!_isClone) {
        _lib.mupdf_drop_document(_ctx, _doc);
      }
      _lib.mupdf_drop_context(_ctx);
      _disposed = true;
    }
  }

  String _lastError() => _lastErrorCtx(_ctx);
}

class MuPdfException implements Exception {
  final String message;
  MuPdfException(this.message);
  @override
  String toString() => 'MuPdfException: $message';
}

// --- Lazy-loaded bindings ---

final DynamicLibrary _dylib = openMupdfLib();
final MupdfBindings _lib = MupdfBindings(_dylib);
