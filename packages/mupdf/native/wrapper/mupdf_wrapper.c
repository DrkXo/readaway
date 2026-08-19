#include "mupdf_wrapper.h"
#include <mupdf/fitz.h>
#include <string.h>
#include <stdlib.h>

/*
 * The fz_try/fz_catch macros use setjmp/longjmp, which cannot cross FFI
 * boundaries. This wrapper catches all MuPDF errors and returns them as
 * error codes so Dart FFI never sees a longjmp.
 */

struct mupdf_context_s {
    fz_context* ctx;
    char last_error[256];
};

#define CTX(ptr) ((struct mupdf_context_s*)(ptr))

static void set_error(struct mupdf_context_s* c, const char* msg) {
    if (msg) {
        strncpy(c->last_error, msg, sizeof(c->last_error) - 1);
        c->last_error[sizeof(c->last_error) - 1] = '\0';
    } else {
        c->last_error[0] = '\0';
    }
}

/* ---- Context ---- */

mupdf_context mupdf_new_context(void) {
    struct mupdf_context_s* c = calloc(1, sizeof(*c));
    if (!c) return NULL;
    c->ctx = fz_new_context(NULL, NULL, FZ_STORE_DEFAULT);
    if (!c->ctx) {
        free(c);
        return NULL;
    }
    fz_register_document_handlers(c->ctx);
    return c;
}

void mupdf_drop_context(mupdf_context handle) {
    if (!handle) return;
    struct mupdf_context_s* c = CTX(handle);
    if (c->ctx) fz_drop_context(c->ctx);
    free(c);
}

/* ---- Document ---- */

