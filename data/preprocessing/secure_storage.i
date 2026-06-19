# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\secure_storage.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\secure_storage.c" 2
/**
 * secure_storage.c — Secure Storage Service for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_storage_items[32], g_storage_item_count, g_storage_initialized
 *   - Types: storage_id_t, storage_item_t
 *   - 8 visible + 1 static = 9 functions
 */

# 1 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 1 3
/*===---- stdint.h - Standard header for sized integer types --------------===*\
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
\*===----------------------------------------------------------------------===*/


// AIX system headers need stdint.h to be re-enterable while _STD_TYPES_T
// is defined until an inclusion of it without _STD_TYPES_T occurs, in which
// case the header guard macro is defined.








/* If we're hosted, fall back to the system's stdint.h, which might have
 * additional definitions.
 */
# 69 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C99 7.18.1.1 Exact-width integer types.
 * C99 7.18.1.2 Minimum-width integer types.
 * C99 7.18.1.3 Fastest minimum-width integer types.
 *
 * The standard requires that exact-width type be defined for 8-, 16-, 32-, and
 * 64-bit types if they are implemented. Other exact width types are optional.
 * This implementation defines an exact-width types for every integer width
 * that is represented in the standard integer types.
 *
 * The standard also requires minimum-width types be defined for 8-, 16-, 32-,
 * and 64-bit widths regardless of whether there are corresponding exact-width
 * types.
 *
 * To accommodate targets that are missing types that are exactly 8, 16, 32, or
 * 64 bits wide, this implementation takes an approach of cascading
 * redefinitions, redefining __int_leastN_t to successively smaller exact-width
 * types. It is therefore important that the types are defined in order of
 * descending widths.
 *
 * We currently assume that the minimum-width types and the fastest
 * minimum-width types are the same. This is allowed by the standard, but is
 * suboptimal.
 *
 * In violation of the standard, some targets do not implement a type that is
 * wide enough to represent all of the required widths (8-, 16-, 32-, 64-bit).
 * To accommodate these targets, a required minimum-width type is only
 * defined if there exists an exact-width type of equal or greater width.
 */



typedef long long int int64_t;

typedef long long unsigned int uint64_t;
# 122 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int64_t int_least64_t;
typedef uint64_t uint_least64_t;
typedef int64_t int_fast64_t;
typedef uint64_t uint_fast64_t;
# 197 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int int32_t;




typedef unsigned int uint32_t;
# 220 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int32_t int_least32_t;
typedef uint32_t uint_least32_t;
typedef int32_t int_fast32_t;
typedef uint32_t uint_fast32_t;
# 245 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef short int16_t;

typedef unsigned short uint16_t;
# 259 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int16_t int_least16_t;
typedef uint16_t uint_least16_t;
typedef int16_t int_fast16_t;
typedef uint16_t uint_fast16_t;





typedef signed char int8_t;

typedef unsigned char uint8_t;







typedef int8_t int_least8_t;
typedef uint8_t uint_least8_t;
typedef int8_t int_fast8_t;
typedef uint8_t uint_fast8_t;


/* prevent glibc sys/types.h from defining conflicting types */




/* C99 7.18.1.4 Integer types capable of holding object pointers.
 */




typedef int intptr_t;






typedef unsigned int uintptr_t;



/* C99 7.18.1.5 Greatest-width integer types.
 */
typedef long long int intmax_t;
typedef long long unsigned int uintmax_t;

/* C99 7.18.4 Macros for minimum-width integer constants.
 *
 * The standard requires that integer constant macros be defined for all the
 * minimum-width types defined above. As 8-, 16-, 32-, and 64-bit minimum-width
 * types are required, the corresponding integer constant macros are defined
 * here. This implementation also defines minimum-width types for every other
 * integer width that the target implements, so corresponding macros are
 * defined below, too.
 *
 * Note that C++ should not check __STDC_CONSTANT_MACROS here, contrary to the
 * claims of the C standard (see C++ 18.3.1p2, [cstdint.syn]).
 */
# 372 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C99 7.18.2.1 Limits of exact-width integer types.
 * C99 7.18.2.2 Limits of minimum-width integer types.
 * C99 7.18.2.3 Limits of fastest minimum-width integer types.
 *
 * The presence of limit macros are completely optional in C99.  This
 * implementation defines limits for all of the types (exact- and
 * minimum-width) that it defines above, using the limits of the minimum-width
 * type for any types that do not have exact-width representations.
 *
 * As in the type definitions, this section takes an approach of
 * successive-shrinking to determine which limits to use for the standard (8,
 * 16, 32, 64) bit widths when they don't have exact representations. It is
 * therefore important that the definitions be kept in order of decending
 * widths.
 *
 * Note that C++ should not check __STDC_LIMIT_MACROS here, contrary to the
 * claims of the C standard (see C++ 18.3.1p2, [cstdint.syn]).
 */
# 763 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* Some utility macros */






/* C99 7.18.2.4 Limits of integer types capable of holding object pointers. */
/* C99 7.18.3 Limits of other integer types. */
# 780 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C23 7.22.2.4 Width of integer types capable of holding object pointers. */







/* ISO9899:2011 7.20 (C11 Annex K): Define RSIZE_MAX if __STDC_WANT_LIB_EXT1__
 * is enabled. */




/* C99 7.18.2.5 Limits of greatest-width integer types. */




/* C23 7.22.2.5 Width of greatest-width integer types. */







/* C99 7.18.3 Limits of other integer types. */
# 829 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* 7.18.4.2 Macros for greatest-width integer constants. */



/* C23 7.22.3.x Width of other integer types. */
# 11 "D:\\programming\\sw_model\\fw_samples\\lib\\secure_storage.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\secure_storage.c" 2

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    STORAGE_APP = 0,
    STORAGE_SYSTEM = 1,
    STORAGE_UPDATE = 2
} storage_id_t;

typedef struct {
    uint32_t item_id;
    uint8_t data[512];
    uint32_t size;
    uint32_t flags;
    _Bool authenticated;
} storage_item_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static storage_item_t g_storage_items[32];
static uint32_t g_storage_item_count = 0;
static _Bool g_storage_initialized = 0;

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
    g_storage_initialized = 1;
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
        g_storage_items[idx].authenticated = 0;
        (void)__builtin_memcpy(g_storage_items[idx].data, data, size);
        return 0;
    }

    /* Create new */
    if (g_storage_item_count >= 32) return -1;

    idx = (int32_t)g_storage_item_count;
    g_storage_items[idx].item_id = item_id;
    g_storage_items[idx].size = size;
    g_storage_items[idx].flags = flags;
    g_storage_items[idx].authenticated = 0;
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
int32_t STORAGE_IsAuthenticated(uint32_t item_id, _Bool *auth)
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
