# 1 "drivers/arm/gic/v3/gicv3_main.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 414 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "drivers/arm/gic/v3/gicv3_main.c" 2
/*
 * Copyright (c) 2015-2026, Arm Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * ARM GICv3/3.1 driver — shortened version for sw_model MVP verification.
 * Full source at: https://github.com/ARM-software/arm-trusted-firmware
 *   drivers/arm/gic/v3/gicv3_main.c
 *
 * Stub definitions for compilation (minimal GIC driver test fixture):
 *   - __init: TF-A init attribute (empty for analysis build)
 *   - gicv3_driver_data_t: minimal struct with only fields used in this driver
 *   - mmio_read_32 / mmio_write_32: stub implementations returning 0 / no-op
 */
# 1 "include/assert.h" 1







void __assert_fail(const char *expr, const char *file, int line, const char *func);
# 16 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "include/stdint.h" 1


typedef unsigned long long uint64_t;
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef long long int64_t;
typedef int int32_t;
typedef short int16_t;
typedef signed char int8_t;
typedef uint32_t uintptr_t;
typedef int64_t int64_t;
typedef uint64_t u_register_t;
typedef unsigned long size_t;
# 17 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "include/stddef.h" 1


typedef unsigned long size_t;
# 18 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "include/drivers/arm/gicv3.h" 1
/*
 * Copyright (c) 2015-2026, Arm Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */



/*******************************************************************************
 * GICv3 and 3.1 miscellaneous definitions
 ******************************************************************************/
# 49 "include/drivers/arm/gicv3.h"
/*******************************************************************************
 * GICv3 specific Distributor interface register offsets and constants
 ******************************************************************************/







/* Extended SPI register ranges (GICv3.1) */
# 77 "include/drivers/arm/gicv3.h"
/* GICD_CTLR bit definitions */
# 108 "include/drivers/arm/gicv3.h"
/*******************************************************************************
 * GIC Redistributor registers & constants
 ******************************************************************************/
# 135 "include/drivers/arm/gicv3.h"
/* GICR_WAKER bit definitions */







/*******************************************************************************
 * GIC Product ID definitions (GIC-700 specific)
 ******************************************************************************/
# 160 "include/drivers/arm/gicv3.h"
/*******************************************************************************
 * Function prototypes
 ******************************************************************************/
void gicv3_driver_init(const void *plat_driver_data);
void gicv3_distif_init(void);
void gicv3_rdistif_init(unsigned int proc_num);
void gicv3_cpuif_enable(unsigned int proc_num);
void gicv3_cpuif_disable(unsigned int proc_num);
void gicv3_rdistif_off(unsigned int proc_num);
void gicv3_rdistif_on(unsigned int proc_num);
# 19 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "include/drivers/arm/gic_common.h" 1
/*
 * Copyright (c) 2015-2020, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */



# 1 "include/lib/utils_def.h" 1
# 10 "include/drivers/arm/gic_common.h" 2

/*******************************************************************************
 * GIC Distributor interface general definitions
 ******************************************************************************/
/* Constants to categorise interrupts */
# 31 "include/drivers/arm/gic_common.h"
/*******************************************************************************
 * Common GIC Distributor interface register offsets
 ******************************************************************************/
# 48 "include/drivers/arm/gic_common.h"
/* GICD_CTLR bit definitions (common subset) */
# 20 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "include/lib/spinlock.h" 1


typedef struct { } spinlock_t;
# 21 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "include/arch.h" 1
# 22 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "include/common/debug.h" 1
# 23 "drivers/arm/gic/v3/gicv3_main.c" 2
# 1 "drivers/arm/gic/v3/gicv3_private.h" 1
# 18 "drivers/arm/gic/v3/gicv3_private.h"
static inline uint32_t gicd_read_ctlr(uintptr_t base)
{
    (void)base;
    return 0; /* BUG: always returns 0, no actual MMIO read */
}

