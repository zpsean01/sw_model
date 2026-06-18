/**
 * main.c — Firmware Entry Point
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>
#include <stdbool.h>

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    APP_INIT    = 0,
    APP_RUNNING = 1,
    APP_ERROR   = 2,
    APP_SLEEP   = 3
} app_state_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static volatile uint32_t g_sys_tick_count  = 0u;
static uint32_t          g_main_loop_count = 0u;

/* ---------------------------------------------------------------------------
 * External function declarations
 * --------------------------------------------------------------------------- */
extern int32_t CRYPTO_Init(void);
extern int32_t STORAGE_Init(void);
extern int32_t ITS_Init(void);
extern int32_t ATTEST_Init(void);
extern void    BOARD_Init(void);
extern int32_t IPC_Init(void);
extern void    SM_Init(void);
extern int32_t SM_Transition(uint32_t to, void *arg);
extern void    NVIC_EnableIRQ(uint32_t irq);
extern int32_t SystemTickConfig(uint32_t reload);
extern void    SystemInit(void);

/* ---------------------------------------------------------------------------
 * SysTick_Handler — ISR defined in vector table
 * --------------------------------------------------------------------------- */
void SysTick_Handler(void)
{
    g_sys_tick_count++;
}

/* ---------------------------------------------------------------------------
 * sys_tick_handler — local wrapper (called from SysTick_Handler if desired)
 * --------------------------------------------------------------------------- */
static void sys_tick_handler(void)
{
    g_sys_tick_count++;
}

/* ---------------------------------------------------------------------------
 * secure_service_init — initialise secure services
 * --------------------------------------------------------------------------- */
int32_t secure_service_init(void)
{
    int32_t ret;

    ret = CRYPTO_Init();
    if (ret != 0) return ret;

    ret = STORAGE_Init();
    if (ret != 0) return ret;

    ret = ITS_Init();
    if (ret != 0) return ret;

    ret = ATTEST_Init();
    if (ret != 0) return ret;

    return 0;
}

/* ---------------------------------------------------------------------------
 * peripheral_init — initialise board-level peripherals
 * --------------------------------------------------------------------------- */
int32_t peripheral_init(void)
{
    BOARD_Init();
    return 0;
}

/* ---------------------------------------------------------------------------
 * ipc_init — initialise inter-processor communication
 * --------------------------------------------------------------------------- */
int32_t ipc_init(void)
{
    return IPC_Init();
}

/* ---------------------------------------------------------------------------
 * app_main_loop — main application loop
 * --------------------------------------------------------------------------- */
int32_t app_main_loop(void)
{
    while (1u)
    {
        g_main_loop_count++;

        /* Process events, check state machine, etc. */
        if (g_main_loop_count % 1000u == 0u)
        {
            /* Toggle LED or do periodic work — placeholder */
        }

        /* Yield to reduce power */
        __asm__("wfi" ::: "memory");
    }

    /* Unreachable */
}

/* ---------------------------------------------------------------------------
 * main — firmware entry
 * --------------------------------------------------------------------------- */
int main(void)
{
    app_state_t app_state = APP_INIT;

    /* System-level initialisation */
    SystemInit();

    /* Reference unused symbols to suppress warnings */
    (void)sys_tick_handler;
    (void)app_state;

    /* Configure SysTick for 1 ms period (assuming 8 MHz clock) */
    (void)SystemTickConfig(8000u);

    /* Enable SysTick interrupt in NVIC */
    NVIC_EnableIRQ(15u);  /* SysTick IRQ number */

    /* Initialise state machine */
    SM_Init();

    /* Initialise secure services */
    if (secure_service_init() != 0)
    {
        app_state = APP_ERROR;
        (void)SM_Transition(3u, (void *)0);  /* -> STATE_ERROR */
        while (1u)
        {
            __asm__("wfi" ::: "memory");
        }
    }

    /* Initialise peripherals */
    if (peripheral_init() != 0)
    {
        app_state = APP_ERROR;
        (void)SM_Transition(3u, (void *)0);
        while (1u)
        {
            __asm__("wfi" ::: "memory");
        }
    }

    /* Initialise IPC */
    if (ipc_init() != 0)
    {
        app_state = APP_ERROR;
        (void)SM_Transition(3u, (void *)0);
        while (1u)
        {
            __asm__("wfi" ::: "memory");
        }
    }

    app_state = APP_RUNNING;

    /* Enter main loop */
    (void)app_main_loop();

    /* Should never reach here */
    return 0;
}