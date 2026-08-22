import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/mupdf_bindings_generated.dart';
import 'src/library.dart';

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
    required this.ulX, required this.ulY,
    required this.urX, required this.urY,
    required this.llX, required this.llY,
    required this.lrX, required this.lrY,
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
    required this.x0, required this.y0,
    required this.x1, required this.y1,
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

typedef FzLoadLinksNative = Pointer<FzLink> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);
typedef FzLoadLinksDart = Pointer<FzLink> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);

typedef FzDropLinkNative = Void Function(
    Pointer<MupdfContext>, Pointer<FzLink>);
typedef FzDropLinkDart = void Function(
    Pointer<MupdfContext>, Pointer<FzLink>);

typedef FzResolveLinkNative = FzLocation Function(
    Pointer<MupdfContext>,
    Pointer<MupdfDocument>,
    Pointer<Utf8>,
    Pointer<Float>,
    Pointer<Float>);
typedef FzResolveLinkDart = FzLocation Function(
    Pointer<MupdfContext>,
    Pointer<MupdfDocument>,
    Pointer<Utf8>,
    Pointer<Float>,
    Pointer<Float>);

typedef FzPageNumberFromLocationNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, FzLocation);
typedef FzPageNumberFromLocationDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, FzLocation);

typedef FzIsExternalLinkNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<Utf8>);
typedef FzIsExternalLinkDart = int Function(
    Pointer<MupdfContext>, Pointer<Utf8>);

/// The wrapper hands out handles to
/// `struct mupdf_context_s { fz_context* ctx; char last_error[256]; }`;
/// direct fz_* calls need the inner fz_context*, not the handle.
final class MupdfContextHandle extends Struct {
  external Pointer<MupdfContext> inner;
}

/// Renders a document page to raw pixel data via MuPDF.
class MuPdfPage {
  final Pointer<MupdfContext> _ctx;
  final Pointer<MupdfPage> _page;

  MuPdfPage._(this._ctx, this._page);

  Pointer<MupdfPage> get pointer => _page;

  double get width => _lib.mupdfPageWidth(_ctx, _page);
  double get height => _lib.mupdfPageHeight(_ctx, _page);

  /// Returns width and height in a single native call.
  PageBoundBox get boundBox {
    final wPtr = calloc<Float>();
    final hPtr = calloc<Float>();
    try {
      final rc = _lib.mupdfPageBoundBox(_ctx, _page, wPtr, hPtr);
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
    final pix = _lib.mupdfNewPixmapFromPageCs(
        _ctx, _page, scaleX, scaleY, alpha ? 1 : 0, cs);
    if (pix == nullptr) throw MuPdfException(_lastErrorCtx(_ctx));

    try {
      final w = _lib.mupdfPixmapWidth(_ctx, pix);
      final h = _lib.mupdfPixmapHeight(_ctx, pix);
      final stride = _lib.mupdfPixmapStride(_ctx, pix);
      final components = _lib.mupdfPixmapComponents(_ctx, pix);
      final samples = _lib.mupdfPixmapSamples(_ctx, pix);

      final totalBytes = h * stride;
      final pixels = (totalBytes > 0 && samples != nullptr)
          ? Uint8List.fromList(samples.asTypedList(totalBytes))
          : Uint8List(0);
      return RenderedPage(
        width: w,
        height: h,
        stride: stride,
        components: components,
        pixels: pixels,
      );
    } finally {
      _lib.mupdfDropPixmap(_ctx, pix);
    }
  }

  /// Extract plain text from the page.
  String? extractText() {
    final ptr = _lib.mupdfExtractText(_ctx, _page);
    if (ptr == nullptr) return null;
    try {
      return ptr.cast<Utf8>().toDartString();
    } finally {
      _lib.mupdfFreeString(_ctx, ptr);
    }
  }

  /// Extract HTML from the page.
  String? extractHtml() {
    final ptr = _lib.mupdfExtractHtml(_ctx, _page);
    if (ptr == nullptr) return null;
    try {
      return ptr.cast<Utf8>().toDartString();
    } finally {
      _lib.mupdfFreeString(_ctx, ptr);
    }
  }

  /// Get the page label (e.g. "iv", "12").
  String? get label {
    final buf = calloc.allocate<Uint8>(64);
    try {
      final len = _lib.mupdfPageLabel(_ctx, _page, buf, 64);
      if (len < 0) return null;
      return buf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buf);
    }
  }

