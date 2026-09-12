# Plan: Migrate ReadAway app to readaway_core (reflowable-only, MuPDF removed from app)

## TL;DR

Replace MuPDF entirely within the app with the pure-Dart `readaway_core` package. Per user decisions: (1) cover-art extraction is added to `readaway_core` (not a follow-up), (2) `ReaderEngineMode.publisherFidelity` is removed with NO backward-compat, (3) MuPDF is removed from the APP completely — dependency, `MuPdfService`, PDF/XPS/CBZ support — while the `packages/mupdf` workspace package is KEPT for now (only the app dependency is dropped). The app becomes **EPUB/HTML/TXT-only (reflowable)**. MuPDF's other app consumers (`LibraryRepositoryImpl` metadata, `DocumentCoverService` cover art) switch to readaway_core.

## Current state (verified 2026-09-13)

- App reflowable path: `ReaderRepositoryImpl` → `ReflowableDocumentReader.fromFile` (app interface) → `EpubDocumentReader` (MuPDF `MuPdfEpubSpine`), `SingleHtmlDocumentReader`, `PlainTextDocumentReader`.
- Pagination: `ReflowablePaginationCoordinator` (ChangeNotifier) + `ReflowablePageSlicer`, wired into `ReaderViewport`, `ReflowableVirtualPage`, `ReaderControllerMixin.jumpToPage`.
- Outline: flat `mupdf.OutlineItem` in `ReaderDocumentInfo`/`ReaderState`; TOC UI = `ReaderTocContent` + `OutlineItemTile`.
- MuPDF consumers beyond reader: `LibraryRepositoryImpl._enrichAndSave` (title/author/pageCount via `MuPdfService`), `DocumentCoverService` (cover via `renderPageFromFile`), `ReaderBloc` (PDF `pageImages`), `FixedReaderPage` (PDF rendering).
- `IsolateService` is SHARED with TTS (`SherpaOnnxTtsService`, `TtsChunkingService`) — KEEP it.
- `packages/mupdf` is a root workspace member with melos scripts (`ffi:build`, `ffi:clean`, `ffi:generate`, `submodules:update`) — KEEP the package and scripts; only the app stops depending on it.
- `readaway_core` NOT yet a dependency of the app.

## Core API gaps to fill (Phase 1 — packages/readaway_core)

1. `PaginationCoordinator.registerChapterHeight` lacks `lineBounds` → add optional `List<({double top, double bottom})>? lineBounds` forwarded to `PageSlicer.computePageOffsets` (preserves line-snapping).
2. `PaginationCoordinator` doesn't expose per-chapter page offsets → add `List<double> getChapterPageOffsets(int chapterIndex)` (cache; `ReflowableVirtualPage` needs it for slice rendering).
3. No `getGlobalPageForChapter(int)` → add convenience (or app helper via `globalPageFromCoordinate`).
4. `OutlineItem` has no chapter index → add `int? chapterIndex` (populated via existing `resolveHref` callback in OpfParser/NcxParser/NavParser) for TOC current-chapter highlight.
5. **Cover extraction (NEW)**: `OpfData` has no cover. Parse OPF cover metadata — EPUB2 `<meta name="cover" content="id"/>` + manifest item href; EPUB3 `<item properties="cover-image">` — add `String? coverImagePath` to `OpfData` (resolved vs `opfDir`) and expose on the reader (e.g., `ReflowableDocumentReader.coverImagePath` or via `DocumentMetadata`).

## Phases

### Phase 1 — Core package extensions (prereq; blocks Phases 3 & 4; cover blocks Phase 2)

- `packages/readaway_core/lib/src/pagination/pagination_coordinator.dart`: add `lineBounds` to `registerChapterHeight`, add `getChapterPageOffsets`, add `getGlobalPageForChapter`.
- `packages/readaway_core/lib/src/models/outline_item.dart`: add `int? chapterIndex`; populate in `opf_parser.dart`/`ncx_parser.dart`/`nav_parser.dart` via `resolveHref`.
- `packages/readaway_core/lib/src/models/epub/opf_data.dart` + `opf_parser.dart`: add `coverImagePath` (EPUB2/EPUB3 cover detection); expose on `ReflowableDocumentReader`/`DocumentReader`.
- Regenerate freezed/json (`dart run build_runner build` in core); add/update core tests for all new APIs.

