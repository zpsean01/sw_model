# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\uart.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\uart.c" 2
/**
 * uart.c — UART Serial Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_uart_instances[2], g_uart_state[2], g_uart_initialized
 *   - Types: uart_id_t, uart_parity_t, uart_stop_t, uart_config_t,
 *            uart_state_t, uart_regs_t
 *   - Register base: UART0_BASE / UART1_BASE
 *   - 10 visible + 1 static + 2 ISRs = 13 functions
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
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\uart.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 14 "D:\\programming\\sw_model\\fw_samples\\lib\\uart.c" 2

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */



/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    UART0 = 0,
    UART1 = 1
} uart_id_t;

typedef enum {
    PARITY_NONE = 0,
    PARITY_EVEN = 1,
    PARITY_ODD = 2
} uart_parity_t;

typedef enum {
    STOP1 = 0,
    STOP2 = 1
} uart_stop_t;

typedef struct {
    uint32_t baudrate;
    uart_parity_t parity;
    uart_stop_t stop;
    uint8_t data_bits;
} uart_config_t;

typedef struct {
    uint8_t tx_buffer[256];
    uint8_t rx_buffer[256];
    volatile uint16_t tx_head;
    volatile uint16_t tx_tail;
    volatile uint16_t rx_head;
    volatile uint16_t rx_tail;
    uint32_t overrun_errors;
    uint32_t framing_errors;
    uint32_t parity_errors;
} uart_state_t;

typedef struct {
    volatile uint32_t SR; /* 0x00 - Status Register      */
    volatile uint32_t DR; /* 0x04 - Data Register        */
    volatile uint32_t BRR; /* 0x08 - Baud Rate Register   */
    volatile uint32_t CR1; /* 0x0C - Control Register 1   */
    volatile uint32_t CR2; /* 0x10 - Control Register 2   */
    volatile uint32_t CR3; /* 0x14 - Control Register 3   */
} uart_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static uart_regs_t *g_uart_instances[2] = {
    (uart_regs_t *)0x40004000UL,
    (uart_regs_t *)0x40005000UL
};

static uart_state_t g_uart_state[2];
static _Bool g_uart_initialized = 0;

/* ------------------------------------------------------------------ */
/*  Static helpers                                                     */
/* ------------------------------------------------------------------ */

/**
 * uart_irq_handler — Common interrupt service routine for UART.
 * Called from UART0_IRQHandler / UART1_IRQHandler.
 */
static void uart_irq_handler(uart_id_t id)
{
    uart_regs_t *regs = g_uart_instances[id];
    uart_state_t *st = &g_uart_state[id];
    uint32_t sr = regs->SR;

    /* --- RXNE: Receive data available --- */
    if ((sr & 0x20UL) != 0U) {
        uint8_t data = (uint8_t)(regs->DR & 0xFFUL);
        uint16_t next = (uint16_t)((st->rx_head + 1U) & 0xFFU);
        if (next != st->rx_tail) {
            st->rx_buffer[st->rx_head] = data;
            st->rx_head = next;
        } else {
            ++st->overrun_errors;
        }
    }

    /* --- Error flags (FE, ORE, NE, PE) --- */
    if ((sr & 0x1FUL) != 0U) {
        /* Read DR to clear error flags (plus discard data) */
        (void)regs->DR;

        if ((sr & 0x01UL) != 0U) ++st->parity_errors; /* PE  */
        if ((sr & 0x02UL) != 0U) ++st->framing_errors; /* FE  */
        if ((sr & 0x04UL) != 0U) ++st->framing_errors; /* NF  */
        if ((sr & 0x08UL) != 0U) ++st->overrun_errors; /* ORE */
    }

    /* --- TXE: Transmit data register empty (application may fill) --- */
    if ((sr & 0x80UL) != 0U) {
        if (st->tx_tail != st->tx_head) {
            regs->DR = st->tx_buffer[st->tx_tail];
            st->tx_tail = (uint16_t)((st->tx_tail + 1U) & 0xFFU);
        }
    }
}

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * UART_Init — Initialise UART peripheral with given configuration.
 */
