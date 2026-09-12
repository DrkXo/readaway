#include "mupdf_wrapper.h"
#include <mupdf/fitz.h>
#include <mupdf/pdf.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <pthread.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/*
 * The fz_try/fz_catch macros use setjmp/longjmp, which cannot cross FFI
 * boundaries. This wrapper catches all MuPDF errors and returns them as
 * error codes or NULL so Dart FFI never sees a longjmp.
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

/* ---- Mutex Locks for Threading & Context Cloning ---- */

static pthread_mutex_t g_mupdf_locks[FZ_LOCK_MAX];
static int g_locks_initialized = 0;
static pthread_mutex_t g_init_mutex = PTHREAD_MUTEX_INITIALIZER;

static void mupdf_lock_cb(void *user, int lock) {
    (void)user;
    if (lock >= 0 && lock < FZ_LOCK_MAX) {
        pthread_mutex_lock(&g_mupdf_locks[lock]);
    }
}

static void mupdf_unlock_cb(void *user, int lock) {
    (void)user;
    if (lock >= 0 && lock < FZ_LOCK_MAX) {
        pthread_mutex_unlock(&g_mupdf_locks[lock]);
    }
}

static void ensure_locks_initialized(void) {
    pthread_mutex_lock(&g_init_mutex);
    if (!g_locks_initialized) {
        for (int i = 0; i < FZ_LOCK_MAX; i++) {
            pthread_mutex_init(&g_mupdf_locks[i], NULL);
        }
        g_locks_initialized = 1;
    }
    pthread_mutex_unlock(&g_init_mutex);
}

/* ---- Context ---- */

mupdf_context mupdf_new_context(void) {
    struct mupdf_context_s* c = calloc(1, sizeof(*c));
    if (!c) return NULL;

    ensure_locks_initialized();
    fz_locks_context locks;
    locks.user = NULL;
    locks.lock = mupdf_lock_cb;
    locks.unlock = mupdf_unlock_cb;

    c->ctx = fz_new_context(NULL, &locks, FZ_STORE_DEFAULT);
    if (!c->ctx) {
        free(c);
        return NULL;
    }
    fz_register_document_handlers(c->ctx);
    return c;
}

mupdf_context mupdf_clone_context(mupdf_context handle) {
    if (!handle) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_context_s* clone = calloc(1, sizeof(*clone));
    if (!clone) return NULL;

    clone->ctx = fz_clone_context(c->ctx);
    if (!clone->ctx) {
        free(clone);
        return NULL;
    }
    return clone;
}

void mupdf_drop_context(mupdf_context handle) {
    if (!handle) return;
    struct mupdf_context_s* c = CTX(handle);
    if (c->ctx) fz_drop_context(c->ctx);
    free(c);
}

/* ---- Cancellation Cookie ---- */

mupdf_cookie mupdf_new_cookie(void) {
    fz_cookie* cookie = calloc(1, sizeof(fz_cookie));
    return cookie;
}

void mupdf_drop_cookie(mupdf_cookie cookie) {
    free(cookie);
}

void mupdf_abort_cookie(mupdf_cookie cookie) {
    if (cookie) {
        ((fz_cookie*)cookie)->abort = 1;
    }
}

/* ---- Document ---- */

mupdf_document mupdf_open_document(mupdf_context handle, const char* filename) {
    struct mupdf_context_s* c = CTX(handle);
    fz_document* doc = NULL;
    fz_var(doc);
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
    fz_var(doc);
    fz_var(buf);
    fz_var(stream);
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
    fz_drop_document(c->ctx, (fz_document*)doc);
}

int mupdf_needs_password(mupdf_context handle, mupdf_document doc) {
    struct mupdf_context_s* c = CTX(handle);
    int result = 0;
    fz_try(c->ctx) {
        result = fz_needs_password(c->ctx, (fz_document*)doc);
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
        result = fz_authenticate_password(c->ctx, (fz_document*)doc, password);
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
        count = fz_count_pages(c->ctx, (fz_document*)doc);
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
        len = fz_lookup_metadata(c->ctx, (fz_document*)doc, key, buf, bufsize);
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
        fz_layout_document(c->ctx, (fz_document*)doc, width, height, em);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return MUPDF_ERR_GENERIC;
    }
    return MUPDF_OK;
}

int mupdf_style_document(
    mupdf_context handle, mupdf_document doc,
    int use_publisher_css, const char* user_css
) {
    if (!handle || !doc) return MUPDF_ERR_GENERIC;
    struct mupdf_context_s* c = CTX(handle);
    fz_try(c->ctx) {
        fz_style_document(c->ctx, (fz_document*)doc, use_publisher_css, user_css);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return MUPDF_ERR_GENERIC;
    }
    return MUPDF_OK;
}

void mupdf_set_user_css(mupdf_context handle, const char* user_css) {
    if (!handle) return;
    struct mupdf_context_s* c = CTX(handle);
    fz_set_user_css(c->ctx, user_css);
}

