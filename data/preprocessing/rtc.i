# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\rtc.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\rtc.c" 2
/**
 * rtc.c — RTC Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_rtc_instance, g_rtc_initialized, g_rtc_alarm_count
 *   - Types: rtc_time_t, rtc_date_t, rtc_format_t, rtc_regs_t
 *   - Register base: RTC_BASE
 *   - BCD encoding/decoding inline
 *   - 7 functions
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
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\rtc.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 14 "D:\\programming\\sw_model\\fw_samples\\lib\\rtc.c" 2

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */


/* ------------------------------------------------------------------ */
/*  BCD conversion helpers (inline)                                    */
/* ------------------------------------------------------------------ */



/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef struct {
    uint8_t hours;
    uint8_t minutes;
    uint8_t seconds;
} rtc_time_t;

typedef struct {
    uint16_t year;
    uint8_t month;
    uint8_t day;
} rtc_date_t;

typedef enum {
    H12 = 0,
    H24 = 1
} rtc_format_t;

typedef struct {
    volatile uint32_t TR; /* 0x00 - Time Register       */
    volatile uint32_t DR; /* 0x04 - Date Register       */
    volatile uint32_t CR; /* 0x08 - Control Register    */
    volatile uint32_t ISR; /* 0x0C - Init & Status Reg   */
    volatile uint32_t PRER; /* 0x10 - Prescaler Register  */
    volatile uint32_t WPR; /* 0x14 - Write Protection    */
    volatile uint32_t CALR; /* 0x18 - Calibration Register*/
} rtc_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static rtc_regs_t *g_rtc_instance = (rtc_regs_t *)0x40002800UL;
static _Bool g_rtc_initialized = 0;
static uint32_t g_rtc_alarm_count = 0;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * RTC_Init — Initialise the RTC peripheral.
 * Enables access and sets default prescaler.
 */
void RTC_Init(void)
{
    rtc_regs_t *regs = g_rtc_instance;

    /* Disable write protection to allow config */
    regs->WPR = 0xCA;
    regs->WPR = 0x53;

    /* Enter initialisation mode */
    regs->ISR |= 0x00000010UL; /* INIT = 1 */
    while ((regs->ISR & 0x00000020UL) == 0U) { } /* Wait for INITF */

    /* Set prescaler: async=128, sync=256 => 1 Hz */
    regs->PRER = (127UL << 16) | 255UL;

    /* Set 24-hour format */
    regs->CR &= ~0x00000040UL; /* FMT = 0 (24h) */

    /* Exit initialisation mode */
    regs->ISR &= ~0x00000010UL; /* INIT = 0 */

    /* Re-enable write protection */
    regs->WPR = 0xFF;

    g_rtc_alarm_count = 0;
    g_rtc_initialized = 1;
}

/**
 * RTC_TimeSet — Set the current time.
 * @param time   : pointer to rtc_time_t (hours, minutes, seconds in binary)
 * @param format : H12 or H24
 */
void RTC_TimeSet(const rtc_time_t *time, rtc_format_t format)
{
    rtc_regs_t *regs = g_rtc_instance;

    regs->WPR = 0xCA;
    regs->WPR = 0x53;

    regs->ISR |= 0x00000010UL;
    while ((regs->ISR & 0x00000020UL) == 0U) { }

    uint32_t tr = 0;

    if (format == H12) {
        /* PM/AM indication via bit 22 (PM=1, AM=0) — simplified: treat as AM */
        tr = (uint32_t)((((time->hours) / 10U) << 4) | ((time->hours) % 10U)) |
            ((uint32_t)((((time->minutes) / 10U) << 4) | ((time->minutes) % 10U)) << 8U) |
            ((uint32_t)((((time->seconds) / 10U) << 4) | ((time->seconds) % 10U)) << 16U);
        /* Hour format: bit 16 in CR? For H12, set HT[21:20] correctly */
        /* We just store as-is; the TR format supports H12 with bit 22 as PM */
    } else {
        tr = ((uint32_t)((((time->hours) / 10U) << 4) | ((time->hours) % 10U)) << 16U) |
             ((uint32_t)((((time->minutes) / 10U) << 4) | ((time->minutes) % 10U)) << 8U) |
              (uint32_t)((((time->seconds) / 10U) << 4) | ((time->seconds) % 10U));
    }

    regs->TR = tr;

    /* Set format in CR */
    if (format == H24) {
        regs->CR &= ~0x00000040UL; /* FMT = 0 -> 24h */
    } else {
        regs->CR |= 0x00000040UL; /* FMT = 1 -> 12h */
    }

    regs->ISR &= ~0x00000010UL;
    regs->WPR = 0xFF;
}

