# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\its.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\its.c" 2
/**
 * its.c — Internal Trusted Storage for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_its_storage[64], g_its_file_count, g_its_initialized
 *   - Types: its_flags_t, its_file_t
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
# 11 "D:\\programming\\sw_model\\fw_samples\\lib\\its.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\its.c" 2

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    ITS_FLAG_NONE = 0,
    ITS_FLAG_ENCRYPT = 1,
    ITS_FLAG_AUTHENTICATE = 2
} its_flags_t;

typedef struct {
    uint32_t file_id;
    uint8_t data[512];
    uint32_t size;
    uint32_t flags;
} its_file_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static its_file_t g_its_storage[64];
static uint32_t g_its_file_count = 0;
static _Bool g_its_initialized = 0;

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
    (void)__builtin_memset(g_its_storage, 0, sizeof(g_its_storage));
    g_its_file_count = 0;
    g_its_initialized = 1;
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
    (void)__builtin_memset(g_its_storage[idx].data, 0, 512);
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
    (void)__builtin_memcpy(g_its_storage[idx].data, data, size);
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
    (void)__builtin_memcpy(data, g_its_storage[idx].data, g_its_storage[idx].size);
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
        (void)__builtin_memmove(&g_its_storage[idx], &g_its_storage[idx + 1],
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
