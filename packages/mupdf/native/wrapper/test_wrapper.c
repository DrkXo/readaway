#include <stdio.h>
#include <string.h>
#include "mupdf_wrapper.h"

int main(void) {
    printf("MuPDF wrapper smoke test\n");

    mupdf_context ctx = mupdf_new_context();
    if (!ctx) {
        fprintf(stderr, "FAIL: could not create context\n");
        return 1;
    }
    printf("OK: context created\n");

    /* Try opening a nonexistent file — should fail gracefully */
    mupdf_document doc = mupdf_open_document(ctx, "/nonexistent.pdf");
    if (doc != NULL) {
        fprintf(stderr, "FAIL: expected NULL for nonexistent file\n");
        mupdf_drop_document(ctx, doc);
        mupdf_drop_context(ctx);
        return 1;
    }
    printf("OK: nonexistent file returns NULL, error: %s\n", mupdf_last_error(ctx));

    mupdf_drop_context(ctx);
    printf("ALL PASSED\n");
    return 0;
}
