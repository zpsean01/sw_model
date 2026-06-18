/**
 * its.c — Internal Trusted Storage for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_its_storage[64], g_its_file_count, g_its_initialized
 *   - Types: its_flags_t, its_file_t
 *   - 8 visible + 1 static = 9 functions
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    ITS_FLAG_NONE         = 0,
    ITS_FLAG_ENCRYPT      = 1,
    ITS_FLAG_AUTHENTICATE = 2
} its_flags_t;

typedef struct {
    uint32_t file_id;
    uint8_t  data[512];
    uint32_t size;
    uint32_t flags;
} its_file_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static its_file_t g_its_storage[64];
static uint32_t   g_its_file_count = 0;
static bool       g_its_initialized = false;

/* ------------------------------------------------------------------ */
/*  Static helpers                                                     */
/* ------------------------------------------------------------------ */

/**
 * its_find_file — Find a file in ITS storage by ID.
 * @param file_id  file identifier.
 * @return index into g_its_storage, or -1 if not found.
 */
static int32_t its_find_file(uint32_t file_id)
{
    for (int32_t i = 0; i < (int32_t)g_its_file_count; ++i) {
        if (g_its_storage[i].file_id == file_id) {
            return i;
        }
    }
    return -1;
}

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * ITS_Init — Initialise the internal trusted storage.
 */
void ITS_Init(void)
{
    (void)memset(g_its_storage, 0, sizeof(g_its_storage));
    g_its_file_count = 0;
    g_its_initialized = true;
}

/**
 * ITS_Create — Create a new file in ITS.
 * @param file_id  file identifier.
 * @param flags    file attributes (ITS_FLAG_*).
 * @return 0 on success, -1 on failure (full or duplicate).
 */
int32_t ITS_Create(uint32_t file_id, uint32_t flags)
{
    if (!g_its_initialized) return -1;
    if (its_find_file(file_id) >= 0) return -1;
    if (g_its_file_count >= 64) return -1;

    uint32_t idx = g_its_file_count;
    g_its_storage[idx].file_id = file_id;
    g_its_storage[idx].size = 0;
    g_its_storage[idx].flags = flags;
    (void)memset(g_its_storage[idx].data, 0, 512);
    ++g_its_file_count;
    return 0;
}

/**
 * ITS_Write — Write data to an existing ITS file.
 * @param file_id  file identifier.
 * @param data     data to write.
 * @param size     number of bytes to write (max 512).
 * @return 0 on success, -1 if file not found or size exceeds limit.
 */
int32_t ITS_Write(uint32_t file_id, const uint8_t *data, uint32_t size)
{
    if (!g_its_initialized) return -1;
    if (size > 512) return -1;

    int32_t idx = its_find_file(file_id);
    if (idx < 0) return -1;

    g_its_storage[idx].size = size;
    (void)memcpy(g_its_storage[idx].data, data, size);
    return 0;
}

/**
 * ITS_Read — Read data from an ITS file.
 * @param file_id  file identifier.
 * @param data     output buffer (must hold at least 512 bytes).
 * @param size     output: number of bytes read.
 * @return 0 on success, -1 if file not found.
 */
int32_t ITS_Read(uint32_t file_id, uint8_t *data, uint32_t *size)
{
    if (!g_its_initialized) return -1;

    int32_t idx = its_find_file(file_id);
    if (idx < 0) return -1;

    *size = g_its_storage[idx].size;
    (void)memcpy(data, g_its_storage[idx].data, g_its_storage[idx].size);
    return 0;
}

/**
 * ITS_Delete — Delete a file from ITS.
 * @param file_id  file identifier.
 * @return 0 on success, -1 if not found.
 */
int32_t ITS_Delete(uint32_t file_id)
{
    if (!g_its_initialized) return -1;

    int32_t idx = its_find_file(file_id);
    if (idx < 0) return -1;

    /* Shift remaining entries */
    uint32_t count = g_its_file_count - (uint32_t)idx - 1U;
    if (count > 0U) {
        (void)memmove(&g_its_storage[idx], &g_its_storage[idx + 1],
                      count * sizeof(its_file_t));
    }
    --g_its_file_count;
    return 0;
}

/**
 * ITS_GetSize — Get the size of an ITS file.
 * @param file_id  file identifier.
 * @param size     output: file size.
 * @return 0 on success, -1 if not found.
 */
int32_t ITS_GetSize(uint32_t file_id, uint32_t *size)
{
    if (!g_its_initialized) return -1;

    int32_t idx = its_find_file(file_id);
    if (idx < 0) return -1;

    *size = g_its_storage[idx].size;
    return 0;
}

/**
 * ITS_GetFlags — Get the flags of an ITS file.
 * @param file_id  file identifier.
 * @param flags    output: file flags.
 * @return 0 on success, -1 if not found.
 */
int32_t ITS_GetFlags(uint32_t file_id, uint32_t *flags)
{
    if (!g_its_initialized) return -1;

    int32_t idx = its_find_file(file_id);
    if (idx < 0) return -1;

    *flags = g_its_storage[idx].flags;
    return 0;
}

/**
 * ITS_EncryptFile — XOR-encrypt the data in an ITS file in-place.
 * @param file_id  file identifier.
 * @param key      XOR key bytes.
 * @param key_len  key length (bytes are repeated cyclically).
 * @return 0 on success, -1 if file not found.
 */
int32_t ITS_EncryptFile(uint32_t file_id, const uint8_t *key, uint32_t key_len)
{
    if (!g_its_initialized) return -1;
    if (key_len == 0) return -1;

    int32_t idx = its_find_file(file_id);
    if (idx < 0) return -1;

    for (uint32_t i = 0; i < g_its_storage[idx].size; ++i) {
        g_its_storage[idx].data[i] ^= key[i % key_len];
    }

    /* Mark as encrypted */
    g_its_storage[idx].flags |= ITS_FLAG_ENCRYPT;
    return 0;
}