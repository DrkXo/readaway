# MuPDF Architecture & C API Reference Guide

> **Source**: Synthesized from *MuPDF Explored* by Robin Watts (MuPDF core architect at Artifex Software).
> **Target Audience**: Developers and AI agents working on `packages/mupdf`, native C wrappers, and Flutter/Dart document rendering in `readaway`.

---

## 1. Executive Summary & Design Philosophy

MuPDF is a high-performance, lightweight PDF, XPS, EPUB, and document manipulation and rendering library written in C. Its core rendering engine is known as **Fitz**.

### Core Tenets
1. **No Global Variables**: The core library has zero global variables. All state is contained within an `fz_context`. This enables clean embedding and multi-instance usage.
2. **No Threading Library Dependencies**: MuPDF does not mandate any specific threading library (POSIX pthreads, Win32 threads, etc.). Instead, the client injects mutex locks via callbacks, allowing MuPDF to operate in any multi-threaded runtime.
3. **Structured Exception System**: MuPDF uses macro-wrapped `setjmp`/`longjmp` for robust error unwinding (`fz_try`, `fz_always`, `fz_catch`).
4. **Separation of Parsing and Rendering**: Document parsers (interpreters) do not draw pixels directly. Instead, they serialize page representations into standard method calls on an abstract `fz_device`.
5. **Reference Counting**: All significant data structures (`fz_document`, `fz_page`, `fz_display_list`, `fz_pixmap`, `fz_text`, etc.) are reference counted with explicit `fz_keep_*` and `fz_drop_*` APIs.

---

## 2. Naming Conventions & Core Types

MuPDF enforces consistent naming conventions throughout its codebase:

| Prefix | Subsystem / Layer | Example |
| :--- | :--- | :--- |
| `fz_` | **Fitz**: Base graphics, rendering engine, formats, geometry, and utility layer | `fz_context`, `fz_pixmap`, `fz_device` |
| `pdf_` | **PDF Interpreter**: PDF-specific DOM, objects, annotations, crypto, and forms | `pdf_document`, `pdf_obj`, `pdf_annot` |
| `xps_` | **XPS Interpreter**: XML Paper Specification engine | `xps_document` |
| `html_` / `epub_` | **HTML / EPUB**: E-book parsing and layout | `epub_document` |

### Function Suffixes / Verbs
- `new`: Allocates a new instance initialized with reference count = 1 (e.g. `fz_new_pixmap`).
- `keep`: Increments reference count and returns the pointer (e.g. `fz_keep_page(ctx, page)`).
- `drop`: Decrements reference count. When it reaches 0, frees all associated memory. **Convention**: all `drop` functions safely accept `NULL` without crashing.
- `open`: Creates or accesses a handle from external resources (e.g. `fz_open_document`).
- `close`: Finalizes operations on an object before dropping (e.g. `fz_close_device`, `fz_close_output`).
- `bound`: Computes the geometric bounding box (e.g. `fz_bound_page`, `fz_bound_text`).

---

## 3. The Context (`fz_context`)

The context is the root structure required by almost every function in the MuPDF API.

```c
fz_context *fz_new_context(
    const fz_alloc_context *alloc,
    const fz_locks_context *locks,
    unsigned int max_store
);
```

### Components of `fz_context`
- **Memory Allocator** (`fz_alloc_context`): Defaults to `malloc`, `realloc`, `free` if `NULL`.
- **Locking Callbacks** (`fz_locks_context`): Callbacks (`lock`, `unlock`, `user` pointer) for `FZ_LOCK_MAX` mutexes. Required for multi-threading.
- **Resource Store** (`fz_store`): Central cache for decoded images, fonts, shadings, and glyphs. `max_store` configures the memory budget (use `FZ_STORE_DEFAULT` [usually 256MB] or `FZ_STORE_UNLIMITED`).
- **Exception Stack**: The stack of `jmp_buf` records for `fz_try`/`fz_catch`. **Because this stack is per-context, a context cannot be used concurrently across multiple threads.**

---

## 4. Multi-Threading & Context Cloning

### The 3 Inviolable Rules of Multi-Threading in MuPDF

> [!CAUTION]
> 1. **No simultaneous calls in different threads may use the same `fz_context`.**
> 2. **No simultaneous calls in different threads may use the same `fz_document`.**
> 3. **No simultaneous calls in different threads may use the same `fz_device`.**

### Context Cloning (`fz_clone_context`)
To use MuPDF concurrently across threads (e.g. worker threads or background rendering isolates):
1. Create the primary context with valid `fz_locks_context` callbacks:
   ```c
   fz_context *base_ctx = fz_new_context(NULL, &my_locks, FZ_STORE_DEFAULT);
   ```