void UART_Init(uart_id_t id, const uart_config_t *config)
{
    uart_regs_t *regs = g_uart_instances[id];

    (void)__builtin_memset(&g_uart_state[id], 0, sizeof(uart_state_t));

    /* Enable UART (UE bit), TX, RX — simplified setup */
    regs->CR1 = 0x0000000CUL; /* UE=0 first, then set after config */
    regs->CR2 = 0;
    regs->CR3 = 0;

    /* Parity */
    uint32_t cr1 = 0x2000UL; /* UE + RE + TE (bit 13 = UE, bit 2=RE, bit 3=TE) */
    if (config->parity == PARITY_EVEN) {
        cr1 |= 0x00000400UL; /* PCE = 1, PS = 0 */
    } else if (config->parity == PARITY_ODD) {
        cr1 |= 0x00000C00UL; /* PCE = 1, PS = 1 */
    }

    /* Stop bits */
    if (config->stop == STOP2) {
        regs->CR2 = 0x00003000UL; /* STOP[13:12] = 0b10 (2 stop bits) */
    } else {
        regs->CR2 = 0x00000000UL; /* STOP[13:12] = 0b00 (1 stop bit)  */
    }

    /* Data bits (default 8; 9 via M bit) */
    if (config->data_bits == 9) {
        cr1 |= 0x00000100UL; /* M = 1 -> 9 data bits */
    }

    /* Baud rate (simplified: assumes 16 MHz clock) */
    regs->BRR = (config->baudrate > 0U) ? (16000000UL / config->baudrate) : 0U;

    regs->CR1 = cr1 | 0x2000UL; /* Finally enable */

    g_uart_initialized = 1;
}

/**
 * UART_DeInit — Reset UART peripheral and state.
 */
void UART_DeInit(uart_id_t id)
{
    uart_regs_t *regs = g_uart_instances[id];
    regs->CR1 = 0;
    (void)__builtin_memset(&g_uart_state[id], 0, sizeof(uart_state_t));
}

/**
 * UART_WriteByte — Write a single byte (blocking, polling).
 */
void UART_WriteByte(uart_id_t id, uint8_t data)
{
    uart_regs_t *regs = g_uart_instances[id];
    /* Wait until TXE is set */
    while ((regs->SR & 0x80UL) == 0U) { }
    regs->DR = data;
}

/**
 * UART_ReadByte — Read a single byte (blocking, polling).
 * @return byte read from the data register.
 */
uint8_t UART_ReadByte(uart_id_t id)
{
    uart_regs_t *regs = g_uart_instances[id];
    /* Wait until RXNE is set */
    while ((regs->SR & 0x20UL) == 0U) { }
    return (uint8_t)(regs->DR & 0xFFUL);
}

/**
 * UART_WriteBuffer — Write a buffer of bytes (blocking, polling).
 */
void UART_WriteBuffer(uart_id_t id, const uint8_t *data, uint32_t length)
{
    for (uint32_t i = 0; i < length; ++i) {
        UART_WriteByte(id, data[i]);
    }
}

/**
 * UART_WriteString — Write a null-terminated string (blocking, polling).
 */
void UART_WriteString(uart_id_t id, const char *str)
{
    while (*str != '\0') {
        UART_WriteByte(id, (uint8_t)*str);
        ++str;
    }
}

/**
 * UART_Flush — Wait until the transmit buffer is empty.
 */
void UART_Flush(uart_id_t id)
{
    uart_regs_t *regs = g_uart_instances[id];
    /* Wait for TC (Transmit Complete) */
    while ((regs->SR & 0x40UL) == 0U) { }
}

/**
 * UART_ErrorsGet — Return the accumulated error counters.
 */
uart_state_t *UART_ErrorsGet(uart_id_t id)
{
    return &g_uart_state[id];
}

/**
 * UART_EnableInterrupt — Enable TXE or RXNE interrupt.
 * @param flags: bit0=RXNEIE, bit1=TCIE, bit2=TXEIE
 */
void UART_EnableInterrupt(uart_id_t id, uint32_t flags)
{
    uart_regs_t *regs = g_uart_instances[id];
    regs->CR1 |= (flags & 0x00002020UL); /* mask to valid bits */
}

/* ------------------------------------------------------------------ */
/*  Interrupt handlers                                                 */
/* ------------------------------------------------------------------ */
void UART0_IRQHandler(void)
{
    uart_irq_handler(UART0);
}

void UART1_IRQHandler(void)
{
    uart_irq_handler(UART1);
}