int mupdf_is_reflowable(mupdf_context handle, mupdf_document doc) {
    struct mupdf_context_s* c = CTX(handle);
    int result = 0;
    fz_try(c->ctx) {
        result = fz_is_document_reflowable(c->ctx, (fz_document*)doc);
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
        count = fz_count_chapters(c->ctx, (fz_document*)doc);
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
        count = fz_count_chapter_pages(c->ctx, (fz_document*)doc, chapter);
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
    fz_var(pg);
    fz_try(c->ctx) {
        pg = fz_load_chapter_page(c->ctx, (fz_document*)doc, chapter, page);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return NULL;
    }
    return pg;
}

int64_t mupdf_make_bookmark(mupdf_context handle, mupdf_document doc, int chapter, int page) {
    if (!handle || !doc) return 0;
    struct mupdf_context_s* c = CTX(handle);
    int64_t mark = 0;
    fz_try(c->ctx) {
        fz_location loc = fz_make_location(chapter, page);
        mark = (int64_t)fz_make_bookmark(c->ctx, (fz_document*)doc, loc);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return 0;
    }
    return mark;
}

int mupdf_lookup_bookmark(mupdf_context handle, mupdf_document doc, int64_t bookmark, int* chapter, int* page) {
    if (!handle || !doc) return MUPDF_ERR_GENERIC;
    struct mupdf_context_s* c = CTX(handle);
    fz_location loc = fz_make_location(-1, -1);
    fz_try(c->ctx) {
        loc = fz_lookup_bookmark(c->ctx, (fz_document*)doc, (fz_bookmark)bookmark);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return MUPDF_ERR_GENERIC;
    }
    if (chapter) *chapter = loc.chapter;
    if (page) *page = loc.page;
    return MUPDF_OK;
}

int mupdf_location_from_page(mupdf_context handle, mupdf_document doc, int page_number, int* chapter, int* page) {
    if (!handle || !doc) return MUPDF_ERR_GENERIC;
    struct mupdf_context_s* c = CTX(handle);
    fz_location loc = fz_make_location(-1, -1);
    fz_try(c->ctx) {
        loc = fz_location_from_page_number(c->ctx, (fz_document*)doc, page_number);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return MUPDF_ERR_GENERIC;
    }
    if (chapter) *chapter = loc.chapter;
    if (page) *page = loc.page;
    return MUPDF_OK;
}

int mupdf_page_from_location(mupdf_context handle, mupdf_document doc, int chapter, int page) {
    if (!handle || !doc) return -1;
    struct mupdf_context_s* c = CTX(handle);
    int page_num = -1;
    fz_try(c->ctx) {
        fz_location loc = fz_make_location(chapter, page);
        page_num = fz_page_number_from_location(c->ctx, (fz_document*)doc, loc);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return page_num;
}

int mupdf_has_permission(mupdf_context handle, mupdf_document doc, int permission) {
    struct mupdf_context_s* c = CTX(handle);
    int result = 0;
    fz_try(c->ctx) {
        result = fz_has_permission(c->ctx, (fz_document*)doc, (fz_permission)permission);
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
        const char* result = fz_page_label(c->ctx, (fz_page*)page, buf, bufsize);
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
    fz_var(page);
    fz_try(c->ctx) {
        page = fz_load_page(c->ctx, (fz_document*)doc, number);
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
    fz_drop_page(c->ctx, (fz_page*)page);
}

float mupdf_page_width(mupdf_context handle, mupdf_page page) {
    struct mupdf_context_s* c = CTX(handle);
    float w = 0;
    fz_try(c->ctx) {
        fz_rect box = fz_bound_page(c->ctx, (fz_page*)page);
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
        fz_rect box = fz_bound_page(c->ctx, (fz_page*)page);
        h = box.y1 - box.y0;
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
    }
    return h;
}

int mupdf_page_rotation(mupdf_context handle, mupdf_page page_handle) {
    if (!handle || !page_handle) return 0;
    struct mupdf_context_s* c = CTX(handle);
    fz_page* page = (fz_page*)page_handle;
    int rotation = 0;

    fz_try(c->ctx) {
        pdf_page* ppage = pdf_page_from_fz_page(c->ctx, page);
        if (ppage) {
            fz_rect mediabox;
            fz_matrix ctm;
            pdf_page_transform(c->ctx, ppage, &mediabox, &ctm);
            float deg = atan2f(ctm.b, ctm.a) * (180.0f / (float)M_PI);
            int int_deg = ((int)roundf(deg) % 360 + 360) % 360;
            if (int_deg >= 45 && int_deg < 135) rotation = 90;
            else if (int_deg >= 135 && int_deg < 225) rotation = 180;
            else if (int_deg >= 225 && int_deg < 315) rotation = 270;
            else rotation = 0;
        }
    }
    fz_catch(c->ctx) {
        rotation = 0;
    }
    return rotation;
}

int mupdf_page_bound_box(mupdf_context handle, mupdf_page page,
                         float* width, float* height) {
    struct mupdf_context_s* c = CTX(handle);
    fz_try(c->ctx) {
        fz_rect box = fz_bound_page(c->ctx, (fz_page*)page);
        if (width) *width = box.x1 - box.x0;
        if (height) *height = box.y1 - box.y0;
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return MUPDF_ERR_GENERIC;
    }
    return MUPDF_OK;
}

/* ---- Pixmap rendering ---- */

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
    return mupdf_new_pixmap_from_page_cookie(handle, page, scale_x, scale_y, alpha, cs, NULL);
}

mupdf_pixmap mupdf_new_pixmap_from_page_cookie(
    mupdf_context handle, mupdf_page page,
    float scale_x, float scale_y, int alpha, int cs,
    mupdf_cookie cookie
) {
    struct mupdf_context_s* c = CTX(handle);
    fz_pixmap* pix = NULL;
    fz_var(pix);
    fz_try(c->ctx) {
        fz_matrix ctm = fz_scale(scale_x, scale_y);
        fz_colorspace* colorspace;
        switch (cs) {
            case 1:  colorspace = fz_device_gray(c->ctx); break;
            case 2:  colorspace = fz_device_cmyk(c->ctx); break;
            default: colorspace = fz_device_rgb(c->ctx); break;
        }
        fz_cookie* ck = (fz_cookie*)cookie;
        if (ck) {
            fz_device* dev = NULL;
            fz_var(dev);
            fz_try(c->ctx) {
                fz_rect rect = fz_bound_page(c->ctx, (fz_page*)page);
                fz_irect bbox = fz_round_rect(fz_transform_rect(rect, ctm));
                pix = fz_new_pixmap_with_bbox(c->ctx, colorspace, bbox, NULL, alpha);
                if (alpha) {
                    fz_clear_pixmap(c->ctx, pix);
                } else {
                    fz_clear_pixmap_with_value(c->ctx, pix, 0xff);
                }
                dev = fz_new_draw_device(c->ctx, fz_identity, pix);
                fz_run_page(c->ctx, (fz_page*)page, dev, ctm, ck);
                fz_close_device(c->ctx, dev);
            }
            fz_always(c->ctx) {
                if (dev) fz_drop_device(c->ctx, dev);
            }
            fz_catch(c->ctx) {
                fz_rethrow(c->ctx);
            }
        } else {
            pix = fz_new_pixmap_from_page(c->ctx, (fz_page*)page, ctm, colorspace, alpha);
        }
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (pix) fz_drop_pixmap(c->ctx, pix);
        return NULL;
    }
    return pix;
}

void mupdf_drop_pixmap(mupdf_context handle, mupdf_pixmap pix) {
    if (!handle || !pix) return;
    struct mupdf_context_s* c = CTX(handle);
    fz_drop_pixmap(c->ctx, (fz_pixmap*)pix);
}

int mupdf_pixmap_width(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_width(c->ctx, (fz_pixmap*)pix);
}

int mupdf_pixmap_height(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_height(c->ctx, (fz_pixmap*)pix);
}

int mupdf_pixmap_stride(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_stride(c->ctx, (fz_pixmap*)pix);
}

int mupdf_pixmap_components(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_components(c->ctx, (fz_pixmap*)pix);
}

const unsigned char* mupdf_pixmap_samples(mupdf_context handle, mupdf_pixmap pix) {
    struct mupdf_context_s* c = CTX(handle);
    return fz_pixmap_samples(c->ctx, (fz_pixmap*)pix);
}

/* ---- Display List ---- */

mupdf_display_list mupdf_new_display_list_from_page(mupdf_context handle, mupdf_page page) {
    if (!handle || !page) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    fz_display_list* list = NULL;
    fz_var(list);

    fz_try(c->ctx) {
        list = fz_new_display_list_from_page(c->ctx, (fz_page*)page);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (list) fz_drop_display_list(c->ctx, list);
        return NULL;
    }
    return list;
}

void mupdf_drop_display_list(mupdf_context handle, mupdf_display_list list) {
    if (!handle || !list) return;
    struct mupdf_context_s* c = CTX(handle);
    fz_drop_display_list(c->ctx, (fz_display_list*)list);
}

mupdf_pixmap mupdf_render_display_list(
    mupdf_context handle, mupdf_display_list list,
    float scale_x, float scale_y, int alpha, int cs,
    mupdf_cookie cookie
) {
    if (!handle || !list) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    fz_pixmap* pix = NULL;
    fz_device* dev = NULL;
    fz_cookie* ck = (fz_cookie*)cookie;
    fz_var(pix);
    fz_var(dev);

    fz_try(c->ctx) {
        fz_rect bounds = fz_bound_display_list(c->ctx, (fz_display_list*)list);
        fz_matrix ctm = fz_scale(scale_x, scale_y);
        fz_rect trans_bounds = fz_transform_rect(bounds, ctm);
        fz_irect bbox = fz_round_rect(trans_bounds);

        fz_colorspace* colorspace;
        switch (cs) {
            case 1:  colorspace = fz_device_gray(c->ctx); break;
            case 2:  colorspace = fz_device_cmyk(c->ctx); break;
            default: colorspace = fz_device_rgb(c->ctx); break;
        }

        pix = fz_new_pixmap_with_bbox(c->ctx, colorspace, bbox, NULL, alpha);
        if (alpha) {
            fz_clear_pixmap(c->ctx, pix);
        } else {
            fz_clear_pixmap_with_value(c->ctx, pix, 0xff);
        }

        dev = fz_new_draw_device(c->ctx, fz_identity, pix);
        fz_run_display_list(c->ctx, (fz_display_list*)list, dev, ctm, fz_infinite_rect, ck);
        fz_close_device(c->ctx, dev);
    }
    fz_always(c->ctx) {
        if (dev) fz_drop_device(c->ctx, dev);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (pix) fz_drop_pixmap(c->ctx, pix);
        return NULL;
    }
    return pix;
}

mupdf_pixmap mupdf_render_display_list_rect(
    mupdf_context handle, mupdf_display_list list,
    float scale_x, float scale_y,
    float x0, float y0, float x1, float y1,
    int alpha, int cs,
    mupdf_cookie cookie
) {
    if (!handle || !list) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    fz_pixmap* pix = NULL;
    fz_device* dev = NULL;
    fz_cookie* ck = (fz_cookie*)cookie;
    fz_var(pix);
    fz_var(dev);

    fz_try(c->ctx) {
        fz_rect clip_rect;
        clip_rect.x0 = x0;
        clip_rect.y0 = y0;
        clip_rect.x1 = x1;
        clip_rect.y1 = y1;

        fz_matrix ctm = fz_scale(scale_x, scale_y);
        fz_rect trans_clip = fz_transform_rect(clip_rect, ctm);
        fz_irect bbox = fz_round_rect(trans_clip);

        fz_colorspace* colorspace;
        switch (cs) {
            case 1:  colorspace = fz_device_gray(c->ctx); break;
            case 2:  colorspace = fz_device_cmyk(c->ctx); break;
            default: colorspace = fz_device_rgb(c->ctx); break;
        }

        pix = fz_new_pixmap_with_bbox(c->ctx, colorspace, bbox, NULL, alpha);
        if (alpha) {
            fz_clear_pixmap(c->ctx, pix);
        } else {
            fz_clear_pixmap_with_value(c->ctx, pix, 0xff);
        }

        dev = fz_new_draw_device(c->ctx, fz_identity, pix);
        fz_run_display_list(c->ctx, (fz_display_list*)list, dev, ctm, clip_rect, ck);
        fz_close_device(c->ctx, dev);
    }
    fz_always(c->ctx) {
        if (dev) fz_drop_device(c->ctx, dev);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (pix) fz_drop_pixmap(c->ctx, pix);
        return NULL;
    }
    return pix;
}

/* ---- Text extraction ---- */

char* mupdf_extract_text(mupdf_context handle, mupdf_page page) {
    struct mupdf_context_s* c = CTX(handle);
    fz_stext_page* stext = NULL;
    fz_buffer* buf = NULL;
    fz_output* out = NULL;
    char* result = NULL;
    fz_var(stext);
    fz_var(buf);
    fz_var(out);
    fz_var(result);
    fz_try(c->ctx) {
        stext = fz_new_stext_page_from_page(c->ctx, (fz_page*)page, NULL);
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
        if (result) {
            free(result);
            result = NULL;
        }
        return NULL;
    }
    return result;
}

char* mupdf_extract_html(mupdf_context handle, mupdf_page page) {
    return mupdf_extract_html_options(handle, page, 0);
}

char* mupdf_extract_html_options(mupdf_context handle, mupdf_page page_handle, int preserve_images) {
    if (!handle || !page_handle) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    fz_page* page = (fz_page*)page_handle;
    fz_buffer* buf = NULL;
    char* result = NULL;
    fz_var(buf);
    fz_var(result);

    fz_try(c->ctx) {
        const char* options = preserve_images ? "preserve-images" : "";
        buf = fz_new_buffer_from_page_with_format(c->ctx, page, "html", options, fz_identity, NULL);
        if (buf) {
            size_t len = fz_buffer_storage(c->ctx, buf, NULL);
            result = malloc(len + 1);
            if (result) {
                unsigned char* data = NULL;
                fz_buffer_storage(c->ctx, buf, &data);
                memcpy(result, data, len);
                result[len] = '\0';
            }
        }
    }
    fz_always(c->ctx) {
        if (buf) fz_drop_buffer(c->ctx, buf);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            free(result);
            result = NULL;
        }
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
        count = fz_search_page(c->ctx, (fz_page*)page, needle, hit_mark, hits, 256);
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
    fz_var(result);
    fz_var(count);

    if (hit_count) *hit_count = 0;

    fz_quad hits[1024];
    int hit_mark[1024];

    fz_try(c->ctx) {
        count = fz_search_page(c->ctx, (fz_page*)page, needle, hit_mark, hits, 1024);
        if (count > 0) {
            result = calloc(count, sizeof(fz_quad));
            if (!result) {
                set_error(c, "out of memory");
                count = 0;
            } else {
                for (int i = 0; i < count; i++) {
                    fz_quad q = hits[i];
                    float* out = result + i * 8;
                    out[0] = q.ul.x; out[1] = q.ul.y;
                    out[2] = q.ur.x; out[3] = q.ur.y;
                    out[4] = q.ll.x; out[5] = q.ll.y;
                    out[6] = q.lr.x; out[7] = q.lr.y;
                }
            }
        }
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            free(result);
            result = NULL;
        }
        count = 0;
    }

    if (hit_count) *hit_count = count;
    return result;
}

void mupdf_free_floats(float* ptr) {
    free(ptr);
}

int mupdf_page_select_text(
    mupdf_context handle, mupdf_page page,
    float ax, float ay, float bx, float by, int mode,
    float* snapped_ax, float* snapped_ay,
    float* snapped_bx, float* snapped_by,
    float** quads, int* quad_count,
    char** selected_text
) {
    if (!handle || !page) return MUPDF_ERR_GENERIC;
    struct mupdf_context_s* c = CTX(handle);
    if (quad_count) *quad_count = 0;
    if (quads) *quads = NULL;
    if (selected_text) *selected_text = NULL;

    fz_stext_page* stext = NULL;
    float* quad_buf = NULL;
    char* text_buf = NULL;
    int q_count = 0;

    fz_var(stext);
    fz_var(quad_buf);
    fz_var(text_buf);
    fz_var(q_count);

    fz_try(c->ctx) {
        stext = fz_new_stext_page_from_page(c->ctx, (fz_page*)page, NULL);
        fz_point a = fz_make_point(ax, ay);
        fz_point b = fz_make_point(bx, by);

        /* Snap coordinates according to mode */
        fz_snap_selection(c->ctx, stext, &a, &b, mode);
        if (snapped_ax) *snapped_ax = a.x;
        if (snapped_ay) *snapped_ay = a.y;
        if (snapped_bx) *snapped_bx = b.x;
        if (snapped_by) *snapped_by = b.y;

        /* Extract quads */
        fz_quad raw_quads[1024];
        q_count = fz_highlight_selection(c->ctx, stext, a, b, raw_quads, 1024);
        if (q_count > 0) {
            quad_buf = (float*)malloc(q_count * 8 * sizeof(float));
            if (quad_buf) {
                for (int i = 0; i < q_count; i++) {
                    fz_quad q = raw_quads[i];
                    float* out = quad_buf + i * 8;
                    out[0] = q.ul.x; out[1] = q.ul.y;
                    out[2] = q.ur.x; out[3] = q.ur.y;
                    out[4] = q.ll.x; out[5] = q.ll.y;
                    out[6] = q.lr.x; out[7] = q.lr.y;
                }
            } else {
                q_count = 0;
            }
        }

        /* Copy selected text (crlf = 0 for standard \n) */
        char* copied = fz_copy_selection(c->ctx, stext, a, b, 0);
        if (copied) {
            size_t tlen = strlen(copied);
            text_buf = (char*)malloc(tlen + 1);
            if (text_buf) {
                memcpy(text_buf, copied, tlen + 1);
            }
            fz_free(c->ctx, copied);
        }
    }
    fz_always(c->ctx) {
        if (stext) fz_drop_stext_page(c->ctx, stext);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (quad_buf) { free(quad_buf); quad_buf = NULL; }
        if (text_buf) { free(text_buf); text_buf = NULL; }
        q_count = 0;
        return MUPDF_ERR_GENERIC;
    }

    if (quads) *quads = quad_buf;
    if (quad_count) *quad_count = q_count;
    if (selected_text) *selected_text = text_buf;

    return MUPDF_OK;
}

int mupdf_page_extract_words(
    mupdf_context handle, mupdf_page page_handle,
    mupdf_word_item** words_out, int* word_count_out
) {
    if (!handle || !page_handle) return MUPDF_ERR_GENERIC;
    struct mupdf_context_s* c = CTX(handle);
    if (words_out) *words_out = NULL;
    if (word_count_out) *word_count_out = 0;

    fz_stext_page* stext = NULL;
    mupdf_word_item* items = NULL;
    int count = 0;
    int capacity = 0;

    fz_var(stext);
    fz_var(items);
    fz_var(count);
    fz_var(capacity);

    fz_try(c->ctx) {
        stext = fz_new_stext_page_from_page(c->ctx, (fz_page*)page_handle, NULL);
        if (stext) {
            capacity = 128;
            items = (mupdf_word_item*)malloc(capacity * sizeof(mupdf_word_item));
            if (!items) {
                fz_throw(c->ctx, FZ_ERROR_SYSTEM, "failed to allocate memory for words");
            }

            char word_buf[1024];
            int word_len = 0;
            fz_rect word_rect = fz_empty_rect;
            int in_word = 0;

            for (fz_stext_block* block = stext->first_block; block; block = block->next) {
                if (block->type != FZ_STEXT_BLOCK_TEXT) continue;
                for (fz_stext_line* line = block->u.t.first_line; line; line = line->next) {
                    for (fz_stext_char* ch = line->first_char; ch; ch = ch->next) {
                        int rune = ch->c;
                        int is_space = (rune == ' ' || rune == '\t' || rune == '\n' || rune == '\r' || rune == 0xa0);
                        if (is_space) {
                            if (in_word) {
                                word_buf[word_len] = '\0';
                                if (count >= capacity) {
                                    capacity *= 2;
                                    mupdf_word_item* new_items = (mupdf_word_item*)realloc(items, capacity * sizeof(mupdf_word_item));
                                    if (!new_items) {
                                        fz_throw(c->ctx, FZ_ERROR_SYSTEM, "failed to expand words array");
                                    }
                                    items = new_items;
                                }
                                items[count].x0 = word_rect.x0;
                                items[count].y0 = word_rect.y0;
                                items[count].x1 = word_rect.x1;
                                items[count].y1 = word_rect.y1;
                                items[count].text = strdup(word_buf);
                                count++;

                                in_word = 0;
                                word_len = 0;
                                word_rect = fz_empty_rect;
                            }
                        } else {
                            fz_rect ch_rect = fz_rect_from_quad(ch->quad);
                            if (!in_word) {
                                in_word = 1;
                                word_len = 0;
                                word_rect = ch_rect;
                            } else {
                                word_rect = fz_union_rect(word_rect, ch_rect);
                            }
                            char utf8[8];
                            int bytes = fz_runetochar(utf8, rune);
                            if (word_len + bytes < (int)sizeof(word_buf) - 1) {
                                memcpy(word_buf + word_len, utf8, bytes);
                                word_len += bytes;
                            }
                        }
                    }
                    if (in_word) {
                        word_buf[word_len] = '\0';
                        if (count >= capacity) {
                            capacity *= 2;
                            mupdf_word_item* new_items = (mupdf_word_item*)realloc(items, capacity * sizeof(mupdf_word_item));
                            if (!new_items) {
                                fz_throw(c->ctx, FZ_ERROR_SYSTEM, "failed to expand words array");
                            }
                            items = new_items;
                        }
                        items[count].x0 = word_rect.x0;
                        items[count].y0 = word_rect.y0;
                        items[count].x1 = word_rect.x1;
                        items[count].y1 = word_rect.y1;
                        items[count].text = strdup(word_buf);
                        count++;

                        in_word = 0;
                        word_len = 0;
                        word_rect = fz_empty_rect;
                    }
                }
            }
        }
    }
    fz_always(c->ctx) {
        if (stext) fz_drop_stext_page(c->ctx, stext);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (items) {
            for (int i = 0; i < count; i++) {
                if (items[i].text) free(items[i].text);
            }
            free(items);
            items = NULL;
        }
        count = 0;
        return MUPDF_ERR_GENERIC;
    }

    if (words_out) *words_out = items;
    if (word_count_out) *word_count_out = count;
    return MUPDF_OK;
}

void mupdf_free_words(mupdf_word_item* words, int count) {
    if (!words) return;
    for (int i = 0; i < count; i++) {
        if (words[i].text) free(words[i].text);
    }
    free(words);
}

/* ---- Links ---- */

int mupdf_page_links(
    mupdf_context handle, mupdf_document doc_handle, mupdf_page page_handle,
    mupdf_link_item** items
) {
    if (!handle || !page_handle) return 0;
    struct mupdf_context_s* c = CTX(handle);
    fz_page* page = (fz_page*)page_handle;
    fz_document* doc = (fz_document*)doc_handle;
    fz_link* head = NULL;
    mupdf_link_item* result = NULL;
    int count = 0;
    fz_var(head);
    fz_var(result);
    fz_var(count);

    if (items) *items = NULL;

    fz_try(c->ctx) {
        head = fz_load_links(c->ctx, page);
        for (fz_link* l = head; l; l = l->next) {
            count++;
        }
        if (count > 0) {
            result = calloc(count, sizeof(mupdf_link_item));
            if (!result) {
                set_error(c, "out of memory");
                count = 0;
            } else {
                int i = 0;
                for (fz_link* l = head; l && i < count; l = l->next, i++) {
                    result[i].x0 = l->rect.x0;
                    result[i].y0 = l->rect.y0;
                    result[i].x1 = l->rect.x1;
                    result[i].y1 = l->rect.y1;
                    result[i].uri = l->uri ? strdup(l->uri) : NULL;
                    result[i].is_external = l->uri ? fz_is_external_link(c->ctx, l->uri) : 0;
                    result[i].page_number = -1;
                    if (!result[i].is_external && l->uri && doc) {
                        fz_location loc = fz_resolve_link(c->ctx, doc, l->uri, NULL, NULL);
                        if (loc.page >= 0 || loc.chapter >= 0) {
                            result[i].page_number = fz_page_number_from_location(c->ctx, doc, loc);
                        }
                    }
                }
            }
        }
    }
    fz_always(c->ctx) {
        if (head) fz_drop_link(c->ctx, head);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            for (int i = 0; i < count; i++) {
                free(result[i].uri);
            }
            free(result);
            result = NULL;
        }
        count = -1;
    }

    if (items) *items = result;
    return count;
}

void mupdf_free_links(mupdf_link_item* items, int count) {
    if (!items) return;
    for (int i = 0; i < count; i++) {
        free(items[i].uri);
    }
    free(items);
}

int mupdf_resolve_uri(mupdf_context handle, mupdf_document doc_handle, const char* uri) {
    if (!handle || !doc_handle || !uri) return -1;
    struct mupdf_context_s* c = CTX(handle);
    fz_document* doc = (fz_document*)doc_handle;
    int page_number = -1;

    fz_try(c->ctx) {
        fz_location loc = fz_resolve_link(c->ctx, doc, uri, NULL, NULL);
        if (loc.chapter >= 0 || loc.page >= 0) {
            if (loc.chapter < 0) loc.chapter = 0;
            if (loc.page < 0) loc.page = 0;
            page_number = fz_page_number_from_location(c->ctx, doc, loc);
        }
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        return -1;
    }
    return page_number;
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
    fz_var(outline);
    fz_var(result);
    fz_var(count);

    if (items) *items = NULL;

    fz_try(c->ctx) {
        outline = fz_load_outline(c->ctx, (fz_document*)doc);
        if (outline) {
            count = count_outline(outline);
            if (count > 0) {
                result = calloc(count, sizeof(mupdf_outline_item));
                if (!result) {
                    set_error(c, "out of memory");
                    count = 0;
                } else {
                    int idx = 0;
                    flatten_outline(c->ctx, outline, 0, result, &idx);
                    count = idx;
                }
            }
        }
    }
    fz_always(c->ctx) {
        if (outline) fz_drop_outline(c->ctx, outline);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            for (int i = 0; i < count; i++) {
                free(result[i].title);
                free(result[i].uri);
            }
            free(result);
            result = NULL;
        }
        count = -1;
    }

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

/* ---- Archive ---- */

struct mupdf_archive_s {
    fz_archive* zip;
};

mupdf_archive mupdf_open_archive(mupdf_context handle, const char* filename) {
    if (!handle || !filename) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_archive_s* arch = NULL;
    fz_archive* zip = NULL;
    fz_var(arch);
    fz_var(zip);

    fz_try(c->ctx) {
        zip = fz_open_archive(c->ctx, filename);
        if (zip) {
            arch = calloc(1, sizeof(*arch));
            if (!arch) {
                fz_throw(c->ctx, FZ_ERROR_SYSTEM, "Out of memory allocating archive handle");
            }
            arch->zip = zip;
        }
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (arch) {
            free(arch);
            arch = NULL;
        }
        if (zip) {
            fz_drop_archive(c->ctx, zip);
        }
    }
    return arch;
}

void mupdf_drop_archive(mupdf_context handle, mupdf_archive arch) {
    if (!arch) return;
    struct mupdf_context_s* c = handle ? CTX(handle) : NULL;
    struct mupdf_archive_s* a = (struct mupdf_archive_s*)arch;
    if (a->zip && c && c->ctx) {
        fz_try(c->ctx) {
            fz_drop_archive(c->ctx, a->zip);
        }
        fz_catch(c->ctx) {
            /* ignore */
        }
    }
    free(a);
}

int mupdf_count_archive_entries(mupdf_context handle, mupdf_archive arch) {
    if (!handle || !arch) return -1;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_archive_s* a = (struct mupdf_archive_s*)arch;
    int count = -1;
    fz_try(c->ctx) {
        count = fz_count_archive_entries(c->ctx, a->zip);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        count = -1;
    }
    return count;
}

const char* mupdf_list_archive_entry(mupdf_context handle, mupdf_archive arch, int idx) {
    if (!handle || !arch) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_archive_s* a = (struct mupdf_archive_s*)arch;
    const char* name = NULL;
    fz_try(c->ctx) {
        name = fz_list_archive_entry(c->ctx, a->zip, idx);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        name = NULL;
    }
    return name;
}

int mupdf_has_archive_entry(mupdf_context handle, mupdf_archive arch, const char* name) {
    if (!handle || !arch || !name) return 0;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_archive_s* a = (struct mupdf_archive_s*)arch;
    int has = 0;
    fz_try(c->ctx) {
        has = fz_has_archive_entry(c->ctx, a->zip, name);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        has = 0;
    }
    return has;
}

uint8_t* mupdf_read_archive_entry(mupdf_context handle, mupdf_archive arch, const char* name, int64_t* out_len) {
    if (!handle || !arch || !name) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_archive_s* a = (struct mupdf_archive_s*)arch;
    uint8_t* result = NULL;
    fz_buffer* buf = NULL;
    fz_var(result);
    fz_var(buf);

    fz_try(c->ctx) {
        buf = fz_read_archive_entry(c->ctx, a->zip, name);
        if (buf) {
            unsigned char* data = NULL;
            size_t len = fz_buffer_storage(c->ctx, buf, &data);
            result = malloc(len > 0 ? len : 1);
            if (!result) {
                fz_throw(c->ctx, FZ_ERROR_SYSTEM, "Out of memory allocating buffer for archive entry");
            }
            if (len > 0 && data) {
                memcpy(result, data, len);
            }
            if (out_len) *out_len = (int64_t)len;
        }
    }
    fz_always(c->ctx) {
        if (buf) fz_drop_buffer(c->ctx, buf);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            free(result);
            result = NULL;
        }
        if (out_len) *out_len = 0;
    }
    return result;
}

