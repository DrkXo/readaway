#ifndef MUPDF_WRAPPER_H
#define MUPDF_WRAPPER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque handles */
typedef void* mupdf_context;
typedef void* mupdf_document;
typedef void* mupdf_page;
typedef void* mupdf_pixmap;

/* Error codes */
#define MUPDF_OK 0
#define MUPDF_ERR_GENERIC 1
#define MUPDF_ERR_MEMORY 2
#define MUPDF_ERR_IO 3
#define MUPDF_ERR_FORMAT 4
#define MUPDF_ERR_PASSWORD 5

/* Context */
mupdf_context mupdf_new_context(void);
void mupdf_drop_context(mupdf_context ctx);

/* Document */
mupdf_document mupdf_open_document(mupdf_context ctx, const char* filename);
mupdf_document mupdf_open_document_from_data(mupdf_context ctx, const uint8_t* data, int64_t size);
void mupdf_drop_document(mupdf_context ctx, mupdf_document doc);
int mupdf_needs_password(mupdf_context ctx, mupdf_document doc);
int mupdf_authenticate_password(mupdf_context ctx, mupdf_document doc, const char* password);
int mupdf_count_pages(mupdf_context ctx, mupdf_document doc);
int mupdf_lookup_metadata(mupdf_context ctx, mupdf_document doc, const char* key, char* buf, int bufsize);
int mupdf_layout_document(mupdf_context ctx, mupdf_document doc, float width, float height, float em);
int mupdf_is_reflowable(mupdf_context ctx, mupdf_document doc);
int mupdf_count_chapters(mupdf_context ctx, mupdf_document doc);
int mupdf_count_chapter_pages(mupdf_context ctx, mupdf_document doc, int chapter);
mupdf_page mupdf_load_chapter_page(mupdf_context ctx, mupdf_document doc, int chapter, int page);

/* Permissions — pass one of 'p','c','e','n','f','y','a','h' */
int mupdf_has_permission(mupdf_context ctx, mupdf_document doc, int permission);

/* Page label — writes label into buf, returns length, or -1 on error */
int mupdf_page_label(mupdf_context ctx, mupdf_page page, char* buf, int bufsize);

/* Page */
mupdf_page mupdf_load_page(mupdf_context ctx, mupdf_document doc, int number);
void mupdf_drop_page(mupdf_context ctx, mupdf_page page);
float mupdf_page_width(mupdf_context ctx, mupdf_page page);
float mupdf_page_height(mupdf_context ctx, mupdf_page page);
int mupdf_page_bound_box(mupdf_context ctx, mupdf_page page,
                         float* width, float* height);

/* Pixmap rendering */
/* cs: 0=RGB (default), 1=gray, 2=CMYK */
mupdf_pixmap mupdf_new_pixmap_from_page(
    mupdf_context ctx, mupdf_page page,
    float scale_x, float scale_y, int alpha
);
mupdf_pixmap mupdf_new_pixmap_from_page_cs(
    mupdf_context ctx, mupdf_page page,
    float scale_x, float scale_y, int alpha, int cs
);
void mupdf_drop_pixmap(mupdf_context ctx, mupdf_pixmap pix);
int mupdf_pixmap_width(mupdf_context ctx, mupdf_pixmap pix);
int mupdf_pixmap_height(mupdf_context ctx, mupdf_pixmap pix);
int mupdf_pixmap_stride(mupdf_context ctx, mupdf_pixmap pix);
int mupdf_pixmap_components(mupdf_context ctx, mupdf_pixmap pix);
const unsigned char* mupdf_pixmap_samples(mupdf_context ctx, mupdf_pixmap pix);

/* Text extraction */
char* mupdf_extract_text(mupdf_context ctx, mupdf_page page);
char* mupdf_extract_html(mupdf_context ctx, mupdf_page page);
void mupdf_free_string(mupdf_context ctx, char* str);

/* Search */
int mupdf_search_page(mupdf_context ctx, mupdf_page page, const char* needle,
                       int* hit_count);

/* Returns an allocated array of 8 floats per hit (ul_x,ul_y,ur_x,ur_y,ll_x,ll_y,lr_x,lr_y).
   Caller must free with mupdf_free_floats. Sets *hit_count to the number of hits. */
float* mupdf_search_page_quads(mupdf_context ctx, mupdf_page page,
                                const char* needle, int* hit_count);
void mupdf_free_floats(float* ptr);

/* Outline (table of contents) */
typedef struct mupdf_outline_item {
    char* title;
    char* uri;
    int chapter;
    int page;
    int level;
    int is_open;
} mupdf_outline_item;

/* Flattens the outline tree into an array. Returns count, or -1 on error.
   Caller must free with mupdf_outline_free. */
int mupdf_outline_flatten(mupdf_context ctx, mupdf_document doc,
                           mupdf_outline_item** items);
void mupdf_outline_free(mupdf_outline_item* items, int count);

/* Last error message (valid until next mupdf call on same context) */
const char* mupdf_last_error(mupdf_context ctx);

#ifdef __cplusplus
}
#endif

#endif /* MUPDF_WRAPPER_H */
