/**
 * ddr5_regs.h — DDR5 Mode Register (MR) definitions
 *
 * Maps JEDEC JESD79-5C §3.4 Mode Register Set.
 * Each MR is accessible via MRW (Mode Register Write) and MRR (Mode Register Read).
 * Reference: spec_model ddr5 extract → object_entities → register
 */

#ifndef DDR5_REGS_H
#define DDR5_REGS_H

#include <stdint.h>

/* ── MR address space: MR0–MR254 ────────────────────────────────────────── */

/* MR0: Burst Length, Read/Write Length, DLL Control (JESD79-5C §3.4.1) */
#define DDR5_MR0        0x00U
#define DDR5_MR0_BL(x)          (((uint8_t)(x) & 0x07U) << 0)   /* Burst Length: 0=BL16, 1=BL32, 2=BL64 */
#define DDR5_MR0_DLL_EN         (1U << 3)                        /* DLL enable */
#define DDR5_MR0_WR_LAT(x)      (((uint8_t)(x) & 0x0FU) << 4)   /* Write latency */
#define DDR5_MR0_RD_LAT(x)      (((uint8_t)(x) & 0x0FU) << 8)   /* Read latency */
#define DDR5_MR0_DQ_BUF_MODE    (1U << 12)                       /* DQ buffer mode */

/* MR1: Driver strength, ODT, termination (JESD79-5C §3.4.2) */
#define DDR5_MR1        0x01U
#define DDR5_MR1_RTT_NOM(x)     (((uint8_t)(x) & 0x07U) << 0)   /* Nominal termination: 0=HiZ, 1=RZQ/4, 2=RZQ/2, 3=RZQ/6, 4=RZQ/8 */
#define DDR5_MR1_DQ_DRV_STR(x)  (((uint8_t)(x) & 0x03U) << 3)   /* DQ driver strength: 0=RZQ/6, 1=RZQ/7, 2=RZQ/8, 3=RZQ/10 */
#define DDR5_MR1_CA_DRV_STR(x)  (((uint8_t)(x) & 0x03U) << 6)   /* CA driver strength: same encoding */

/* MR2: Vref training, CA training (JESD79-5C §3.4.3) */
#define DDR5_MR2        0x02U
#define DDR5_MR2_VREF_DQ_TRAIN_EN  (1U << 0)                     /* Vref DQ training enable */
#define DDR5_MR2_VREF_CA_TRAIN_EN  (1U << 1)                     /* Vref CA training enable */
#define DDR5_MR2_VREF_DQ_RANGE(x)  (((uint8_t)(x) & 0x03U) << 2) /* Vref DQ range */
#define DDR5_MR2_VREF_CA_RANGE(x)  (((uint8_t)(x) & 0x03U) << 4) /* Vref CA range */

/* MR3: CRC, parity, data mask (JESD79-5C §3.4.4) */
#define DDR5_MR3        0x03U
#define DDR5_MR3_CRC_EN_WR       (1U << 0)   /* CRC enable for writes */
#define DDR5_MR3_CRC_EN_RD       (1U << 1)   /* CRC enable for reads */
#define DDR5_MR3_PARITY_EN       (1U << 2)   /* Command/address parity enable */
#define DDR5_MR3_DM_EN           (1U << 3)   /* Data mask enable */

/* MR4: Per-DRAM addressability, connectivity test (JESD79-5C §3.4.5) */
#define DDR5_MR4        0x04U
#define DDR5_MR4_PDA_EN         (1U << 0)   /* Per-DRAM addressability enable */
#define DDR5_MR4_CONN_TEST_EN   (1U << 1)   /* Connectivity test enable */

/* MR5: Read preamble, write preamble, DFE (JESD79-5C §3.4.6) */
#define DDR5_MR5        0x05U
#define DDR5_MR5_RD_PREAMBLE(x)     (((uint8_t)(x) & 0x03U) << 0)  /* Read preamble: 0=1tCK, 1=2tCK, 2=off */
#define DDR5_MR5_WR_PREAMBLE(x)     (((uint8_t)(x) & 0x01U) << 2)  /* Write preamble: 0=1tCK, 1=2tCK */
#define DDR5_MR5_DFE_EN             (1U << 3)                       /* Decision Feedback Equalization */
#define DDR5_MR5_DM_N_PIN           (1U << 5)                       /* DM_n pin function */

/* MR6–MR13: Training configuration registers (JESD79-5C §3.4.7–3.4.14) */
#define DDR5_MR6        0x06U
#define DDR5_MR7        0x07U
#define DDR5_MR8        0x08U
#define DDR5_MR9        0x09U
#define DDR5_MR10       0x0AU
#define DDR5_MR11       0x0BU
#define DDR5_MR12       0x0CU
#define DDR5_MR13       0x0DU

