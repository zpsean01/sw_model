# 1 "D:\\programming\\sw_model\\fw_samples\\src\\startup.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\startup.c" 2
/**
 * startup.c - ARM Cortex-M33 Startup / Vector Table
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
# 8 "D:\\programming\\sw_model\\fw_samples\\src\\startup.c" 2

/* ---------------------------------------------------------------------------
 * Extern symbols from linker script
 * --------------------------------------------------------------------------- */
extern uint32_t _stack_end[];
extern uint32_t _sbss[];
extern uint32_t _ebss[];
extern uint32_t _sdata[];
extern uint32_t _edata[];
extern uint32_t _sidata[];

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef void (*isr_func_t)(void);

/* ---------------------------------------------------------------------------
 * Register access
 * --------------------------------------------------------------------------- */


/* ---------------------------------------------------------------------------
 * Forward declarations
 * --------------------------------------------------------------------------- */
void Reset_Handler(void);
static void Default_Handler(void);
static void __initialize_hardware_early(void);

/* ---------------------------------------------------------------------------
 * Weak alias macros for interrupt handlers
 * --------------------------------------------------------------------------- */



void NMI_Handler(void) __attribute__((weak, alias("Default_Handler")));
void HardFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void MemManage_Handler(void) __attribute__((weak, alias("Default_Handler")));
void BusFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void UsageFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SecureFault_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SVCall_Handler(void) __attribute__((weak, alias("Default_Handler")));
void DebugMon_Handler(void) __attribute__((weak, alias("Default_Handler")));
void PendSV_Handler(void) __attribute__((weak, alias("Default_Handler")));
void SysTick_Handler(void) __attribute__((weak, alias("Default_Handler")));

/* Weak alias for reserved exception slots */
void RESERVED(void) __attribute__((weak, alias("Default_Handler")));

/* ---------------------------------------------------------------------------
 * Vector table — 48 entries as required by Cortex-M33
 * --------------------------------------------------------------------------- */
const void *g_pfnVectors[48] __attribute__((section(".vectors"))) = {
    /* Stack pointer and Reset */
    (const void *)&_stack_end, /* 00: Initial Main Stack Pointer */
    (const void *)Reset_Handler, /* 01: Reset */

    /* Exception handlers */
    (const void *)NMI_Handler, /* 02: NMI */
    (const void *)HardFault_Handler, /* 03: Hard Fault */
    (const void *)MemManage_Handler, /* 04: MemManage Fault */
    (const void *)BusFault_Handler, /* 05: Bus Fault */
    (const void *)UsageFault_Handler, /* 06: Usage Fault */
    (const void *)SecureFault_Handler,/* 07: Secure Fault */
    (const void *)RESERVED, /* 08: Reserved */
    (const void *)RESERVED, /* 09: Reserved */
    (const void *)RESERVED, /* 10: Reserved */
    (const void *)SVCall_Handler, /* 11: SVCall */
    (const void *)DebugMon_Handler, /* 12: Debug Monitor */
    (const void *)RESERVED, /* 13: Reserved */
    (const void *)PendSV_Handler, /* 14: PendSV */
    (const void *)SysTick_Handler, /* 15: SysTick */

    /* Interrupt handlers 16..47 (32 entries) */
    (const void *)RESERVED, /* 16: IRQ 0 */
    (const void *)RESERVED, /* 17: IRQ 1 */
    (const void *)RESERVED, /* 18: IRQ 2 */
    (const void *)RESERVED, /* 19: IRQ 3 */
    (const void *)RESERVED, /* 20: IRQ 4 */
    (const void *)RESERVED, /* 21: IRQ 5 */
    (const void *)RESERVED, /* 22: IRQ 6 */
    (const void *)RESERVED, /* 23: IRQ 7 */
    (const void *)RESERVED, /* 24: IRQ 8 */
    (const void *)RESERVED, /* 25: IRQ 9 */
    (const void *)RESERVED, /* 26: IRQ 10 */
    (const void *)RESERVED, /* 27: IRQ 11 */
    (const void *)RESERVED, /* 28: IRQ 12 */
    (const void *)RESERVED, /* 29: IRQ 13 */
    (const void *)RESERVED, /* 30: IRQ 14 */
    (const void *)RESERVED, /* 31: IRQ 15 */
    (const void *)RESERVED, /* 32: IRQ 16 */
    (const void *)RESERVED, /* 33: IRQ 17 */
    (const void *)RESERVED, /* 34: IRQ 18 */
    (const void *)RESERVED, /* 35: IRQ 19 */
    (const void *)RESERVED, /* 36: IRQ 20 */
    (const void *)RESERVED, /* 37: IRQ 21 */
    (const void *)RESERVED, /* 38: IRQ 22 */
    (const void *)RESERVED, /* 39: IRQ 23 */
    (const void *)RESERVED, /* 40: IRQ 24 */
    (const void *)RESERVED, /* 41: IRQ 25 */
    (const void *)RESERVED, /* 42: IRQ 26 */
    (const void *)RESERVED, /* 43: IRQ 27 */
    (const void *)RESERVED, /* 44: IRQ 28 */
    (const void *)RESERVED, /* 45: IRQ 29 */
    (const void *)RESERVED, /* 46: IRQ 30 */
    (const void *)RESERVED, /* 47: IRQ 31 */
};

