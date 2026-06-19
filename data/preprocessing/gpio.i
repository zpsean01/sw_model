# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\gpio.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\gpio.c" 2
/**
 * gpio.c — GPIO Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_gpio_ports[2], g_gpio_initialized
 *   - Types: gpio_port_t, gpio_pin_t, gpio_mode_t, gpio_pull_t, gpio_regs_t
 *   - Register access via GPIOA_BASE / GPIOB_BASE (volatile pointer)
 *   - 7 public functions + 1 ISR placeholder
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
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\gpio.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\gpio.c" 2

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */



/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    PORTA = 0,
    PORTB = 1
} gpio_port_t;

typedef uint16_t gpio_pin_t;

typedef enum {
    INPUT = 0,
    OUTPUT = 1,
    AF = 2,
    ANALOG = 3
} gpio_mode_t;

typedef enum {
    NOPULL = 0,
    PULLUP = 1,
    PULLDOWN = 2
} gpio_pull_t;

typedef struct {
    volatile uint32_t MODER; /* 0x00 */
    volatile uint32_t OTYPER; /* 0x04 */
    volatile uint32_t OSPEEDR; /* 0x08 */
    volatile uint32_t PUPDR; /* 0x0C */
    volatile uint32_t IDR; /* 0x10 */
    volatile uint32_t ODR; /* 0x14 */
    volatile uint32_t BSRR; /* 0x18 */
    volatile uint32_t AFR[2]; /* 0x1C - 0x20 */
} gpio_regs_t; /* total size = 0x28 */

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static gpio_regs_t *g_gpio_ports[2] = {
    (gpio_regs_t *)0x40020000UL,
    (gpio_regs_t *)0x40020400UL
};
static _Bool g_gpio_initialized = 0;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * GPIO_Init — Configure a GPIO pin mode and pull setting.
 * @param port  : port index (PORTA or PORTB)
 * @param pin   : pin bitmask (bit0=pin0 … bit15=pin15)
 * @param mode  : INPUT, OUTPUT, AF, ANALOG
 * @param pull  : NOPULL, PULLUP, PULLDOWN
 */
void GPIO_Init(gpio_port_t port, gpio_pin_t pin, gpio_mode_t mode, gpio_pull_t pull)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    uint32_t pos = 0;
    uint32_t bit = pin;

    /* Find the lowest set bit position (pin number 0-15) */
    while ((bit & 1U) == 0U) {
        bit >>= 1U;
        ++pos;
    }

    uint32_t shift = pos * 2U;

    /* MODER: 2 bits per pin */
    regs->MODER &= ~(3UL << shift);
    regs->MODER |= ((uint32_t)mode << shift);

    /* PUPDR: 2 bits per pin */
    regs->PUPDR &= ~(3UL << shift);
    regs->PUPDR |= ((uint32_t)pull << shift);
}

/**
 * GPIO_WritePin — Set or clear a single output pin.
 */
void GPIO_WritePin(gpio_port_t port, gpio_pin_t pin, _Bool state)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    if (state) {
        regs->BSRR = (uint32_t)pin; /* set */
    } else {
        regs->BSRR = ((uint32_t)pin << 16U); /* reset */
    }
}

/**
 * GPIO_ReadPin — Read the input level of a pin.
 * @return true if pin is high, false otherwise.
 */
_Bool GPIO_ReadPin(gpio_port_t port, gpio_pin_t pin)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    return (regs->IDR & (uint32_t)pin) != 0U;
}

/**
 * GPIO_TogglePin — Toggle an output pin.
 */
void GPIO_TogglePin(gpio_port_t port, gpio_pin_t pin)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    regs->ODR ^= (uint32_t)pin;
}

/**
 * GPIO_WritePort — Write an entire 16-bit word to the output data register.
 */
void GPIO_WritePort(gpio_port_t port, uint16_t value)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    regs->ODR = (uint32_t)value;
}

/**
 * GPIO_ReadPort — Read the full 16-bit input data register.
 */
uint16_t GPIO_ReadPort(gpio_port_t port)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    return (uint16_t)(regs->IDR & 0xFFFFUL);
}

/**
 * GPIO_SetAF — Configure alternate-function for a pin.
 * @param af: alternate-function number (0..15).
 */
void GPIO_SetAF(gpio_port_t port, gpio_pin_t pin, uint8_t af)
{
    gpio_regs_t *regs = g_gpio_ports[port];

    uint32_t pos = 0;
    uint32_t bit = pin;
    while ((bit & 1U) == 0U) {
        bit >>= 1U;
        ++pos;
    }

    uint32_t idx = (pos < 8U) ? 0U : 1U;
    uint32_t shift = (pos % 8U) * 4U;

    regs->AFR[idx] &= ~(0xFUL << shift);
    regs->AFR[idx] |= ((uint32_t)(af & 0x0FU) << shift);
}

/* ------------------------------------------------------------------ */
/*  Interrupt handler (placeholder)                                    */
/* ------------------------------------------------------------------ */
void GPIOA_IRQHandler(void)
{
    /* Placeholder — application-defined behaviour should be added here */
}
