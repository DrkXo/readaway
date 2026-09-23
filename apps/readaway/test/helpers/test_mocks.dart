import 'dart:typed_data';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/result/result.dart';
import 'package:readaway/src/core/services/file_open_service.dart';
import 'package:readaway/src/core/services/notification_service.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/storage/hive/app_storage_service.dart';
import 'package:readaway/src/core/services/window_service.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/domain/repositories/library_repository.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway_core/readaway_core.dart';

@GenerateNiceMocks([
  MockSpec<AppPathService>(),
  MockSpec<WindowService>(),
  MockSpec<NotificationService>(),
  MockSpec<FileOpenService>(),
  MockSpec<LibraryRepository>(),
  MockSpec<ReaderRepository>(),
  MockSpec<AppStorageService>(),
  MockSpec<SettingsService>(),
])
export 'test_mocks.mocks.dart';

/// Registers Mockito dummy values for [Result] and other complex return types.
void registerMockitoDummies() {
  const dummyFailure = UnexpectedFailure('mock_dummy');
  provideDummy<Result<Uint8List>>(const Failed(dummyFailure));
  provideDummy<Result<PageSize?>>(const Failed(dummyFailure));
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
}
