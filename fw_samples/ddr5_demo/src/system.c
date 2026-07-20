/**
 * system.c — System / Clock Initialization
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>
#include <stdbool.h>

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */
#define SCB_AIRCR       (*(volatile uint32_t *)0xE000ED0CUL)
#define SCB_SCR         (*(volatile uint32_t *)0xE000ED10UL)
#define SYSTICK_CSR     (*(volatile uint32_t *)0xE000E010UL)
#define SYSTICK_RVR     (*(volatile uint32_t *)0xE000E014UL)
#define PWR_CR          (*(volatile uint32_t *)0x40007000UL)
#define FLASH_ACR       (*(volatile uint32_t *)0x40022000UL)

/* AIRCR key and bits */
#define AIRCR_VECTKEY   0x5FA00000UL
#define AIRCR_SYSRESET  0x00000004UL

/* SCR bits */
#define SCR_SLEEPDEEP   (1u << 2)
#define SCR_SLEEPONEXIT (1u << 1)

/* PWR_CR bits */
#define PWR_CR_LPDS     (1u << 0)
#define PWR_CR_PDDS     (1u << 1)
#define PWR_CR_CWUF     (1u << 2)
#define PWR_CR_CSBF     (1u << 3)

/* FLASH_ACR bits */
#define FLASH_ACR_LATENCY_MASK 0x07u
#define FLASH_ACR_PRFTEN       (1u << 8)
#define FLASH_ACR_ICEN         (1u << 9)
#define FLASH_ACR_DCEN         (1u << 10)

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    POWER_MODE_RUN        = 0,
    POWER_MODE_SLEEP      = 1,
    POWER_MODE_DEEP_SLEEP = 2,
    POWER_MODE_STANDBY    = 3
} power_mode_t;

typedef enum
{
    CLOCK_SOURCE_HSI = 0,
    CLOCK_SOURCE_HSE = 1,
    CLOCK_SOURCE_PLL = 2
} clock_source_t;

typedef struct
{
    clock_source_t source;
    uint32_t       ahb_div;
    uint32_t       apb1_div;
    uint32_t       apb2_div;
} system_clock_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static uint32_t       g_reset_cause     = 0u;
static uint32_t       g_system_clock_hz = 8000000u;  /* default 8 MHz HSI */
static power_mode_t   g_current_power_mode = POWER_MODE_RUN;
static system_clock_t g_clock_config        = {
    .source  = CLOCK_SOURCE_HSI,
    .ahb_div  = 1u,
    .apb1_div = 1u,
    .apb2_div = 1u
};

/* ---------------------------------------------------------------------------
 * Forward declarations (static helpers)
 * --------------------------------------------------------------------------- */
static void system_configure_flash_latency(uint32_t clock_mhz);
void SystemClockDividerSet(uint32_t ahb, uint32_t apb1, uint32_t apb2);

/* ---------------------------------------------------------------------------
 * SystemInit — early system initialisation
 * --------------------------------------------------------------------------- */
void SystemInit(void)
{
    /* Enable Flash prefetch, I-cache, D-cache */
    FLASH_ACR |= (FLASH_ACR_PRFTEN | FLASH_ACR_ICEN | FLASH_ACR_DCEN);

    /* Configure Flash latency for current clock */
    system_configure_flash_latency(g_system_clock_hz / 1000000u);

    /* Set system clock divider defaults */
    SystemClockDividerSet(1u, 1u, 1u);

    /* Capture reset cause from RCC (placeholder) */
    g_reset_cause = 0x01u;  /* POR */

    g_current_power_mode = POWER_MODE_RUN;
}

/* ---------------------------------------------------------------------------
 * SystemCoreClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemCoreClockGet(void)
{
    return g_system_clock_hz;
}

/* ---------------------------------------------------------------------------
 * SystemCoreClockUpdate — recalculate g_system_clock_hz from registers
 * --------------------------------------------------------------------------- */
void SystemCoreClockUpdate(void)
{
    /* Placeholder: read actual clock registers and compute HZ value.
     * Default implementation keeps the stored value. */
    __asm__("" ::: "memory");
}

/* ---------------------------------------------------------------------------
 * SystemResetCauseGet
 * --------------------------------------------------------------------------- */
uint32_t SystemResetCauseGet(void)
{
    return g_reset_cause;
}

/* ---------------------------------------------------------------------------
 * SystemReset — full system reset via SYSRESETREQ
 * --------------------------------------------------------------------------- */