/* ---- EPUB Spine & Chapter Extraction ---- */

typedef struct mupdf_epub_spine_item_s {
    int index;
    char* id;
    char* path;
    char* media_type;
} mupdf_epub_spine_item_s;

struct mupdf_epub_spine_s {
    fz_archive* zip;
    char* opf_dir;
    int count;
    mupdf_epub_spine_item_s* items;
};

static fz_buffer* read_epub_container_and_prefix(fz_context* ctx, fz_archive* zip, char* prefix, size_t prefix_len) {
    int n = fz_count_archive_entries(ctx, zip);
    int i;
    prefix[0] = 0;

    for (i = 0; i < n; i++) {
        const char* p = fz_list_archive_entry(ctx, zip, i);
        if (p && !strcmp(p, "META-INF/container.xml"))
            return fz_read_archive_entry(ctx, zip, "META-INF/container.xml");
    }

    for (i = 0; i < n; i++) {
        const char* p = fz_list_archive_entry(ctx, zip, i);
        if (!p) continue;
        size_t z = strlen(p);
        size_t z0 = sizeof("META-INF/container.xml") - 1;
        if (z < z0) continue;
        if (!strcmp(p + z - z0, "META-INF/container.xml")) {
            if (z - z0 >= prefix_len) continue;
            memcpy(prefix, p, z - z0);
            prefix[z - z0] = 0;
            return fz_read_archive_entry(ctx, zip, p);
        }
    }

    return fz_read_archive_entry(ctx, zip, "META-INF/container.xml");
}