2. In each worker thread, clone the context:
   ```c
   fz_context *worker_ctx = fz_clone_context(base_ctx);
   ```
3. Cloned contexts:
   - Share the memory allocator, Store (cache), and mutex locks.
   - Have their **own independent exception stack**, making them thread-safe.
   - Can independently tune rendering properties (e.g. lower anti-aliasing for thumbnail generation).
4. When the worker thread finishes, drop the clone: `fz_drop_context(worker_ctx)`.

> [!WARNING]
> If the base context was created with `locks == NULL`, `fz_clone_context()` will return `NULL` to prevent unsafe unsynchronized store access!

---

## 5. Error Handling & The `fz_var` Requirement

MuPDF uses C macros wrapping `setjmp` and `longjmp`:
```c
fz_var(local_pointer); /* CRITICAL before fz_try */
fz_try(ctx) {
    /* Code that may throw */
}
fz_always(ctx) {
    /* Code that ALWAYS runs (cleanup) */
}
fz_catch(ctx) {
    /* Code that runs only on error */
}
```

### The 7 Golden Rules of MuPDF Exception Handling
1. **Almost all MuPDF functions can throw exceptions** on error or OOM (unless explicitly documented otherwise). Never call them outside `fz_try` in host wrappers.
2. **`fz_try` must be paired with `fz_catch`**, with an optional `fz_always` in between.
3. **NEVER return from within an `fz_try` block.** Direct `return` circumvents `setjmp`/`longjmp` bookkeeping and corrupts the context's exception stack.
4. Control leaves `fz_try` normally when reaching the end of the block or via `break`.
5. **CRITICAL: Protect modified locals with `fz_var(x)`.**
   According to the C standard (ISO/IEC 9899), local variables modified between `setjmp` and `longjmp` become indeterminate/undefined unless declared `volatile`. The compiler may hold them in CPU registers that get overwritten during `longjmp`.
   `fz_var(ptr)` takes the address of `ptr`, forcing the compiler to preserve its value in stack memory across setjmp/longjmp unwinding.
   **Always call `fz_var` on any local pointer/resource that is modified inside `fz_try` and inspected/freed in `fz_always` or `fz_catch`.**
6. Code inside `fz_always` always executes regardless of whether an exception occurred.
7. Errors can be inspected with:
   - `fz_caught(ctx)`: Returns error code (`FZ_ERROR_MEMORY`, `FZ_ERROR_GENERIC`, `FZ_ERROR_SYNTAX`, `FZ_ERROR_TRYLATER`, `FZ_ERROR_ABORT`).
   - `fz_caught_message(ctx)`: Returns descriptive error string.

### Dart FFI Safety Boundary
> [!IMPORTANT]
> `setjmp`/`longjmp` **MUST NEVER** cross a Dart FFI boundary. An unhandled `longjmp` jumping across Dart VM stack frames will immediately corrupt the Dart stack and crash the process. All C wrapper entrypoints must catch all exceptions inside C and return status codes or error strings to Dart.

---

## 6. Memory Management & The Store

MuPDF maintains a centralized resource cache called **The Store** (`fz_store`).

### How The Store Works
- Caches decoded images, fonts, shadings, and display lists.
- Items are keyed by cryptographic hashes or identity keys.
- Reference counted: When an application requests an image on multiple pages, it is decoded once and kept in the Store.
- **Scavenging Memory Allocator**: When `fz_malloc` fails because memory is exhausted, MuPDF does not immediately crash. It executes a "reap pass" on the Store, evicting unreferenced cached items, and re-attempts the allocation. Only if memory is still unavailable does it throw `FZ_ERROR_MEMORY`.

---

## 7. The Document & Page Interface

### Unified Architecture
MuPDF abstracts all formats into `fz_document`:
- Open file: `fz_open_document(ctx, filepath)`
- Open stream/buffer: `fz_open_document_with_stream(ctx, magic_mime_type, stream)`
- Passwords: Check with `fz_needs_password(ctx, doc)`, authenticate with `fz_authenticate_password(ctx, doc, password)`.

### Reflowable vs Fixed-Layout Documents
- Check: `fz_is_document_reflowable(ctx, doc)`
  - Fixed layout (PDF, XPS): Pages have fixed dimensions and media boxes.
  - Reflowable (EPUB, HTML, FB2): Dimensions depend on window size and font sizing!
