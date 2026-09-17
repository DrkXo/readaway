/// High-performance pure Dart document reading, formatting, and TTS engine for ReadAway.
library;

// Abstracts
export 'src/abstracts/document_format_handler.dart';
export 'src/abstracts/document_reader.dart';
export 'src/abstracts/reflowable_document_reader.dart';

// Audio & PCM
export 'src/audio/audio.dart';

// Errors
export 'src/errors/document_exception.dart';

// Extensions
export 'src/extensions/extensions.dart';

// Lifecycle
export 'src/lifecycle/disposable.dart';

// Logging
export 'src/logging/readaway_logger.dart';

// Models
export 'src/models/models.dart';

// Pagination
export 'src/pagination/page_slicer.dart';
export 'src/pagination/pagination_coordinator.dart';

// Readers & Factory
export 'src/readers/builtin_handlers.dart';
export 'src/readers/cbz_document_reader.dart';
export 'src/readers/document_reader_factory.dart';
export 'src/readers/epub_document_reader.dart';
export 'src/readers/html_text_extractor.dart';
export 'src/readers/plain_text_document_reader.dart';
export 'src/readers/single_html_document_reader.dart';

// Transformers
export 'src/transformers/transformers.dart';

// TTS & Speech
export 'src/tts/sentence_segmenter.dart';
export 'src/tts/speech_normalizer.dart';
export 'src/tts/tts_chunker.dart';
