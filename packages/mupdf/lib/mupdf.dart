import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/library.dart';
import 'src/mupdf_bindings_generated.dart';

/// Colorspace constants for [MuPdfPage.render].
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

// --- Direct MuPDF link access ---
//
// The wrapper links libmupdf.a with --whole-archive, so MuPDF's own C API
// stays exported from libmupdf_wrapper.so. Link extraction needs no glue
// code: these hand-written bindings call fz_load_links & friends directly.

final class FzRect extends Struct {
  @Float()
  external double x0;
  @Float()
  external double y0;
  @Float()
  external double x1;
  @Float()
  external double y1;
}

/// Mirrors fz_link; trailing callback members omitted (never read here and
/// they sit after every field we need).
final class FzLink extends Struct {
  @Int()
  external int refs;

  external Pointer<FzLink> next;

  external FzRect rect;

  external Pointer<Utf8> uri;
}

/// Mirrors fz_location (returned/passed by value).
final class FzLocation extends Struct {
  @Int32()
  external int chapter;
  @Int32()
  external int page;
}

typedef FzLoadLinksNative = Pointer<FzLink> Function(mupdf_context, mupdf_page);
typedef FzLoadLinksDart = Pointer<FzLink> Function(mupdf_context, mupdf_page);

typedef FzDropLinkNative = Void Function(mupdf_context, Pointer<FzLink>);
typedef FzDropLinkDart = void Function(mupdf_context, Pointer<FzLink>);

typedef FzResolveLinkNative =
    FzLocation Function(
      mupdf_context,
      mupdf_document,
      Pointer<Utf8>,
      Pointer<Float>,
      Pointer<Float>,
    );
typedef FzResolveLinkDart =
    FzLocation Function(
      mupdf_context,
      mupdf_document,
      Pointer<Utf8>,
      Pointer<Float>,
      Pointer<Float>,
    );

typedef FzPageNumberFromLocationNative =
    Int32 Function(mupdf_context, mupdf_document, FzLocation);
typedef FzPageNumberFromLocationDart =
    int Function(mupdf_context, mupdf_document, FzLocation);

typedef FzIsExternalLinkNative = Int32 Function(mupdf_context, Pointer<Utf8>);
typedef FzIsExternalLinkDart = int Function(mupdf_context, Pointer<Utf8>);

/// The wrapper hands out handles to
/// `struct mupdf_context_s { fz_context* ctx; char last_error[256]; }`;
/// direct fz_* calls need the inner fz_context*, not the handle.
final class MupdfContextHandle extends Struct {
  external mupdf_context inner;
}

/// Renders a document page to raw pixel data via MuPDF.
class MuPdfPage {
  final mupdf_context _ctx;
  final mupdf_page _page;

  MuPdfPage._(this._ctx, this._page);

  mupdf_page get pointer => _page;

  double get width => _lib.mupdf_page_width(_ctx, _page);
  double get height => _lib.mupdf_page_height(_ctx, _page);

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