static const char* epub_rel_path_from_idref(fz_xml* manifest, const char* idref) {
    fz_xml* item;
    if (!idref || !manifest) return NULL;
    item = fz_xml_find_down(manifest, "item");
    while (item) {
        const char* id = fz_xml_att(item, "id");
        if (id && !strcmp(id, idref))
            return fz_xml_att(item, "href");
        item = fz_xml_find_next(item, "item");
    }
    return NULL;
}

static const char* epub_media_type_from_idref(fz_xml* manifest, const char* idref) {
    fz_xml* item;
    if (!idref || !manifest) return "application/xhtml+xml";
    item = fz_xml_find_down(manifest, "item");
    while (item) {
        const char* id = fz_xml_att(item, "id");
        if (id && !strcmp(id, idref)) {
            const char* mt = fz_xml_att(item, "media-type");
            return mt ? mt : "application/xhtml+xml";
        }
        item = fz_xml_find_next(item, "item");
    }
    return "application/xhtml+xml";
}

static const char* epub_path_from_idref(char* path, fz_xml* manifest, const char* base_uri, const char* idref, int n) {
    const char* rel_path = epub_rel_path_from_idref(manifest, idref);
    if (!rel_path) {
        path[0] = 0;
        return NULL;
    }
    if (base_uri && base_uri[0] != '\0') {
        fz_strlcpy(path, base_uri, n);
        fz_strlcat(path, "/", n);
        fz_strlcat(path, rel_path, n);
    } else {
        fz_strlcpy(path, rel_path, n);
    }
    fz_urldecode(path);
    fz_cleanname(path);
    if (path[0] == '/') {
        memmove(path, path + 1, strlen(path));
    }
    return path;
}

