/**
 * platform.c — Platform Abstraction Layer
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>
#include <stdbool.h>

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */
#define FPU_CPACR (*(volatile uint32_t *)0xE000ED88UL)

/* CPACR bits for CP10, CP11 — full access */
#define CPACR_CP10_FULL (0x03u << 20)
#define CPACR_CP11_FULL (0x03u << 22)

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    PLATFORM_INIT   = 0,
    PLATFORM_ACTIVE = 1,
    PLATFORM_SLEEP  = 2,
    PLATFORM_ERROR  = 3
} platform_state_t;

typedef struct
{
    bool secure_mode;
    bool debug_enabled;
    bool fpu_enabled;
} platform_config_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static platform_state_t  g_platform_state  = PLATFORM_INIT;
static platform_config_t g_platform_config = {
    .secure_mode   = true,
    .debug_enabled = true,
    .fpu_enabled   = true
};
static uint32_t g_error_code = 0u;

/* ---------------------------------------------------------------------------
 * PLATFORM_Init — initialise platform hardware
 * --------------------------------------------------------------------------- */
int32_t PLATFORM_Init(void)
{
    /* Apply default config */
    if (g_platform_config.fpu_enabled)
    {
        FPU_CPACR |= (CPACR_CP10_FULL | CPACR_CP11_FULL);
        __asm__("dsb sy" ::: "memory");
        __asm__("isb sy" ::: "memory");
    }

    g_platform_state = PLATFORM_ACTIVE;
    g_error_code     = 0u;

    return 0;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_PostInit — post-initialisation steps
 * --------------------------------------------------------------------------- */
int32_t PLATFORM_PostInit(void)
{
    /* Ensure FPU is still enabled (may have been altered by secure monitor) */
    if (g_platform_config.fpu_enabled)
    {
        FPU_CPACR |= (CPACR_CP10_FULL | CPACR_CP11_FULL);
        __asm__("dsb sy" ::: "memory");
        __asm__("isb sy" ::: "memory");
    }

    return 0;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_Sleep — enter low-power mode
 * --------------------------------------------------------------------------- */
void PLATFORM_Sleep(void)
{
    g_platform_state = PLATFORM_SLEEP;
    __asm__("wfi" ::: "memory");
    g_platform_state = PLATFORM_ACTIVE;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_SetConfig
 * --------------------------------------------------------------------------- */
void PLATFORM_SetConfig(const platform_config_t *cfg)
{
    if (cfg != (const platform_config_t *)0)
    {
        g_platform_config = *cfg;

        /* Apply FPU setting immediately */
        if (cfg->fpu_enabled)
        {
            FPU_CPACR |= (CPACR_CP10_FULL | CPACR_CP11_FULL);
        }
        else
        {
            FPU_CPACR &= ~(CPACR_CP10_FULL | CPACR_CP11_FULL);
        }
        __asm__("dsb sy" ::: "memory");
        __asm__("isb sy" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * PLATFORM_GetConfig
 * --------------------------------------------------------------------------- */
void PLATFORM_GetConfig(platform_config_t *cfg)
{
    if (cfg != (platform_config_t *)0)
    {
        *cfg = g_platform_config;
    }
}

/* ---------------------------------------------------------------------------
 * PLATFORM_IsSecure
 * --------------------------------------------------------------------------- */
bool PLATFORM_IsSecure(void)
{
    return g_platform_config.secure_mode;
}

/* ---------------------------------------------------------------------------
 * PLATFORM_GetVersion — return a 32-bit version identifier
 * --------------------------------------------------------------------------- */
uint32_t PLATFORM_GetVersion(void)
{
    return 0x01000001u;  /* major.minor.patch */
}

/* ---------------------------------------------------------------------------
 * PLATFORM_ErrorHandler — record and enter error state
 * --------------------------------------------------------------------------- */
void PLATFORM_ErrorHandler(uint32_t error_code)
{
    g_error_code    = error_code;
    g_platform_state = PLATFORM_ERROR;

    /* Infinite loop in error state */
    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ===========================================================================
 * DDR5 init controller platform abstraction
 *
 * Provides the extern functions required by src/ddr5_init_controller.c.
 * These are simplified implementations for analysis purposes.
 * ======================================================================== */

/* ── DDR controller MMIO base (simulated) ─────────────────────────────── */
#define DDR_CTRL_BASE           0x40000000UL
#define DDR_CTRL_MR_OP          (DDR_CTRL_BASE + 0x0000U)
#define DDR_CTRL_MR_ADDR        (DDR_CTRL_BASE + 0x0004U)
#define DDR_CTRL_MR_DATA        (DDR_CTRL_BASE + 0x0008U)
#define DDR_CTRL_MR_CMD         (DDR_CTRL_BASE + 0x000CU)
#define DDR_CTRL_TRAIN_CTRL     (DDR_CTRL_BASE + 0x0020U)
#define DDR_CTRL_TRAIN_STATUS   (DDR_CTRL_BASE + 0x0024U)
#define DDR_CTRL_ZQ_CTRL        (DDR_CTRL_BASE + 0x0030U)

/* Simple busy-wait delay (approximate cycle count) */
void ddr5_delay_cycles(uint32_t cycles)
{
    volatile uint32_t i;
    for (i = 0; i < cycles; i++)
    {
        __asm__("nop");
    }
}

/* Memory-mapped register read */
uint32_t ddr5_read_reg(uint32_t addr)
{
    return *(volatile uint32_t *)addr;
}

/* Memory-mapped register write */
void ddr5_write_reg(uint32_t addr, uint32_t val)
{
    *(volatile uint32_t *)addr = val;
}

/* DDR5 Mode Register Read via controller MRR operation */
uint32_t ddr5_mr_read(uint8_t mr_addr)
{
    ddr5_write_reg(DDR_CTRL_MR_ADDR, mr_addr);
    ddr5_write_reg(DDR_CTRL_MR_CMD, 0x01U);   /* MRR command */
    while (ddr5_read_reg(DDR_CTRL_MR_CMD) & (1U << 31));  /* wait busy */
    return ddr5_read_reg(DDR_CTRL_MR_DATA);
}

/* DDR5 Mode Register Write via controller MRW operation */
void ddr5_mr_write(uint8_t mr_addr, uint32_t data)
{
    ddr5_write_reg(DDR_CTRL_MR_ADDR, mr_addr);
    ddr5_write_reg(DDR_CTRL_MR_DATA, data);
    ddr5_write_reg(DDR_CTRL_MR_CMD, 0x00U);   /* MRW command */
    while (ddr5_read_reg(DDR_CTRL_MR_CMD) & (1U << 31));  /* wait busy */
}

/* DDR5 CA Bus command send (simplified) */
void ddr5_ca_bus_send(uint16_t cmd, uint32_t addr)
{
    /* In real hardware: drives CA[13:0] bus signals with command + address.
     * Here we write to a simulated controller register for analysis tracing. */
    ddr5_write_reg(DDR_CTRL_TRAIN_CTRL, ((uint32_t)cmd << 16) | (addr & 0xFFFFU));
}

/* DDR5 CKE control */
void ddr5_set_cke(uint8_t state)
{
    /* CKE is typically a SoC GPIO or PLL control line. */
    ddr5_write_reg(DDR_CTRL_BASE + 0x1000U, state ? 1U : 0U);
}

/* DDR5 RESET_n control */
void ddr5_set_reset_n(uint8_t state)
{
    /* RESET_n is typically a SoC GPIO. */
    ddr5_write_reg(DDR_CTRL_BASE + 0x1004U, state ? 1U : 0U);
}