/* MR6: Vref DQ training value (JESD79-5C §3.4.7) */
#define DDR5_MR6_VREF_DQ_VAL(x)     ((uint8_t)(x) & 0x7FU)        /* 7-bit Vref DQ code */

/* MR7: Vref CA training value (JESD79-5C §3.4.8) */
#define DDR5_MR7_VREF_CA_VAL(x)     ((uint8_t)(x) & 0x7FU)        /* 7-bit Vref CA code */

/* MR8: DQ training pattern A (JESD79-5C §3.4.9) */
#define DDR5_MR8_DQ_PAT_A(x)        ((x) & 0xFFFFU)               /* 16-bit training pattern A */

/* MR9: DQ training pattern B (JESD79-5C §3.4.10) */
#define DDR5_MR9_DQ_PAT_B(x)        ((x) & 0xFFFFU)               /* 16-bit training pattern B */

/* MR10: CA training pattern (JESD79-5C §3.4.11) */
#define DDR5_MR10_CA_PAT(x)         ((x) & 0xFFFFU)               /* 16-bit CA training pattern */

/* MR11: Duty cycle adjuster (JESD79-5C §3.4.12) */
#define DDR5_MR11_DCA_EN            (1U << 0)
#define DDR5_MR11_DCA_VAL(x)        (((uint8_t)(x) & 0x1FU) << 1) /* 5-bit duty cycle adjust */

/* MR21: Write CRC mode (JESD79-5C §3.4.21) */
#define DDR5_MR21       0x15U
#define DDR5_MR21_WCRC(x)           (((uint8_t)(x) & 0x03U) << 0) /* Write CRC: 0=off, 1=CRC-8, 2=CRC-16 */

/* MR22: Read CRC mode (JESD79-5C §3.4.22) */
#define DDR5_MR22       0x16U
#define DDR5_MR22_RCRC(x)           (((uint8_t)(x) & 0x03U) << 0) /* Read CRC: 0=off, 1=CRC-8, 2=CRC-16 */

/* ── DDR5 DIMM controller register map ───────────────────────────────────── */
/* These are SoC-specific controller registers that interact with DDR5 DIMMs  */

/* DDR controller configuration registers (memory-mapped) */
#define DDR_CTRL_BASE           0x40000000UL
#define DDR_CTRL_MR_OP          (DDR_CTRL_BASE + 0x0000U)  /* MRW/MRR operation trigger */
#define DDR_CTRL_MR_ADDR        (DDR_CTRL_BASE + 0x0004U)  /* MR address */
#define DDR_CTRL_MR_DATA        (DDR_CTRL_BASE + 0x0008U)  /* MR write data / read data */
#define DDR_CTRL_MR_CMD         (DDR_CTRL_BASE + 0x000CU)  /* 0=MRW, 1=MRR */
#define DDR_CTRL_TIMING_CFG     (DDR_CTRL_BASE + 0x0010U)  /* Timing configuration (tRCD, tCL, etc.) */
#define DDR_CTRL_DRV_STR        (DDR_CTRL_BASE + 0x0014U)  /* Driver strength configuration */
#define DDR_CTRL_ODT_CFG        (DDR_CTRL_BASE + 0x0018U)  /* ODT configuration */
#define DDR_CTRL_TRAIN_CTRL     (DDR_CTRL_BASE + 0x0020U)  /* Training control */
#define DDR_CTRL_TRAIN_STATUS   (DDR_CTRL_BASE + 0x0024U)  /* Training status */
#define DDR_CTRL_INIT_STATUS    (DDR_CTRL_BASE + 0x0028U)  /* Initialization status */
#define DDR_CTRL_ZQ_CTRL        (DDR_CTRL_BASE + 0x0030U)  /* ZQ calibration control */
#define DDR_CTRL_ERR_STATUS     (DDR_CTRL_BASE + 0x00F0U)  /* Error status register */
#define DDR_CTRL_TEMP_MONITOR   (DDR_CTRL_BASE + 0x00F4U)  /* Temperature monitor */

/* Bit fields for DDR_CTRL_MR_CMD */
#define MR_CMD_MRW             (0x00U)
#define MR_CMD_MRR             (0x01U)
#define MR_CMD_BUSY            (1U << 31)  /* Command in progress */

/* Bit fields for DDR_CTRL_INIT_STATUS */
#define INIT_DONE              (1U << 0)
#define INIT_ERR               (1U << 1)
#define TRAIN_DONE             (1U << 2)
#define TRAIN_ERR              (1U << 3)
#define ZQ_CALIB_DONE          (1U << 4)

#endif /* DDR5_REGS_H */