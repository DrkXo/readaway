import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/core/error/failures.dart';
import 'package:readaway/src/core/models/models.dart';
import 'package:readaway/src/core/services/file_open_service.dart';
import 'package:readaway/src/core/services/notification_service.dart';
import 'package:readaway/src/core/services/path_service.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/storage/hive/app_storage_service.dart';
import 'package:readaway/src/core/services/window_service.dart';
import 'package:readaway/src/features/library/domain/entity/recent_document.dart';
import 'package:readaway/src/features/library/domain/repositories/library_repository.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
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

/// Registers Mockito dummy values for fpdart [TaskEither] and other complex return types.
void registerMockitoDummies() {
  const dummyFailure = UnexpectedFailure('mock_dummy');
  provideDummy<TaskEither<Failure, Uint8List>>(TaskEither.left(dummyFailure));
  provideDummy<TaskEither<Failure, PageSize>>(TaskEither.left(dummyFailure));
  provideDummy<TaskEither<Failure, PageSize?>>(TaskEither.left(dummyFailure));
  provideDummy<TaskEither<Failure, String>>(TaskEither.left(dummyFailure));
  provideDummy<TaskEither<Failure, Unit>>(TaskEither.left(dummyFailure));
  provideDummy<TaskEither<Failure, List<RecentDocument>>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, RecentDocument>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, Option<RecentDocument>>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, Option<String>>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, Option<ReadingAnchor>>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, ReadingAnchor?>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, ReaderDocumentInfo>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, ReaderPageData>>(
    TaskEither.left(dummyFailure),
  );
  provideDummy<TaskEither<Failure, Settings>>(
    TaskEither.left(dummyFailure),
  );
}