  /// Search the page and return hit bounding quads.
  List<SearchHit> searchQuads(String needle) {
    final needlePtr = needle.toNativeUtf8();
    final countPtr = calloc<Int32>();
    try {
      final ptr = _lib.mupdfSearchPageQuads(_ctx, _page, needlePtr, countPtr);
      final count = countPtr.value;
      if (ptr == nullptr || count <= 0) return [];
      try {
        final hits = <SearchHit>[];
        for (var i = 0; i < count; i++) {
          final off = i * 8;
          hits.add(SearchHit(
            ulX: ptr[off], ulY: ptr[off + 1],
            urX: ptr[off + 2], urY: ptr[off + 3],
            llX: ptr[off + 4], llY: ptr[off + 5],
            lrX: ptr[off + 6], lrY: ptr[off + 7],
          ));
        }
        return hits;
      } finally {
        _lib.mupdfFreeFloats(ptr);
      }
    } finally {
      calloc.free(needlePtr);
      calloc.free(countPtr);
    }
  }

  void dispose() {
    _lib.mupdfDropPage(_ctx, _page);
  }
}

String _lastErrorCtx(Pointer<MupdfContext> ctx) {
  final ptr = _lib.mupdfLastError(ctx);
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
  final Pointer<MupdfContext> _ctx;
  final Pointer<MupdfDocument> _doc;

  MuPdfDocument._(this._ctx, this._doc);

  /// Open a document from a file path.
  factory MuPdfDocument.openFile(String path) {
    final ctx = _lib.mupdfNewContext();
    if (ctx == nullptr) throw MuPdfException('Failed to create MuPDF context');

    final pathPtr = path.toNativeUtf8();
    try {
      final doc = _lib.mupdfOpenDocument(ctx, pathPtr);
      if (doc == nullptr) throw MuPdfException(_lastErrorCtx(ctx));
      return MuPdfDocument._(ctx, doc);
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// Open a document from raw bytes.
  factory MuPdfDocument.openBytes(Uint8List data) {
    final ctx = _lib.mupdfNewContext();
    if (ctx == nullptr) throw MuPdfException('Failed to create MuPDF context');

    final dataPtr = calloc.allocate<Uint8>(data.length);
    dataPtr.asTypedList(data.length).setAll(0, data);
    try {
      final doc = _lib.mupdfOpenDocumentFromData(ctx, dataPtr, data.length);
      if (doc == nullptr) throw MuPdfException(_lastErrorCtx(ctx));
      return MuPdfDocument._(ctx, doc);
    } finally {
      calloc.free(dataPtr);
    }
  }

  int get pageCount {
    final count = _lib.mupdfCountPages(_ctx, _doc);
    if (count < 0) throw MuPdfException(_lastError());
    return count;
  }

  bool get needsPassword => _lib.mupdfNeedsPassword(_ctx, _doc) != 0;

  bool authenticatePassword(String password) {
    final pwdPtr = password.toNativeUtf8();
    try {
      return _lib.mupdfAuthenticatePassword(_ctx, _doc, pwdPtr) != 0;
    } finally {
      calloc.free(pwdPtr);
    }
  }

  String? metadata(String key) {
    final keyPtr = key.toNativeUtf8();
    try {
      final len = _lib.mupdfLookupMetadata(_ctx, _doc, keyPtr, nullptr, 0);
      if (len < 0) return null;

      final buf = calloc.allocate<Uint8>(len + 1);
      try {
        _lib.mupdfLookupMetadata(_ctx, _doc, keyPtr, buf, len + 1);
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
    final result = _lib.mupdfIsReflowable(_ctx, _doc);
    if (result < 0) throw MuPdfException(_lastError());
    return result != 0;
  }

  /// Number of chapters in the document.
  int get chapterCount {
    final count = _lib.mupdfCountChapters(_ctx, _doc);
    if (count < 0) throw MuPdfException(_lastError());
    return count;
  }

  /// Number of pages in a specific chapter.
  int chapterPageCount(int chapter) {
    final count = _lib.mupdfCountChapterPages(_ctx, _doc, chapter);
    if (count < 0) throw MuPdfException(_lastError());
    return count;
  }

  /// Load a page by chapter and page number.
  MuPdfPage loadChapterPage(int chapter, int page) {
    final pg = _lib.mupdfLoadChapterPage(_ctx, _doc, chapter, page);
    if (pg == nullptr) throw MuPdfException(_lastError());
    return MuPdfPage._(_ctx, pg);
  }

  /// Check if the document grants a specific permission.
  /// Use [permPrint], [permCopy], [permEdit], [permAnnotate].
  bool hasPermission(int permission) {
    final result = _lib.mupdfHasPermission(_ctx, _doc, permission);
    if (result < 0) throw MuPdfException(_lastError());
    return result != 0;
  }

  /// Get the flattened outline (table of contents).
  List<OutlineItem> get outline {
    final itemsPtr = calloc<Pointer<MupdfOutlineItem>>();
    try {
      final count = _lib.mupdfOutlineFlatten(_ctx, _doc, itemsPtr);
      if (count <= 0) return [];
      final items = itemsPtr.value;
      if (items == nullptr) return [];
      try {
        final result = <OutlineItem>[];
        for (var i = 0; i < count; i++) {
          final item = items[i];
          result.add(OutlineItem(
            title: item.title.address != 0
                ? item.title.cast<Utf8>().toDartString()
                : null,
            uri: item.uri.address != 0
                ? item.uri.cast<Utf8>().toDartString()
                : null,
            chapter: item.chapter,
            page: item.page,
            level: item.level,
            isOpen: item.isOpen != 0,
          ));
        }
        return result;
      } finally {
        _lib.mupdfOutlineFree(items, count);
      }
    } finally {
      calloc.free(itemsPtr);
    }
  }

  MuPdfPage loadPage(int number) {
    final page = _lib.mupdfLoadPage(_ctx, _doc, number);
    if (page == nullptr) throw MuPdfException(_lastError());
    return MuPdfPage._(_ctx, page);
  }

  /// Loads the interactive links of page [number], resolving internal
  /// destinations to flat page numbers.
  List<PageLink> pageLinks(int number) {
    final page = loadPage(number);
    try {
      final ctx = _ctx.cast<MupdfContextHandle>().ref.inner;
      final head = _lib.fzLoadLinks(ctx, page._page);
      if (head == nullptr) return [];
      try {
        final result = <PageLink>[];
        for (var ptr = head; ptr != nullptr; ptr = ptr.ref.next) {
          final link = ptr.ref;
          final uriPtr = link.uri;
          final uri =
              uriPtr == nullptr ? '' : uriPtr.cast<Utf8>().toDartString();
          var pageNumber = -1;
          if (uri.isNotEmpty && _lib.fzIsExternalLink(ctx, uriPtr) == 0) {
            final loc = _lib.fzResolveLink(ctx, _doc, uriPtr, nullptr, nullptr);
            if (loc.page >= 0) {
              pageNumber = _lib.fzPageNumberFromLocation(ctx, _doc, loc);
            }
          }
          result.add(PageLink(
            x0: link.rect.x0,
            y0: link.rect.y0,
            x1: link.rect.x1,
            y1: link.rect.y1,
            uri: uri,
            pageNumber: pageNumber,
          ));
        }
        return result;
      } finally {
        _lib.fzDropLink(ctx, head);
      }
    } finally {
      page.dispose();
    }
  }

  void dispose() {
    _lib.mupdfDropDocument(_ctx, _doc);
    _lib.mupdfDropContext(_ctx);
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

// ignore_for_file: unnecessary_late
late final _MupdfBindings _lib = _MupdfBindings();

class _MupdfBindings {
  late final MupdfNewContextDart mupdfNewContext;
  late final MupdfDropContextDart mupdfDropContext;
  late final MupdfOpenDocumentDart mupdfOpenDocument;
  late final MupdfOpenDocumentFromDataDart mupdfOpenDocumentFromData;
  late final MupdfDropDocumentDart mupdfDropDocument;
  late final MupdfNeedsPasswordDart mupdfNeedsPassword;
  late final MupdfAuthenticatePasswordDart mupdfAuthenticatePassword;
  late final MupdfCountPagesDart mupdfCountPages;
  late final MupdfLookupMetadataDart mupdfLookupMetadata;
  late final MupdfLayoutDocumentDart mupdfLayoutDocument;
  late final MupdfIsReflowableDart mupdfIsReflowable;
  late final MupdfCountChaptersDart mupdfCountChapters;
  late final MupdfCountChapterPagesDart mupdfCountChapterPages;
  late final MupdfLoadChapterPageDart mupdfLoadChapterPage;
  late final MupdfLoadPageDart mupdfLoadPage;
  late final MupdfDropPageDart mupdfDropPage;
  late final MupdfPageWidthDart mupdfPageWidth;
  late final MupdfPageHeightDart mupdfPageHeight;
  late final MupdfPageBoundBoxDart mupdfPageBoundBox;
  late final MupdfHasPermissionDart mupdfHasPermission;
  late final MupdfPageLabelDart mupdfPageLabel;
  late final MupdfNewPixmapFromPageDart mupdfNewPixmapFromPage;
  late final MupdfNewPixmapFromPageCsDart mupdfNewPixmapFromPageCs;
  late final MupdfDropPixmapDart mupdfDropPixmap;
  late final MupdfPixmapWidthDart mupdfPixmapWidth;
  late final MupdfPixmapHeightDart mupdfPixmapHeight;
  late final MupdfPixmapStrideDart mupdfPixmapStride;
  late final MupdfPixmapComponentsDart mupdfPixmapComponents;
  late final MupdfPixmapSamplesDart mupdfPixmapSamples;
  late final MupdfExtractTextDart mupdfExtractText;
  late final MupdfExtractHtmlDart mupdfExtractHtml;
  late final MupdfFreeStringDart mupdfFreeString;
  late final MupdfSearchPageDart mupdfSearchPage;
  late final MupdfSearchPageQuadsDart mupdfSearchPageQuads;
  late final MupdfFreeFloatsDart mupdfFreeFloats;
  late final MupdfOutlineFlattenDart mupdfOutlineFlatten;
  late final MupdfOutlineFreeDart mupdfOutlineFree;
  late final MupdfLastErrorDart mupdfLastError;

  // Direct MuPDF C API (symbols kept alive by --whole-archive linking).
  late final FzLoadLinksDart fzLoadLinks;
  late final FzDropLinkDart fzDropLink;
  late final FzResolveLinkDart fzResolveLink;
  late final FzPageNumberFromLocationDart fzPageNumberFromLocation;
  late final FzIsExternalLinkDart fzIsExternalLink;

  _MupdfBindings() {
    final dylib = openMupdfLib();

    mupdfNewContext = dylib.lookupFunction<MupdfNewContextNative, MupdfNewContextDart>('mupdf_new_context');
    mupdfDropContext = dylib.lookupFunction<MupdfDropContextNative, MupdfDropContextDart>('mupdf_drop_context');
    mupdfOpenDocument = dylib.lookupFunction<MupdfOpenDocumentNative, MupdfOpenDocumentDart>('mupdf_open_document');
    mupdfOpenDocumentFromData = dylib.lookupFunction<MupdfOpenDocumentFromDataNative, MupdfOpenDocumentFromDataDart>('mupdf_open_document_from_data');
    mupdfDropDocument = dylib.lookupFunction<MupdfDropDocumentNative, MupdfDropDocumentDart>('mupdf_drop_document');
    mupdfNeedsPassword = dylib.lookupFunction<MupdfNeedsPasswordNative, MupdfNeedsPasswordDart>('mupdf_needs_password');
    mupdfAuthenticatePassword = dylib.lookupFunction<MupdfAuthenticatePasswordNative, MupdfAuthenticatePasswordDart>('mupdf_authenticate_password');
    mupdfCountPages = dylib.lookupFunction<MupdfCountPagesNative, MupdfCountPagesDart>('mupdf_count_pages');
    mupdfLookupMetadata = dylib.lookupFunction<MupdfLookupMetadataNative, MupdfLookupMetadataDart>('mupdf_lookup_metadata');
    mupdfLayoutDocument = dylib.lookupFunction<MupdfLayoutDocumentNative, MupdfLayoutDocumentDart>('mupdf_layout_document');
    mupdfIsReflowable = dylib.lookupFunction<MupdfIsReflowableNative, MupdfIsReflowableDart>('mupdf_is_reflowable');
    mupdfCountChapters = dylib.lookupFunction<MupdfCountChaptersNative, MupdfCountChaptersDart>('mupdf_count_chapters');
    mupdfCountChapterPages = dylib.lookupFunction<MupdfCountChapterPagesNative, MupdfCountChapterPagesDart>('mupdf_count_chapter_pages');
    mupdfLoadChapterPage = dylib.lookupFunction<MupdfLoadChapterPageNative, MupdfLoadChapterPageDart>('mupdf_load_chapter_page');
    mupdfLoadPage = dylib.lookupFunction<MupdfLoadPageNative, MupdfLoadPageDart>('mupdf_load_page');
    mupdfDropPage = dylib.lookupFunction<MupdfDropPageNative, MupdfDropPageDart>('mupdf_drop_page');
    mupdfPageWidth = dylib.lookupFunction<MupdfPageWidthNative, MupdfPageWidthDart>('mupdf_page_width');
    mupdfPageHeight = dylib.lookupFunction<MupdfPageHeightNative, MupdfPageHeightDart>('mupdf_page_height');
    mupdfPageBoundBox = dylib.lookupFunction<MupdfPageBoundBoxNative, MupdfPageBoundBoxDart>('mupdf_page_bound_box');
    mupdfHasPermission = dylib.lookupFunction<MupdfHasPermissionNative, MupdfHasPermissionDart>('mupdf_has_permission');
    mupdfPageLabel = dylib.lookupFunction<MupdfPageLabelNative, MupdfPageLabelDart>('mupdf_page_label');
    mupdfNewPixmapFromPage = dylib.lookupFunction<MupdfNewPixmapFromPageNative, MupdfNewPixmapFromPageDart>('mupdf_new_pixmap_from_page');
    mupdfNewPixmapFromPageCs = dylib.lookupFunction<MupdfNewPixmapFromPageCsNative, MupdfNewPixmapFromPageCsDart>('mupdf_new_pixmap_from_page_cs');
    mupdfDropPixmap = dylib.lookupFunction<MupdfDropPixmapNative, MupdfDropPixmapDart>('mupdf_drop_pixmap');
    mupdfPixmapWidth = dylib.lookupFunction<MupdfPixmapWidthNative, MupdfPixmapWidthDart>('mupdf_pixmap_width');
    mupdfPixmapHeight = dylib.lookupFunction<MupdfPixmapHeightNative, MupdfPixmapHeightDart>('mupdf_pixmap_height');
    mupdfPixmapStride = dylib.lookupFunction<MupdfPixmapStrideNative, MupdfPixmapStrideDart>('mupdf_pixmap_stride');
    mupdfPixmapComponents = dylib.lookupFunction<MupdfPixmapComponentsNative, MupdfPixmapComponentsDart>('mupdf_pixmap_components');
    mupdfPixmapSamples = dylib.lookupFunction<MupdfPixmapSamplesNative, MupdfPixmapSamplesDart>('mupdf_pixmap_samples');
    mupdfExtractText = dylib.lookupFunction<MupdfExtractTextNative, MupdfExtractTextDart>('mupdf_extract_text');
    mupdfExtractHtml = dylib.lookupFunction<MupdfExtractHtmlNative, MupdfExtractHtmlDart>('mupdf_extract_html');
    mupdfFreeString = dylib.lookupFunction<MupdfFreeStringNative, MupdfFreeStringDart>('mupdf_free_string');
    mupdfSearchPage = dylib.lookupFunction<MupdfSearchPageNative, MupdfSearchPageDart>('mupdf_search_page');
    mupdfSearchPageQuads = dylib.lookupFunction<MupdfSearchPageQuadsNative, MupdfSearchPageQuadsDart>('mupdf_search_page_quads');
    mupdfFreeFloats = dylib.lookupFunction<MupdfFreeFloatsNative, MupdfFreeFloatsDart>('mupdf_free_floats');
    mupdfOutlineFlatten = dylib.lookupFunction<MupdfOutlineFlattenNative, MupdfOutlineFlattenDart>('mupdf_outline_flatten');
    mupdfOutlineFree = dylib.lookupFunction<MupdfOutlineFreeNative, MupdfOutlineFreeDart>('mupdf_outline_free');
    mupdfLastError = dylib.lookupFunction<MupdfLastErrorNative, MupdfLastErrorDart>('mupdf_last_error');

    fzLoadLinks = dylib.lookupFunction<FzLoadLinksNative, FzLoadLinksDart>('fz_load_links');
    fzDropLink = dylib.lookupFunction<FzDropLinkNative, FzDropLinkDart>('fz_drop_link');
    fzResolveLink = dylib.lookupFunction<FzResolveLinkNative, FzResolveLinkDart>('fz_resolve_link');
    fzPageNumberFromLocation = dylib.lookupFunction<FzPageNumberFromLocationNative, FzPageNumberFromLocationDart>('fz_page_number_from_location');
    fzIsExternalLink = dylib.lookupFunction<FzIsExternalLinkNative, FzIsExternalLinkDart>('fz_is_external_link');
  }
}