mupdf_epub_spine mupdf_open_epub_spine(mupdf_context handle, const char* filename) {
    if (!handle || !filename) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_epub_spine_s* spine = NULL;
    fz_archive* zip = NULL;
    fz_buffer* buf = NULL;
    fz_xml_doc* container_xml = NULL;
    fz_xml_doc* content_opf = NULL;
    char* prefixed_full_path = NULL;

    fz_var(spine);
    fz_var(zip);
    fz_var(buf);
    fz_var(container_xml);
    fz_var(content_opf);
    fz_var(prefixed_full_path);

    fz_try(c->ctx) {
        zip = fz_open_archive(c->ctx, filename);
        if (!zip) {
            fz_throw(c->ctx, FZ_ERROR_GENERIC, "Failed to open archive: %s", filename);
        }

        spine = calloc(1, sizeof(*spine));
        if (!spine) {
            fz_throw(c->ctx, FZ_ERROR_SYSTEM, "Out of memory allocating epub_spine");
        }
        spine->zip = zip;

        char base_uri[2048];
        buf = read_epub_container_and_prefix(c->ctx, zip, base_uri, sizeof(base_uri));
        container_xml = fz_parse_xml(c->ctx, buf, 0);
        fz_drop_buffer(c->ctx, buf);
        buf = NULL;

        size_t prefix_len = strlen(base_uri);
        fz_xml* container = fz_xml_find(fz_xml_root(container_xml), "container");
        fz_xml* rootfiles = fz_xml_find_down(container, "rootfiles");
        fz_xml* rootfile = fz_xml_find_down(rootfiles, "rootfile");
        const char* full_path = fz_xml_att(rootfile, "full-path");
        if (!full_path) {
            fz_throw(c->ctx, FZ_ERROR_FORMAT, "Cannot find rootfile full-path in EPUB container");
        }

        fz_dirname(base_uri + prefix_len, full_path, sizeof(base_uri) - prefix_len);
        spine->opf_dir = strdup(base_uri);

        prefixed_full_path = fz_malloc(c->ctx, strlen(full_path) + prefix_len + 1);
        memcpy(prefixed_full_path, base_uri, prefix_len);
        strcpy(prefixed_full_path + prefix_len, full_path);

        buf = fz_read_archive_entry(c->ctx, zip, prefixed_full_path);
        content_opf = fz_parse_xml(c->ctx, buf, 0);
        fz_drop_buffer(c->ctx, buf);
        buf = NULL;

        fz_xml* package = fz_xml_find(fz_xml_root(content_opf), "package");
        fz_xml* manifest = fz_xml_find_down(package, "manifest");
        fz_xml* spine_xml = fz_xml_find_down(package, "spine");

        // Count spine items
        int count = 0;
        fz_xml* itemref = fz_xml_find_down(spine_xml, "itemref");
        char s[2048];
        while (itemref) {
            const char* idref = fz_xml_att(itemref, "idref");
            if (epub_path_from_idref(s, manifest, base_uri, idref, sizeof(s))) {
                count++;
            }
            itemref = fz_xml_find_next(itemref, "itemref");
        }

        spine->count = count;
        if (count > 0) {
            spine->items = calloc(count, sizeof(mupdf_epub_spine_item_s));
            if (!spine->items) {
                fz_throw(c->ctx, FZ_ERROR_SYSTEM, "Out of memory allocating spine items");
            }

            int idx = 0;
            itemref = fz_xml_find_down(spine_xml, "itemref");
            while (itemref && idx < count) {
                const char* idref = fz_xml_att(itemref, "idref");
                if (epub_path_from_idref(s, manifest, base_uri, idref, sizeof(s))) {
                    spine->items[idx].index = idx;
                    spine->items[idx].id = idref ? strdup(idref) : NULL;
                    spine->items[idx].path = strdup(s);
                    const char* mt = epub_media_type_from_idref(manifest, idref);
                    spine->items[idx].media_type = strdup(mt ? mt : "application/xhtml+xml");
                    idx++;
                }
                itemref = fz_xml_find_next(itemref, "itemref");
            }
            spine->count = idx;
        }
    }
    fz_always(c->ctx) {
        if (content_opf) fz_drop_xml(c->ctx, content_opf);
        if (container_xml) fz_drop_xml(c->ctx, container_xml);
        if (buf) fz_drop_buffer(c->ctx, buf);
        if (prefixed_full_path) fz_free(c->ctx, prefixed_full_path);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (spine) {
            if (spine->items) {
                for (int i = 0; i < spine->count; i++) {
                    free(spine->items[i].id);
                    free(spine->items[i].path);
                    free(spine->items[i].media_type);
                }
                free(spine->items);
            }
            free(spine->opf_dir);
            if (zip) fz_drop_archive(c->ctx, zip);
            free(spine);
            spine = NULL;
        } else if (zip) {
            fz_drop_archive(c->ctx, zip);
        }
    }

    return spine;
}