- To lay out a reflowable document:
  ```c
  fz_layout_document(ctx, doc, width, height, em_size);
  ```
- **Chapters**: Reflowable documents group pages into chapters.
  - `fz_count_chapters(ctx, doc)`
  - `fz_count_chapter_pages(ctx, doc, chapter)`
  - `fz_load_chapter_page(ctx, doc, chapter, page)`
- Fixed layout documents have a single chapter: `fz_count_pages(ctx, doc)`, `fz_load_page(ctx, doc, page_number)`.

---

## 8. The Device Interface & Rendering Pipeline

`fz_device` is the central rendering abstraction. When a page is rendered (`fz_run_page(ctx, page, dev, ctm, cookie)`), the document interpreter converts the page content into a stream of device method calls.

### Key Inbuilt Devices
1. **Draw Device** (`fz_new_draw_device(ctx, transform, pixmap)`):
   Renders graphic operations directly into a target `fz_pixmap`.
2. **Display List Device** (`fz_new_list_device(ctx, list)`):
   Records all drawing commands into an `fz_display_list` for instantaneous playback.
3. **Structured Text Device** (`fz_new_stext_device(ctx, options)`):
   Extracts text, words, lines, bounding boxes, and styles into an `fz_stext_page`.
4. **BBox Device** (`fz_new_bbox_device(ctx, &rect)`):
   Measures the exact bounding box of drawn content.
5. **PDF Output Device** (`pdf_page_write`):
   Writes elements into a PDF content stream.
6. **SVG Output Device** (`fz_new_svg_device(ctx, output, width, height)`):
   Generates vector SVG output.

### The Cookie (`fz_cookie`)
A lightweight struct passed to `fz_run_page` and `fz_run_display_list`:
```c
fz_cookie cookie = { 0 };
cookie.incomplete_ok = 1;
fz_run_page(ctx, page, dev, &ctm, &cookie);
```
- **Cancellation**: Set `cookie.abort = 1` from any thread to terminate rendering midway.
- **Error Tracking**: `cookie.errors` counts recoverable rendering errors without aborting.
- **Progress**: `cookie.progress` and `cookie.progress_max` provide progress metrics.

---

## 9. Display Lists: The Secret to High-Performance Viewers

Because an `fz_document` cannot be accessed simultaneously from multiple threads, rendering directly from `fz_page` to `fz_pixmap` on worker threads causes lock contention.

### The Optimal Reader Architecture
```
[Document / Disk / Main Thread]
             │
        fz_load_page
             │
   fz_new_display_list + fz_new_list_device
             │
        fz_run_page  (Records page once into memory)
             │
     fz_display_list  (Thread-Safe Immutable Cache)
      ┌──────┴─────────────────────────┐
      ▼                                ▼
[Worker 1: Render Tile]       [Worker 2: Text Search]
fz_run_display_list(DrawDev)   fz_run_display_list(STextDev)
```

1. Record page once into `fz_display_list`.
2. Drop the page and close the list device.
3. The resulting `fz_display_list` can be safely played back simultaneously from multiple worker threads without touching the document or disk.
4. Fast panning and zooming: Replaying a display list with different `fz_matrix` (scale/translation) and `clip` rects is drastically faster than re-parsing the PDF.

---

## 10. Building Blocks: Pixmaps, Colorspaces & Matrices

### Pixmaps (`fz_pixmap`)
- Represents a rectangular 2D array of pixel samples:
  - `w`, `h`: Dimensions in pixels.
  - `x`, `y`: Top-left origin offset.
  - `n`: Total components (`color_components + (alpha ? 1 : 0)`).
  - `stride`: Byte width of a single row (`w * n` or padded).
  - `samples`: Pointer to raw byte array.

### PREMULTIPLIED ALPHA GOTCHA
> [!IMPORTANT]
> **MuPDF pixmaps store colors using PREMULTIPLIED ALPHA!**
> Sample byte values are stored as:
> `R_stored = (R * A) / 255`, `G_stored = (G * A) / 255`, `B_stored = (B * A) / 255`.
> When converting to Flutter `ui.Image`, Skia, or exporting to formats expecting straight alpha (un-premultiplied RGBA), samples must either be un-premultiplied or passed to an engine configured for premultiplied alpha (such as `PixelFormat.rgba8888` / `ui.ColorSpace.sRGB` with premultiplied blend modes).

