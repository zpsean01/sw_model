#ifndef GICV3_PRIVATE_H
#define GICV3_PRIVATE_H

#include <stdint.h>
#include <drivers/arm/gicv3.h>
#include <drivers/arm/gic_common.h>

#define RWP_TRUE  1
#define RWP_FALSE 0

#define GICD_OFFSET(REG, id)  (GICD_##REG##R + (((uintptr_t)(id) >> REG##R_SHIFT) << 2))
#define GICD_READ(REG, base, id)   (0)
#define GICD_WRITE(REG, base, id, v) ((void)0)

#define MIN_ESPI_ID 4096
#define round_up(x, y) (((x) + (y) - 1) & ~((y) - 1))

static inline uint32_t gicd_read_ctlr(uintptr_t base)
{
    extern uint32_t mmio_read_32(uintptr_t);
    return mmio_read_32(base + GICD_CTLR);
}

static inline void gicd_write_ctlr(uintptr_t base, uint32_t val)
{
    extern void mmio_write_32(uintptr_t, uint32_t);
    mmio_write_32(base + GICD_CTLR, val);
}

static inline uint32_t gicd_read_pidr2(uintptr_t base)
{
    return 0;
}

static inline uint32_t gicr_read_waker(uintptr_t base) { return 0; }
static inline void gicr_write_waker(uintptr_t base, uint32_t val) { }
static inline void gicr_write_igroupr(uintptr_t base, unsigned int id, uint32_t v) { }
static inline uint32_t gicr_read_igroupr(uintptr_t base, unsigned int id) { return 0; }
static inline uint32_t gicd_read_igroupr(uintptr_t base, unsigned int id) { return 0; }
static inline uint32_t gicr_read_igrpmodr(uintptr_t base, unsigned int id) { return 0; }
static inline uint32_t gicd_read_igrpmodr(uintptr_t base, unsigned int id) { return 0; }
static inline uint32_t gicd_get_igroupr(uintptr_t base, unsigned int id) { return 0; }
static inline uint32_t gicr_get_igroupr(uintptr_t base, unsigned int id) { return 0; }
static inline uint32_t gicd_get_igrpmodr(uintptr_t base, unsigned int id) { return 0; }
static inline uint32_t gicr_get_igrpmodr(uintptr_t base, unsigned int id) { return 0; }

void gicd_clr_ctlr(uintptr_t base, unsigned int bitmap, unsigned int rwp);
void gicd_set_ctlr(uintptr_t base, unsigned int bitmap, unsigned int rwp);
void gicd_wait_for_pending_write(uintptr_t gicd_base);

#endif
