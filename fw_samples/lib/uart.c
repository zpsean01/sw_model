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

#include <stdint.h>
#include <stdbool.h>

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */
#define UART0_BASE             0x40004000UL
#define UART1_BASE             0x40005000UL

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
    PARITY_ODD  = 2
} uart_parity_t;

typedef enum {
    STOP1 = 0,
    STOP2 = 1
} uart_stop_t;

typedef struct {
    uint32_t       baudrate;
    uart_parity_t  parity;
    uart_stop_t    stop;
    uint8_t        data_bits;
} uart_config_t;

typedef struct {
    uint8_t  tx_buffer[256];
    uint8_t  rx_buffer[256];
    volatile uint16_t tx_head;
    volatile uint16_t tx_tail;
    volatile uint16_t rx_head;
    volatile uint16_t rx_tail;
    uint32_t overrun_errors;
    uint32_t framing_errors;
    uint32_t parity_errors;
} uart_state_t;

typedef struct {
    volatile uint32_t SR;    /* 0x00 - Status Register      */
    volatile uint32_t DR;    /* 0x04 - Data Register        */
    volatile uint32_t BRR;   /* 0x08 - Baud Rate Register   */
    volatile uint32_t CR1;   /* 0x0C - Control Register 1   */
    volatile uint32_t CR2;   /* 0x10 - Control Register 2   */
    volatile uint32_t CR3;   /* 0x14 - Control Register 3   */
} uart_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static uart_regs_t *g_uart_instances[2] = {
    (uart_regs_t *)UART0_BASE,
    (uart_regs_t *)UART1_BASE
};

static uart_state_t g_uart_state[2];
static bool         g_uart_initialized = false;

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
    uart_state_t *st  = &g_uart_state[id];
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

        if ((sr & 0x01UL) != 0U)  ++st->parity_errors;   /* PE  */
        if ((sr & 0x02UL) != 0U)  ++st->framing_errors;  /* FE  */
        if ((sr & 0x04UL) != 0U)  ++st->framing_errors;  /* NF  */
        if ((sr & 0x08UL) != 0U)  ++st->overrun_errors;  /* ORE */
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
    regs->CR1 = 0x0000000CUL;   /* UE=0 first, then set after config */
    regs->CR2 = 0;
    regs->CR3 = 0;

    /* Parity */
    uint32_t cr1 = 0x2000UL;    /* UE + RE + TE (bit 13 = UE, bit 2=RE, bit 3=TE) */
    if (config->parity == PARITY_EVEN) {
        cr1 |= 0x00000400UL;    /* PCE = 1, PS = 0 */
    } else if (config->parity == PARITY_ODD) {
        cr1 |= 0x00000C00UL;    /* PCE = 1, PS = 1 */
    }

    /* Stop bits */
    if (config->stop == STOP2) {
        regs->CR2 = 0x00003000UL;  /* STOP[13:12] = 0b10 (2 stop bits) */
    } else {
        regs->CR2 = 0x00000000UL;  /* STOP[13:12] = 0b00 (1 stop bit)  */
    }

    /* Data bits (default 8; 9 via M bit) */
    if (config->data_bits == 9) {
        cr1 |= 0x00000100UL;    /* M = 1 -> 9 data bits */
    }

    /* Baud rate (simplified: assumes 16 MHz clock) */
    regs->BRR = (config->baudrate > 0U) ? (16000000UL / config->baudrate) : 0U;

    regs->CR1 = cr1 | 0x2000UL; /* Finally enable */

    g_uart_initialized = true;
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
    regs->CR1 |= (flags & 0x00002020UL);  /* mask to valid bits */
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