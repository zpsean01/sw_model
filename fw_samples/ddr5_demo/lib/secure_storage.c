/**
 * secure_storage.c — Secure Storage Service for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_storage_items[32], g_storage_item_count, g_storage_initialized
 *   - Types: storage_id_t, storage_item_t
 *   - 8 visible + 1 static = 9 functions
 */

#include <stdint.h>
#include <stdbool.h>

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    STORAGE_APP    = 0,
    STORAGE_SYSTEM = 1,
    STORAGE_UPDATE = 2
} storage_id_t;

typedef struct {
    uint32_t item_id;
    uint8_t  data[512];
    uint32_t size;
    uint32_t flags;
    bool     authenticated;
} storage_item_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static storage_item_t g_storage_items[32];
static uint32_t       g_storage_item_count = 0;
static bool           g_storage_initialized = false;

/* ------------------------------------------------------------------ */
/*  Static helpers                                                     */
/* ------------------------------------------------------------------ */

/**
 * storage_find_item — Find a storage item by its ID.
 * @param item_id  identifier to search for.
 * @return index into g_storage_items, or -1 if not found.
 */
static int32_t storage_find_item(uint32_t item_id)
{
    for (int32_t i = 0; i < (int32_t)g_storage_item_count; ++i) {
        if (g_storage_items[i].item_id == item_id) {
            return i;
        }
    }
    return -1;
}

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * STORAGE_Init — Initialise the secure storage service.
 */
void STORAGE_Init(void)
{
    (void)__builtin_memset(g_storage_items, 0, sizeof(g_storage_items));
    g_storage_item_count = 0;
    g_storage_initialized = true;
}

/**
 * STORAGE_Write — Write (create or update) a storage item.
 * @param item_id  item identifier.
 * @param data     data to store.
 * @param size     size of data (max 512).
 * @param flags    attribute flags.
 * @return 0 on success, -1 on failure.
 */
int32_t STORAGE_Write(uint32_t item_id, const uint8_t *data,
                      uint32_t size, uint32_t flags)
{
    if (!g_storage_initialized) return -1;
    if (size > 512) return -1;

    int32_t idx = storage_find_item(item_id);
    if (idx >= 0) {
        /* Update existing */
        g_storage_items[idx].size = size;
        g_storage_items[idx].flags = flags;
        g_storage_items[idx].authenticated = false;
        (void)__builtin_memcpy(g_storage_items[idx].data, data, size);
        return 0;
    }

    /* Create new */
    if (g_storage_item_count >= 32) return -1;

    idx = (int32_t)g_storage_item_count;
    g_storage_items[idx].item_id = item_id;
    g_storage_items[idx].size = size;
    g_storage_items[idx].flags = flags;
    g_storage_items[idx].authenticated = false;
    (void)__builtin_memcpy(g_storage_items[idx].data, data, size);
    ++g_storage_item_count;
    return 0;
}

/**
 * STORAGE_Read — Read a storage item.
 * @param item_id  item identifier.
 * @param data     output buffer (must hold at least 512 bytes).
 * @param size     output size read.
 * @return 0 on success, -1 if not found.
 */
int32_t STORAGE_Read(uint32_t item_id, uint8_t *data, uint32_t *size)
{
    if (!g_storage_initialized) return -1;

    int32_t idx = storage_find_item(item_id);
    if (idx < 0) return -1;

    *size = g_storage_items[idx].size;
    (void)__builtin_memcpy(data, g_storage_items[idx].data, g_storage_items[idx].size);
    return 0;
}

/**
 * STORAGE_Delete — Delete a storage item.
 * @param item_id  item identifier.
 * @return 0 on success, -1 if not found.
 */
int32_t STORAGE_Delete(uint32_t item_id)
{
    if (!g_storage_initialized) return -1;

    int32_t idx = storage_find_item(item_id);
    if (idx < 0) return -1;

    /* Shift remaining items down */
    uint32_t count = g_storage_item_count - (uint32_t)idx - 1U;
    if (count > 0U) {
        (void)__builtin_memmove(&g_storage_items[idx], &g_storage_items[idx + 1],
                      count * sizeof(storage_item_t));
    }
    --g_storage_item_count;
    return 0;
}

/**
 * STORAGE_GetInfo — Get metadata about a storage item.
 * @param item_id      item identifier.
 * @param out_size     output: stored data size.
 * @param out_flags    output: attribute flags.
 * @return 0 on success, -1 if not found.
 */
int32_t STORAGE_GetInfo(uint32_t item_id, uint32_t *out_size,
                        uint32_t *out_flags)
{
    if (!g_storage_initialized) return -1;

    int32_t idx = storage_find_item(item_id);
    if (idx < 0) return -1;

    *out_size = g_storage_items[idx].size;
    *out_flags = g_storage_items[idx].flags;
    return 0;
}

/**
 * STORAGE_List — List all stored item IDs.
 * @param ids    output buffer for item IDs.
 * @param count  output: number of items stored.
 * @return 0 on success.
 */
int32_t STORAGE_List(uint32_t *ids, uint32_t *count)
{
    if (!g_storage_initialized) return -1;

    *count = g_storage_item_count;
    for (uint32_t i = 0; i < g_storage_item_count; ++i) {
        ids[i] = g_storage_items[i].item_id;
    }
    return 0;
}

/**
 * STORAGE_IsAuthenticated — Check whether a storage item is authenticated.
 * @param item_id  item identifier.
 * @param auth     output: true if authenticated.
 * @return 0 on success, -1 if not found.
 */
int32_t STORAGE_IsAuthenticated(uint32_t item_id, bool *auth)
{
    if (!g_storage_initialized) return -1;

    int32_t idx = storage_find_item(item_id);
    if (idx < 0) return -1;

    *auth = g_storage_items[idx].authenticated;
    return 0;
}

/**
 * STORAGE_EraseAll — Erase all stored items.
 */
void STORAGE_EraseAll(void)
{
    if (!g_storage_initialized) return;

    (void)__builtin_memset(g_storage_items, 0, sizeof(g_storage_items));
    g_storage_item_count = 0;
}