/* ---------------------------------------------------------------------------
 * Default_Handler — infinite loop
 * --------------------------------------------------------------------------- */
static void Default_Handler(void)
{
    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * __initialize_hardware_early — called before data/bss init
 * --------------------------------------------------------------------------- */
static void __initialize_hardware_early(void)
{
    /* Set vector table offset to the link-time location of g_pfnVectors */
    (*(volatile uint32_t *)0xE000ED08UL) = (uint32_t)g_pfnVectors;

    /* Enable FPU (CP10, CP11) — Full access */
    volatile uint32_t *cpacr = (volatile uint32_t *)0xE000ED88UL;
    *cpacr |= (0xFu << 20);

    /* Instruction and data barriers */
    __asm__("dsb sy" ::: "memory");
    __asm__("isb sy" ::: "memory");
}

/* ---------------------------------------------------------------------------
 * Reset_Handler — entry point after reset
 * --------------------------------------------------------------------------- */
void Reset_Handler(void)
{
    uint32_t *src, *dst;

    __initialize_hardware_early();

    /* Copy .data from Flash to RAM */
    dst = _sdata;
    src = _sidata;
    while (dst < _edata)
    {
        *dst++ = *src++;
    }

    /* Zero-fill .bss */
    dst = _sbss;
    while (dst < _ebss)
    {
        *dst++ = 0u;
    }

    /* Call main — should never return */
    extern int main(void);
    (void)main();

    /* If main returns, hang */
    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * ARM EABI runtime helper implementations for bare-metal
 * --------------------------------------------------------------------------- */
__attribute__((used))
void __aeabi_memclr4(void *ptr) {
    uint32_t *p = (uint32_t *)ptr;
    p[0] = 0; p[1] = 0; p[2] = 0; p[3] = 0;
}

__attribute__((used))
void __aeabi_memclr8(void *ptr) {
    uint32_t *p = (uint32_t *)ptr;
    p[0] = 0; p[1] = 0; p[2] = 0; p[3] = 0;
    p[4] = 0; p[5] = 0; p[6] = 0; p[7] = 0;
}

__attribute__((used))
void __aeabi_memcpy4(void *dest, const void *src, uint32_t n) {
    uint32_t *d = (uint32_t *)dest;
    const uint32_t *s = (const uint32_t *)src;
    for (uint32_t i = 0; i < (n >> 2); i++) { d[i] = s[i]; }
}

__attribute__((used))
void __aeabi_memcpy8(void *dest, const void *src, uint32_t n) {
    __aeabi_memcpy4(dest, src, n);
}