/**
 * RTC_TimeGet — Read the current time.
 * @param time   : pointer to rtc_time_t to fill
 * @param format : H12 or H24
 */
void RTC_TimeGet(rtc_time_t *time, rtc_format_t format)
{
    rtc_regs_t *regs = g_rtc_instance;
    uint32_t tr = regs->TR;

    if (format == H12) {
        time->seconds = (((((uint8_t)(tr & 0x7FUL)) >> 4) * 10U) + (((uint8_t)(tr & 0x7FUL)) & 0x0FU));
        time->minutes = (((((uint8_t)((tr >> 8U) & 0x7FUL)) >> 4) * 10U) + (((uint8_t)((tr >> 8U) & 0x7FUL)) & 0x0FU));
        time->hours = (((((uint8_t)((tr >> 16U) & 0x1FUL)) >> 4) * 10U) + (((uint8_t)((tr >> 16U) & 0x1FUL)) & 0x0FU));
    } else {
        time->seconds = (((((uint8_t)(tr & 0x7FUL)) >> 4) * 10U) + (((uint8_t)(tr & 0x7FUL)) & 0x0FU));
        time->minutes = (((((uint8_t)((tr >> 8U) & 0x7FUL)) >> 4) * 10U) + (((uint8_t)((tr >> 8U) & 0x7FUL)) & 0x0FU));
        time->hours = (((((uint8_t)((tr >> 16U) & 0x3FUL)) >> 4) * 10U) + (((uint8_t)((tr >> 16U) & 0x3FUL)) & 0x0FU));
    }
}

/**
 * RTC_DateSet — Set the current date.
 * @param date : pointer to rtc_date_t (year, month, day in binary)
 */
void RTC_DateSet(const rtc_date_t *date)
{
    rtc_regs_t *regs = g_rtc_instance;

    regs->WPR = 0xCA;
    regs->WPR = 0x53;

    regs->ISR |= 0x00000010UL;
    while ((regs->ISR & 0x00000020UL) == 0U) { }

    uint32_t dr = ((uint32_t)((((date->year % 100U) / 10U) << 4) | ((date->year % 100U) % 10U)) << 16U) |
                   ((uint32_t)((((date->month) / 10U) << 4) | ((date->month) % 10U)) << 8U) |
                   (uint32_t)((((date->day) / 10U) << 4) | ((date->day) % 10U));
    regs->DR = dr;

    regs->ISR &= ~0x00000010UL;
    regs->WPR = 0xFF;
}

/**
 * RTC_DateGet — Read the current date.
 * @param date : pointer to rtc_date_t to fill
 */
void RTC_DateGet(rtc_date_t *date)
{
    rtc_regs_t *regs = g_rtc_instance;
    uint32_t dr = regs->DR;

    date->day = (((((uint8_t)(dr & 0x3FUL)) >> 4) * 10U) + (((uint8_t)(dr & 0x3FUL)) & 0x0FU));
    date->month = (((((uint8_t)((dr >> 8U) & 0x1FUL)) >> 4) * 10U) + (((uint8_t)((dr >> 8U) & 0x1FUL)) & 0x0FU));
    date->year = 2000U + (((((uint8_t)((dr >> 16U) & 0xFFUL)) >> 4) * 10U) + (((uint8_t)((dr >> 16U) & 0xFFUL)) & 0x0FU));
}

/**
 * RTC_AlarmSet — Set an alarm time (simplified).
 * Increments alarm count for tracking.
 */
void RTC_AlarmSet(const rtc_time_t *alarm_time)
{
    (void)alarm_time;
    ++g_rtc_alarm_count;
}

/* ------------------------------------------------------------------ */
/*  Interrupt handler                                                  */
/* ------------------------------------------------------------------ */
void RTC_IRQHandler(void)
{
    rtc_regs_t *regs = g_rtc_instance;

    /* Check alarm flag */
    if ((regs->ISR & 0x00000001UL) != 0U) {
        /* Clear alarm flag */
        regs->ISR &= ~0x00000001UL;
        ++g_rtc_alarm_count;
    }

    /* Check wake-up / others could be handled here */
}
