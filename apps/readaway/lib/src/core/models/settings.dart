part of 'models.dart';

Settings settingsFromJson(String str) => Settings.fromJson(json.decode(str));

String settingsToJson(Settings data) => json.encode(data.toJson());

@freezed
abstract class Settings with _$Settings {
  const factory Settings({
    @Default(1) int schemaVersion,
    @Default(1) int version,
    @Default(1) int migrationVersion,
    @Default('') String localBooksDir,
    String? customRootDir,
    @Default([]) List<String> externalLibraryFolders,
    @Default([]) List<String> autoImportFolders,
    @Default([]) List<String> autoImportFlattenFolders,
    @Default(true) bool keepLogin,
    @Default(false) bool alwaysOnTop,
    @Default(false) bool openBookInNewWindow,
    @Default(true) bool autoCheckUpdates,
    @Default('stable') String updateChannel,
    @Default(false) bool screenWakeLock,
    @Default(false) bool autohideCursor,
    @Default(1.0) double screenBrightness,
    @Default(true) bool autoScreenBrightness,
    @Default(true) bool swipeBrightnessGesture,
    @Default(HardwarePageTurner()) HardwarePageTurner hardwarePageTurner,
    @Default(true) bool alwaysShowStatusBar,
    @Default(true) bool openLastBooks,
    @Default([]) List<String> lastOpenBooks,
    @Default(true) bool autoImportBooksOnOpen,
    @Default(false) bool savedBookCoverForLockScreen,
    String? savedBookCoverForLockScreenPath,
    @Default(false) bool telemetryEnabled,
    @Default(false) bool discordRichPresenceEnabled,
    @Default('grid') String libraryViewMode,
    @Default('updated') String librarySortBy,
    @Default(true) bool librarySortAscending,
    @Default(true) bool librarySortByAuto,
    @Default('title') String libraryThenSortBy,
    @Default(true) bool libraryThenSortAscending,
    @Default('group') String libraryGroupBy,
    @Default('crop') String libraryCoverFit,
    @Default(true) bool libraryAutoColumns,
    @Default(6) int libraryColumns,
    @Default(false) bool librarySkeuomorphicCovers,
    @Default(false) bool libraryHideCovers,
    @Default(false) bool libraryRecentShelfEnabled,
    String? libraryBackgroundTextureId,
    @Default(1.0) double libraryBackgroundOpacity,
    @Default('cover') String libraryBackgroundSize,
    @Default([]) List<CustomFont> customFonts,
    @Default([]) List<CustomDictionary> customDictionaries,
    @Default(DictionarySettings()) DictionarySettings dictionarySettings,
    @Default([]) List<OpdsCatalog> opdsCatalogs,
    @Default([]) List<AbsServer> absServers,
    @Default(false) bool metadataSeriesCollapsed,
    @Default(false) bool metadataOthersCollapsed,
    @Default(false) bool metadataDescriptionCollapsed,
    @Default(false) bool pinCodeEnabled,
    String? pinCodeHash,
    String? pinCodeSalt,
    @Default(false) bool biometricUnlockEnabled,
    @Default(AiSettings()) AiSettings aiSettings,
    @Default(GlobalReadSettings()) GlobalReadSettings globalReadSettings,
    @Default(GlobalViewSettings()) GlobalViewSettings globalViewSettings,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}

@freezed
abstract class AiSettings with _$AiSettings {
  const factory AiSettings({
    @Default(false) bool enabled,
    @Default('openai') String provider,
    String? apiKey,
    @Default('gpt-4o-mini') String model,
    @Default(1024) int maxTokens,
    @Default(0.7) double temperature,
  }) = _AiSettings;

  factory AiSettings.fromJson(Map<String, dynamic> json) =>
      _$AiSettingsFromJson(json);
}

@freezed
abstract class DictionarySettings with _$DictionarySettings {
  const factory DictionarySettings({
    String? defaultDictionary,
    @Default([]) List<String> onlineDictionaries,
  }) = _DictionarySettings;

  factory DictionarySettings.fromJson(Map<String, dynamic> json) =>
      _$DictionarySettingsFromJson(json);
}

@freezed
abstract class CustomFont with _$CustomFont {
  const factory CustomFont({
    @Default('') String id,
    @Default('') String name,
    @Default('') String path,
  }) = _CustomFont;

  factory CustomFont.fromJson(Map<String, dynamic> json) =>
      _$CustomFontFromJson(json);
}

@freezed
abstract class CustomDictionary with _$CustomDictionary {
  const factory CustomDictionary({
    @Default('') String id,
    @Default('') String name,
    @Default('') String url,
  }) = _CustomDictionary;

  factory CustomDictionary.fromJson(Map<String, dynamic> json) =>
      _$CustomDictionaryFromJson(json);
}

@freezed
abstract class OpdsCatalog with _$OpdsCatalog {
  const factory OpdsCatalog({
    @Default('') String id,
    @Default('') String title,
    @Default('') String url,
  }) = _OpdsCatalog;

  factory OpdsCatalog.fromJson(Map<String, dynamic> json) =>
      _$OpdsCatalogFromJson(json);
}

@freezed
abstract class AbsServer with _$AbsServer {
  const factory AbsServer({
    @Default('') String serverUrl,
    @Default('') String username,
    @Default('') String password,
  }) = _AbsServer;

  factory AbsServer.fromJson(Map<String, dynamic> json) =>
      _$AbsServerFromJson(json);
}

@freezed
abstract class ProofreadRule with _$ProofreadRule {
  const factory ProofreadRule({
    @Default('') String pattern,
    @Default('') String replacement,
    @Default(false) bool caseSensitive,
  }) = _ProofreadRule;

  factory ProofreadRule.fromJson(Map<String, dynamic> json) =>
      _$ProofreadRuleFromJson(json);
}

@freezed
abstract class GlobalReadSettings with _$GlobalReadSettings {
  const factory GlobalReadSettings({
    @Default(320) int sidebarWidth,
    @Default(360) int notebookWidth,
    @Default('google') String translationProvider,
    @Default('en') String translateTargetLang,
    @Default(true) bool wordLensAutoDownload,
    @Default('underline') String highlightStyle,
    @Default(HighlightStyles()) HighlightStyles highlightStyles,
    @Default([
      '#FFD700',
      '#FF6B6B',
      '#4ECDC4',
      '#45B7D1',
      '#96CEB4',
      '#FFEAA7',
    ])
    List<String> customHighlightColors,
    @Default([]) List<String> userHighlightColors,
    @Default(['Important', 'Question', 'Idea'])
    List<String> defaultHighlightLabels,
    @Default(
      CustomTtsHighlightColors(sentence: '#4ECDC4', paragraph: '#45B7D1'),
    )
    CustomTtsHighlightColors customTtsHighlightColors,
    @Default([]) List<String> customThemes,
  }) = _GlobalReadSettings;

  factory GlobalReadSettings.fromJson(Map<String, dynamic> json) =>
      _$GlobalReadSettingsFromJson(json);
}

@freezed
abstract class CustomTtsHighlightColors with _$CustomTtsHighlightColors {
  const factory CustomTtsHighlightColors({
    @Default('#4ECDC4') String sentence,
    @Default('#45B7D1') String paragraph,
  }) = _CustomTtsHighlightColors;

  factory CustomTtsHighlightColors.fromJson(Map<String, dynamic> json) =>
      _$CustomTtsHighlightColorsFromJson(json);
}

@freezed
abstract class HighlightStyles with _$HighlightStyles {
  const factory HighlightStyles({
    @Default(Background(color: '#FFD700', backgroundColor: 'transparent'))
    Background underline,
    @Default(Background(color: 'transparent', backgroundColor: '#FFD700'))
    Background background,
    @Default(Background(color: '#FFD700', backgroundColor: 'transparent'))
    Background outline,
  }) = _HighlightStyles;

  factory HighlightStyles.fromJson(Map<String, dynamic> json) =>
      _$HighlightStylesFromJson(json);
}

@freezed
abstract class Background with _$Background {
  const factory Background({
    @Default('transparent') String color,
    @Default('transparent') String backgroundColor,
  }) = _Background;

  factory Background.fromJson(Map<String, dynamic> json) =>
      _$BackgroundFromJson(json);
}

@freezed
abstract class GlobalViewSettings with _$GlobalViewSettings {
  const factory GlobalViewSettings({
    @Default(8) int marginTopPx,
    @Default(8) int marginBottomPx,
    @Default(8) int marginLeftPx,
    @Default(8) int marginRightPx,
    @Default(4) int compactMarginTopPx,
    @Default(4) int compactMarginBottomPx,
    @Default(4) int compactMarginLeftPx,
    @Default(4) int compactMarginRightPx,
    @Default(5) int gapPercent,
    @Default(false) bool scrolled,
    @Default('vertical') String scrolledDirection,
    @Default(false) bool webtoonMode,
    @Default(false) bool noContinuousScroll,
    @Default(false) bool disableClick,
    @Default(false) bool disableSwipe,
    @Default(false) bool disableDoubleClick,
    @Default(false) bool fullscreenClickArea,
    @Default(false) bool swapClickArea,
    @Default(false) bool volumeKeysToFlip,
    @Default(1) int maxColumnCount,
    @Default(0) int maxInlineSize,
    @Default(0) int maxBlockSize,
    @Default('horizontal-tb') String writingMode,
    @Default(false) bool vertical,
    @Default(false) bool rtl,
    @Default(0) int scrollingOverlap,
    @Default(true) bool allowScript,
    @Default(false) bool hideScrollbar,
    @Default(1) int autoScrollSpeed,
    @Default(false) bool autoScrollRunning,
    @Default(1.0) double zoomLevel,
    @Default('system') String theme,
    String? backgroundTextureId,
    @Default(1.0) double backgroundOpacity,
    @Default('cover') String backgroundSize,
    @Default(0.3) double highlightOpacity,
    @Default(true) bool codeHighlighting,
    String? codeLanguage,
    String? userStylesheet,
    @Default(false) bool overrideLayout,
    @Default(false) bool overrideColor,
    @Default(false) bool useBookLayout,
    @Default('fit-width') String zoomMode,
    @Default('auto') String spreadMode,
    @Default(true) bool keepCoverSpread,
    @Default(true) bool invertImgColorInDark,
    @JsonKey(name: 'applyThemeToPDF') @Default(true) bool applyThemeToPdf,
    @Default(1.0) double contrast,
    @Default('Sans-serif') String defaultFont,
    @JsonKey(name: 'defaultCJKFont')
    @Default('Source Han Sans')
    String defaultCjkFont,
    @Default(true) bool replaceQuotationMarks,
    @Default('simplified') String convertChineseVariant,
    @Default('toc') String sideBarTab,
    @Default('system') String uiLanguage,
    @JsonKey(name: 'sortedTOC') @Default(true) bool sortedToc,
    @Default(false) bool doubleBorder,
    @Default('#000000') String borderColor,
    @Default(true) bool showHeader,
    @Default(true) bool showFooter,
    @Default(true) bool showRemainingTime,
    @Default(true) bool showRemainingPages,
    @Default(false) bool showProgressInfo,
    @Default(true) bool showStickyProgressBar,
    @Default(false) bool showCurrentTime,
    @Default(false) bool showCurrentBatteryStatus,
    @Default(false) bool showBatteryPercentage,
    @Default(true) bool showPaginationButtons,
    @Default('fraction') String progressStyle,
    @Default(0) int referencePageCount,
    @Default(true) bool animated,
    @Default('slide') String pageTurnStyle,
    @Default(false) bool isEink,
    @Default(false) bool isColorEink,
    @Default(ParagraphMode()) ParagraphMode paragraphMode,
    @Default(false) bool readingRulerEnabled,
    @Default(1) int readingRulerLines,
    @Default(0.5) double readingRulerPosition,
    @Default(0.3) double readingRulerOpacity,
    @Default('#000000') String readingRulerColor,
    @Default(1.0) double ttsRate,
    @Default(500) int ttsSentenceGap,
    @Default(1000) int ttsParagraphGap,
    String? ttsVoice,
    @Default(false) bool ttsUseNarration,
    @Default('sentence') String ttsLocation,
    @Default(['sentence']) List<String> ttsHighlightOptions,
    @Default('sentence') String ttsHighlightGranularity,
    dynamic ttsMediaMetadata,
    @Default('default') String ttsPlayerStyle,
    @Default(false) bool translationEnabled,
    @Default('google') String translationProvider,
    @Default('en') String translateTargetLang,
    @Default(true) bool showTranslateSource,
    @Default(false) bool ttsReadAloudText,
    @Default('auto') String screenOrientation,
    @Default([]) List<ProofreadRule> proofreadRules,
    @Default(true) bool enableAnnotationQuickActions,
    @Default('dictionary') String annotationQuickAction,
    @Default(['highlight', 'note', 'dictionary', 'translate'])
    List<String> annotationToolbarItems,
    @Default(true) bool copyToNotebook,
    @Default(true) bool wordLensEnabled,
    @Default('medium') String wordLensLevel,
    @Default('en') String wordLensHintLang,
    @Default(14) int wordLensGlossFontSize,
    @Default('#333333') String wordLensGlossColor,
    @Default(true) bool isGlobal,
  }) = _GlobalViewSettings;

  factory GlobalViewSettings.fromJson(Map<String, dynamic> json) =>
      _$GlobalViewSettingsFromJson(json);
}

@freezed
abstract class ParagraphMode with _$ParagraphMode {
  const factory ParagraphMode({
    @Default(false) bool enabled,
    @Default(2) int indentSize,
    @Default(3) int maxLines,
  }) = _ParagraphMode;

  factory ParagraphMode.fromJson(Map<String, dynamic> json) =>
      _$ParagraphModeFromJson(json);
}

@freezed
abstract class HardwarePageTurner with _$HardwarePageTurner {
  const factory HardwarePageTurner({
    @Default(false) bool enabled,
    @Default(['KEYCODE_VOLUME_DOWN', 'KEYCODE_VOLUME_UP'])
    List<String> pageTurnKeys,
  }) = _HardwarePageTurner;

  factory HardwarePageTurner.fromJson(Map<String, dynamic> json) =>
      _$HardwarePageTurnerFromJson(json);
}