### Phase 2 — Reflowable-only data layer (depends on Phase 1 cover)

- `apps/readaway/pubspec.yaml`: add `readaway_core`; remove `mupdf: ^0.1.0`.
- `reader_repository_impl.dart`: use `DocumentReaderFactory().open(path)` for ALL docs (no PDF branch); `loadAssetBytes` simplified to core-only (`resolveAssetPath` + `loadAsset`, drop 5-fallback chain); `extractPageText` via `loadSectionHtml` + `reader_html_utils`.
- `reader_repository.dart` (domain): remove PDF-specific methods (`convertPagePosition`, `getPageCountForMode`, PDF `resolveLink`); `ReaderDocumentInfo` drops `isReflowable` (always true) and uses `List<core.OutlineItem>`.
- `library_repository_impl.dart` `_enrichAndSave`: extract title/author/pageCount via core reader (`title`, `metadata.author`, `sectionCount`).
- `document_cover_service.dart`: use core `coverImagePath` + `loadAsset`; keep white-margin crop + PNG cache logic (`decodeRenderedPage` stays).
- Delete: `core/services/mupdf_service.dart`, `core/services/reader/` (all 6 files), `fixed_reader_page.dart`.
- `reader_state.dart`/`reader_bloc.dart`/`reader_event.dart`: remove `pageImages`, PDF branches, `engineMode`; `ReaderState.outline` → `List<core.OutlineItem>`; regenerate freezed.
- `reader_viewport.dart`: remove PDF branches (no `FixedReaderPage`, no `pageImages`).

### Phase 3 — Pagination replacement (depends on Phase 1)

- Delete `core/services/reader/reflowable_pagination_coordinator.dart` + `reflowable_page_slicer.dart`.
- DI (`injection.config.dart`): register core `PaginationCoordinator`; drop `ReflowablePageSlicer`/`ReflowablePaginationCoordinator` registrations.
- `reader_viewport.dart`: subscribe to `coordinator.state` (ValueStream) instead of `addListener`; `totalPageCount` → `currentState.totalPages`; `getGlobalPageForChapter` → core helper; `createAnchor(globalPage)` → `createAnchor(coordinateFromGlobalPage(globalPage))`; `restoreFromAnchor(anchor)` → `.globalPage`; adapt `initialize`/`updateViewport` (viewportHeight = availableHeight; pass last-known chapter height from `currentState.chapterHeights`).
- `reflowable_virtual_page.dart`: subscribe to `state`; `registerChapterHeight(chapterIndex:, contentHeight:, lineBounds:)`; `getChapterPageOffsets` (core).
- `reader_page_mixin.dart` `jumpToPage`: adapt to core API.

### Phase 4 — TOC migration (depends on Phase 2)

- `reader_toc_content.dart` + `outline_item_tile.dart`: consume `List<core.OutlineItem>`; use `flatten()` + `item.chapterIndex` for current-chapter highlight and jump targets (replace `_indexOfCurrent` using `item.chapter`/`item.page`).

### Phase 5 — Engine mode & format scope reduction (independent)

- Remove `ReaderEngineMode` ENTIRELY (no backward-compat, no `@JsonKey(unknownEnumValue:)`): `reader_preferences.dart` (drop `engineMode` field), `ReaderState`/`ReaderEvent` (drop `engineMode`/`engineModeChanged`), `ReaderRepository` (drop `engineMode` params), `reader_page.dart` engine-mode listener; regenerate freezed/json.
- `supported_document_formats.dart`: trim `allFormats` to epub/html/txt only; audit consumers (`file_picker_data_source.dart` pickerExtensions, `file_open_service.dart` isSupported).

### Phase 6 — Cleanup & tests (last)

- NO workspace changes: `packages/mupdf` stays in root `pubspec.yaml` workspace members and melos scripts (`ffi:*`, `submodules:update`) are untouched. The app dependency was already removed in Phase 2.
- Collapse `isReflowable` branches across UI (`reader_page.dart`, `reader_bottom_bar.dart`, `reader_top_bar.dart`, `reader_viewport.dart`, `reader_toc_content.dart`) — app is reflowable-only.
- Tests: delete `epub_spine_reader_test.dart` (MuPDF-backed; core has own tests) or rewrite vs core `EpubDocumentReader`; update `toc_navigation_test.dart` to core `OutlineItem`; update `reflowable_document_reader_repository_test.dart` (drop `MockMuPdfService`, use core); audit `reflowable_image_rendering_test.dart`/`hyper_render_analysis_test.dart` for MuPDF usage; add pagination/cover/adapter tests.
- Run `dart analyze`, `dart format`, `flutter test`, `melos run analyze`.

