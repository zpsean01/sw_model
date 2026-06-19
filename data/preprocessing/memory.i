# 1 "D:\\programming\\sw_model\\fw_samples\\src\\memory.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\memory.c" 2
/**
 * memory.c — Memory Pool Manager
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
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
# 8 "D:\\programming\\sw_model\\fw_samples\\src\\memory.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 9 "D:\\programming\\sw_model\\fw_samples\\src\\memory.c" 2

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */




/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef struct boundary_tag
{
    uint32_t magic; /* must be 0xA5A5A5A5 */
    uint32_t size;
    _Bool free;
    struct boundary_tag *next;
} boundary_tag_t;

typedef struct
{
    void *pool_base;
    uint32_t pool_size;
    uint32_t block_size;
    uint32_t alloc_count;
    uint32_t free_count;
} mem_pool_t;

typedef struct
{
    uint32_t total_allocated;
    uint32_t peak_allocated;
    uint32_t alloc_count;
} heap_usage_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static uint8_t g_memory_pool[8192];
static mem_pool_t g_mem_pool;
static _Bool g_mem_initialized = 0;
static heap_usage_t g_heap_usage = { 0u, 0u, 0u };

/* ---------------------------------------------------------------------------
 * MEM_Init — initialise the memory pool
 * --------------------------------------------------------------------------- */
void MEM_Init(void)
{
    if (g_mem_initialized)
    {
        return;
    }

    /* Setup pool descriptor */
    g_mem_pool.pool_base = (void *)g_memory_pool;
    g_mem_pool.pool_size = sizeof(g_memory_pool);
    g_mem_pool.block_size = 16u; /* minimum alignment / block size */
    g_mem_pool.alloc_count = 0u;
    g_mem_pool.free_count = 1u;

    /* Initialise the first (and only) free block as a boundary tag */
    boundary_tag_t *tag = (boundary_tag_t *)g_memory_pool;
    tag->magic = 0xA5A5A5A5UL;
    tag->size = sizeof(g_memory_pool) - sizeof(boundary_tag_t);
    tag->free = 1;
    tag->next = (boundary_tag_t *)0;

    g_heap_usage.total_allocated = 0u;
    g_heap_usage.peak_allocated = 0u;
    g_heap_usage.alloc_count = 0u;

    g_mem_initialized = 1;
}

/* ---------------------------------------------------------------------------
 * MEM_Alloc — allocate a block from the pool (first-fit)
 * --------------------------------------------------------------------------- */
void *MEM_Alloc(uint32_t size)
{
    if (!g_mem_initialized || size == 0u)
    {
        return (void *)0;
    }

    /* Align size to 8 bytes */
    size = (size + 7u) & ~7u;

    boundary_tag_t *curr = (boundary_tag_t *)g_mem_pool.pool_base;

    while (curr != (boundary_tag_t *)0)
    {
        if (curr->free && (curr->size >= size))
        {
            /* Split if remaining space is large enough for another tag + minimal block */
            uint32_t remaining = curr->size - size;
            if (remaining > sizeof(boundary_tag_t) + 16u)
            {
                boundary_tag_t *new_tag =
                    (boundary_tag_t *)((uint8_t *)(curr + 1) + size);
                new_tag->magic = 0xA5A5A5A5UL;
                new_tag->size = remaining - sizeof(boundary_tag_t);
                new_tag->free = 1;
                new_tag->next = curr->next;

                curr->size = size;
                curr->next = new_tag;
            }

            curr->free = 0;
            g_mem_pool.alloc_count++;
            g_mem_pool.free_count--;

            g_heap_usage.total_allocated += size;
            g_heap_usage.alloc_count++;
            if (g_heap_usage.total_allocated > g_heap_usage.peak_allocated)
            {
                g_heap_usage.peak_allocated = g_heap_usage.total_allocated;
            }

            return (void *)(curr + 1);
        }
        curr = curr->next;
    }

    /* No suitable block found */
    return (void *)0;
}

/* ---------------------------------------------------------------------------
 * MEM_Free — return a block to the pool
 * --------------------------------------------------------------------------- */
void MEM_Free(void *ptr)
{
    if (ptr == (void *)0 || !g_mem_initialized)
    {
        return;
    }

    boundary_tag_t *tag = (boundary_tag_t *)((uint8_t *)ptr - sizeof(boundary_tag_t));

    if (tag->magic != 0xA5A5A5A5UL)
    {
        /* Corrupted boundary tag — silently ignore */
        return;
    }

    tag->free = 1;
    g_mem_pool.alloc_count--;
    g_mem_pool.free_count++;

    g_heap_usage.total_allocated -= tag->size;

    /* Coalesce with next free block */
    if (tag->next != (boundary_tag_t *)0 && tag->next->free)
    {
        tag->size += sizeof(boundary_tag_t) + tag->next->size;
        tag->next = tag->next->next;
        g_mem_pool.free_count--;
    }

    /* Coalesce with previous free block (linear search) */
    boundary_tag_t *prev = (boundary_tag_t *)g_mem_pool.pool_base;
    while (prev != (boundary_tag_t *)0 && prev->next != tag)
    {
        prev = prev->next;
    }

    if (prev != (boundary_tag_t *)0 && prev->free)
    {
        prev->size += sizeof(boundary_tag_t) + tag->size;
        prev->next = tag->next;
        g_mem_pool.free_count--;
    }
}

/* ---------------------------------------------------------------------------
 * MEM_GetFreeSize — total free bytes available
 * --------------------------------------------------------------------------- */
uint32_t MEM_GetFreeSize(void)
{
    uint32_t free_size = 0u;
    boundary_tag_t *curr = (boundary_tag_t *)g_mem_pool.pool_base;

    while (curr != (boundary_tag_t *)0)
    {
        if (curr->free)
        {
            free_size += curr->size;
        }
        curr = curr->next;
    }

    return free_size;
}

/* ---------------------------------------------------------------------------
 * MEM_GetAllocSize — total allocated bytes
 * --------------------------------------------------------------------------- */
uint32_t MEM_GetAllocSize(void)
{
    return g_heap_usage.total_allocated;
}

/* ---------------------------------------------------------------------------
 * MEM_ProtectRegion — configure MPU for a memory region
 * --------------------------------------------------------------------------- */
void MEM_ProtectRegion(uint32_t region, uint32_t base, uint32_t size, uint32_t attrs)
{
    (*(volatile uint32_t *)0xE000ED98UL) = region;
    (*(volatile uint32_t *)0xE000ED9CUL) = base | (1u << 4); /* VALID bit set */
    (*(volatile uint32_t *)0xE000EDA0UL) = (attrs & 0x00FFFFFFUL) | (1u << 0); /* ENABLE */

    __asm__("dsb sy" ::: "memory");
    __asm__("isb sy" ::: "memory");
}
