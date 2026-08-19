// AUTO-GENERATED — matches mupdf_wrapper.h
// ignore_for_file: type=lint, unused_element

import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class MupdfContext extends Opaque {}

final class MupdfDocument extends Opaque {}

final class MupdfPage extends Opaque {}

final class MupdfPixmap extends Opaque {}

final class MupdfOutlineItem extends Struct {
  external Pointer<Utf8> title;
  external Pointer<Utf8> uri;
  @Int32()
  external int chapter;
  @Int32()
  external int page;
  @Int32()
  external int level;
  @Int32()
  external int isOpen;
}

// Context
typedef MupdfNewContextNative = Pointer<MupdfContext> Function();
typedef MupdfNewContextDart = Pointer<MupdfContext> Function();

typedef MupdfDropContextNative = Void Function(Pointer<MupdfContext>);
typedef MupdfDropContextDart = void Function(Pointer<MupdfContext>);

// Document
typedef MupdfOpenDocumentNative = Pointer<MupdfDocument> Function(
    Pointer<MupdfContext>, Pointer<Utf8>);
typedef MupdfOpenDocumentDart = Pointer<MupdfDocument> Function(
    Pointer<MupdfContext>, Pointer<Utf8>);

typedef MupdfOpenDocumentFromDataNative = Pointer<MupdfDocument> Function(
    Pointer<MupdfContext>, Pointer<Uint8>, Int64);
typedef MupdfOpenDocumentFromDataDart = Pointer<MupdfDocument> Function(
    Pointer<MupdfContext>, Pointer<Uint8>, int);

typedef MupdfDropDocumentNative = Void Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);
typedef MupdfDropDocumentDart = void Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);

typedef MupdfNeedsPasswordNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);
typedef MupdfNeedsPasswordDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);

typedef MupdfAuthenticatePasswordNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, Pointer<Utf8>);
typedef MupdfAuthenticatePasswordDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, Pointer<Utf8>);

typedef MupdfCountPagesNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);
typedef MupdfCountPagesDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);

typedef MupdfLookupMetadataNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>,
    Pointer<Utf8>, Pointer<Uint8>, Int32);
typedef MupdfLookupMetadataDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>,
    Pointer<Utf8>, Pointer<Uint8>, int);

typedef MupdfLayoutDocumentNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>,
    Float, Float, Float);
typedef MupdfLayoutDocumentDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>,
    double, double, double);

typedef MupdfIsReflowableNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);
typedef MupdfIsReflowableDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);

typedef MupdfCountChaptersNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);
typedef MupdfCountChaptersDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>);

typedef MupdfCountChapterPagesNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, Int32);
typedef MupdfCountChapterPagesDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, int);

typedef MupdfLoadChapterPageNative = Pointer<MupdfPage> Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, Int32, Int32);
typedef MupdfLoadChapterPageDart = Pointer<MupdfPage> Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, int, int);

// Page
typedef MupdfLoadPageNative = Pointer<MupdfPage> Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, Int32);
typedef MupdfLoadPageDart = Pointer<MupdfPage> Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, int);

typedef MupdfDropPageNative = Void Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);
typedef MupdfDropPageDart = void Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);

typedef MupdfPageWidthNative = Float Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);
typedef MupdfPageWidthDart = double Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);

typedef MupdfPageHeightNative = Float Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);
typedef MupdfPageHeightDart = double Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);

typedef MupdfPageBoundBoxNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Float>, Pointer<Float>);
typedef MupdfPageBoundBoxDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Float>, Pointer<Float>);

typedef MupdfHasPermissionNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, Int32);
typedef MupdfHasPermissionDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>, int);

typedef MupdfPageLabelNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Uint8>, Int32);
typedef MupdfPageLabelDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Uint8>, int);

// Pixmap
typedef MupdfNewPixmapFromPageNative = Pointer<MupdfPixmap> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>, Float, Float, Int32);
typedef MupdfNewPixmapFromPageDart = Pointer<MupdfPixmap> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>, double, double, int);

typedef MupdfNewPixmapFromPageCsNative = Pointer<MupdfPixmap> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>, Float, Float, Int32, Int32);
typedef MupdfNewPixmapFromPageCsDart = Pointer<MupdfPixmap> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>, double, double, int, int);

typedef MupdfDropPixmapNative = Void Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);
typedef MupdfDropPixmapDart = void Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);

typedef MupdfPixmapWidthNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);
typedef MupdfPixmapWidthDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);

typedef MupdfPixmapHeightNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);
typedef MupdfPixmapHeightDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);

typedef MupdfPixmapStrideNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);
typedef MupdfPixmapStrideDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);

typedef MupdfPixmapComponentsNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);
typedef MupdfPixmapComponentsDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);

typedef MupdfPixmapSamplesNative = Pointer<Uint8> Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);
typedef MupdfPixmapSamplesDart = Pointer<Uint8> Function(
    Pointer<MupdfContext>, Pointer<MupdfPixmap>);

// Text
typedef MupdfExtractTextNative = Pointer<Utf8> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);
typedef MupdfExtractTextDart = Pointer<Utf8> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);

typedef MupdfExtractHtmlNative = Pointer<Utf8> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);
typedef MupdfExtractHtmlDart = Pointer<Utf8> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>);

typedef MupdfFreeStringNative = Void Function(
    Pointer<MupdfContext>, Pointer<Utf8>);
typedef MupdfFreeStringDart = void Function(
    Pointer<MupdfContext>, Pointer<Utf8>);

// Search
typedef MupdfSearchPageNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Utf8>, Pointer<Int32>);
typedef MupdfSearchPageDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Utf8>, Pointer<Int32>);

typedef MupdfSearchPageQuadsNative = Pointer<Float> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Utf8>, Pointer<Int32>);
typedef MupdfSearchPageQuadsDart = Pointer<Float> Function(
    Pointer<MupdfContext>, Pointer<MupdfPage>,
    Pointer<Utf8>, Pointer<Int32>);

typedef MupdfFreeFloatsNative = Void Function(Pointer<Float>);
typedef MupdfFreeFloatsDart = void Function(Pointer<Float>);

// Outline
typedef MupdfOutlineFlattenNative = Int32 Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>,
    Pointer<Pointer<MupdfOutlineItem>>);
typedef MupdfOutlineFlattenDart = int Function(
    Pointer<MupdfContext>, Pointer<MupdfDocument>,
    Pointer<Pointer<MupdfOutlineItem>>);

typedef MupdfOutlineFreeNative = Void Function(
    Pointer<MupdfOutlineItem>, Int32);
typedef MupdfOutlineFreeDart = void Function(
    Pointer<MupdfOutlineItem>, int);

// Error
typedef MupdfLastErrorNative = Pointer<Utf8> Function(Pointer<MupdfContext>);
typedef MupdfLastErrorDart = Pointer<Utf8> Function(Pointer<MupdfContext>);
