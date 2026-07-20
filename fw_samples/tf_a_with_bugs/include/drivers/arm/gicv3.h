/*
 * Copyright (c) 2015-2026, Arm Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */
#ifndef GICV3_H
#define GICV3_H

/*******************************************************************************
 * GICv3 and 3.1 miscellaneous definitions
 ******************************************************************************/
#define INTR_GROUP1S		U(0)
#define INTR_GROUP0		U(1)
#define INTR_GROUP1NS		U(2)

#define PENDING_G1S_INTID	U(1020)
#define PENDING_G1NS_INTID	U(1021)
#define MIN_LPI_ID		U(8192)
#define GICV3_MAX_SGI_TARGETS	U(16)
#define MAX_PPI_ID		U(31)

#define MIN_SPI_ID		U(32)
#define MAX_SPI_ID		U(1019)
#define TOTAL_SPI_INTR_NUM	(MAX_SPI_ID - MIN_SPI_ID + U(1))
#define TOTAL_PCPU_INTR_NUM	(MIN_SPI_ID - MIN_SGI_ID)

#if GIC_EXT_INTID
#define MIN_EPPI_ID		U(1056)
#define MAX_EPPI_ID		U(1119)
#define TOTAL_EPPI_INTR_NUM	(MAX_EPPI_ID - MIN_EPPI_ID + U(1))
#define TOTAL_PRIVATE_INTR_NUM	(TOTAL_PCPU_INTR_NUM + TOTAL_EPPI_INTR_NUM)
#define MIN_ESPI_ID		U(4096)
#define MAX_ESPI_ID		U(5119)
#define TOTAL_ESPI_INTR_NUM	(MAX_ESPI_ID - MIN_ESPI_ID + U(1))
#define	TOTAL_SHARED_INTR_NUM	(TOTAL_SPI_INTR_NUM + TOTAL_ESPI_INTR_NUM)
#define	IS_SGI_PPI(id)		(((id) <= MAX_PPI_ID) || \
				(((id) >= MIN_EPPI_ID) && ((id) <= MAX_EPPI_ID)))
#define	IS_SPI(id)		((((id) >= MIN_SPI_ID) && ((id) <= MAX_SPI_ID)) || \
				 (((id) >= MIN_ESPI_ID) && ((id) <= MAX_ESPI_ID)))
#else
#define TOTAL_PRIVATE_INTR_NUM	TOTAL_PCPU_INTR_NUM
#define	TOTAL_SHARED_INTR_NUM	TOTAL_SPI_INTR_NUM
#define	IS_SGI_PPI(id)		((id) <= MAX_PPI_ID)
#define	IS_SPI(id)		(((id) >= MIN_SPI_ID) && ((id) <= MAX_SPI_ID))
#endif

#define GIC_REV(r, p)           ((r << 4) | p)

/*******************************************************************************
 * GICv3 specific Distributor interface register offsets and constants
 ******************************************************************************/
#define GICD_TYPER2		U(0x0c)
#define GICD_STATUSR		U(0x10)
#define GICD_SETSPI_NSR		U(0x40)
#define GICD_CLRSPI_NSR		U(0x48)
#define GICD_SETSPI_SR		U(0x50)
#define GICD_CLRSPI_SR		U(0x58)
#define GICD_IGRPMODR		U(0xd00)
/* Extended SPI register ranges (GICv3.1) */
#define GICD_IGROUPRE		U(0x1000)
#define GICD_ISENABLERE		U(0x1200)
#define GICD_ICENABLERE		U(0x1400)
#define GICD_ISPENDRE		U(0x1600)
#define GICD_ICPENDRE		U(0x1800)
#define GICD_ISACTIVERE		U(0x1a00)
#define GICD_ICACTIVERE		U(0x1c00)
#define GICD_IPRIORITYRE	U(0x2000)
#define GICD_ICFGRE		U(0x3000)
#define GICD_IGRPMODRE		U(0x3400)
#define GICD_NSACRE		U(0x3600)
#define GICD_IROUTER		U(0x6000)
#define GICD_IROUTERE		U(0x8000)
#define GICD_PIDR0_GICV3	U(0xffe0)
#define GICD_PIDR1_GICV3	U(0xffe4)
#define GICD_PIDR2_GICV3	U(0xffe8)

/* GICD_CTLR bit definitions */
#define CTLR_ENABLE_G1NS_SHIFT		1
#define CTLR_ENABLE_G1S_SHIFT		2
#define CTLR_ARE_S_SHIFT		4
#define CTLR_ARE_NS_SHIFT		5
#define CTLR_DS_SHIFT			6
#define CTLR_E1NWF_SHIFT		7
#define GICD_CTLR_RWP_SHIFT		31

