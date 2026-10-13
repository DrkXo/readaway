import 'dart:typed_data';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/services/audio/audio_player_service.dart';
import 'package:readaway/src/core/services/background_downloader_service.dart';
import 'package:readaway/src/core/services/file_open_service.dart';
import 'package:readaway/src/core/services/notification_service.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/tts/cache/tts_chapter_cache_service.dart';
import 'package:readaway/src/core/services/tts/catalog/tts_catalog_service.dart';
import 'package:readaway/src/core/services/tts/importer/custom_tts_model_importer_service.dart';
import 'package:readaway/src/core/services/tts/sherpa/tts_download_manager.dart';
import 'package:readaway/src/core/services/tts/tts_chunker_service.dart';
import 'package:readaway/src/core/services/tts/tts_engine.dart';
import 'package:readaway/src/core/services/tts/tts_models.dart';
import 'package:readaway/src/core/services/wakelock_service.dart';
import 'package:readaway/src/core/services/window_service.dart';
import 'package:readaway/src/features/annotations/domain/entity/document_notes.dart';
import 'package:readaway/src/features/annotations/domain/repositories/annotations_repository.dart';
import 'package:readaway/src/features/library/data/datasources/file_picker_data_source.dart';
import 'package:readaway/src/features/library/data/datasources/library_local_data_source.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/domain/repositories/library_repository.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_tts_repository.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:readaway/src/features/settings/domain/repositories/tts_model_repository.dart';
import 'package:readaway_core/readaway_core.dart';

@GenerateNiceMocks([
  // Core services
  MockSpec<AppPathService>(),
  MockSpec<WindowService>(),
  MockSpec<NotificationService>(),
  MockSpec<FileOpenService>(),
  MockSpec<SettingsService>(),
  MockSpec<WakelockService>(),
  MockSpec<AudioPlayerService>(),
  MockSpec<BackGroundDownloaderService>(),

  // Repositories & Data Sources
  MockSpec<LibraryRepository>(),
  MockSpec<LibraryLocalDataSource>(),
  MockSpec<FilePickerDataSource>(),
  MockSpec<ReaderRepository>(),
  MockSpec<ReaderTtsRepository>(),
  MockSpec<AnnotationsRepository>(),
  MockSpec<SettingsRepository>(),
  MockSpec<TtsModelRepository>(),

  // TTS Services
  MockSpec<TtsChapterCacheService>(),
  MockSpec<TtsEngineRegistry>(),
  MockSpec<TtsEngine>(),
  MockSpec<TtsChunkingService>(),
  MockSpec<TtsDownloadManager>(),
  MockSpec<ReflowableDocumentReader>(),
])
export 'test_mocks.mocks.dart';

/// Registers Mockito dummy values for [Result] and other complex return types.
void registerMockitoDummies() {
  const dummyFailure = UnexpectedFailure('mock_dummy');
  provideDummy<Result<Uint8List>>(const Failed(dummyFailure));
  provideDummy<Result<PageSize?>>(const Failed(dummyFailure));
  provideDummy<Result<DocumentNotes>>(const Failed(dummyFailure));
  provideDummy<Result<String>>(const Failed(dummyFailure));
  provideDummy<Result<String?>>(const Failed(dummyFailure));
  provideDummy<Result<void>>(const Failed(dummyFailure));
  provideDummy<Result<List<RecentDocument>>>(const Failed(dummyFailure));
  provideDummy<Result<RecentDocument>>(const Failed(dummyFailure));
  provideDummy<Result<RecentDocument?>>(const Failed(dummyFailure));
  provideDummy<Result<ReadingAnchor?>>(const Failed(dummyFailure));
  provideDummy<Result<ReaderDocumentInfo>>(const Failed(dummyFailure));
  provideDummy<Result<ReaderPageData>>(const Failed(dummyFailure));
  provideDummy<Result<Settings>>(const Failed(dummyFailure));
  provideDummy<Result<int>>(const Failed(dummyFailure));
  provideDummy<Result<int?>>(const Failed(dummyFailure));
  provideDummy<Result<bool>>(const Failed(dummyFailure));
  provideDummy<Result<Uri?>>(const Failed(dummyFailure));
  provideDummy<Result<FootnoteItem?>>(const Failed(dummyFailure));
  provideDummy<Result<List<SherpaTtsModelInfo>>>(const Failed(dummyFailure));
  provideDummy<Result<SherpaTtsModelInfo>>(const Failed(dummyFailure));
  provideDummy<Result<TtsCatalogSyncResult>>(const Failed(dummyFailure));
  provideDummy<Result<CustomModelInspectionResult>>(
    const Failed(dummyFailure),
  );
}
