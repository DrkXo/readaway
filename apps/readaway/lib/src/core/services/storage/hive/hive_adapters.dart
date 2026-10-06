import 'package:hive_ce/hive.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../features/annotations/domain/entity/document_notes.dart';
import '../../../../features/annotations/domain/entity/reader_note.dart';
import '../../../../features/library/domain/entity/reading_status.dart';
import '../../../../features/library/domain/entity/recent_document.dart';
import '../../../../features/settings/domain/entity/reader_preferences.dart';
import '../../../../features/settings/domain/entity/settings.dart';
import '../../../../features/settings/domain/entity/tts_lyric_style.dart';
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

  // TTS Lyric View
  AdapterSpec<TtsLyricStyle>(),
  AdapterSpec<LyricLineAlign>(),
  AdapterSpec<LyricContentAlign>(),
  AdapterSpec<LyricAnchorAlign>(),

  // TTS Catalog
  AdapterSpec<SherpaTtsModelInfo>(),
  AdapterSpec<SherpaTtsModelType>(),
  AdapterSpec<SherpaTtsModelFamily>(),

  // Annotations — bookmarks, highlights and notes.
  //
  // Appended after every existing spec on purpose: generated typeIds follow
  // this list's order, so inserting above would renumber the adapters that
  // already have data written under them.
  AdapterSpec<DocumentNotes>(),
  AdapterSpec<ReaderNote>(),
  AdapterSpec<ReaderNoteAnchor>(),
  AdapterSpec<ReaderNoteType>(),
  AdapterSpec<NoteAnchorKind>(),
  AdapterSpec<HighlightStyle>(),
])
// ignore: unused_element
void _() {}
