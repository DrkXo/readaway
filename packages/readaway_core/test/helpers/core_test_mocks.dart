import 'package:mockito/annotations.dart';
import 'package:readaway_core/src/abstracts/document_format_handler.dart';
import 'package:readaway_core/src/abstracts/document_reader.dart';
import 'package:readaway_core/src/abstracts/page_document_reader.dart';
import 'package:readaway_core/src/abstracts/reflowable_document_reader.dart';
import 'package:readaway_core/src/lifecycle/disposable.dart';
import 'package:readaway_core/src/readers/comic/comic_archive_adapter.dart';
import 'package:readaway_core/src/readers/pdf/pdf_engine_manager.dart';

@GenerateNiceMocks([
  MockSpec<DocumentReader>(),
  MockSpec<ReflowableDocumentReader>(),
  MockSpec<PageDocumentReader>(),
  MockSpec<DocumentFormatHandler>(),
  MockSpec<ComicArchiveAdapter>(),
  MockSpec<PdfEngineManager>(),
  MockSpec<Disposable>(),
])
export 'core_test_mocks.mocks.dart';
