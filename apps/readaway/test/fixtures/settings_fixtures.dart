import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';

/// Creates a fake [ReaderPreferences] with sensible defaults.
ReaderPreferences fakeReaderPreferences({
  double fontSize = 16.0,
  String fontFamily = 'Noto Serif',
  double lineHeight = 1.5,
  double paragraphMargin = 0.5,
  double letterSpacing = 0.0,
  ReaderPageTransition pageTransition = ReaderPageTransition.slide,
  ReaderScrollDirection scrollDirection = ReaderScrollDirection.horizontal,
  ReaderTextAlign textAlign = ReaderTextAlign.left,
  ReaderProgressStyle footerProgressStyle = ReaderProgressStyle.pageNumber,
}) => ReaderPreferences(
  fontSize: fontSize,
  fontFamily: fontFamily,
  lineHeight: lineHeight,
  paragraphMargin: paragraphMargin,
  letterSpacing: letterSpacing,
  pageTransition: pageTransition,
  scrollDirection: scrollDirection,
  textAlign: textAlign,
  footerProgressStyle: footerProgressStyle,
);

/// Creates a fake [Settings] with sensible defaults.
Settings fakeSettings({
  ReaderPreferences? globalReaderPrefs,
  GlobalViewSettings globalViewSettings = const GlobalViewSettings(),
  String libraryViewMode = 'grid',
  String librarySortBy = 'dateOpened',
  bool librarySortAscending = false,
  String libraryFilterStatus = 'all',
}) => Settings(
  globalViewSettings: globalViewSettings,
  libraryViewMode: libraryViewMode,
  librarySortBy: librarySortBy,
  librarySortAscending: librarySortAscending,
  libraryFilterStatus: libraryFilterStatus,
);