void mupdf_drop_epub_spine(mupdf_context handle, mupdf_epub_spine spine) {
    if (!spine) return;
    struct mupdf_context_s* c = handle ? CTX(handle) : NULL;
    struct mupdf_epub_spine_s* sp = (struct mupdf_epub_spine_s*)spine;

    if (sp->items) {
        for (int i = 0; i < sp->count; i++) {
            free(sp->items[i].id);
            free(sp->items[i].path);
            free(sp->items[i].media_type);
        }
        free(sp->items);
    }
    free(sp->opf_dir);
    if (sp->zip && c && c->ctx) {
        fz_try(c->ctx) {
            fz_drop_archive(c->ctx, sp->zip);
        }
        fz_catch(c->ctx) {
            /* ignore */
        }
    }
    free(sp);
}

int mupdf_epub_spine_count(mupdf_epub_spine spine) {
    if (!spine) return 0;
    return ((struct mupdf_epub_spine_s*)spine)->count;
}

const char* mupdf_epub_spine_path(mupdf_epub_spine spine, int chapter) {
    if (!spine) return NULL;
    struct mupdf_epub_spine_s* sp = (struct mupdf_epub_spine_s*)spine;
    if (chapter < 0 || chapter >= sp->count) return NULL;
    return sp->items[chapter].path;
}

