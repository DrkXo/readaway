/// High-performance Rust-backed document reading and TTS engine for ReadAway.
library;

// Abstracts
export 'src/abstracts/document_format_handler.dart';
export 'src/abstracts/document_reader.dart';
export 'src/abstracts/reflowable_document_reader.dart';
// Adapters
export 'src/adapters/rust_cbz_reader.dart';
export 'src/adapters/rust_epub_reader.dart';
export 'src/adapters/rust_html_extractor.dart';
export 'src/adapters/rust_tts_chunker.dart';
// Audio & PCM
export 'src/audio/audio.dart';
// Errors
export 'src/errors/document_exception.dart';
// Logging
export 'src/logging/rust_logger.dart';
// Models
export 'src/models/models.dart';
// Pagination
export 'src/pagination/page_slicer.dart';
export 'src/pagination/pagination_coordinator.dart';
// Readers & Factory
export 'src/readers/builtin_handlers.dart';
export 'src/readers/document_reader_factory.dart';
export 'src/readers/html_text_extractor.dart';
export 'src/readers/plain_text_document_reader.dart';
export 'src/readers/rust_cbz_document_reader.dart';
export 'src/readers/rust_epub_document_reader.dart';
export 'src/readers/single_html_document_reader.dart';
export 'src/rust/api/document.dart';
export 'src/rust/api/init.dart';
export 'src/rust/api/models.dart';
export 'src/rust/api/tts.dart';
export 'src/rust/frb_generated.dart' show RustLib;
export 'src/rust/rust_init.dart';
// Transformers
export 'src/transformers/transformers.dart';
