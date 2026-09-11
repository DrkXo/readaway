# Workspace Agent Guidelines & Architecture Rules

## Core Packages & Responsibilities
- `apps/readaway`: Main Flutter application for document reading, text-to-speech, and annotations.
- `packages/mupdf`: Native MuPDF FFI package providing high-performance PDF, XPS, and EPUB rendering, text extraction, search quads, and outline navigation.

---

## MuPDF Architecture & C FFI Rules
Detailed guidelines derived from *MuPDF Explored* by Robin Watts:
- **Reference Manual**: [`packages/mupdf/docs/mupdf_architecture_guide.md`](file:///home/drkxo/Documents/Projects/playground/readaway/packages/mupdf/docs/mupdf_architecture_guide.md)
- **EPUB Engine Memory Guide**: [`packages/mupdf/docs/epub_rendering_and_layout_guide.md`](file:///home/drkxo/Documents/Projects/playground/readaway/packages/mupdf/docs/epub_rendering_and_layout_guide.md)
- **Rules File**: [`.agents/rules/mupdf.md`](file:///home/drkxo/Documents/Projects/playground/readaway/.agents/rules/mupdf.md)
- **Specialized Skill**: `mupdf-expert` ([`.agents/skills/mupdf-expert/SKILL.md`](file:///home/drkxo/Documents/Projects/playground/readaway/.agents/skills/mupdf-expert/SKILL.md))

### Inviolable Rules
1. **Never allow `longjmp` across Dart FFI**: Wrap all native MuPDF calls in `fz_try` and `fz_catch`.
2. **Always call `fz_var(ptr)`** on local variables modified inside `fz_try` and inspected/dropped in `fz_always` or `fz_catch`.
3. **Never `return` inside `fz_try`**.
4. **Never share `fz_context` or `fz_document` concurrently between threads/isolates**.
5. **Context Cloning**: If sharing the cache/Store across threads, initialize the base context with `fz_locks_context` and call `fz_clone_context()`.
6. **Parallel Rendering**: Record page into `fz_display_list` on the main thread, then worker threads can play back the display list in parallel without touching the document.
7. **Premultiplied Alpha**: Pixmaps use premultiplied alpha (`R * A / 255`). Keep this in mind when passing samples to Flutter.
8. **Cancellation**: Pass `fz_cookie` and set `cookie.abort = 1` for responsive rendering cancellation.

---

## HyperRender Architecture & Extensibility
- **Reference Guide**: [`apps/readaway/docs/hyper_render_architecture_and_extensibility_guide.md`](file:///home/drkxo/Documents/Projects/playground/readaway/apps/readaway/docs/hyper_render_architecture_and_extensibility_guide.md)
- **Rules File**: [`.agents/rules/hyper_render.md`](file:///home/drkxo/Documents/Projects/playground/readaway/.agents/rules/hyper_render.md)
- Single `RenderObject` (`RenderHyperBox`) with Block/Inline Formatting Context, CSS Float, and CJK Ruby.
- Extensibility via `HyperPluginRegistry` (block/inline custom tags), `widgetBuilder`, `HyperImageLoader`, `HyperViewerController`, `HyperPageController`, and `HyperStreamingController`.
