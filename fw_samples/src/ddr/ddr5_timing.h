/**
 * ddr5_timing.h — DDR5 Timing Parameter Definitions
 *
 * Maps JEDEC JESD79-5C §5.2 Timing Parameters (tRCD, tCL, tRP, etc.).
 * These are the minimum timing constraints the firmware must respect
 * when sequencing DDR5 commands.
 * Reference: spec_model ddr5 extract → behavior_constraints → timing parameters
 */

#ifndef DDR5_TIMING_H
#define DDR5_TIMING_H

#include <stdint.h>

/* ── Frequency-dependent timing parameters (DDR5-4800 example) ───────────── */

#define DDR5_SPEED_BIN        DDR5_4800

typedef enum {
    DDR5_3200 = 3200,
    DDR5_3600 = 3600,
    DDR5_4000 = 4000,
    DDR5_4400 = 4400,
    DDR5_4800 = 4800,
    DDR5_5600 = 5600,
    DDR5_6400 = 6400,
} ddr5_speed_bin_t;

/* ── Core timing parameters (in clock cycles, at DDR5-4800) ──────────────── */

/* CL (CAS Latency): READ command to first data element — JESD79-5C §5.2.1 */
#define DDR5_CL_CYCLES        40U   /* CAS latency at DDR5-4800 (tCK=0.417ns → ~16.7ns) */

/* tRCD (RAS to CAS Delay): ACTIVE to READ/WRITE — JESD79-5C §5.2.7 */
#define DDR5_TRCD_CYCLES      40U   /* ACT→RD/WR minimum cycles */

/* tRP (Row Precharge Time): PRECHARGE to ACTIVE — JESD79-5C §5.2.8 */
#define DDR5_TRP_CYCLES       40U   /* PRE→ACT minimum cycles */

/* tRAS (Active to Precharge): ACTIVE to PRECHARGE — JESD79-5C §5.2.9 */
#define DDR5_TRAS_CYCLES      84U   /* ACT→PRE minimum cycles */

/* tRC (Row Cycle Time): ACTIVE to next ACTIVE (same bank) — JESD79-5C §5.2.10 */
#define DDR5_TRC_CYCLES       124U  /* tRAS + tRP */

/* tRFC (Refresh Cycle Time): REFRESH to next REFRESH — JESD79-5C §5.2.16 */
#define DDR5_TRFC_CYCLES      560U  /* Single bank refresh interval at 4800 MT/s */

/* tWR (Write Recovery Time): WRITE end to PRECHARGE — JESD79-5C §5.2.12 */
#define DDR5_TWR_CYCLES       48U   /* WR→PRE minimum cycles */

/* tWTR (Write to Read): Last write data to READ — JESD79-5C §5.2.13 */
#define DDR5_TWTR_L_CYCLES    16U   /* Write→Read same bank group */
#define DDR5_TWTR_S_CYCLES    8U    /* Write→Read different bank group */

/* tCCD (Column to Column Delay): READ/WRITE to another READ/WRITE — JESD79-5C §5.2.14 */
#define DDR5_TCCD_L_CYCLES    8U    /* Same bank group */
#define DDR5_TCCD_S_CYCLES    4U    /* Different bank group */

/* tRRD (Row to Row Delay): ACTIVE to another ACTIVE — JESD79-5C §5.2.15 */
#define DDR5_TRRD_L_CYCLES    8U    /* Same bank group */
#define DDR5_TRRD_S_CYCLES    4U    /* Different bank group */

/* tMRD (Mode Register Set Delay): MRW to MRR/MRW — JESD79-5C §5.2.17 */
#define DDR5_TMRD_CYCLES      8U    /* MRW→MRR minimum cycles */

/* tZQinit (Initial ZQ Calibration): ZQ_CL to NORMAL — JESD79-5C §5.2.18 */
#define DDR5_TZQINIT_CYCLES   1024U /* Initial ZQ calibration time */

/* tZQoper (Operation ZQ Calibration): ZQ_CS to NORMAL — JESD79-5C §5.2.19 */
#define DDR5_TZQOPER_CYCLES   512U  /* Operational ZQ short calibration */

/* tXPR (Exit Power-Down to READ): CKE high to first valid command after Reset — JESD79-5C §5.2.20 */
#define DDR5_TXPR_CYCLES      512U  /* CKE → first command after reset exit */

/* tDLLK (DLL Lock): DLL enable to DLL lock ready — JESD79-5C §5.2.21 */
#define DDR5_TDLLK_CYCLES     1024U /* DLL lock time (typical 1024 tCK) */

/* ── Timing computation hints ────────────────────────────────────────────── */

/**
 * Wait for specified number of DDR5 clock cycles.
 * The controller converts cycle counts to real-time delays based on
 * the current DDR speed bin (tCK period).
 */
static inline uint32_t ddr5_tck_ns(ddr5_speed_bin_t bin)
{
    /* tCK (ns) = 2000 / data_rate (MT/s) */
    switch (bin) {
        case DDR5_3200: return 625;   /* 0.625 ns × 1000 → picosecond granularity */
        case DDR5_3600: return 556;   /* 2000/3600 ≈ 0.556 ns */
        case DDR5_4000: return 500;
        case DDR5_4400: return 455;
        case DDR5_4800: return 417;
        case DDR5_5600: return 357;
        case DDR5_6400: return 312;
        default:        return 417;
    }
}

/* Wait macro — converts DDR cycles to controller wait loops */
#define DDR5_WAIT_CYCLES(n)       ddr5_delay_cycles((uint32_t)(n))

/* Helper to convert DDR cycles to real time */
#define DDR5_NS_FROM_CYCLES(n, bin)  (((uint64_t)(n) * ddr5_tck_ns(bin)) / 1000U)

#endif /* DDR5_TIMING_H */