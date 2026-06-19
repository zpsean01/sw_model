# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\interrupt.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\interrupt.c" 2
/**
 * interrupt.c — NVIC Interrupt Controller for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_irq_count, g_last_irq
 *   - Types: irq_priority_t enum
 *   - Direct register access via macro-defined volatile pointers
 *   - 8 functions
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
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\interrupt.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\interrupt.c" 2

/* ------------------------------------------------------------------ */
/*  NVIC register definitions (Cortex-M33)                             */
/* ------------------------------------------------------------------ */






/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    PRIO_LOWEST = 15,
    PRIO_LOW = 10,
    PRIO_MEDIUM = 5,
    PRIO_HIGH = 1,
    PRIO_HIGHEST = 0
} irq_priority_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static uint32_t g_irq_count = 0;
static uint8_t g_last_irq = 0;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * NVIC_EnableIRQ — Enable an interrupt in the NVIC.
 * @param irq_num : IRQ number (0..239 for Cortex-M33)
 */
void NVIC_EnableIRQ(uint8_t irq_num)
{
    uint32_t idx = irq_num / 32U;
    uint32_t bit = 1UL << (irq_num % 32U);
    ((volatile uint32_t *)0xE000E100UL)[idx] = bit;
    ++g_irq_count;
    g_last_irq = irq_num;
}

/**
 * NVIC_DisableIRQ — Disable an interrupt in the NVIC.
 */
void NVIC_DisableIRQ(uint8_t irq_num)
{
    uint32_t idx = irq_num / 32U;
    uint32_t bit = 1UL << (irq_num % 32U);
    ((volatile uint32_t *)0xE000E180UL)[idx] = bit;
}

/**
 * NVIC_SetPriority — Set priority of an interrupt.
 * @param irq_num  : IRQ number
 * @param priority : priority value (0..15, lower number = higher priority)
 */
void NVIC_SetPriority(uint8_t irq_num, uint8_t priority)
{
    uint32_t idx = irq_num;
    /* IPR is byte-accessible, each IRQ uses one byte (upper 4 bits) */
    ((volatile uint8_t *)0xE000E400UL)[idx] = (uint8_t)(priority << 4U);
}

/**
 * NVIC_GetPriority — Get priority of an interrupt.
 * @return priority value (0..15).
 */
uint8_t NVIC_GetPriority(uint8_t irq_num)
{
    uint32_t idx = irq_num;
    return (uint8_t)(((volatile uint8_t *)0xE000E400UL)[idx] >> 4U);
}

/**
 * NVIC_GetPendingIRQ — Check if an interrupt is pending.
 * @return true if pending.
 */
_Bool NVIC_GetPendingIRQ(uint8_t irq_num)
{
    uint32_t idx = irq_num / 32U;
    uint32_t bit = 1UL << (irq_num % 32U);
    return (((volatile uint32_t *)0xE000E200UL)[idx] & bit) != 0U;
}

/**
 * NVIC_ClearPendingIRQ — Clear pending status of an interrupt.
 */
void NVIC_ClearPendingIRQ(uint8_t irq_num)
{
    uint32_t idx = irq_num / 32U;
    uint32_t bit = 1UL << (irq_num % 32U);
    ((volatile uint32_t *)0xE000E280UL)[idx] = bit;
}

/**
 * NVIC_SystemReset — Trigger a system reset via the NVIC.
 * This writes to the AIRCR register in the System Control Block.
 */
void NVIC_SystemReset(void)
{
    volatile uint32_t *aircr = (volatile uint32_t *)0xE000ED0CUL;
    *aircr = (0x5FAUL << 16U) | (1UL << 2U); /* SYSRESETREQ */
}

/**
 * NVIC_GetActiveIRQ — Return the last recorded IRQ number.
 * This is a simplified software-tracked active IRQ.
 * @return last IRQ number that was enabled.
 */
uint8_t NVIC_GetActiveIRQ(void)
{
    return g_last_irq;
}
