/**
 * interrupt.c — NVIC Interrupt Controller for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_irq_count, g_last_irq
 *   - Types: irq_priority_t enum
 *   - Direct register access via macro-defined volatile pointers
 *   - 8 functions
 */

#include <stdint.h>
#include <stdbool.h>

/* ------------------------------------------------------------------ */
/*  NVIC register definitions (Cortex-M33)                             */
/* ------------------------------------------------------------------ */
#define NVIC_ISER   ((volatile uint32_t *)0xE000E100UL)   /* 8 x 32-bit (IRQ 0..255) */
#define NVIC_ICER   ((volatile uint32_t *)0xE000E180UL)
#define NVIC_ISPR   ((volatile uint32_t *)0xE000E200UL)
#define NVIC_ICPR   ((volatile uint32_t *)0xE000E280UL)
#define NVIC_IPR    ((volatile uint8_t  *)0xE000E400UL)   /* byte-accessible */

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    PRIO_LOWEST  = 15,
    PRIO_LOW     = 10,
    PRIO_MEDIUM  =  5,
    PRIO_HIGH    =  1,
    PRIO_HIGHEST =  0
} irq_priority_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static uint32_t g_irq_count = 0;
static uint8_t  g_last_irq  = 0;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * NVIC_EnableIRQ — Enable an interrupt in the NVIC.
 * @param irq_num : IRQ number (0..239 for Cortex-M33)
 */
void NVIC_EnableIRQ(uint8_t irq_num)
{
    uint32_t idx   = irq_num / 32U;
    uint32_t bit   = 1UL << (irq_num % 32U);
    NVIC_ISER[idx] = bit;
    ++g_irq_count;
    g_last_irq = irq_num;
}

/**
 * NVIC_DisableIRQ — Disable an interrupt in the NVIC.
 */
void NVIC_DisableIRQ(uint8_t irq_num)
{
    uint32_t idx   = irq_num / 32U;
    uint32_t bit   = 1UL << (irq_num % 32U);
    NVIC_ICER[idx] = bit;
}

/**
 * NVIC_SetPriority — Set priority of an interrupt.
 * @param irq_num  : IRQ number
 * @param priority : priority value (0..15, lower number = higher priority)
 */
void NVIC_SetPriority(uint8_t irq_num, uint8_t priority)
{
    uint32_t idx = irq_num;
    /* IPR is byte-accessible, each IRQ uses one byte (upper 4 bits) */
    NVIC_IPR[idx] = (uint8_t)(priority << 4U);
}

/**
 * NVIC_GetPriority — Get priority of an interrupt.
 * @return priority value (0..15).
 */
uint8_t NVIC_GetPriority(uint8_t irq_num)
{
    uint32_t idx = irq_num;
    return (uint8_t)(NVIC_IPR[idx] >> 4U);
}

/**
 * NVIC_GetPendingIRQ — Check if an interrupt is pending.
 * @return true if pending.
 */
bool NVIC_GetPendingIRQ(uint8_t irq_num)
{
    uint32_t idx = irq_num / 32U;
    uint32_t bit = 1UL << (irq_num % 32U);
    return (NVIC_ISPR[idx] & bit) != 0U;
}

/**
 * NVIC_ClearPendingIRQ — Clear pending status of an interrupt.
 */
void NVIC_ClearPendingIRQ(uint8_t irq_num)
{
    uint32_t idx = irq_num / 32U;
    uint32_t bit = 1UL << (irq_num % 32U);
    NVIC_ICPR[idx] = bit;
}

/**
 * NVIC_SystemReset — Trigger a system reset via the NVIC.
 * This writes to the AIRCR register in the System Control Block.
 */
void NVIC_SystemReset(void)
{
    volatile uint32_t *aircr = (volatile uint32_t *)0xE000ED0CUL;
    *aircr = (0x5FAUL << 16U) | (1UL << 2U);  /* SYSRESETREQ */
}

/**
 * NVIC_GetActiveIRQ — Return the last recorded IRQ number.
 * This is a simplified software-tracked active IRQ.
 * @return last IRQ number that was enabled.
 */
uint8_t NVIC_GetActiveIRQ(void)
{
    return g_last_irq;
}