### Transforms (`fz_matrix`)
MuPDF represents affine transforms using a 6-element matrix:
```c
struct fz_matrix {
    float a, b, c, d, e, f;
};
```
- `fz_identity`: Identity matrix (`[1, 0, 0, 1, 0, 0]`).
- `fz_scale(sx, sy)`: Scaling matrix.
- `fz_pre_scale`, `fz_pre_rotate`, `fz_concat`: Transform chaining.
- Matrix coordinates transform points `(x, y)` to `(x', y')` via:
  $$x' = a \cdot x + c \cdot y + e$$
  $$y' = b \cdot x + d \cdot y + f$$

---

## 11. Structured Text (SText) & Search

### Hierarchy of `fz_stext_page`
```
fz_stext_page
 └── fz_stext_block (Text or Image)
      └── fz_stext_line
           └── fz_stext_span (Font, size, color, bidi level)
                └── fz_stext_char (Unicode UCS-4, origin x/y, bbox)
```

### Capabilities
- Plain text extraction: `fz_print_stext_page_as_text`
- HTML with absolute positioning: `fz_print_stext_page_as_html`
- Search: `fz_search_page(ctx, page, needle, hit_mark, hits, max_hits)` returns `fz_quad` array.
  - `fz_quad` contains 4 coordinates: `ul` (upper-left), `ur` (upper-right), `ll` (lower-left), `lr` (lower-right).
  - Quads allow accurate highlights even when text is rotated, slanted, or multi-directional.

---

## 12. Links, Annotations & PDF Widgets

### Document Links (`fz_link`)
- `fz_load_links(ctx, page)` returns a linked list of `fz_link`.
- Each link has:
  - `rect`: The active clickable hotzone on the page.
  - `uri`: The destination (e.g. `https://...` or `#page=12&view=Fit`).
- Dropping the head pointer drops the entire chain: `fz_drop_link(ctx, links)`.

### Annotations & Form Fields
1. **Fitz Level** (Read/Render):
   - Iterate: `fz_first_annot(ctx, page)`, `fz_next_annot(ctx, annot)`.
   - Render: `fz_run_annot(ctx, annot, dev, ctm, cookie)`.
   - Bounds: `fz_bound_annot(ctx, annot)`.
2. **PDF Level** (Create/Edit):
   - Cast: `pdf_annot *annot = (pdf_annot*)fz_annot`.
   - Creation: `pdf_create_annot(ctx, page, PDF_ANNOT_HIGHLIGHT)`.
   - Update appearance streams: `pdf_update_annot(ctx, annot)`.
   - Form Widgets (`pdf_widget`): Interactive text boxes, checkboxes, radio groups, signatures.
   - Event handling & JavaScript: `pdf_set_event_callback` for execution of AcroForm scripts.

---

## 13. Stories (`fz_story`): The Fitz Reflow Engine

MuPDF includes a full-featured styled text typesetting engine:
- Takes HTML/XML text with CSS rules.
- Lays out styled paragraphs into arbitrary geometric rectangles.
- Supports font selection, line heights, margins, padding, borders, hyphenation, and bi-directional text.
- Can place stories across multiple pages/columns and render results to any `fz_device`.

---

## 14. MuTool Utilities Quick Reference

MuPDF ships with the `mutool` command-line suite:
- `mutool clean`: Rewrite, sanitize, pretty-print, or decompress PDF syntax.
- `mutool draw`: Render pages to PNG, PAM, PBM, SVG, or display lists from CLI.
- `mutool convert`: Convert entire documents between formats (PDF to HTML, XPS to PDF).
- `mutool show`: Low-level inspector for PDF objects, trailers, xref tables, and streams.
- `mutool merge`: Combine multiple PDFs into a single document.
- `mutool pages`: Reorder, extract, or delete pages.
- `mutool run`: Run JavaScript automation scripts controlling MuPDF.

---

## 15. Summary of Key Checklist Items for `packages/mupdf`

1. **Wrap All C Entrypoints with `fz_try` / `fz_catch`**: Never let a longjmp cross into Dart FFI.
2. **Use `fz_var()` for all local variables modified inside `fz_try`** that need to be read or freed in `fz_always` or `fz_catch`.
3. **Multi-Thread with Cloned Contexts**:
   - Provide `fz_locks_context` when creating the main context.
   - Clone context for worker threads (`fz_clone_context`).
4. **Use Display Lists for Background Tile / Zoom Rendering**:
   - Cache `fz_display_list` per page to eliminate PDF re-parsing contention.
5. **Account for Premultiplied Alpha**:
   - Remember that `fz_pixmap_samples` produces premultiplied alpha values.
6. **Free Returned Native Buffers**:
   - Ensure strings, quad arrays, and pixmaps allocated in C have corresponding Dart finalizers or explicit free calls.
