# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\spi.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\spi.c" 2
/**
 * spi.c — SPI Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_spi_instance, g_spi_initialized, g_spi_base
 *   - Types: spi_role_t, spi_cpol_t, spi_cpha_t, spi_dff_t, spi_regs_t
 *   - Register base: SPI_MASTER_BASE / SPI_SLAVE_BASE
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
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\spi.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\spi.c" 2

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */



/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    MASTER = 0,
    SLAVE = 1
} spi_role_t;

typedef enum {
    CPOL0 = 0,
    CPOL1 = 1
} spi_cpol_t;

typedef enum {
    CPHA0 = 0,
    CPHA1 = 1
} spi_cpha_t;

typedef enum {
    DFF8 = 0,
    DFF16 = 1
} spi_dff_t;

typedef struct {
    volatile uint32_t CR1; /* 0x00 */
    volatile uint32_t CR2; /* 0x04 */
    volatile uint32_t SR; /* 0x08 */
    volatile uint32_t DR; /* 0x0C */
    volatile uint32_t CRCPR; /* 0x10 */
    volatile uint32_t RXCRCR; /* 0x14 */
    volatile uint32_t TXCRCR; /* 0x18 */
} spi_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static spi_regs_t *g_spi_instance = (spi_regs_t *)0x40013000UL;
static _Bool g_spi_initialized = 0;
static uint32_t g_spi_base = 0x40013000UL;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * SPI_Init — Configure SPI peripheral.
 * @param role  : MASTER or SLAVE
 * @param cpol  : clock polarity
 * @param cpha  : clock phase
 * @param dff   : data frame format (8-bit or 16-bit)
 * @param baud_divider : clock prescaler (2, 4, 8, 16, 32, 64, 128, 256)
 */
void SPI_Init(spi_role_t role, spi_cpol_t cpol, spi_cpha_t cpha,
              spi_dff_t dff, uint32_t baud_divider)
{
    /* Select instance based on role */
    if (role == SLAVE) {
        g_spi_instance = (spi_regs_t *)0x40013400UL;
        g_spi_base = 0x40013400UL;
    } else {
        g_spi_instance = (spi_regs_t *)0x40013000UL;
        g_spi_base = 0x40013000UL;
    }

    spi_regs_t *regs = g_spi_instance;

    /* Disable SPI first (SPE = 0) */
    regs->CR1 = 0;

    uint32_t cr1 = 0;

    /* Master / Slave */
    if (role == MASTER) {
        cr1 |= 0x00000004UL; /* MSTR = 1 */
    }

    /* CPOL + CPHA */
    if (cpol == CPOL1) cr1 |= 0x00000002UL;
    if (cpha == CPHA1) cr1 |= 0x00000001UL;

    /* Data frame format */
    if (dff == DFF16) cr1 |= 0x00000800UL; /* DFF = 1 */

    /* Baud rate divider (BR[2:0]) */
    uint32_t br = 0;
    if (baud_divider >= 256) br = 7;
    else if (baud_divider >= 128) br = 6;
    else if (baud_divider >= 64) br = 5;
    else if (baud_divider >= 32) br = 4;
    else if (baud_divider >= 16) br = 3;
    else if (baud_divider >= 8) br = 2;
    else if (baud_divider >= 4) br = 1;
    else br = 0; /* fPCLK / 2 */
    cr1 |= (br << 3U);

    /* SSI = 1 (internal slave select) when master */
    if (role == MASTER) {
        cr1 |= 0x00000100UL; /* SSI = 1 */
    }

    regs->CR1 = cr1;

    /* Enable SPI (SPE = 1) */
    regs->CR1 |= 0x00000040UL;

    g_spi_initialized = 1;
}

/**
 * SPI_Transmit — Transmit a single byte (blocking, polling).
 */
void SPI_Transmit(uint8_t data)
{
    spi_regs_t *regs = g_spi_instance;
    /* Wait until TXE is set */
    while ((regs->SR & 0x00000002UL) == 0U) { }
    regs->DR = data;
    /* Wait for RXNE to ensure transmission complete */
    while ((regs->SR & 0x00000001UL) == 0U) { }
    /* Dummy read to clear RXNE */
    (void)regs->DR;
}

/**
 * SPI_Receive — Receive a single byte (blocking, polling).
 * @return byte read from the SPI data register.
 */
uint8_t SPI_Receive(void)
{
    spi_regs_t *regs = g_spi_instance;
    /* Transmit dummy byte to generate clock */
    regs->DR = 0xFF;
    /* Wait until RXNE is set */
    while ((regs->SR & 0x00000001UL) == 0U) { }
    return (uint8_t)(regs->DR & 0xFFUL);
}

/**
 * SPI_TransmitReceive — Simultaneous transmit and receive (full duplex).
 * @param tx_data : byte to send
 * @return received byte
 */
uint8_t SPI_TransmitReceive(uint8_t tx_data)
{
    spi_regs_t *regs = g_spi_instance;
    while ((regs->SR & 0x00000002UL) == 0U) { }
    regs->DR = tx_data;
    while ((regs->SR & 0x00000001UL) == 0U) { }
    return (uint8_t)(regs->DR & 0xFFUL);
}

/**
 * SPI_ReadRegister — Read a memory-mapped register at given offset from SPI base.
 * @param offset : byte offset from base address
 * @return 32-bit register value
 */
uint32_t SPI_ReadRegister(uint32_t offset)
{
    volatile uint32_t *addr = (volatile uint32_t *)(g_spi_base + offset);
    return *addr;
}

/**
 * SPI_WriteRegister — Write a value to a memory-mapped register at given offset.
 */
void SPI_WriteRegister(uint32_t offset, uint32_t value)
{
    volatile uint32_t *addr = (volatile uint32_t *)(g_spi_base + offset);
    *addr = value;
}

/* ------------------------------------------------------------------ */
/*  Interrupt handlers                                                 */
/* ------------------------------------------------------------------ */
void SPIM_IRQHandler(void)
{
    /* Placeholder — application-defined behaviour */
}

void SPIS_IRQHandler(void)
{
    /* Placeholder — application-defined behaviour */
}
