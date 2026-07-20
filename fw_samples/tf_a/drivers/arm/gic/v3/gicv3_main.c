/*
 * Copyright (c) 2015-2026, Arm Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * ARM GICv3/3.1 driver — shortened version for sw_model MVP verification.
 * Full source at: https://github.com/ARM-software/arm-trusted-firmware
 *   drivers/arm/gic/v3/gicv3_main.c
 */
#include <assert.h>
#include <drivers/arm/gicv3.h>
#include <drivers/arm/gic_common.h>
#include "gicv3_private.h"

const gicv3_driver_data_t *gicv3_driver_data;
static spinlock_t gic_lock;

#pragma weak gicv3_rdistif_off
#pragma weak gicv3_rdistif_on

/*******************************************************************************
 * This function initialises the ARM GICv3 driver in EL3 with provided platform
 * inputs.
 ******************************************************************************/
void __init gicv3_driver_init(const gicv3_driver_data_t *plat_driver_data)
{
    unsigned int gic_version;
    unsigned int gicv2_compat;

    assert(plat_driver_data != NULL);
    assert(plat_driver_data->gicd_base != 0U);
    assert(plat_driver_data->rdistif_num != 0U);
    assert(plat_driver_data->rdistif_base_addrs != NULL);
    assert(IS_IN_EL3());

    gic_version = gicd_read_pidr2(plat_driver_data->gicd_base);
    gic_version >>= PIDR2_ARCH_REV_SHIFT;
    gic_version &= PIDR2_ARCH_REV_MASK;

#if !GIC_ENABLE_V4_EXTN
    assert(gic_version == ARCH_REV_GICV3);
#endif

    /* Check GICv2 compatibility — ARE_S bit resets to 0 if supported */
    gicv2_compat = gicd_read_ctlr(plat_driver_data->gicd_base);
    gicv2_compat >>= CTLR_ARE_S_SHIFT;
    gicv2_compat = gicv2_compat & CTLR_ARE_S_MASK;

    if (plat_driver_data->gicr_base != 0U) {
        gicv3_rdistif_base_addrs_probe(
            plat_driver_data->rdistif_base_addrs,
            plat_driver_data->rdistif_num,
            plat_driver_data->gicr_base,
            plat_driver_data->mpidr_to_core_pos);
    }

    gicv3_driver_data = plat_driver_data;
    gicv3_check_erratas_applies(plat_driver_data->gicd_base);

    INFO("GICv%u with%s legacy support detected.\n", gic_version,
         (gicv2_compat == 0U) ? "" : "out");
    INFO("ARM GICv%u driver initialized in EL3\n", gic_version);
}

/*******************************************************************************
 * This function initialises the GIC distributor interface.
 * GICD_CTLR is the central configuration register — this function
 * demonstrates the key programming sequence that sw_model must audit.
 ******************************************************************************/
void __init gicv3_distif_init(void)
{
    unsigned int bitmap;

    assert(gicv3_driver_data != NULL);
    assert(gicv3_driver_data->gicd_base != 0U);
    assert(IS_IN_EL3());

    /*
     * Step 1: Clear ALL group enable bits before configuring ARE_S.
     * Required by GIC spec: writing ARE bits while any group is enabled
     * may cause system error (GICD_CTLR.RWP polling ensures completion).
     */
    gicd_clr_ctlr(gicv3_driver_data->gicd_base,
                  CTLR_ENABLE_G0_BIT |
                  CTLR_ENABLE_G1S_BIT |
                  CTLR_ENABLE_G1NS_BIT,
                  RWP_TRUE);

    /*
     * Step 2: Set ARE_S and ARE_NS bits.
     * These enable GICv3 affinity routing mode for Secure and Non-Secure.
     * Must be done with all groups disabled (per spec).
     */
    gicd_set_ctlr(gicv3_driver_data->gicd_base,
                  CTLR_ARE_S_BIT | CTLR_ARE_NS_BIT, RWP_TRUE);

    /* Step 3: Configure default SPI attributes */
    gicv3_spis_config_defaults(gicv3_driver_data->gicd_base);

    /* Step 4: Configure secure SPIs and re-enable groups */
    bitmap = gicv3_secure_spis_config_props(
                gicv3_driver_data->gicd_base,
                gicv3_driver_data->interrupt_props,
                gicv3_driver_data->interrupt_props_num);

    gicd_set_ctlr(gicv3_driver_data->gicd_base, bitmap, RWP_TRUE);
}

/*******************************************************************************
 * This function initialises the GIC Redistributor interface (per-core).
 ******************************************************************************/
void gicv3_rdistif_init(unsigned int proc_num)
{
    uintptr_t gicr_base;
    unsigned int bitmap;
    uint32_t ctlr;

    assert(gicv3_driver_data != NULL);
    assert(proc_num < gicv3_driver_data->rdistif_num);
    assert(gicv3_driver_data->rdistif_base_addrs != NULL);
    assert(gicv3_driver_data->gicd_base != 0U);

    ctlr = gicd_read_ctlr(gicv3_driver_data->gicd_base);
    assert((ctlr & CTLR_ARE_S_BIT) != 0U);
    assert(IS_IN_EL3());

    gicv3_rdistif_on(proc_num);
    gicr_base = gicv3_driver_data->rdistif_base_addrs[proc_num];
    assert(gicr_base != 0U);

    gicv3_ppi_sgi_config_defaults(gicr_base);
    bitmap = gicv3_secure_ppi_sgi_config_props(
                gicr_base,
                gicv3_driver_data->interrupt_props,
                gicv3_driver_data->interrupt_props_num);

    if ((ctlr & bitmap) != bitmap) {
        gicd_set_ctlr(gicv3_driver_data->gicd_base, bitmap, RWP_TRUE);
    }
}

void gicv3_rdistif_off(unsigned int proc_num) { }
void gicv3_rdistif_on(unsigned int proc_num) { }

/*******************************************************************************
 * GICD_CTLR register accessor functions
 * These are the functions that sw_model stage4/5 must analyze.
 ******************************************************************************/
static inline uint32_t gicd_read_ctlr(uintptr_t base)
{
    return mmio_read_32(base + GICD_CTLR);
}

static inline void gicd_write_ctlr(uintptr_t base, uint32_t val)
{
    mmio_write_32(base + GICD_CTLR, val);
}

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
    if (rwp != 0U) {
        gicd_wait_for_pending_write(base);
    }
}

void gicd_wait_for_pending_write(uintptr_t gicd_base)
{
    while ((gicd_read_ctlr(gicd_base) & GICD_CTLR_RWP_BIT) != 0U) { }
}
