# 1 "D:\\programming\\sw_model\\fw_samples\\src\\system.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\system.c" 2
/**
 * system.c — System / Clock Initialization
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
# 8 "D:\\programming\\sw_model\\fw_samples\\src\\system.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 9 "D:\\programming\\sw_model\\fw_samples\\src\\system.c" 2

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */







/* AIRCR key and bits */



/* SCR bits */



/* PWR_CR bits */





/* FLASH_ACR bits */





/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    POWER_MODE_RUN = 0,
    POWER_MODE_SLEEP = 1,
    POWER_MODE_DEEP_SLEEP = 2,
    POWER_MODE_STANDBY = 3
} power_mode_t;

typedef enum
{
    CLOCK_SOURCE_HSI = 0,
    CLOCK_SOURCE_HSE = 1,
    CLOCK_SOURCE_PLL = 2
} clock_source_t;

typedef struct
{
    clock_source_t source;
    uint32_t ahb_div;
    uint32_t apb1_div;
    uint32_t apb2_div;
} system_clock_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static uint32_t g_reset_cause = 0u;
static uint32_t g_system_clock_hz = 8000000u; /* default 8 MHz HSI */
static power_mode_t g_current_power_mode = POWER_MODE_RUN;
static system_clock_t g_clock_config = {
    .source = CLOCK_SOURCE_HSI,
    .ahb_div = 1u,
    .apb1_div = 1u,
    .apb2_div = 1u
};

/* ---------------------------------------------------------------------------
 * Forward declarations (static helpers)
 * --------------------------------------------------------------------------- */
static void system_configure_flash_latency(uint32_t clock_mhz);
void SystemClockDividerSet(uint32_t ahb, uint32_t apb1, uint32_t apb2);

/* ---------------------------------------------------------------------------
 * SystemInit — early system initialisation
 * --------------------------------------------------------------------------- */
void SystemInit(void)
{
    /* Enable Flash prefetch, I-cache, D-cache */
    (*(volatile uint32_t *)0x40022000UL) |= ((1u << 8) | (1u << 9) | (1u << 10));

    /* Configure Flash latency for current clock */
    system_configure_flash_latency(g_system_clock_hz / 1000000u);

    /* Set system clock divider defaults */
    SystemClockDividerSet(1u, 1u, 1u);

    /* Capture reset cause from RCC (placeholder) */
    g_reset_cause = 0x01u; /* POR */

    g_current_power_mode = POWER_MODE_RUN;
}

/* ---------------------------------------------------------------------------
 * SystemCoreClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemCoreClockGet(void)
{
    return g_system_clock_hz;
}

/* ---------------------------------------------------------------------------
 * SystemCoreClockUpdate — recalculate g_system_clock_hz from registers
 * --------------------------------------------------------------------------- */
void SystemCoreClockUpdate(void)
{
    /* Placeholder: read actual clock registers and compute HZ value.
     * Default implementation keeps the stored value. */
    __asm__("" ::: "memory");
}

/* ---------------------------------------------------------------------------
 * SystemResetCauseGet
 * --------------------------------------------------------------------------- */
uint32_t SystemResetCauseGet(void)
{
    return g_reset_cause;
}

/* ---------------------------------------------------------------------------
 * SystemReset — full system reset via SYSRESETREQ
 * --------------------------------------------------------------------------- */
