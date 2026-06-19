# 1 "D:\\programming\\sw_model\\fw_samples\\src\\fault.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\fault.c" 2
/**
 * fault.c — Fault Handlers and Logging
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
# 8 "D:\\programming\\sw_model\\fw_samples\\src\\fault.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 9 "D:\\programming\\sw_model\\fw_samples\\src\\fault.c" 2

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */





/* CFSR sub-register masks */




/* HFSR bits */




/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    FAULT_HARD = 0,
    FAULT_MEM = 1,
    FAULT_BUS = 2,
    FAULT_USAGE = 3,
    FAULT_SECURE = 4
} fault_type_t;

typedef struct
{
    fault_type_t type;
    uint32_t addr;
    uint32_t cfsr;
    uint32_t timestamp;
} fault_record_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static fault_record_t g_fault_log[16];
static uint32_t g_fault_count = 0u;
static uint32_t g_fault_next_index = 0u;

/* ---------------------------------------------------------------------------
 * Forward declarations
 * --------------------------------------------------------------------------- */
static void fault_log(fault_type_t type, uint32_t addr);

/* ---------------------------------------------------------------------------
 * Fault_Init — initialise fault log
 * --------------------------------------------------------------------------- */
void Fault_Init(void)
{
    g_fault_count = 0u;
    g_fault_next_index = 0u;

    for (uint32_t i = 0u; i < 16u; i++)
    {
        g_fault_log[i].type = FAULT_HARD;
        g_fault_log[i].addr = 0u;
        g_fault_log[i].cfsr = 0u;
        g_fault_log[i].timestamp = 0u;
    }
}

/* ---------------------------------------------------------------------------
 * fault_log — internal helper to record a fault record
 * --------------------------------------------------------------------------- */
static void fault_log(fault_type_t type, uint32_t addr)
{
    uint32_t idx = g_fault_next_index;

    g_fault_log[idx].type = type;
    g_fault_log[idx].addr = addr;
    g_fault_log[idx].cfsr = (*(volatile uint32_t *)0xE000ED28UL);
    g_fault_log[idx].timestamp = g_fault_count; /* sequence number */

    g_fault_next_index = (idx + 1u) % 16u;
    if (g_fault_count < 16u)
    {
        g_fault_count++;
    }

    /* Invalidate CFSR by writing back (clear all fault bits) */
    (*(volatile uint32_t *)0xE000ED28UL) = (*(volatile uint32_t *)0xE000ED28UL);
}

/* ---------------------------------------------------------------------------
 * HardFault_Handler
 * --------------------------------------------------------------------------- */
void HardFault_Handler(void)
{
    uint32_t hfsr = (*(volatile uint32_t *)0xE000ED2CUL);
    uint32_t addr = 0u;

    if (hfsr & (1u << 30))
    {
        /* A forced fault means a lower-priority fault escalated */
        uint32_t cfsr = (*(volatile uint32_t *)0xE000ED28UL);

        if (cfsr & 0xFF000000UL)
        {
            addr = (*(volatile uint32_t *)0xE000ED34UL);
        }
        else if (cfsr & 0x00FF0000UL)
        {
            addr = (*(volatile uint32_t *)0xE000ED38UL);
        }
    }

    fault_log(FAULT_HARD, addr);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * MemManage_Handler
 * --------------------------------------------------------------------------- */
void MemManage_Handler(void)
{
    uint32_t addr = (*(volatile uint32_t *)0xE000ED34UL);
    fault_log(FAULT_MEM, addr);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * BusFault_Handler
 * --------------------------------------------------------------------------- */
void BusFault_Handler(void)
{
    uint32_t addr = (*(volatile uint32_t *)0xE000ED38UL);
    fault_log(FAULT_BUS, addr);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * UsageFault_Handler
 * --------------------------------------------------------------------------- */
void UsageFault_Handler(void)
{
    fault_log(FAULT_USAGE, 0u);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * SecureFault_Handler
 * --------------------------------------------------------------------------- */
void SecureFault_Handler(void)
{
    fault_log(FAULT_SECURE, 0u);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * Fault_GetCount
 * --------------------------------------------------------------------------- */
uint32_t Fault_GetCount(void)
{
    return g_fault_count;
}

/* ---------------------------------------------------------------------------
 * Fault_GetLog — copy fault records into user buffer
 * --------------------------------------------------------------------------- */
uint32_t Fault_GetLog(fault_record_t *buf, uint32_t max)
{
    uint32_t count = (max < g_fault_count) ? max : g_fault_count;

    for (uint32_t i = 0u; i < count; i++)
    {
        buf[i] = g_fault_log[i];
    }

    return count;
}
