/**
 * ddr5_cmds.h — DDR5 Command Set Definitions
 *
 * Maps JEDEC JESD79-5C §4 Command Set.
 * Each command is encoded via CA[13:0] bus signals.
 * Reference: spec_model ddr5 extract → generalized_interfaces → CA_Bus operations
 */

#ifndef DDR5_CMDS_H
#define DDR5_CMDS_H

#include <stdint.h>

/* ── CA Bus command encoding (CA[13:0]) ──────────────────────────────────── */

/* Activation commands */
#define CA_CMD_ACTIVATE        0x0001U    /* Activate row — requires row address on CA[12:0] */
#define CA_CMD_ACTIVATE_NOP    0x0000U    /* Activate NOP */

/* Read commands */
#define CA_CMD_READ            0x0004U    /* Read — requires column address */
#define CA_CMD_READ_WITH_AP    0x0005U    /* Read with auto-precharge */
#define CA_CMD_READ_NOP        0x0006U    /* Read NOP */

/* Write commands */
#define CA_CMD_WRITE           0x0008U    /* Write — requires column address + data */
#define CA_CMD_WRITE_WITH_AP   0x0009U    /* Write with auto-precharge */
#define CA_CMD_WRITE_NOP       0x000AU    /* Write NOP */

/* Precharge commands */
#define CA_CMD_PRECHARGE           0x000CU    /* Precharge single bank */
#define CA_CMD_PRECHARGE_ALL       0x000DU    /* Precharge all banks */
#define CA_CMD_PRECHARGE_NOP       0x000EU    /* Precharge NOP */

/* Refresh commands */
#define CA_CMD_REFRESH         0x0010U    /* Refresh — single bank */
#define CA_CMD_REFRESH_ALL     0x0011U    /* Refresh all banks */
#define CA_CMD_REFRESH_PER_BANK 0x0012U   /* Per-bank refresh */

/* Mode Register access */
#define CA_CMD_MRW             0x0014U    /* Mode Register Write */
#define CA_CMD_MRR             0x0015U    /* Mode Register Read */
#define CA_CMD_MRW_NOP         0x0016U    /* MRW NOP */

/* Self-refresh / Power-down */
#define CA_CMD_SRE             0x0018U    /* Self-Refresh Entry */
#define CA_CMD_SRX             0x0019U    /* Self-Refresh Exit */
#define CA_CMD_PDE             0x001AU    /* Power-Down Entry */
#define CA_CMD_PDX             0x001BU    /* Power-Down Exit */

/* Training commands */
#define CA_CMD_MPC             0x0020U    /* Multi-Purpose Command (training) */

/* ZQ calibration */
#define CA_CMD_ZQ_CL           0x0024U    /* ZQ Calibration Long */
#define CA_CMD_ZQ_CS           0x0025U    /* ZQ Calibration Short */
#define CA_CMD_ZQ_LATCH        0x0026U    /* ZQ Calibration Latch */

/* ── DDR5 initialization command sequence ─────────────────────────────────── */

/**
 * DDR5 initialization requires the following CA bus command sequence
 * as defined by JEDEC JESD79-5C §3.3 Initialization Procedure:
 *
 *   Power-up → RESET low (≥200μs) → RESET high
 *     → CKE high → wait tXPR
 *     → MRW MR0 (Burst Length, DLL, latency)
 *     → MRW MR1 (Driver strength, ODT)
 *     → MRW MR2 (Vref training config)
 *     → MRW MR3 (CRC, parity, data mask)
 *     → MRW MR4 (PDA, connectivity test)
 *     → MRW MR5 (Read/Write preamble, DFE)
 *     → MRW MR6 (Vref DQ training value)
 *     → MRW MR7 (Vref CA training value)
 *     → ZQ_CL (ZQ Calibration Long) → wait tZQinit
 *     → Training (Vref DQ, Vref CA, Duty cycle)
 *     → MRR verification for each configured MR
 *     → Normal operation ready
 */

#endif /* DDR5_CMDS_H */