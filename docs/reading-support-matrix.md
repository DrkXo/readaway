# Reading Engine Support Matrix

Baseline as of 2026-10-13. Production-parity reference: `foliate-js`.

## Legend
- ✅ Supported/Production
- 🟡 Partial/Work-in-progress
- ❌ Not supported (roadmap)

## Pagination & viewport
| Capability | Status | Evidence / Notes |
|---|---|---|
| Line-snapped page breaks (no split lines) | ✅ | `PageSlicer` uses render `lineBounds`; tests in `page_slicer_test.dart` |
| Per-chapter page counts (virtual) | ✅ | `PaginationCoordinator` + `registerChapterLayout` |
| Continuous scroll mode | ✅ | `ContinuousReaderView` |
| Paged/native transitions | ✅ | `PagedReaderView`, `PagedTransitionController` |
| Overscroll page turn | ✅ | `ReaderViewportController.handleInnerOverscroll` |
| Touch drag/snap | ✅ | `ReaderViewportController` delegates |
| Resize/orientation handling | 🟡 | LayoutBuilder triggers `updateViewport`; needs stronger resize regression tests |
| RTL text progression | ❌ | No direction handling (P0) |
| Vertical writing (rl/lr) | ❌ | No writing-mode handling (P0) |
| Multi-column reflowable pages | 🟡 | Always single column; P1 optional |

## Fixed-layout / images
| Capability | Status | Notes |
|---|---|---|
| PDF reader | ✅ | `PdfReaderView` |
| CBZ/comic reader | ✅ | `fixed_layout/*` |
| Dual-spread helper | ✅ | `FixedLayoutSpreadHelper` tests |
| Missing-image / decode failure containment | 🟡 | Partial handling in `_resolveAssetBytes`; P4 hardening |

## Highlight & annotations
| Capability | Status | Notes |
|---|---|---|
| Annotation styles (highlight/underline/strikethrough/squiggly/outline) | ✅ | `ReaderAnnotationPainter` |
| Anchor repair on text drift | ✅ | `AnnotationAnchorResolver` exact/repaired/orphaned |
| Slice clipping across page boundaries | ✅ | `_visibleRects` |
| Tap hit-slop for thin strokes | ✅ | `noteAt` with 4px slop |
| TTS sentence-level highlight | ✅ | `TtsSpeechHighlightPainter` |
| TTS word-level karaoke | ✅ | `wordRects` + `ValueNotifier` repaint |
| Geometry from exact render runs | ✅ | `RenderHyperBox.debugLineFragments()` via fork |

## Navigation & position
| Capability | Status | Notes |
|---|---|---|
| Chapter/page jump | ✅ | `ReaderViewportController` |
| Saved restore anchor | ✅ | `pendingRestoreAnchor` handling |
| Reading progress persistence | ✅ | `reader_progress_persistence_test.dart` |
| In-book full-text search | ❌ | TOC title search only (P2) |
| EPUB CFI interop | ❌ | Internal anchors only (P3) |

## Production hardening checklist (baseline)
- [x] `fvm exec melos run analyze` green (2026-10-13)
- [x] Unit/widget tests executed via `fvm exec melos run test` (passed: readaway + readaway_core + vscode_theme_parser, 2026-10-13)
- [ ] Long-book stress profile (1000+ pages with images/ruby) captured
- [ ] Resize/orientation regression tests added (P4)
- [ ] Decode-failure containment regression test added (P4)

## How to reproduce baseline
```sh
fvm use --skip-pub-get
fvm exec melos bootstrap
fvm exec melos run codegen
fvm exec melos run analyze
fvm exec melos run test
```