  /// Render the page at the given scale. Returns RGBA pixel data.
  ///
  /// [cs] selects the output colorspace: [csRgb], [csGray], or [csCmyk].
  RenderedPage render({
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool alpha = false,
    int cs = csRgb,
  }) {
    final pix = _lib.mupdf_new_pixmap_from_page_cs(
      _ctx,
      _page,
      scaleX,
      scaleY,
      alpha ? 1 : 0,
      cs,
    );
    if (pix == nullptr) throw MuPdfException(_lastErrorCtx(_ctx));

    try {
      final w = _lib.mupdf_pixmap_width(_ctx, pix);
      final h = _lib.mupdf_pixmap_height(_ctx, pix);
      final stride = _lib.mupdf_pixmap_stride(_ctx, pix);
      final components = _lib.mupdf_pixmap_components(_ctx, pix);
      final samples = _lib.mupdf_pixmap_samples(_ctx, pix);

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
  String? extractHtml() {
    final ptr = _lib.mupdf_extract_html(_ctx, _page);
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

  void dispose() {
    _lib.mupdf_drop_page(_ctx, _page);
  }
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

  MuPdfDocument._(this._ctx, this._doc);

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
        final ctxInner = _ctx.cast<MupdfContextHandle>().ref.inner;
        for (var i = 0; i < count; i++) {
          final item = items[i];
          int flatPage = -1;
          // EPUB/reflowable outlines often carry chapter-relative or empty
          // page numbers. Resolve the item's URI to obtain the real location,
          // then flatten it to a page index (matches MuPDF's Java/WASM viewers).
          if (item.uri.address != 0) {
            final uriStr = item.uri.cast<Utf8>().toDartString();
            final uriNative = uriStr.toNativeUtf8();
            final xPtr = calloc<Float>();
            final yPtr = calloc<Float>();
            try {
              final loc = fzResolveLink(
                ctxInner,
                _doc,
                uriNative,
                xPtr,
                yPtr,
              );
              if (loc.page >= 0) {
                flatPage = fzPageNumberFromLocation(ctxInner, _doc, loc);
              }
            } finally {
              calloc.free(xPtr);
              calloc.free(yPtr);
              calloc.free(uriNative);
            }
          }
          // Fallback: convert chapter/page directly (PDF/XPS).
          if (flatPage < 0) {
            final loc = calloc<FzLocation>();
            loc.ref.chapter = item.chapter;
            loc.ref.page = item.page;
            flatPage = fzPageNumberFromLocation(ctxInner, _doc, loc.ref);
            calloc.free(loc);
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
  /// destinations to flat page numbers.
  List<PageLink> pageLinks(int number) {
    final page = loadPage(number);
    try {
      final ctx = _ctx.cast<MupdfContextHandle>().ref.inner;
      final head = fzLoadLinks(ctx, page._page);
      if (head == nullptr) return [];
      try {
        final result = <PageLink>[];
        for (var ptr = head; ptr != nullptr; ptr = ptr.ref.next) {
          final link = ptr.ref;
          final uriPtr = link.uri;
          final uri = uriPtr == nullptr
              ? ''
              : uriPtr.cast<Utf8>().toDartString();
          var pageNumber = -1;
          if (uri.isNotEmpty && fzIsExternalLink(ctx, uriPtr) == 0) {
            final loc = fzResolveLink(ctx, _doc, uriPtr, nullptr, nullptr);
            if (loc.page >= 0) {
              pageNumber = fzPageNumberFromLocation(ctx, _doc, loc);
            }
          }
          result.add(
            PageLink(
              x0: link.rect.x0,
              y0: link.rect.y0,
              x1: link.rect.x1,
              y1: link.rect.y1,
              uri: uri,
              pageNumber: pageNumber,
            ),
          );
        }
        return result;
      } finally {
        fzDropLink(ctx, head);
      }
    } finally {
      page.dispose();
    }
  }

  void dispose() {
    _lib.mupdf_drop_document(_ctx, _doc);
    _lib.mupdf_drop_context(_ctx);
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

// Direct MuPDF C API (symbols kept alive by --whole-archive linking).
final FzLoadLinksDart fzLoadLinks = _dylib
    .lookupFunction<FzLoadLinksNative, FzLoadLinksDart>('fz_load_links');
final FzDropLinkDart fzDropLink = _dylib
    .lookupFunction<FzDropLinkNative, FzDropLinkDart>('fz_drop_link');
final FzResolveLinkDart fzResolveLink = _dylib
    .lookupFunction<FzResolveLinkNative, FzResolveLinkDart>(
      'fz_resolve_link',
    );
final FzPageNumberFromLocationDart fzPageNumberFromLocation = _dylib
    .lookupFunction<
      FzPageNumberFromLocationNative,
      FzPageNumberFromLocationDart
    >('fz_page_number_from_location');
final FzIsExternalLinkDart fzIsExternalLink = _dylib
    .lookupFunction<FzIsExternalLinkNative, FzIsExternalLinkDart>(
      'fz_is_external_link',
    );