void SystemReset(void)
{
    (*(volatile uint32_t *)0xE000ED0CUL) = 0x5FA00000UL | 0x00000004UL;
    __asm__("dsb sy" ::: "memory");
    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * SystemSoftReset — software-initiated reset (same mechanism)
 * --------------------------------------------------------------------------- */
void SystemSoftReset(void)
{
    SystemReset();
}

/* ---------------------------------------------------------------------------
 * SystemPowerModeSet
 * --------------------------------------------------------------------------- */
void SystemPowerModeSet(power_mode_t mode)
{
    uint32_t scr = (*(volatile uint32_t *)0xE000ED10UL);
    uint32_t pwr = (*(volatile uint32_t *)0x40007000UL);

    switch (mode)
    {
        case POWER_MODE_SLEEP:
            scr &= ~(1u << 2);
            pwr &= ~((1u << 0) | (1u << 1));
            break;

        case POWER_MODE_DEEP_SLEEP:
            scr |= (1u << 2);
            pwr &= ~(1u << 1);
            pwr |= (1u << 0);
            break;

        case POWER_MODE_STANDBY:
            scr |= (1u << 2);
            pwr &= ~(1u << 0);
            pwr |= (1u << 1);
            break;

        default: /* RUN */
            scr &= ~(1u << 2);
            pwr &= ~((1u << 0) | (1u << 1));
            break;
    }

    (*(volatile uint32_t *)0xE000ED10UL) = scr;
    (*(volatile uint32_t *)0x40007000UL) = pwr;

    g_current_power_mode = mode;
}

/* ---------------------------------------------------------------------------
 * SystemPowerModeGet
 * --------------------------------------------------------------------------- */
power_mode_t SystemPowerModeGet(void)
{
    return g_current_power_mode;
}

/* ---------------------------------------------------------------------------
 * SystemTickConfig — configure SysTick to fire every 'reload' ticks
 * --------------------------------------------------------------------------- */
int32_t SystemTickConfig(uint32_t reload)
{
    (*(volatile uint32_t *)0xE000E014UL) = reload & 0x00FFFFFFUL;
    (*(volatile uint32_t *)0xE000E010UL) = 0x07UL; /* Enable + interrupt + processor clock */
    return 0;
}

/* ---------------------------------------------------------------------------
 * SystemTickDisable
 * --------------------------------------------------------------------------- */
void SystemTickDisable(void)
{
    (*(volatile uint32_t *)0xE000E010UL) = 0x00UL;
}

/* ---------------------------------------------------------------------------
 * SystemTickCountGet — read current SysTick counter value
 * --------------------------------------------------------------------------- */
uint32_t SystemTickCountGet(void)
{
    return *(volatile uint32_t *)0xE000E018UL; /* SYSTICK_CVR */
}

/* ---------------------------------------------------------------------------
 * SystemDelayMs — busy-wait millisecond delay using SysTick
 * --------------------------------------------------------------------------- */
void SystemDelayMs(uint32_t ms)
{
    volatile uint32_t count;

    while (ms--)
    {
        /* Assuming SysTick runs at 1 ms period */
        count = SystemTickCountGet();
        while (SystemTickCountGet() == count)
        {
            /* spin */
        }
    }
}

/* ---------------------------------------------------------------------------
 * SystemClockDividerSet — set AHB, APB1, APB2 prescalers
 * --------------------------------------------------------------------------- */
void SystemClockDividerSet(uint32_t ahb, uint32_t apb1, uint32_t apb2)
{
    g_clock_config.ahb_div = ahb;
    g_clock_config.apb1_div = apb1;
    g_clock_config.apb2_div = apb2;

    /* Placeholder: write actual RCC clock configuration registers */
}

/* ---------------------------------------------------------------------------
 * SystemAHBClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemAHBClockGet(void)
{
    return g_system_clock_hz / g_clock_config.ahb_div;
}

/* ---------------------------------------------------------------------------
 * SystemAPB1ClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemAPB1ClockGet(void)
{
    return SystemAHBClockGet() / g_clock_config.apb1_div;
}

/* ---------------------------------------------------------------------------
 * SystemAPB2ClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemAPB2ClockGet(void)
{
    return SystemAHBClockGet() / g_clock_config.apb2_div;
}

/* ---------------------------------------------------------------------------
 * system_configure_flash_latency (static helper)
 * --------------------------------------------------------------------------- */
static void system_configure_flash_latency(uint32_t clock_mhz)
{
    uint32_t latency = 0u;

    if (clock_mhz > 48u)
    {
        latency = 4u;
    }
    else if (clock_mhz > 36u)
    {
        latency = 3u;
    }
    else if (clock_mhz > 24u)
    {
        latency = 2u;
    }
    else if (clock_mhz > 12u)
    {
        latency = 1u;
    }
    else
    {
        latency = 0u;
    }

    (*(volatile uint32_t *)0x40022000UL) = ((*(volatile uint32_t *)0x40022000UL) & ~0x07u) | latency;
}

/* ---------------------------------------------------------------------------
 * SystemInfoPrint — placeholder debug output
 * --------------------------------------------------------------------------- */
void SystemInfoPrint(void)
{
    /* In a real system this would print to UART or debug console.
     * Placeholder to satisfy the interface. */
    volatile uint32_t dummy = g_system_clock_hz;
    (void)dummy;
}
