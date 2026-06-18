/**
 * startup.c - ARM Cortex-M33 Startup / Vector Table
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>

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
#define SCB_VTOR (*(volatile uint32_t *)0xE000ED08UL)

/* ---------------------------------------------------------------------------
 * Forward declarations
 * --------------------------------------------------------------------------- */
void Reset_Handler(void);
static void Default_Handler(void);
static void __initialize_hardware_early(void);

/* ---------------------------------------------------------------------------
 * Weak alias macros for interrupt handlers
 * --------------------------------------------------------------------------- */
#define WEAK_ALIAS(name)                                                    \
    void name(void) __attribute__((weak, alias("Default_Handler")))

WEAK_ALIAS(NMI_Handler);
WEAK_ALIAS(HardFault_Handler);
WEAK_ALIAS(MemManage_Handler);
WEAK_ALIAS(BusFault_Handler);
WEAK_ALIAS(UsageFault_Handler);
WEAK_ALIAS(SecureFault_Handler);
WEAK_ALIAS(SVCall_Handler);
WEAK_ALIAS(DebugMon_Handler);
WEAK_ALIAS(PendSV_Handler);
WEAK_ALIAS(SysTick_Handler);

/* Weak alias for reserved exception slots */
void RESERVED(void) __attribute__((weak, alias("Default_Handler")));

/* ---------------------------------------------------------------------------
 * Vector table — 48 entries as required by Cortex-M33
 * --------------------------------------------------------------------------- */
const void *g_pfnVectors[48] __attribute__((section(".vectors"))) = {
    /* Stack pointer and Reset */
    (const void *)&_stack_end,       /* 00: Initial Main Stack Pointer */
    (const void *)Reset_Handler,      /* 01: Reset */

    /* Exception handlers */
    (const void *)NMI_Handler,        /* 02: NMI */
    (const void *)HardFault_Handler,  /* 03: Hard Fault */
    (const void *)MemManage_Handler,  /* 04: MemManage Fault */
    (const void *)BusFault_Handler,   /* 05: Bus Fault */
    (const void *)UsageFault_Handler, /* 06: Usage Fault */
    (const void *)SecureFault_Handler,/* 07: Secure Fault */
    (const void *)RESERVED,           /* 08: Reserved */
    (const void *)RESERVED,           /* 09: Reserved */
    (const void *)RESERVED,           /* 10: Reserved */
    (const void *)SVCall_Handler,     /* 11: SVCall */
    (const void *)DebugMon_Handler,   /* 12: Debug Monitor */
    (const void *)RESERVED,           /* 13: Reserved */
    (const void *)PendSV_Handler,     /* 14: PendSV */
    (const void *)SysTick_Handler,    /* 15: SysTick */

    /* Interrupt handlers 16..47 (32 entries) */
    (const void *)RESERVED,           /* 16: IRQ 0 */
    (const void *)RESERVED,           /* 17: IRQ 1 */
    (const void *)RESERVED,           /* 18: IRQ 2 */
    (const void *)RESERVED,           /* 19: IRQ 3 */
    (const void *)RESERVED,           /* 20: IRQ 4 */
    (const void *)RESERVED,           /* 21: IRQ 5 */
    (const void *)RESERVED,           /* 22: IRQ 6 */
    (const void *)RESERVED,           /* 23: IRQ 7 */
    (const void *)RESERVED,           /* 24: IRQ 8 */
    (const void *)RESERVED,           /* 25: IRQ 9 */
    (const void *)RESERVED,           /* 26: IRQ 10 */
    (const void *)RESERVED,           /* 27: IRQ 11 */
    (const void *)RESERVED,           /* 28: IRQ 12 */
    (const void *)RESERVED,           /* 29: IRQ 13 */
    (const void *)RESERVED,           /* 30: IRQ 14 */
    (const void *)RESERVED,           /* 31: IRQ 15 */
    (const void *)RESERVED,           /* 32: IRQ 16 */
    (const void *)RESERVED,           /* 33: IRQ 17 */
    (const void *)RESERVED,           /* 34: IRQ 18 */
    (const void *)RESERVED,           /* 35: IRQ 19 */
    (const void *)RESERVED,           /* 36: IRQ 20 */
    (const void *)RESERVED,           /* 37: IRQ 21 */
    (const void *)RESERVED,           /* 38: IRQ 22 */
    (const void *)RESERVED,           /* 39: IRQ 23 */
    (const void *)RESERVED,           /* 40: IRQ 24 */
    (const void *)RESERVED,           /* 41: IRQ 25 */
    (const void *)RESERVED,           /* 42: IRQ 26 */
    (const void *)RESERVED,           /* 43: IRQ 27 */
    (const void *)RESERVED,           /* 44: IRQ 28 */
    (const void *)RESERVED,           /* 45: IRQ 29 */
    (const void *)RESERVED,           /* 46: IRQ 30 */
    (const void *)RESERVED,           /* 47: IRQ 31 */
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
    SCB_VTOR = (uint32_t)g_pfnVectors;

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