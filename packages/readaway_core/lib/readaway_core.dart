/// ReadAway Core — pure-Dart document reading engine.
///
/// Provides a unified [DocumentReader] abstraction over reflowable (EPUB,
/// HTML, plain text) and fixed-layout (PDF) documents, with no native
/// dependencies.
library;

export 'src/abstracts/document_format_handler.dart';
export 'src/abstracts/document_reader.dart';
export 'src/abstracts/pdf_document_reader.dart';
export 'src/abstracts/reflowable_document_reader.dart';
export 'src/errors/document_exception.dart';
export 'src/models/models.dart';
export 'src/pagination/page_slicer.dart';
export 'src/pagination/pagination_coordinator.dart';
export 'src/readers/builtin_handlers.dart';
export 'src/readers/cbz/cbz_document_reader.dart';
export 'src/readers/cbz/natural_sort.dart';
export 'src/readers/document_reader_factory.dart';
export 'src/readers/epub/epub_container.dart';
export 'src/readers/epub/epub_document_reader.dart';
export 'src/readers/epub/nav_parser.dart';
export 'src/readers/epub/ncx_parser.dart';
export 'src/readers/epub/opf_parser.dart';
export 'src/readers/html/html_text_extractor.dart';
export 'src/readers/html/single_html_document_reader.dart';
export 'src/readers/text/plain_text_document_reader.dart';
export 'src/readers/zip_container.dart';