const char* mupdf_epub_spine_id(mupdf_epub_spine spine, int chapter) {
    if (!spine) return NULL;
    struct mupdf_epub_spine_s* sp = (struct mupdf_epub_spine_s*)spine;
    if (chapter < 0 || chapter >= sp->count) return NULL;
    return sp->items[chapter].id;
}

const char* mupdf_epub_spine_media_type(mupdf_epub_spine spine, int chapter) {
    if (!spine) return NULL;
    struct mupdf_epub_spine_s* sp = (struct mupdf_epub_spine_s*)spine;
    if (chapter < 0 || chapter >= sp->count) return NULL;
    return sp->items[chapter].media_type;
}

char* mupdf_epub_read_chapter_xhtml(mupdf_context handle, mupdf_epub_spine spine, int chapter, int64_t* out_len) {
    if (!handle || !spine) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_epub_spine_s* sp = (struct mupdf_epub_spine_s*)spine;
    if (chapter < 0 || chapter >= sp->count) {
        set_error(c, "Chapter index out of range");
        return NULL;
    }

    const char* path = sp->items[chapter].path;
    if (!path) {
        set_error(c, "Chapter path is null");
        return NULL;
    }

    char* result = NULL;
    fz_buffer* buf = NULL;
    fz_var(result);
    fz_var(buf);

    fz_try(c->ctx) {
        buf = fz_read_archive_entry(c->ctx, sp->zip, path);
        if (!buf) {
            fz_throw(c->ctx, FZ_ERROR_GENERIC, "Failed to read entry: %s", path);
        }
        unsigned char* data = NULL;
        size_t len = fz_buffer_storage(c->ctx, buf, &data);
        result = malloc(len + 1);
        if (!result) {
            fz_throw(c->ctx, FZ_ERROR_SYSTEM, "Out of memory copying chapter xhtml");
        }
        if (len > 0 && data) {
            memcpy(result, data, len);
        }
        result[len] = '\0';
        if (out_len) *out_len = (int64_t)len;
    }
    fz_always(c->ctx) {
        if (buf) fz_drop_buffer(c->ctx, buf);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            free(result);
            result = NULL;
        }
        if (out_len) *out_len = 0;
    }

    return result;
}

