# 1 "D:\\programming\\sw_model\\fw_samples\\src\\platform.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\platform.c" 2
/**
 * platform.c — Platform Abstraction Layer
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
# 8 "D:\\programming\\sw_model\\fw_samples\\src\\platform.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 9 "D:\\programming\\sw_model\\fw_samples\\src\\platform.c" 2

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */


/* CPACR bits for CP10, CP11 — full access */



/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    PLATFORM_INIT = 0,
    PLATFORM_ACTIVE = 1,
    PLATFORM_SLEEP = 2,
    PLATFORM_ERROR = 3
} platform_state_t;

typedef struct
{
    _Bool secure_mode;
    _Bool debug_enabled;
    _Bool fpu_enabled;
} platform_config_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static platform_state_t g_platform_state = PLATFORM_INIT;
static platform_config_t g_platform_config = {
    .secure_mode = 1,
    .debug_enabled = 1,
    .fpu_enabled = 1
};
static uint32_t g_error_code = 0u;

/* ---------------------------------------------------------------------------
 * PLATFORM_Init — initialise platform hardware
 * --------------------------------------------------------------------------- */
int32_t PLATFORM_Init(void)
{
    /* Apply default config */
    if (g_platform_config.fpu_enabled)
    {
        (*(volatile uint32_t *)0xE000ED88UL) |= ((0x03u << 20) | (0x03u << 22));
        __asm__("dsb sy" ::: "memory");
        __asm__("isb sy" ::: "memory");
    }

    g_platform_state = PLATFORM_ACTIVE;
    g_error_code = 0u;

    return 0;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_PostInit — post-initialisation steps
 * --------------------------------------------------------------------------- */
int32_t PLATFORM_PostInit(void)
{
    /* Ensure FPU is still enabled (may have been altered by secure monitor) */
    if (g_platform_config.fpu_enabled)
    {
        (*(volatile uint32_t *)0xE000ED88UL) |= ((0x03u << 20) | (0x03u << 22));
        __asm__("dsb sy" ::: "memory");
        __asm__("isb sy" ::: "memory");
    }

    return 0;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_Sleep — enter low-power mode
 * --------------------------------------------------------------------------- */
void PLATFORM_Sleep(void)
{
    g_platform_state = PLATFORM_SLEEP;
    __asm__("wfi" ::: "memory");
    g_platform_state = PLATFORM_ACTIVE;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_SetConfig
 * --------------------------------------------------------------------------- */
void PLATFORM_SetConfig(const platform_config_t *cfg)
{
    if (cfg != (const platform_config_t *)0)
    {
        g_platform_config = *cfg;

        /* Apply FPU setting immediately */
        if (cfg->fpu_enabled)
        {
            (*(volatile uint32_t *)0xE000ED88UL) |= ((0x03u << 20) | (0x03u << 22));
        }
        else
        {
            (*(volatile uint32_t *)0xE000ED88UL) &= ~((0x03u << 20) | (0x03u << 22));
        }
        __asm__("dsb sy" ::: "memory");
        __asm__("isb sy" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * PLATFORM_GetConfig
 * --------------------------------------------------------------------------- */
void PLATFORM_GetConfig(platform_config_t *cfg)
{
    if (cfg != (platform_config_t *)0)
    {
        *cfg = g_platform_config;
    }
}

/* ---------------------------------------------------------------------------
 * PLATFORM_IsSecure
 * --------------------------------------------------------------------------- */
_Bool PLATFORM_IsSecure(void)
{
    return g_platform_config.secure_mode;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_GetVersion — return a 32-bit version identifier
 * --------------------------------------------------------------------------- */
uint32_t PLATFORM_GetVersion(void)
{
    return 0x01000001u; /* major.minor.patch */
}

/* ---------------------------------------------------------------------------
 * PLATFORM_ErrorHandler — record and enter error state
 * --------------------------------------------------------------------------- */
void PLATFORM_ErrorHandler(uint32_t error_code)
{
    g_error_code = error_code;
    g_platform_state = PLATFORM_ERROR;

    /* Infinite loop in error state */
    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ===========================================================================
 * DDR5 init controller platform abstraction
 *
 * Provides the extern functions required by src/ddr5_init_controller.c.
 * These are simplified implementations for analysis purposes.
 * ======================================================================== */

/* ── DDR controller MMIO base (simulated) ─────────────────────────────── */
# 175 "D:\\programming\\sw_model\\fw_samples\\src\\platform.c"
/* Simple busy-wait delay (approximate cycle count) */
void ddr5_delay_cycles(uint32_t cycles)
{
    volatile uint32_t i;
    for (i = 0; i < cycles; i++)
    {
        __asm__("nop");
    }
}

/* Memory-mapped register read */
uint32_t ddr5_read_reg(uint32_t addr)
{
    return *(volatile uint32_t *)addr;
}

/* Memory-mapped register write */
void ddr5_write_reg(uint32_t addr, uint32_t val)
{
    *(volatile uint32_t *)addr = val;
}

/* DDR5 Mode Register Read via controller MRR operation */
uint32_t ddr5_mr_read(uint8_t mr_addr)
{
    ddr5_write_reg((0x40000000UL + 0x0004U), mr_addr);
    ddr5_write_reg((0x40000000UL + 0x000CU), 0x01U); /* MRR command */
    while (ddr5_read_reg((0x40000000UL + 0x000CU)) & (1U << 31)); /* wait busy */
    return ddr5_read_reg((0x40000000UL + 0x0008U));
}

/* DDR5 Mode Register Write via controller MRW operation */
void ddr5_mr_write(uint8_t mr_addr, uint32_t data)
{
    ddr5_write_reg((0x40000000UL + 0x0004U), mr_addr);
    ddr5_write_reg((0x40000000UL + 0x0008U), data);
    ddr5_write_reg((0x40000000UL + 0x000CU), 0x00U); /* MRW command */
    while (ddr5_read_reg((0x40000000UL + 0x000CU)) & (1U << 31)); /* wait busy */
}

/* DDR5 CA Bus command send (simplified) */
void ddr5_ca_bus_send(uint16_t cmd, uint32_t addr)
{
    /* In real hardware: drives CA[13:0] bus signals with command + address.
     * Here we write to a simulated controller register for analysis tracing. */
    ddr5_write_reg((0x40000000UL + 0x0020U), ((uint32_t)cmd << 16) | (addr & 0xFFFFU));
}

/* DDR5 CKE control */
void ddr5_set_cke(uint8_t state)
{
    /* CKE is typically a SoC GPIO or PLL control line. */
    ddr5_write_reg(0x40000000UL + 0x1000U, state ? 1U : 0U);
}

/* DDR5 RESET_n control */
void ddr5_set_reset_n(uint8_t state)
{
    /* RESET_n is typically a SoC GPIO. */
    ddr5_write_reg(0x40000000UL + 0x1004U, state ? 1U : 0U);
}
