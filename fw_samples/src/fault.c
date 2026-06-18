/**
 * fault.c — Fault Handlers and Logging
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>
#include <stdbool.h>

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */
#define SCB_CFSR  (*(volatile uint32_t *)0xE000ED28UL)
#define SCB_HFSR  (*(volatile uint32_t *)0xE000ED2CUL)
#define SCB_MMFAR (*(volatile uint32_t *)0xE000ED34UL)
#define SCB_BFAR  (*(volatile uint32_t *)0xE000ED38UL)

/* CFSR sub-register masks */
#define CFSR_USG_FAULT_MASK  0x0000FFFFUL
#define CFSR_BUS_FAULT_MASK  0x00FF0000UL
#define CFSR_MEM_FAULT_MASK  0xFF000000UL

/* HFSR bits */
#define HFSR_DEBUGEVT  (1u << 31)
#define HFSR_FORCED    (1u << 30)
#define HFSR_VECTBL    (1u << 1)

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    FAULT_HARD   = 0,
    FAULT_MEM    = 1,
    FAULT_BUS    = 2,
    FAULT_USAGE  = 3,
    FAULT_SECURE = 4
} fault_type_t;

typedef struct
{
    fault_type_t type;
    uint32_t     addr;
    uint32_t     cfsr;
    uint32_t     timestamp;
} fault_record_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static fault_record_t g_fault_log[16];
static uint32_t       g_fault_count     = 0u;
static uint32_t       g_fault_next_index = 0u;

/* ---------------------------------------------------------------------------
 * Forward declarations
 * --------------------------------------------------------------------------- */
static void fault_log(fault_type_t type, uint32_t addr);

/* ---------------------------------------------------------------------------
 * Fault_Init — initialise fault log
 * --------------------------------------------------------------------------- */
void Fault_Init(void)
{
    g_fault_count      = 0u;
    g_fault_next_index = 0u;

    for (uint32_t i = 0u; i < 16u; i++)
    {
        g_fault_log[i].type      = FAULT_HARD;
        g_fault_log[i].addr      = 0u;
        g_fault_log[i].cfsr      = 0u;
        g_fault_log[i].timestamp = 0u;
    }
}

/* ---------------------------------------------------------------------------
 * fault_log — internal helper to record a fault record
 * --------------------------------------------------------------------------- */
static void fault_log(fault_type_t type, uint32_t addr)
{
    uint32_t idx = g_fault_next_index;

    g_fault_log[idx].type      = type;
    g_fault_log[idx].addr      = addr;
    g_fault_log[idx].cfsr      = SCB_CFSR;
    g_fault_log[idx].timestamp = g_fault_count;  /* sequence number */

    g_fault_next_index = (idx + 1u) % 16u;
    if (g_fault_count < 16u)
    {
        g_fault_count++;
    }

    /* Invalidate CFSR by writing back (clear all fault bits) */
    SCB_CFSR = SCB_CFSR;
}

/* ---------------------------------------------------------------------------
 * HardFault_Handler
 * --------------------------------------------------------------------------- */
void HardFault_Handler(void)
{
    uint32_t hfsr = SCB_HFSR;
    uint32_t addr = 0u;

    if (hfsr & HFSR_FORCED)
    {
        /* A forced fault means a lower-priority fault escalated */
        uint32_t cfsr = SCB_CFSR;

        if (cfsr & CFSR_MEM_FAULT_MASK)
        {
            addr = SCB_MMFAR;
        }
        else if (cfsr & CFSR_BUS_FAULT_MASK)
        {
            addr = SCB_BFAR;
        }
    }

    fault_log(FAULT_HARD, addr);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * MemManage_Handler
 * --------------------------------------------------------------------------- */
void MemManage_Handler(void)
{
    uint32_t addr = SCB_MMFAR;
    fault_log(FAULT_MEM, addr);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * BusFault_Handler
 * --------------------------------------------------------------------------- */
void BusFault_Handler(void)
{
    uint32_t addr = SCB_BFAR;
    fault_log(FAULT_BUS, addr);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * UsageFault_Handler
 * --------------------------------------------------------------------------- */
void UsageFault_Handler(void)
{
    fault_log(FAULT_USAGE, 0u);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * SecureFault_Handler
 * --------------------------------------------------------------------------- */
void SecureFault_Handler(void)
{
    fault_log(FAULT_SECURE, 0u);

    while (1u)
    {
        __asm__("wfi" ::: "memory");
    }
}

/* ---------------------------------------------------------------------------
 * Fault_GetCount
 * --------------------------------------------------------------------------- */
uint32_t Fault_GetCount(void)
{
    return g_fault_count;
}

/* ---------------------------------------------------------------------------
 * Fault_GetLog — copy fault records into user buffer
 * --------------------------------------------------------------------------- */
uint32_t Fault_GetLog(fault_record_t *buf, uint32_t max)
{
    uint32_t count = (max < g_fault_count) ? max : g_fault_count;

    for (uint32_t i = 0u; i < count; i++)
    {
        buf[i] = g_fault_log[i];
    }

    return count;
}