uint8_t* mupdf_epub_read_asset(mupdf_context handle, mupdf_epub_spine spine, const char* name, int64_t* out_len) {
    if (!handle || !spine || !name) return NULL;
    struct mupdf_context_s* c = CTX(handle);
    struct mupdf_epub_spine_s* sp = (struct mupdf_epub_spine_s*)spine;

    uint8_t* result = NULL;
    fz_buffer* buf = NULL;
    fz_var(result);
    fz_var(buf);

    const char* clean_name = name;
    while (clean_name[0] == '/') clean_name++;

    fz_try(c->ctx) {
        buf = fz_try_read_archive_entry(c->ctx, sp->zip, clean_name);
        if (!buf && sp->opf_dir && sp->opf_dir[0]) {
            char resolved[2048];
            fz_strlcpy(resolved, sp->opf_dir, sizeof(resolved));
            fz_strlcat(resolved, "/", sizeof(resolved));
            fz_strlcat(resolved, clean_name, sizeof(resolved));
            fz_cleanname(resolved);
            buf = fz_try_read_archive_entry(c->ctx, sp->zip, resolved);
        }
        if (!buf) {
            char normalized[2048];
            fz_strlcpy(normalized, clean_name, sizeof(normalized));
            fz_cleanname(normalized);
            buf = fz_try_read_archive_entry(c->ctx, sp->zip, normalized);
        }
        if (!buf) {
            // Basename / case-insensitive search across archive entries
            const char* base = strrchr(clean_name, '/');
            base = base ? base + 1 : clean_name;
            int n = fz_count_archive_entries(c->ctx, sp->zip);
            for (int i = 0; i < n; i++) {
                const char* entry = fz_list_archive_entry(c->ctx, sp->zip, i);
                if (!entry) continue;
                const char* entry_base = strrchr(entry, '/');
                entry_base = entry_base ? entry_base + 1 : entry;
                if (strcasecmp(entry, clean_name) == 0 || strcasecmp(entry_base, base) == 0) {
                    buf = fz_try_read_archive_entry(c->ctx, sp->zip, entry);
                    if (buf) break;
                }
            }
        }
        if (!buf) {
            fz_throw(c->ctx, FZ_ERROR_GENERIC, "Asset not found in epub: %s", name);
        }
        unsigned char* data = NULL;
        size_t len = fz_buffer_storage(c->ctx, buf, &data);
        result = malloc(len > 0 ? len : 1);
        if (!result) {
            fz_throw(c->ctx, FZ_ERROR_SYSTEM, "Out of memory copying asset");
        }
        if (len > 0 && data) {
            memcpy(result, data, len);
        }
        if (out_len) *out_len = (int64_t)len;
    }
    fz_always(c->ctx) {
        if (buf) fz_drop_buffer(c->ctx, buf);
    }
    fz_catch(c->ctx) {
        set_error(c, fz_caught_message(c->ctx));
        if (result) {
            free(result);
            result = NULL;
        }
        if (out_len) *out_len = 0;
    }

    return result;
}

/* Generic free */
void mupdf_free(void* ptr) {
    if (ptr) free(ptr);
}