## Relevant files

- `packages/readaway_core/lib/src/pagination/pagination_coordinator.dart` — extend (lineBounds, getChapterPageOffsets, getGlobalPageForChapter)
- `packages/readaway_core/lib/src/models/outline_item.dart` + `opf_parser.dart`/`ncx_parser.dart`/`nav_parser.dart` — chapterIndex
- `packages/readaway_core/lib/src/models/epub/opf_data.dart` + `opf_parser.dart` — coverImagePath
- `apps/readaway/pubspec.yaml` — add readaway_core, remove mupdf
- `apps/readaway/lib/src/features/reader/data/repositories/reader_repository_impl.dart` — core-only
- `apps/readaway/lib/src/features/reader/domain/repositories/reader_repository.dart` — drop PDF methods
- `apps/readaway/lib/src/features/library/data/repositories/library_repository_impl.dart` — core metadata
- `apps/readaway/lib/src/core/services/document_cover_service.dart` — core cover
- `apps/readaway/lib/src/features/reader/presentation/bloc/{reader_state,reader_bloc,reader_event}.dart` — drop pageImages/engineMode/PDF
- `apps/readaway/lib/src/features/reader/presentation/widgets/viewport/reader_viewport.dart` + `page_content/reflowable_virtual_page.dart` + `pages/reader_page_mixin.dart` — core coordinator
- `apps/readaway/lib/src/features/reader/presentation/widgets/toc/{reader_toc_content,outline_item_tile}.dart` — core outline
- `apps/readaway/lib/src/features/settings/domain/entity/reader_preferences.dart` — remove engineMode
- `apps/readaway/lib/src/core/models/reader/supported_document_formats.dart` — epub/html/txt only
- `apps/readaway/lib/src/core/config/injection.config.dart` — DI updates
- DELETE (app only): `apps/readaway/lib/src/core/services/mupdf_service.dart`, `core/services/reader/` (6 files), `fixed_reader_page.dart`
- KEEP: `packages/mupdf/` (workspace package + melos scripts untouched)

## Verification

1. `dart analyze` + `dart format` clean in `packages/readaway_core` and `apps/readaway`; `melos run analyze` passes.
2. `dart test` in core (new pagination/outline/cover tests) + `flutter test` in app (migrated tests).
3. Manual: open EPUB → spine/outline load, page turns with line-snapping, TOC navigation + current-chapter highlight, TTS read-aloud, images render, font-size reflow preserves position (anchor).
4. Manual: library add → title/author/pageCount/cover extracted via core; cover thumbnail cached.
5. Manual: file picker only offers epub/html/txt; PDF/mobi/cbz rejected.
6. Confirm no `mupdf` references remain in the APP: `grep -r mupdf apps/readaway/lib apps/readaway/pubspec.yaml` → empty (packages/mupdf itself is expected to reference mupdf).

## Decisions

- Cover extraction added to readaway_core (Phase 1), not a follow-up (user).
- `ReaderEngineMode` removed entirely, no backward-compat JSON fallback (user).
- MuPDF removed from the APP completely (dependency, `MuPdfService`, PDF/XPS/CBZ support); `packages/mupdf` workspace package KEPT for now (user).
- `IsolateService` KEPT (shared with TTS).
- `decodeRenderedPage`/`reader_image_utils.dart` KEPT (cover art crop/cache).
- Core needs 5 small extensions (lineBounds, getChapterPageOffsets, getGlobalPageForChapter, OutlineItem.chapterIndex, OpfData.coverImagePath).

## Further considerations

1. PDF support is intentionally dropped from the app. `readaway_core` retains the `PdfDocumentReader` interface — a future native backend can restore PDF without touching the app's reflowable path.
2. `isReflowable` collapse (Phase 6) is mechanical but broad (~8 files); sequenced after the core migration is verifiable.
3. `DocumentCoverService` crop/trim + PNG cache logic is preserved; only the image source changes (core `loadAsset` instead of MuPDF render).
4. `packages/mupdf` remains in the workspace as an orphaned package (no app consumer). Revisit later: either delete it or repurpose it as the future `PdfDocumentReader` backend.
