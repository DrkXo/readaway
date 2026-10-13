import 'package:bloc_test/bloc_test.dart';
import 'package:readaway/src/features/annotations/presentation/bloc/annotations_bloc.dart';
import 'package:readaway/src/features/library/presentation/bloc/library_bloc.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_tts_repository.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/tts/reader_tts_bloc.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings/settings_bloc.dart';
import 'package:readaway/src/features/settings/presentation/bloc/tts_library/tts_library_bloc.dart';

import 'test_mocks.dart';

/// Central reusable [MockBloc] for [ReaderBloc].
class MockReaderBloc extends MockBloc<ReaderEvent, ReaderState>
    implements ReaderBloc {
  final List<ReaderEvent> addedEvents = [];

  @override
  void add(ReaderEvent event) {
    addedEvents.add(event);
    super.add(event);
  }

  @override
  bool get isClosed => false;
}

/// Central reusable [MockBloc] for [ReaderTtsBloc].
class MockReaderTtsBloc extends MockBloc<ReaderTtsEvent, ReaderTtsState>
    implements ReaderTtsBloc {
  MockReaderTtsBloc({
    ReaderTtsRepository? ttsRepository,
    ReaderRepository? readerRepository,
  }) : ttsRepository = ttsRepository ?? MockReaderTtsRepository(),
       readerRepository = readerRepository ?? MockReaderRepository();

  final List<ReaderTtsEvent> addedEvents = [];

  @override
  void add(ReaderTtsEvent event) {
    addedEvents.add(event);
    super.add(event);
  }

  @override
  final ReaderTtsRepository ttsRepository;

  @override
  final ReaderRepository readerRepository;

  @override
  bool get isClosed => false;
}

/// Central reusable [MockBloc] for [SettingsBloc].
class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {
  @override
  bool get isClosed => false;
}

/// Central reusable [MockBloc] for [AnnotationsBloc].
class MockAnnotationsBloc extends MockBloc<AnnotationsEvent, AnnotationsState>
    implements AnnotationsBloc {
  @override
  bool get isClosed => false;
}

/// Central reusable [MockBloc] for [LibraryBloc].
class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {
  @override
  bool get isClosed => false;
}

/// Central reusable [MockBloc] for [TtsLibraryBloc].
class MockTtsLibraryBloc extends MockBloc<TtsLibraryEvent, TtsLibraryState>
    implements TtsLibraryBloc {
  @override
  bool get isClosed => false;
}
