# 1 "D:\\programming\\sw_model\\fw_samples\\src\\board.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\board.c" 2
/**
 * board.c — Board Initialisation
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
# 8 "D:\\programming\\sw_model\\fw_samples\\src\\board.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 9 "D:\\programming\\sw_model\\fw_samples\\src\\board.c" 2

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */


/* GPIO register map base (example: GPIOA) */





/* Enable bit for GPIOA in AHBENR */


/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    BOARD_REV_A = 0,
    BOARD_REV_B = 1,
    BOARD_REV_C = 2
} board_id_t;

typedef struct
{
    board_id_t rev;
    uint8_t serial[16];
    uint32_t hw_version;
} board_info_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static board_info_t g_board_info;
static _Bool g_led_initialized = 0;
static uint16_t g_led_pin = 5u; /* GPIOA pin 5 */

/* ---------------------------------------------------------------------------
 * External interface declarations (provided by lower-level drivers)
 * --------------------------------------------------------------------------- */
extern int32_t GPIO_Init(uint32_t port, uint32_t pin, uint32_t mode);
extern int32_t UART_Init(uint32_t instance, uint32_t baud);
extern int32_t SPI_Init(uint32_t instance, uint32_t speed);


/* ---------------------------------------------------------------------------
 * BOARD_Init — initialise board-level hardware
 * --------------------------------------------------------------------------- */
void BOARD_Init(void)
{
    /* Enable GPIOA clock */
    (*(volatile uint32_t *)0x40023814UL) |= (1u << 0);

    /* Initialise board info defaults */
    g_board_info.rev = BOARD_REV_A;
    g_board_info.hw_version = 0x01000000u;

    for (uint32_t i = 0u; i < sizeof(g_board_info.serial); i++)
    {
        g_board_info.serial[i] = 0u;
    }

    /* Call peripheral init routines */
    (void)GPIO_Init(0u, g_led_pin, 1u); /* output */
    (void)UART_Init(0u, 115200u);
    (void)SPI_Init(0u, 1000000u);
    /* I2C not implemented on this board variant */
}

/* ---------------------------------------------------------------------------
 * BOARD_GetInfo — fill user-supplied board_info_t
 * --------------------------------------------------------------------------- */
void BOARD_GetInfo(board_info_t *info)
{
    if (info != (board_info_t *)0)
    {
        *info = g_board_info;
    }
}

/* ---------------------------------------------------------------------------
 * BOARD_GetSerialNumber — copy serial number into buffer
 * --------------------------------------------------------------------------- */
void BOARD_GetSerialNumber(uint8_t *buf, uint32_t len)
{
    uint32_t copy_len = (len < sizeof(g_board_info.serial))
                            ? len
                            : sizeof(g_board_info.serial);

    for (uint32_t i = 0u; i < copy_len; i++)
    {
        buf[i] = g_board_info.serial[i];
    }
}

/* ---------------------------------------------------------------------------
 * BOARD_LEDInit — configure LED pin
 * --------------------------------------------------------------------------- */
void BOARD_LEDInit(uint16_t pin)
{
    g_led_pin = pin;
    g_led_initialized = 1;

    /* Enable GPIOA clock */
    (*(volatile uint32_t *)0x40023814UL) |= (1u << 0);

    /* Configure as general-purpose output (mode = 0x01) */
    (*(volatile uint32_t *)(0x40020000UL + 0x00UL)) = ((*(volatile uint32_t *)(0x40020000UL + 0x00UL)) & ~(0x03u << (pin * 2u))) | (0x01u << (pin * 2u));
}

/* ---------------------------------------------------------------------------
 * BOARD_LEDSet — turn LED on (state != 0) or off (state == 0)
 * --------------------------------------------------------------------------- */
void BOARD_LEDSet(uint8_t state)
{
    if (!g_led_initialized)
    {
        return;
    }

    if (state != 0u)
    {
        (*(volatile uint32_t *)(0x40020000UL + 0x18UL)) = (1u << g_led_pin); /* set bit */
    }
    else
    {
        (*(volatile uint32_t *)(0x40020000UL + 0x18UL)) = (1u << (g_led_pin + 16u)); /* reset bit */
    }
}

/* ---------------------------------------------------------------------------
 * BOARD_Reset — trigger system reset
 * --------------------------------------------------------------------------- */
void BOARD_Reset(void)
{
    extern void SystemReset(void);
    SystemReset();
}

/* ---------------------------------------------------------------------------
 * BOARD_DelayMs — simple blocking delay
 * --------------------------------------------------------------------------- */
void BOARD_DelayMs(uint32_t ms)
{
    extern void SystemDelayMs(uint32_t);
    SystemDelayMs(ms);
}
