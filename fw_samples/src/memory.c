/**
 * memory.c — Memory Pool Manager
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>
#include <stdbool.h>

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */
#define MPU_RNR  (*(volatile uint32_t *)0xE000ED98UL)
#define MPU_RBAR (*(volatile uint32_t *)0xE000ED9CUL)
#define MPU_RASR (*(volatile uint32_t *)0xE000EDA0UL)

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef struct boundary_tag
{
    uint32_t            magic;   /* must be 0xA5A5A5A5 */
    uint32_t            size;
    bool                free;
    struct boundary_tag *next;
} boundary_tag_t;

typedef struct
{
    void   *pool_base;
    uint32_t pool_size;
    uint32_t block_size;
    uint32_t alloc_count;
    uint32_t free_count;
} mem_pool_t;

typedef struct
{
    uint32_t total_allocated;
    uint32_t peak_allocated;
    uint32_t alloc_count;
} heap_usage_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static uint8_t     g_memory_pool[8192];
static mem_pool_t  g_mem_pool;
static bool        g_mem_initialized  = false;
static heap_usage_t g_heap_usage      = { 0u, 0u, 0u };

/* ---------------------------------------------------------------------------
 * MEM_Init — initialise the memory pool
 * --------------------------------------------------------------------------- */
void MEM_Init(void)
{
    if (g_mem_initialized)
    {
        return;
    }

    /* Setup pool descriptor */
    g_mem_pool.pool_base   = (void *)g_memory_pool;
    g_mem_pool.pool_size   = sizeof(g_memory_pool);
    g_mem_pool.block_size  = 16u;   /* minimum alignment / block size */
    g_mem_pool.alloc_count = 0u;
    g_mem_pool.free_count  = 1u;

    /* Initialise the first (and only) free block as a boundary tag */
    boundary_tag_t *tag = (boundary_tag_t *)g_memory_pool;
    tag->magic = 0xA5A5A5A5UL;
    tag->size  = sizeof(g_memory_pool) - sizeof(boundary_tag_t);
    tag->free  = true;
    tag->next  = (boundary_tag_t *)0;

    g_heap_usage.total_allocated = 0u;
    g_heap_usage.peak_allocated  = 0u;
    g_heap_usage.alloc_count     = 0u;

    g_mem_initialized = true;
}

/* ---------------------------------------------------------------------------
 * MEM_Alloc — allocate a block from the pool (first-fit)
 * --------------------------------------------------------------------------- */
void *MEM_Alloc(uint32_t size)
{
    if (!g_mem_initialized || size == 0u)
    {
        return (void *)0;
    }

    /* Align size to 8 bytes */
    size = (size + 7u) & ~7u;

    boundary_tag_t *curr = (boundary_tag_t *)g_mem_pool.pool_base;

    while (curr != (boundary_tag_t *)0)
    {
        if (curr->free && (curr->size >= size))
        {
            /* Split if remaining space is large enough for another tag + minimal block */
            uint32_t remaining = curr->size - size;
            if (remaining > sizeof(boundary_tag_t) + 16u)
            {
                boundary_tag_t *new_tag =
                    (boundary_tag_t *)((uint8_t *)(curr + 1) + size);
                new_tag->magic = 0xA5A5A5A5UL;
                new_tag->size  = remaining - sizeof(boundary_tag_t);
                new_tag->free  = true;
                new_tag->next  = curr->next;

                curr->size = size;
                curr->next = new_tag;
            }

            curr->free = false;
            g_mem_pool.alloc_count++;
            g_mem_pool.free_count--;

            g_heap_usage.total_allocated += size;
            g_heap_usage.alloc_count++;
            if (g_heap_usage.total_allocated > g_heap_usage.peak_allocated)
            {
                g_heap_usage.peak_allocated = g_heap_usage.total_allocated;
            }

            return (void *)(curr + 1);
        }
        curr = curr->next;
    }

    /* No suitable block found */
    return (void *)0;
}

/* ---------------------------------------------------------------------------
 * MEM_Free — return a block to the pool
 * --------------------------------------------------------------------------- */
void MEM_Free(void *ptr)
{
    if (ptr == (void *)0 || !g_mem_initialized)
    {
        return;
    }

    boundary_tag_t *tag = (boundary_tag_t *)((uint8_t *)ptr - sizeof(boundary_tag_t));

    if (tag->magic != 0xA5A5A5A5UL)
    {
        /* Corrupted boundary tag — silently ignore */
        return;
    }

    tag->free = true;
    g_mem_pool.alloc_count--;
    g_mem_pool.free_count++;

    g_heap_usage.total_allocated -= tag->size;

    /* Coalesce with next free block */
    if (tag->next != (boundary_tag_t *)0 && tag->next->free)
    {
        tag->size += sizeof(boundary_tag_t) + tag->next->size;
        tag->next   = tag->next->next;
        g_mem_pool.free_count--;
    }

    /* Coalesce with previous free block (linear search) */
    boundary_tag_t *prev = (boundary_tag_t *)g_mem_pool.pool_base;
    while (prev != (boundary_tag_t *)0 && prev->next != tag)
    {
        prev = prev->next;
    }

    if (prev != (boundary_tag_t *)0 && prev->free)
    {
        prev->size += sizeof(boundary_tag_t) + tag->size;
        prev->next   = tag->next;
        g_mem_pool.free_count--;
    }
}

/* ---------------------------------------------------------------------------
 * MEM_GetFreeSize — total free bytes available
 * --------------------------------------------------------------------------- */
uint32_t MEM_GetFreeSize(void)
{
    uint32_t free_size = 0u;
    boundary_tag_t *curr = (boundary_tag_t *)g_mem_pool.pool_base;

    while (curr != (boundary_tag_t *)0)
    {
        if (curr->free)
        {
            free_size += curr->size;
        }
        curr = curr->next;
    }

    return free_size;
}

/* ---------------------------------------------------------------------------
 * MEM_GetAllocSize — total allocated bytes
 * --------------------------------------------------------------------------- */
uint32_t MEM_GetAllocSize(void)
{
    return g_heap_usage.total_allocated;
}

/* ---------------------------------------------------------------------------
 * MEM_ProtectRegion — configure MPU for a memory region
 * --------------------------------------------------------------------------- */
void MEM_ProtectRegion(uint32_t region, uint32_t base, uint32_t size, uint32_t attrs)
{
    MPU_RNR  = region;
    MPU_RBAR = base | (1u << 4);  /* VALID bit set */
    MPU_RASR = (attrs & 0x00FFFFFFUL) | (1u << 0);  /* ENABLE */

    __asm__("dsb sy" ::: "memory");
    __asm__("isb sy" ::: "memory");
}