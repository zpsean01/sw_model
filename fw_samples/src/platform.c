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