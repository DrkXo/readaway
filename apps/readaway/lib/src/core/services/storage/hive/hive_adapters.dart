import 'package:hive_ce/hive.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../features/library/domain/entity/reading_status.dart';
import '../../../../features/library/domain/entity/recent_document.dart';
import '../../../../features/settings/domain/entity/reader_preferences.dart';
import '../../../../features/settings/domain/entity/settings.dart';
import '../../tts/tts_models.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  // Library & Reading Progress
  AdapterSpec<RecentDocument>(),
  AdapterSpec<ReadingStatus>(),
  AdapterSpec<ReadingAnchor>(),

  // Reader Preferences
  AdapterSpec<ReaderPreferences>(),
  AdapterSpec<ReaderDefaultFont>(),
  AdapterSpec<ReaderTextAlign>(),
  AdapterSpec<ReaderProgressStyle>(),
  AdapterSpec<ReaderHeaderAlignment>(),
  AdapterSpec<ReaderScrollDirection>(),
  AdapterSpec<ReaderPageTransition>(),

  // App Settings & Sub-configs
  AdapterSpec<Settings>(),
  AdapterSpec<CustomFont>(),
  AdapterSpec<GlobalViewSettings>(),

  // TTS Catalog
  AdapterSpec<SherpaTtsModelInfo>(),
  AdapterSpec<SherpaTtsModelType>(),
  AdapterSpec<SherpaTtsModelFamily>(),
])
// ignore: unused_element
void _() {}