#define CTLR_ENABLE_G1NS_MASK		U(0x1)
#define CTLR_ENABLE_G1S_MASK		U(0x1)
#define CTLR_ARE_S_MASK			U(0x1)
#define CTLR_ARE_NS_MASK		U(0x1)
#define CTLR_DS_MASK			U(0x1)
#define CTLR_E1NWF_MASK			U(0x1)
#define GICD_CTLR_RWP_MASK		U(0x1)

#define CTLR_ENABLE_G0_BIT		BIT_32(0)
#define CTLR_ENABLE_G1NS_BIT		BIT_32(CTLR_ENABLE_G1NS_SHIFT)
#define CTLR_ENABLE_G1S_BIT		BIT_32(CTLR_ENABLE_G1S_SHIFT)
#define CTLR_ARE_S_BIT			BIT_32(CTLR_ARE_S_SHIFT)
#define CTLR_ARE_NS_BIT			BIT_32(CTLR_ARE_NS_SHIFT)
#define CTLR_DS_BIT			BIT_32(CTLR_DS_SHIFT)
#define CTLR_E1NWF_BIT			BIT_32(CTLR_E1NWF_SHIFT)
#define GICD_CTLR_RWP_BIT		BIT_32(GICD_CTLR_RWP_SHIFT)

#define IROUTER_IRM_SHIFT	31
#define IROUTER_IRM_MASK	U(0x1)
#define GICV3_IRM_PE		U(0)
#define GICV3_IRM_ANY		U(1)

/*******************************************************************************
 * GIC Redistributor registers & constants
 ******************************************************************************/
#define GICR_V4_PCPUBASE_SHIFT	0x12
#define GICR_V3_PCPUBASE_SHIFT	0x11
#define GICR_SGIBASE_OFFSET	U(65536)

#define GICR_CTLR		U(0x0)
#define GICR_IIDR		U(0x04)
#define GICR_TYPER		U(0x08)
#define GICR_STATUSR		U(0x10)
#define GICR_WAKER		U(0x14)
#define GICR_PROPBASER		U(0x70)
#define GICR_PENDBASER		U(0x78)
#define GICR_IGROUPR0		(GICR_SGIBASE_OFFSET + U(0x80))
#define GICR_ISENABLER0		(GICR_SGIBASE_OFFSET + U(0x100))
#define GICR_ICENABLER0		(GICR_SGIBASE_OFFSET + U(0x180))
#define GICR_ISPENDR0		(GICR_SGIBASE_OFFSET + U(0x200))
#define GICR_ICPENDR0		(GICR_SGIBASE_OFFSET + U(0x280))
#define GICR_ISACTIVER0		(GICR_SGIBASE_OFFSET + U(0x300))
#define GICR_ICACTIVER0		(GICR_SGIBASE_OFFSET + U(0x380))
#define GICR_IPRIORITYR		(GICR_SGIBASE_OFFSET + U(0x400))
#define GICR_ICFGR0		(GICR_SGIBASE_OFFSET + U(0xc00))
#define GICR_ICFGR1		(GICR_SGIBASE_OFFSET + U(0xc04))
#define GICR_IGRPMODR0		(GICR_SGIBASE_OFFSET + U(0xd00))
#define GICR_NSACR		(GICR_SGIBASE_OFFSET + U(0xe00))

/* GICR_WAKER bit definitions */
#define WAKER_CA_SHIFT		2
#define WAKER_PS_SHIFT		1
#define WAKER_CA_MASK		U(0x1)
#define WAKER_PS_MASK		U(0x1)
#define WAKER_CA_BIT		BIT_32(WAKER_CA_SHIFT)
#define WAKER_PS_BIT		BIT_32(WAKER_PS_SHIFT)

/*******************************************************************************
 * GIC Product ID definitions (GIC-700 specific)
 ******************************************************************************/
#define GIC_PRODUCT_ID_GIC600	U(0x2)
#define GIC_PRODUCT_ID_GIC600AE	U(0x3)
#define GIC_PRODUCT_ID_GIC700	U(0x4)

#define GIC_REV_P0		U(0x1)
#define GIC_REV_P1		U(0x3)
#define GIC_REV_P2		U(0x4)
#define GIC_REV_P3		U(0x5)
#define GIC_REV_P4		U(0x6)
#define GIC_REV_P6		U(0x7)
#define GIC_VARIANT_R0		U(0x0)
#define GIC_VARIANT_R1		U(0x1)
#define GIC_VARIANT_R2		U(0x2)

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

#endif /* GICV3_H */
