/**
 * spi.c — SPI Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_spi_instance, g_spi_initialized, g_spi_base
 *   - Types: spi_role_t, spi_cpol_t, spi_cpha_t, spi_dff_t, spi_regs_t
 *   - Register base: SPI_MASTER_BASE / SPI_SLAVE_BASE
 *   - 8 functions
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */
#define SPI_MASTER_BASE        0x40013000UL
#define SPI_SLAVE_BASE         0x40013400UL

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    MASTER = 0,
    SLAVE  = 1
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
    DFF8  = 0,
    DFF16 = 1
} spi_dff_t;

typedef struct {
    volatile uint32_t CR1;       /* 0x00 */
    volatile uint32_t CR2;       /* 0x04 */
    volatile uint32_t SR;        /* 0x08 */
    volatile uint32_t DR;        /* 0x0C */
    volatile uint32_t CRCPR;     /* 0x10 */
    volatile uint32_t RXCRCR;    /* 0x14 */
    volatile uint32_t TXCRCR;    /* 0x18 */
} spi_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static spi_regs_t *g_spi_instance = (spi_regs_t *)SPI_MASTER_BASE;
static bool        g_spi_initialized = false;
static uint32_t    g_spi_base = SPI_MASTER_BASE;

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
        g_spi_instance = (spi_regs_t *)SPI_SLAVE_BASE;
        g_spi_base     = SPI_SLAVE_BASE;
    } else {
        g_spi_instance = (spi_regs_t *)SPI_MASTER_BASE;
        g_spi_base     = SPI_MASTER_BASE;
    }

    spi_regs_t *regs = g_spi_instance;

    /* Disable SPI first (SPE = 0) */
    regs->CR1 = 0;

    uint32_t cr1 = 0;

    /* Master / Slave */
    if (role == MASTER) {
        cr1 |= 0x00000004UL;    /* MSTR = 1 */
    }

    /* CPOL + CPHA */
    if (cpol == CPOL1) cr1 |= 0x00000002UL;
    if (cpha == CPHA1) cr1 |= 0x00000001UL;

    /* Data frame format */
    if (dff == DFF16) cr1 |= 0x00000800UL;   /* DFF = 1 */

    /* Baud rate divider (BR[2:0]) */
    uint32_t br = 0;
    if (baud_divider >= 256)      br = 7;
    else if (baud_divider >= 128) br = 6;
    else if (baud_divider >= 64)  br = 5;
    else if (baud_divider >= 32)  br = 4;
    else if (baud_divider >= 16)  br = 3;
    else if (baud_divider >= 8)   br = 2;
    else if (baud_divider >= 4)   br = 1;
    else                          br = 0;  /* fPCLK / 2 */
    cr1 |= (br << 3U);

    /* SSI = 1 (internal slave select) when master */
    if (role == MASTER) {
        cr1 |= 0x00000100UL;    /* SSI = 1 */
    }

    regs->CR1 = cr1;

    /* Enable SPI (SPE = 1) */
    regs->CR1 |= 0x00000040UL;

    g_spi_initialized = true;
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