void SystemReset(void)
{
    SCB_AIRCR = AIRCR_VECTKEY | AIRCR_SYSRESET;
    __asm__("dsb sy" ::: "memory");
    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * SystemSoftReset — software-initiated reset (same mechanism)
 * --------------------------------------------------------------------------- */
void SystemSoftReset(void)
{
    SystemReset();
}

/* ---------------------------------------------------------------------------
 * SystemPowerModeSet
 * --------------------------------------------------------------------------- */
void SystemPowerModeSet(power_mode_t mode)
{
    uint32_t scr = SCB_SCR;
    uint32_t pwr = PWR_CR;

    switch (mode)
    {
        case POWER_MODE_SLEEP:
            scr &= ~SCR_SLEEPDEEP;
            pwr &= ~(PWR_CR_LPDS | PWR_CR_PDDS);
            break;

        case POWER_MODE_DEEP_SLEEP:
            scr |= SCR_SLEEPDEEP;
            pwr &= ~PWR_CR_PDDS;
            pwr |= PWR_CR_LPDS;
            break;

        case POWER_MODE_STANDBY:
            scr |= SCR_SLEEPDEEP;
            pwr &= ~PWR_CR_LPDS;
            pwr |= PWR_CR_PDDS;
            break;

        default: /* RUN */
            scr &= ~SCR_SLEEPDEEP;
            pwr &= ~(PWR_CR_LPDS | PWR_CR_PDDS);
            break;
    }

    SCB_SCR = scr;
    PWR_CR  = pwr;

    g_current_power_mode = mode;
}

/* ---------------------------------------------------------------------------
 * SystemPowerModeGet
 * --------------------------------------------------------------------------- */
power_mode_t SystemPowerModeGet(void)
{
    return g_current_power_mode;
}

/* ---------------------------------------------------------------------------
 * SystemTickConfig — configure SysTick to fire every 'reload' ticks
 * --------------------------------------------------------------------------- */
int32_t SystemTickConfig(uint32_t reload)
{
    SYSTICK_RVR = reload & 0x00FFFFFFUL;
    SYSTICK_CSR = 0x07UL;  /* Enable + interrupt + processor clock */
    return 0;
}

/* ---------------------------------------------------------------------------
 * SystemTickDisable
 * --------------------------------------------------------------------------- */
void SystemTickDisable(void)
{
    SYSTICK_CSR = 0x00UL;
}

/* ---------------------------------------------------------------------------
 * SystemTickCountGet — read current SysTick counter value
 * --------------------------------------------------------------------------- */
uint32_t SystemTickCountGet(void)
{
    return *(volatile uint32_t *)0xE000E018UL;  /* SYSTICK_CVR */
}

/* ---------------------------------------------------------------------------
 * SystemDelayMs — busy-wait millisecond delay using SysTick
 * --------------------------------------------------------------------------- */
void SystemDelayMs(uint32_t ms)
{
    volatile uint32_t count;

    while (ms--)
    {
        /* Assuming SysTick runs at 1 ms period */
        count = SystemTickCountGet();
        while (SystemTickCountGet() == count)
        {
            /* spin */
        }
    }
}

/* ---------------------------------------------------------------------------
 * SystemClockDividerSet — set AHB, APB1, APB2 prescalers
 * --------------------------------------------------------------------------- */
void SystemClockDividerSet(uint32_t ahb, uint32_t apb1, uint32_t apb2)
{
    g_clock_config.ahb_div  = ahb;
    g_clock_config.apb1_div = apb1;
    g_clock_config.apb2_div = apb2;

    /* Placeholder: write actual RCC clock configuration registers */
}

/* ---------------------------------------------------------------------------
 * SystemAHBClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemAHBClockGet(void)
{
    return g_system_clock_hz / g_clock_config.ahb_div;
}

/* ---------------------------------------------------------------------------
 * SystemAPB1ClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemAPB1ClockGet(void)
{
    return SystemAHBClockGet() / g_clock_config.apb1_div;
}

/* ---------------------------------------------------------------------------
 * SystemAPB2ClockGet
 * --------------------------------------------------------------------------- */
uint32_t SystemAPB2ClockGet(void)
{
    return SystemAHBClockGet() / g_clock_config.apb2_div;
}

/* ---------------------------------------------------------------------------
 * system_configure_flash_latency (static helper)
 * --------------------------------------------------------------------------- */
static void system_configure_flash_latency(uint32_t clock_mhz)
{
    uint32_t latency = 0u;

    if (clock_mhz > 48u)
    {
        latency = 4u;
    }
    else if (clock_mhz > 36u)
    {
        latency = 3u;
    }
    else if (clock_mhz > 24u)
    {
        latency = 2u;
    }
    else if (clock_mhz > 12u)
    {
        latency = 1u;
    }
    else
    {
        latency = 0u;
    }

    FLASH_ACR = (FLASH_ACR & ~FLASH_ACR_LATENCY_MASK) | latency;
}

/* ---------------------------------------------------------------------------
 * SystemInfoPrint — placeholder debug output
 * --------------------------------------------------------------------------- */
void SystemInfoPrint(void)
{
    /* In a real system this would print to UART or debug console.
     * Placeholder to satisfy the interface. */
    volatile uint32_t dummy = g_system_clock_hz;
    (void)dummy;
}