mupdf_document mupdf_open_document(mupdf_context handle, const char* filename) {
    struct mupdf_context_s* c = CTX(handle);
    fz_document* doc = NULL;
    fz_try(c->ctx) {
        doc = fz_open_document(c->ctx, filename);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return doc;
}

mupdf_document mupdf_open_document_from_data(
    mupdf_context handle, const uint8_t* data, int64_t size
) {
    struct mupdf_context_s* c = CTX(handle);
    fz_document* doc = NULL;
    fz_buffer* buf = NULL;
    fz_stream* stream = NULL;
    fz_try(c->ctx) {
        buf = fz_new_buffer_from_copied_data(c->ctx, data, size);
        stream = fz_open_buffer(c->ctx, buf);
        doc = fz_open_document_with_stream(c->ctx, "application/octet-stream", stream);
    }
    fz_always(c->ctx) {
        if (stream) fz_drop_stream(c->ctx, stream);
        if (buf) fz_drop_buffer(c->ctx, buf);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return doc;
}

void mupdf_drop_document(mupdf_context handle, mupdf_document doc) {
    if (!handle || !doc) return;
    struct mupdf_context_s* c = CTX(handle);
    fz_drop_document(c->ctx, doc);
}

int mupdf_needs_password(mupdf_context handle, mupdf_document doc) {
    struct mupdf_context_s* c = CTX(handle);
    int result = 0;
    fz_try(c->ctx) {
        result = fz_needs_password(c->ctx, doc);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return result;
}

int mupdf_authenticate_password(
    mupdf_context handle, mupdf_document doc, const char* password
) {
    struct mupdf_context_s* c = CTX(handle);
    int result = 0;
    fz_try(c->ctx) {
        result = fz_authenticate_password(c->ctx, doc, password);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return result;
}

int mupdf_count_pages(mupdf_context handle, mupdf_document doc) {
    struct mupdf_context_s* c = CTX(handle);
    int count = 0;
    fz_try(c->ctx) {
        count = fz_count_pages(c->ctx, doc);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return count;
}

int mupdf_lookup_metadata(
    mupdf_context handle, mupdf_document doc,
    const char* key, char* buf, int bufsize
) {
    struct mupdf_context_s* c = CTX(handle);
    int len = -1;
    fz_try(c->ctx) {
        len = fz_lookup_metadata(c->ctx, doc, key, buf, bufsize);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return len;
}

int mupdf_layout_document(
    mupdf_context handle, mupdf_document doc,
    float width, float height, float em
) {
    struct mupdf_context_s* c = CTX(handle);
    fz_try(c->ctx) {
        fz_layout_document(c->ctx, doc, width, height, em);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return MUPDF_ERR_GENERIC;
    }
    return MUPDF_OK;
}

int mupdf_is_reflowable(mupdf_context handle, mupdf_document doc) {
    struct mupdf_context_s* c = CTX(handle);
    int result = 0;
    fz_try(c->ctx) {
        result = fz_is_document_reflowable(c->ctx, doc);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return result;
}

int mupdf_count_chapters(mupdf_context handle, mupdf_document doc) {
    struct mupdf_context_s* c = CTX(handle);
    int count = 0;
    fz_try(c->ctx) {
        count = fz_count_chapters(c->ctx, doc);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return count;
}

int mupdf_count_chapter_pages(mupdf_context handle, mupdf_document doc, int chapter) {
    struct mupdf_context_s* c = CTX(handle);
    int count = 0;
    fz_try(c->ctx) {
        count = fz_count_chapter_pages(c->ctx, doc, chapter);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return count;
}

mupdf_page mupdf_load_chapter_page(
    mupdf_context handle, mupdf_document doc, int chapter, int page
) {
    struct mupdf_context_s* c = CTX(handle);
    fz_page* pg = NULL;
    fz_try(c->ctx) {
        pg = fz_load_chapter_page(c->ctx, doc, chapter, page);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return pg;
}

int mupdf_has_permission(mupdf_context handle, mupdf_document doc, int permission) {
    struct mupdf_context_s* c = CTX(handle);
    int result = 0;
    fz_try(c->ctx) {
        result = fz_has_permission(c->ctx, doc, (fz_permission)permission);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return result;
}

int mupdf_page_label(mupdf_context handle, mupdf_page page, char* buf, int bufsize) {
    struct mupdf_context_s* c = CTX(handle);
    int len = -1;
    fz_try(c->ctx) {
        const char* result = fz_page_label(c->ctx, page, buf, bufsize);
        if (result)
            len = (int)strlen(result);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return len;
}

/* ---- Page ---- */

mupdf_page mupdf_load_page(mupdf_context handle, mupdf_document doc, int number) {
    struct mupdf_context_s* c = CTX(handle);
    fz_page* page = NULL;
    fz_try(c->ctx) {
        page = fz_load_page(c->ctx, doc, number);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return page;
}

void mupdf_drop_page(mupdf_context handle, mupdf_page page) {
    if (!handle || !page) return;
    struct mupdf_context_s* c = CTX(handle);
    fz_drop_page(c->ctx, page);
}

float mupdf_page_width(mupdf_context handle, mupdf_page page) {
    struct mupdf_context_s* c = CTX(handle);
    float w = 0;
    fz_try(c->ctx) {
        fz_rect box = fz_bound_page(c->ctx, page);
        w = box.x1 - box.x0;
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
    }
    return w;
}

float mupdf_page_height(mupdf_context handle, mupdf_page page) {
    struct mupdf_context_s* c = CTX(handle);
    float h = 0;
    fz_try(c->ctx) {
        fz_rect box = fz_bound_page(c->ctx, page);
        h = box.y1 - box.y0;
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
    }
    return h;
}

int mupdf_page_bound_box(mupdf_context handle, mupdf_page page,
                         float* width, float* height) {
    struct mupdf_context_s* c = CTX(handle);
    fz_try(c->ctx) {
        fz_rect box = fz_bound_page(c->ctx, page);
        if (width) *width = box.x1 - box.x0;
        if (height) *height = box.y1 - box.y0;
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return MUPDF_ERR_GENERIC;
    }
    return MUPDF_OK;
}

/* ---- Pixmap ---- */

mupdf_pixmap mupdf_new_pixmap_from_page(
    mupdf_context handle, mupdf_page page,
    float scale_x, float scale_y, int alpha
) {
    return mupdf_new_pixmap_from_page_cs(handle, page, scale_x, scale_y, alpha, 0);
}

mupdf_pixmap mupdf_new_pixmap_from_page_cs(
    mupdf_context handle, mupdf_page page,
    float scale_x, float scale_y, int alpha, int cs
) {
    struct mupdf_context_s* c = CTX(handle);
    fz_pixmap* pix = NULL;
    fz_try(c->ctx) {
        fz_matrix ctm = fz_scale(scale_x, scale_y);
        fz_colorspace* colorspace;
        switch (cs) {
            case 1:  colorspace = fz_device_gray(c->ctx); break;
            case 2:  colorspace = fz_device_cmyk(c->ctx); break;
            default: colorspace = fz_device_rgb(c->ctx); break;
        }
        pix = fz_new_pixmap_from_page(c->ctx, page, ctm, colorspace, alpha);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return pix;
}

void mupdf_drop_pixmap(mupdf_context handle, mupdf_pixmap pix) {
    if (!handle || !pix) return;
    struct mupdf_context_s* c = CTX(handle);
    fz_drop_pixmap(c->ctx, pix);
}

int mupdf_pixmap_width(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_width(c->ctx, pix);
}

int mupdf_pixmap_height(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_height(c->ctx, pix);
}

int mupdf_pixmap_stride(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_stride(c->ctx, pix);
}

int mupdf_pixmap_components(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_components(c->ctx, pix);
}

const unsigned char* mupdf_pixmap_samples(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_samples(c->ctx, pix);
}

/* ---- Text extraction ---- */

char* mupdf_extract_text(mupdf_context handle, mupdf_page page) {
    struct mupdf_context_s* c = CTX(handle);
    fz_stext_page* stext = NULL;
    fz_buffer* buf = NULL;
    fz_output* out = NULL;
    char* result = NULL;
    fz_try(c->ctx) {
        stext = fz_new_stext_page_from_page(c->ctx, page, NULL);
        buf = fz_new_buffer(c->ctx, 256);
        out = fz_new_output_with_buffer(c->ctx, buf);
        fz_print_stext_page_as_text(c->ctx, out, stext);
        fz_close_output(c->ctx, out);

        size_t len = fz_buffer_storage(c->ctx, buf, NULL);
        result = malloc(len + 1);
        if (result) {
            unsigned char* data = NULL;
            fz_buffer_storage(c->ctx, buf, &data);
            memcpy(result, data, len);
            result[len] = '\0';
        }
    }
    fz_always(c->ctx) {
        if (out) fz_drop_output(c->ctx, out);
        if (buf) fz_drop_buffer(c->ctx, buf);
        if (stext) fz_drop_stext_page(c->ctx, stext);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return result;
}

char* mupdf_extract_html(mupdf_context handle, mupdf_page page) {
    struct mupdf_context_s* c = CTX(handle);
    fz_stext_page* stext = NULL;
    fz_buffer* buf = NULL;
    fz_output* out = NULL;
    char* result = NULL;
    fz_try(c->ctx) {
        stext = fz_new_stext_page_from_page(c->ctx, page, NULL);
        buf = fz_new_buffer(c->ctx, 256);
        out = fz_new_output_with_buffer(c->ctx, buf);
        fz_print_stext_page_as_html(c->ctx, out, stext, 0);
        fz_close_output(c->ctx, out);

        size_t len = fz_buffer_storage(c->ctx, buf, NULL);
        result = malloc(len + 1);
        if (result) {
            unsigned char* data = NULL;
            fz_buffer_storage(c->ctx, buf, &data);
            memcpy(result, data, len);
            result[len] = '\0';
        }
    }
    fz_always(c->ctx) {
        if (out) fz_drop_output(c->ctx, out);
        if (buf) fz_drop_buffer(c->ctx, buf);
        if (stext) fz_drop_stext_page(c->ctx, stext);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return result;
}

void mupdf_free_string(mupdf_context handle, char* str) {
    (void)handle;
    free(str);
}

/* ---- Search ---- */

int mupdf_search_page(
    mupdf_context handle, mupdf_page page,
    const char* needle, int* hit_count
) {
    struct mupdf_context_s* c = CTX(handle);
    int count = 0;
    fz_quad hits[256];
    int hit_mark[256];
    fz_try(c->ctx) {
        count = fz_search_page(c->ctx, page, needle, hit_mark, hits, 256);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    if (hit_count) *hit_count = count;
    return MUPDF_OK;
}

float* mupdf_search_page_quads(
    mupdf_context handle, mupdf_page page,
    const char* needle, int* hit_count
) {
    struct mupdf_context_s* c = CTX(handle);
    int count = 0;
    float* result = NULL;

    if (hit_count) *hit_count = 0;

    /* Use a generous buffer; truncate if exceeded */
    fz_quad hits[1024];
    int hit_mark[1024];

    fz_try(c->ctx) {
        count = fz_search_page(c->ctx, page, needle, hit_mark, hits, 1024);

        if (count <= 0) goto done;

        result = calloc(count, sizeof(fz_quad));
        if (!result) {
            set_error(c, "out of memory");
            count = 0;
            goto done;
        }

        /* Convert fz_quad (4 points = 8 floats) to flat float array */
        for (int i = 0; i < count; i++) {
            fz_quad q = hits[i];
            float* out = result + i * 8;
            out[0] = q.ul.x; out[1] = q.ul.y;
            out[2] = q.ur.x; out[3] = q.ur.y;
            out[4] = q.ll.x; out[5] = q.ll.y;
            out[6] = q.lr.x; out[7] = q.lr.y;
        }
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        free(result);
        result = NULL;
        count = 0;
    }

done:
    if (hit_count) *hit_count = count;
    return result;
}

void mupdf_free_floats(float* ptr) {
    free(ptr);
}

/* ---- Outline ---- */

static int count_outline(fz_outline* ol) {
    int n = 0;
    for (; ol; ol = ol->next) {
        n++;
        if (ol->down) n += count_outline(ol->down);
    }
    return n;
}

static void flatten_outline(fz_context* ctx, fz_outline* ol, int level,
                             mupdf_outline_item* out, int* idx) {
    for (; ol; ol = ol->next) {
        mupdf_outline_item* item = &out[*idx];
        item->title = ol->title ? strdup(ol->title) : NULL;
        item->uri = ol->uri ? strdup(ol->uri) : NULL;
        item->chapter = ol->page.chapter;
        item->page = ol->page.page;
        item->level = level;
        item->is_open = ol->is_open;
        (*idx)++;
        if (ol->down) flatten_outline(ctx, ol->down, level + 1, out, idx);
    }
}

int mupdf_outline_flatten(
    mupdf_context handle, mupdf_document doc,
    mupdf_outline_item** items
) {
    struct mupdf_context_s* c = CTX(handle);
    fz_outline* outline = NULL;
    mupdf_outline_item* result = NULL;
    int count = 0;

    if (items) *items = NULL;

    fz_try(c->ctx) {
        outline = fz_load_outline(c->ctx, doc);
        if (!outline) goto done;

        count = count_outline(outline);
        if (count <= 0) goto done;

        result = calloc(count, sizeof(mupdf_outline_item));
        if (!result) {
            set_error(c, "out of memory");
            count = 0;
            goto done;
        }

        int idx = 0;
        flatten_outline(c->ctx, outline, 0, result, &idx);
        count = idx;
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            for (int i = 0; i < count; i++) {
                free(result[i].title);
                free(result[i].uri);
            }
            free(result);
        }
        result = NULL;
        count = 0;
    }

done:
    if (outline) fz_drop_outline(c->ctx, outline);
    if (items) *items = result;
    return count;
}

void mupdf_outline_free(mupdf_outline_item* items, int count) {
    if (!items) return;
    for (int i = 0; i < count; i++) {
        free(items[i].title);
        free(items[i].uri);
    }
    free(items);
}

/* ---- Error ---- */

const char* mupdf_last_error(mupdf_context handle) {
    if (!handle) return "";
    return CTX(handle)->last_error;
}