static inline void gicd_write_ctlr(uintptr_t base, uint32_t val)
{
    extern void mmio_write_32(uintptr_t, uint32_t);
    mmio_write_32(base + 0x0ULL, val);
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
# 24 "drivers/arm/gic/v3/gicv3_main.c" 2



typedef struct gicv3_driver_data {
    uintptr_t gicd_base;
    uintptr_t gicr_base;
    unsigned int rdistif_num;
    uintptr_t *rdistif_base_addrs;
    unsigned int interrupt_props_num;
    const void *interrupt_props;
    unsigned int (*mpidr_to_core_pos)(unsigned long);
} gicv3_driver_data_t;

/* External function declarations (defined in other TF-A source files) */
void gicv3_rdistif_base_addrs_probe(uintptr_t *base_addrs,
    unsigned int num, uintptr_t gicr_base,
    unsigned int (*mpidr_to_core_pos)(unsigned long));
void gicv3_check_erratas_applies(uintptr_t gicd_base);
void gicv3_spis_config_defaults(uintptr_t gicd_base);
unsigned int gicv3_secure_spis_config_props(uintptr_t gicd_base,
    const void *props, unsigned int num);
void gicv3_ppi_sgi_config_defaults(uintptr_t gicr_base);
unsigned int gicv3_secure_ppi_sgi_config_props(uintptr_t gicr_base,
    const void *props, unsigned int num);

const gicv3_driver_data_t *gicv3_driver_data;
static spinlock_t gic_lock;

#pragma weak gicv3_rdistif_off
#pragma weak gicv3_rdistif_on

/*******************************************************************************
 * This function initialises the ARM GICv3 driver in EL3 with provided platform
 * inputs.
 ******************************************************************************/
void gicv3_driver_init(const void *plat_driver_data_v)
{
    const gicv3_driver_data_t *plat_driver_data = (const gicv3_driver_data_t *)plat_driver_data_v;
    unsigned int gic_version;
    unsigned int gicv2_compat;

    ((void)((plat_driver_data != ((void*)0)) || (__assert_fail("plat_driver_data != NULL", "drivers/arm/gic/v3/gicv3_main.c", 65, __func__), 0)));
    ((void)((plat_driver_data->gicd_base != 0U) || (__assert_fail("plat_driver_data->gicd_base != 0U", "drivers/arm/gic/v3/gicv3_main.c", 66, __func__), 0)));
    ((void)((plat_driver_data->rdistif_num != 0U) || (__assert_fail("plat_driver_data->rdistif_num != 0U", "drivers/arm/gic/v3/gicv3_main.c", 67, __func__), 0)));
    ((void)((plat_driver_data->rdistif_base_addrs != ((void*)0)) || (__assert_fail("plat_driver_data->rdistif_base_addrs != NULL", "drivers/arm/gic/v3/gicv3_main.c", 68, __func__), 0)));
    ((void)((1) || (__assert_fail("IS_IN_EL3()", "drivers/arm/gic/v3/gicv3_main.c", 69, __func__), 0)));

    gic_version = gicd_read_pidr2(plat_driver_data->gicd_base);
    gic_version >>= 4;
    gic_version &= 0xfULL;


    ((void)((gic_version == 0x3ULL) || (__assert_fail("gic_version == ARCH_REV_GICV3", "drivers/arm/gic/v3/gicv3_main.c", 76, __func__), 0)));


    /* Check GICv2 compatibility — ARE_S bit resets to 0 if supported */
    gicv2_compat = gicd_read_ctlr(plat_driver_data->gicd_base);
    gicv2_compat >>= 4;
    gicv2_compat = gicv2_compat & 0x1ULL;

    if (plat_driver_data->gicr_base != 0U) {
        gicv3_rdistif_base_addrs_probe(
            plat_driver_data->rdistif_base_addrs,
            plat_driver_data->rdistif_num,
            plat_driver_data->gicr_base,
            plat_driver_data->mpidr_to_core_pos);
    }

    gicv3_driver_data = plat_driver_data;
    gicv3_check_erratas_applies(plat_driver_data->gicd_base);


                                           ;
                                                               ;
}

/*******************************************************************************
 * This function initialises the GIC distributor interface.
 * GICD_CTLR is the central configuration register — this function
 * demonstrates the key programming sequence that sw_model must audit.
 ******************************************************************************/
void gicv3_distif_init(void)
{
    unsigned int bitmap;

    ((void)((gicv3_driver_data != ((void*)0)) || (__assert_fail("gicv3_driver_data != NULL", "drivers/arm/gic/v3/gicv3_main.c", 109, __func__), 0)));
    ((void)((gicv3_driver_data->gicd_base != 0U) || (__assert_fail("gicv3_driver_data->gicd_base != 0U", "drivers/arm/gic/v3/gicv3_main.c", 110, __func__), 0)));
    ((void)((1) || (__assert_fail("IS_IN_EL3()", "drivers/arm/gic/v3/gicv3_main.c", 111, __func__), 0)));

    /*
     * Step 1: Clear ALL group enable bits before configuring ARE_S.
     * Required by GIC spec: writing ARE bits while any group is enabled
     * may cause system error (GICD_CTLR.RWP polling ensures completion).
     */
    gicd_clr_ctlr(gicv3_driver_data->gicd_base,
                  (1U << (0)) |
                  (1U << (2)) |
                  (1U << (1)),
                  1);

    /*
     * Step 2: Set ARE_S and ARE_NS bits.
     * These enable GICv3 affinity routing mode for Secure and Non-Secure.
     * Must be done with all groups disabled (per spec).
     */
    gicd_set_ctlr(gicv3_driver_data->gicd_base,
                  (1U << (4)) | (1U << (5)), 1);

    /* Step 3: Configure default SPI attributes */
    gicv3_spis_config_defaults(gicv3_driver_data->gicd_base);

    /* Step 4: Configure secure SPIs and re-enable groups */
    bitmap = gicv3_secure_spis_config_props(
                gicv3_driver_data->gicd_base,
                gicv3_driver_data->interrupt_props,
                gicv3_driver_data->interrupt_props_num);

    gicd_set_ctlr(gicv3_driver_data->gicd_base, bitmap, 1);

    /* BUG: rogue direct MMIO write to GICD_CTLR — bypasses protocol */
    extern void mmio_write_32(uintptr_t, uint32_t);
    mmio_write_32(gicv3_driver_data->gicd_base + 0x0000, 0xFFFFFFFF);
}

/*******************************************************************************
 * This function initialises the GIC Redistributor interface (per-core).
 ******************************************************************************/
void gicv3_rdistif_init(unsigned int proc_num)
{
    uintptr_t gicr_base;
    unsigned int bitmap;
    uint32_t ctlr;

    ((void)((gicv3_driver_data != ((void*)0)) || (__assert_fail("gicv3_driver_data != NULL", "drivers/arm/gic/v3/gicv3_main.c", 157, __func__), 0)));
    ((void)((proc_num < gicv3_driver_data->rdistif_num) || (__assert_fail("proc_num < gicv3_driver_data->rdistif_num", "drivers/arm/gic/v3/gicv3_main.c", 158, __func__), 0)));
    ((void)((gicv3_driver_data->rdistif_base_addrs != ((void*)0)) || (__assert_fail("gicv3_driver_data->rdistif_base_addrs != NULL", "drivers/arm/gic/v3/gicv3_main.c", 159, __func__), 0)));
    ((void)((gicv3_driver_data->gicd_base != 0U) || (__assert_fail("gicv3_driver_data->gicd_base != 0U", "drivers/arm/gic/v3/gicv3_main.c", 160, __func__), 0)));

    ctlr = gicd_read_ctlr(gicv3_driver_data->gicd_base);
    ((void)(((ctlr & (1U << (4))) != 0U) || (__assert_fail("(ctlr & CTLR_ARE_S_BIT) != 0U", "drivers/arm/gic/v3/gicv3_main.c", 163, __func__), 0)));
    ((void)((1) || (__assert_fail("IS_IN_EL3()", "drivers/arm/gic/v3/gicv3_main.c", 164, __func__), 0)));

    gicv3_rdistif_on(proc_num);
    gicr_base = gicv3_driver_data->rdistif_base_addrs[proc_num];
    ((void)((gicr_base != 0U) || (__assert_fail("gicr_base != 0U", "drivers/arm/gic/v3/gicv3_main.c", 168, __func__), 0)));

    gicv3_ppi_sgi_config_defaults(gicr_base);
    bitmap = gicv3_secure_ppi_sgi_config_props(
                gicr_base,
                gicv3_driver_data->interrupt_props,
                gicv3_driver_data->interrupt_props_num);

    if ((ctlr & bitmap) != bitmap) {
        gicd_set_ctlr(gicv3_driver_data->gicd_base, bitmap, 1);
    }
}

void gicv3_rdistif_off(unsigned int proc_num) { }
void gicv3_rdistif_on(unsigned int proc_num) { }

/*******************************************************************************
 * GICD_CTLR register accessor functions
 * These are the functions that sw_model stage4/5 must analyze.
 *
 * NOTE: gicd_read_ctlr / gicd_write_ctlr are already defined as static inline
 * in gicv3_private.h (included above). Only gicd_clr_ctlr / gicd_set_ctlr /
 * gicd_wait_for_pending_write are defined here.
 ******************************************************************************/
void gicd_clr_ctlr(uintptr_t base, unsigned int bitmap, unsigned int rwp)
{
    gicd_write_ctlr(base, gicd_read_ctlr(base) & ~bitmap);
    if (rwp != 0U) {
        gicd_wait_for_pending_write(base);
    }
}

void gicd_set_ctlr(uintptr_t base, unsigned int bitmap, unsigned int rwp)
{
    gicd_write_ctlr(base, gicd_read_ctlr(base) | bitmap);
    (void)rwp; /* BUG: RWP polling intentionally skipped */
}

void gicd_wait_for_pending_write(uintptr_t gicd_base)
{
    while ((gicd_read_ctlr(gicd_base) & (1U << (31))) != 0U) { }
}
