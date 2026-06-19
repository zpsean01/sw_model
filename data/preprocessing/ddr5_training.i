# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\ddr\\ddr5_training.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\ddr\\ddr5_training.c" 2
/**
 * ddr5_training.c — DDR5 Training Routine Implementations
 *
 * Simplified implementations of DDR5 training procedures for analysis purposes.
 * These functions are referenced by src/ddr5_init_controller.c via
 * the declarations in src/ddr5_training.h.
 */

# 1 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 1 3
/*===---- stdint.h - Standard header for sized integer types --------------===*\
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
\*===----------------------------------------------------------------------===*/


// AIX system headers need stdint.h to be re-enterable while _STD_TYPES_T
// is defined until an inclusion of it without _STD_TYPES_T occurs, in which
// case the header guard macro is defined.








/* If we're hosted, fall back to the system's stdint.h, which might have
 * additional definitions.
 */
# 69 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C99 7.18.1.1 Exact-width integer types.
 * C99 7.18.1.2 Minimum-width integer types.
 * C99 7.18.1.3 Fastest minimum-width integer types.
 *
 * The standard requires that exact-width type be defined for 8-, 16-, 32-, and
 * 64-bit types if they are implemented. Other exact width types are optional.
 * This implementation defines an exact-width types for every integer width
 * that is represented in the standard integer types.
 *
 * The standard also requires minimum-width types be defined for 8-, 16-, 32-,
 * and 64-bit widths regardless of whether there are corresponding exact-width
 * types.
 *
 * To accommodate targets that are missing types that are exactly 8, 16, 32, or
 * 64 bits wide, this implementation takes an approach of cascading
 * redefinitions, redefining __int_leastN_t to successively smaller exact-width
 * types. It is therefore important that the types are defined in order of
 * descending widths.
 *
 * We currently assume that the minimum-width types and the fastest
 * minimum-width types are the same. This is allowed by the standard, but is
 * suboptimal.
 *
 * In violation of the standard, some targets do not implement a type that is
 * wide enough to represent all of the required widths (8-, 16-, 32-, 64-bit).
 * To accommodate these targets, a required minimum-width type is only
 * defined if there exists an exact-width type of equal or greater width.
 */



typedef long long int int64_t;

typedef long long unsigned int uint64_t;
# 122 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int64_t int_least64_t;
typedef uint64_t uint_least64_t;
typedef int64_t int_fast64_t;
typedef uint64_t uint_fast64_t;
# 197 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int int32_t;




typedef unsigned int uint32_t;
# 220 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int32_t int_least32_t;
typedef uint32_t uint_least32_t;
typedef int32_t int_fast32_t;
typedef uint32_t uint_fast32_t;
# 245 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef short int16_t;

typedef unsigned short uint16_t;
# 259 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int16_t int_least16_t;
typedef uint16_t uint_least16_t;
typedef int16_t int_fast16_t;
typedef uint16_t uint_fast16_t;





typedef signed char int8_t;

typedef unsigned char uint8_t;







typedef int8_t int_least8_t;
typedef uint8_t uint_least8_t;
typedef int8_t int_fast8_t;
typedef uint8_t uint_fast8_t;


/* prevent glibc sys/types.h from defining conflicting types */




/* C99 7.18.1.4 Integer types capable of holding object pointers.
 */




typedef int intptr_t;






typedef unsigned int uintptr_t;



/* C99 7.18.1.5 Greatest-width integer types.
 */
typedef long long int intmax_t;
typedef long long unsigned int uintmax_t;

/* C99 7.18.4 Macros for minimum-width integer constants.
 *
 * The standard requires that integer constant macros be defined for all the
 * minimum-width types defined above. As 8-, 16-, 32-, and 64-bit minimum-width
 * types are required, the corresponding integer constant macros are defined
 * here. This implementation also defines minimum-width types for every other
 * integer width that the target implements, so corresponding macros are
 * defined below, too.
 *
 * Note that C++ should not check __STDC_CONSTANT_MACROS here, contrary to the
 * claims of the C standard (see C++ 18.3.1p2, [cstdint.syn]).
 */
# 372 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C99 7.18.2.1 Limits of exact-width integer types.
 * C99 7.18.2.2 Limits of minimum-width integer types.
 * C99 7.18.2.3 Limits of fastest minimum-width integer types.
 *
 * The presence of limit macros are completely optional in C99.  This
 * implementation defines limits for all of the types (exact- and
 * minimum-width) that it defines above, using the limits of the minimum-width
 * type for any types that do not have exact-width representations.
 *
 * As in the type definitions, this section takes an approach of
 * successive-shrinking to determine which limits to use for the standard (8,
 * 16, 32, 64) bit widths when they don't have exact representations. It is
 * therefore important that the definitions be kept in order of decending
 * widths.
 *
 * Note that C++ should not check __STDC_LIMIT_MACROS here, contrary to the
 * claims of the C standard (see C++ 18.3.1p2, [cstdint.syn]).
 */
# 763 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* Some utility macros */






/* C99 7.18.2.4 Limits of integer types capable of holding object pointers. */
/* C99 7.18.3 Limits of other integer types. */
# 780 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C23 7.22.2.4 Width of integer types capable of holding object pointers. */







/* ISO9899:2011 7.20 (C11 Annex K): Define RSIZE_MAX if __STDC_WANT_LIB_EXT1__
 * is enabled. */




/* C99 7.18.2.5 Limits of greatest-width integer types. */




/* C23 7.22.2.5 Width of greatest-width integer types. */







/* C99 7.18.3 Limits of other integer types. */
# 829 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* 7.18.4.2 Macros for greatest-width integer constants. */



/* C23 7.22.3.x Width of other integer types. */
# 10 "D:\\programming\\sw_model\\fw_samples\\lib\\ddr\\ddr5_training.c" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_training.h" 1
/**
 * ddr5_training.h — DDR5 Training State Machine and Routines
 *
 * Defines the DDR5 initialization state machine and training procedures.
 * Reference: spec_model ddr5 extract → behavior_constraints → state_machines
 *            + scenarios → initialization scenario paths
 */





# 1 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_regs.h" 1
/**
 * ddr5_regs.h — DDR5 Mode Register (MR) definitions
 *
 * Maps JEDEC JESD79-5C §3.4 Mode Register Set.
 * Each MR is accessible via MRW (Mode Register Write) and MRR (Mode Register Read).
 * Reference: spec_model ddr5 extract → object_entities → register
 */






/* ── MR address space: MR0–MR254 ────────────────────────────────────────── */

/* MR0: Burst Length, Read/Write Length, DLL Control (JESD79-5C §3.4.1) */







/* MR1: Driver strength, ODT, termination (JESD79-5C §3.4.2) */





/* MR2: Vref training, CA training (JESD79-5C §3.4.3) */






/* MR3: CRC, parity, data mask (JESD79-5C §3.4.4) */






/* MR4: Per-DRAM addressability, connectivity test (JESD79-5C §3.4.5) */




/* MR5: Read preamble, write preamble, DFE (JESD79-5C §3.4.6) */






/* MR6–MR13: Training configuration registers (JESD79-5C §3.4.7–3.4.14) */
# 66 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_regs.h"
/* MR6: Vref DQ training value (JESD79-5C §3.4.7) */


/* MR7: Vref CA training value (JESD79-5C §3.4.8) */


/* MR8: DQ training pattern A (JESD79-5C §3.4.9) */


/* MR9: DQ training pattern B (JESD79-5C §3.4.10) */


/* MR10: CA training pattern (JESD79-5C §3.4.11) */


/* MR11: Duty cycle adjuster (JESD79-5C §3.4.12) */



/* MR21: Write CRC mode (JESD79-5C §3.4.21) */



/* MR22: Read CRC mode (JESD79-5C §3.4.22) */



/* ── DDR5 DIMM controller register map ───────────────────────────────────── */
/* These are SoC-specific controller registers that interact with DDR5 DIMMs  */

/* DDR controller configuration registers (memory-mapped) */
# 112 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_regs.h"
/* Bit fields for DDR_CTRL_MR_CMD */




/* Bit fields for DDR_CTRL_INIT_STATUS */
# 14 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_training.h" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_timing.h" 1
/**
 * ddr5_timing.h — DDR5 Timing Parameter Definitions
 *
 * Maps JEDEC JESD79-5C §5.2 Timing Parameters (tRCD, tCL, tRP, etc.).
 * These are the minimum timing constraints the firmware must respect
 * when sequencing DDR5 commands.
 * Reference: spec_model ddr5 extract → behavior_constraints → timing parameters
 */






/* ── Frequency-dependent timing parameters (DDR5-4800 example) ───────────── */



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


/* tRCD (RAS to CAS Delay): ACTIVE to READ/WRITE — JESD79-5C §5.2.7 */


/* tRP (Row Precharge Time): PRECHARGE to ACTIVE — JESD79-5C §5.2.8 */


/* tRAS (Active to Precharge): ACTIVE to PRECHARGE — JESD79-5C §5.2.9 */


/* tRC (Row Cycle Time): ACTIVE to next ACTIVE (same bank) — JESD79-5C §5.2.10 */


/* tRFC (Refresh Cycle Time): REFRESH to next REFRESH — JESD79-5C §5.2.16 */


/* tWR (Write Recovery Time): WRITE end to PRECHARGE — JESD79-5C §5.2.12 */


/* tWTR (Write to Read): Last write data to READ — JESD79-5C §5.2.13 */



/* tCCD (Column to Column Delay): READ/WRITE to another READ/WRITE — JESD79-5C §5.2.14 */



/* tRRD (Row to Row Delay): ACTIVE to another ACTIVE — JESD79-5C §5.2.15 */



/* tMRD (Mode Register Set Delay): MRW to MRR/MRW — JESD79-5C §5.2.17 */


/* tZQinit (Initial ZQ Calibration): ZQ_CL to NORMAL — JESD79-5C §5.2.18 */


/* tZQoper (Operation ZQ Calibration): ZQ_CS to NORMAL — JESD79-5C §5.2.19 */


/* tXPR (Exit Power-Down to READ): CKE high to first valid command after Reset — JESD79-5C §5.2.20 */


/* tDLLK (DLL Lock): DLL enable to DLL lock ready — JESD79-5C §5.2.21 */


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
        case DDR5_3200: return 625; /* 0.625 ns × 1000 → picosecond granularity */
        case DDR5_3600: return 556; /* 2000/3600 ≈ 0.556 ns */
        case DDR5_4000: return 500;
        case DDR5_4400: return 455;
        case DDR5_4800: return 417;
        case DDR5_5600: return 357;
        case DDR5_6400: return 312;
        default: return 417;
    }
}

/* Wait macro — converts DDR cycles to controller wait loops */


/* Helper to convert DDR cycles to real time */
# 15 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_training.h" 2

/* ── DDR5 initialization state machine ──────────────────────────────────── */

typedef enum {
    DDR5_STATE_RESET = 0, /* RESET asserted, VDD/VDDQ stable */
    DDR5_STATE_CKE_HIGH = 1, /* CKE raised after RESET de-assert */
    DDR5_STATE_MR_CONFIG = 2, /* Configuring MR0–MR5 via MRW */
    DDR5_STATE_VREF_TRAIN = 3, /* Vref DQ and CA training (MR6-MR7) */
    DDR5_STATE_ZQ_CALIB = 4, /* ZQ calibration long */
    DDR5_STATE_DQ_TRAIN = 5, /* DQ training pattern A/B (MR8-MR9) */
    DDR5_STATE_CA_TRAIN = 6, /* CA training pattern (MR10) */
    DDR5_STATE_DCA_TRAIN = 7, /* Duty cycle adjust (MR11) */
    DDR5_STATE_CRC_CONFIG = 8, /* CRC configuration (MR21-MR22) */
    DDR5_STATE_MR_VERIFY = 9, /* MRR verification of all config MRs */
    DDR5_STATE_READY = 10, /* Normal operation */
    DDR5_STATE_ERROR = 15, /* Fatal initialization error */
} ddr5_init_state_t;

/* State transition table (JESD79-5C §3.3 — Initialization Procedure) */
static const char* ddr5_state_names[] = {
    [DDR5_STATE_RESET] = "RESET",
    [DDR5_STATE_CKE_HIGH] = "CKE_HIGH",
    [DDR5_STATE_MR_CONFIG] = "MR_CONFIG",
    [DDR5_STATE_VREF_TRAIN] = "VREF_TRAIN",
    [DDR5_STATE_ZQ_CALIB] = "ZQ_CALIB",
    [DDR5_STATE_DQ_TRAIN] = "DQ_TRAIN",
    [DDR5_STATE_CA_TRAIN] = "CA_TRAIN",
    [DDR5_STATE_DCA_TRAIN] = "DCA_TRAIN",
    [DDR5_STATE_CRC_CONFIG] = "CRC_CONFIG",
    [DDR5_STATE_MR_VERIFY] = "MR_VERIFY",
    [DDR5_STATE_READY] = "READY",
    [DDR5_STATE_ERROR] = "ERROR",
};

/* ── Vref training result structure ──────────────────────────────────────── */

typedef struct {
    uint8_t vref_dq_code; /* MR6 value — Vref DQ training result */
    uint8_t vref_ca_code; /* MR7 value — Vref CA training result */
    uint8_t duty_cycle_val; /* MR11 value — duty cycle adjust value */
    uint32_t dq_pattern_a; /* MR8 value — DQ training pattern A */
    uint32_t dq_pattern_b; /* MR9 value — DQ training pattern B */
    uint32_t ca_pattern; /* MR10 value — CA training pattern */
    uint8_t training_pass; /* 1 = all training passed, 0 = failed */
} ddr5_training_result_t;

/* ── Training routine entry points ───────────────────────────────────────── */

/**
 * Perform Vref DQ training:
 *   - Sweep Vref DQ range via MR6
 *   - Read data eyes to find optimal Vref value
 *   - Update MR6 with optimal code
 *   Returns optimal Vref DQ code (0–127)
 */
uint8_t ddr5_train_vref_dq(void);

/**
 * Perform Vref CA training:
 *   - Sweep Vref CA range via MR7
 *   - Send CA training pattern via MR10
 *   - Read DIMM response to find optimal Vref
 *   - Update MR7 with optimal code
 *   Returns optimal Vref CA code (0–127)
 */
uint8_t ddr5_train_vref_ca(void);

/**
 * Perform DQ training (write leveling):
 *   - Configure MR8/MR9 with training patterns A and B
 *   - Execute write leveling via MPC command
 *   - Adjust per-bit delays in DDR controller
 */
void ddr5_train_dq_write_leveling(void);

/**
 * Perform Duty Cycle Adjuster (DCA) training:
 *   - Enable DCA in MR11
 *   - Sweep adjust values to minimize duty cycle error
 *   - Lock optimal value to MR11
 *   Returns optimal DCA value (0–31)
 */
uint8_t ddr5_train_duty_cycle(void);
# 11 "D:\\programming\\sw_model\\fw_samples\\lib\\ddr\\ddr5_training.c" 2

/* ── Vref DQ training: sweep Vref and find optimal value ──────────────────── */

uint8_t ddr5_train_vref_dq(void)
{
    /* Simplified: sweep Vref DQ from 0–127 and return optimal code.
     * In real hardware: send training patterns via MR8/MR9, measure DQ eye,
     * find the Vref value that maximizes the eye opening. */

    uint8_t optimal_code = 64; /* default midpoint — real training would calibrate this */

    /* [BUG] If this function returns a value > 127, the caller (MR6 write)
     * silently truncates it via DDR5_MR6_VREF_DQ_VAL(x) 7-bit mask. */

    return optimal_code;
}

/* ── Vref CA training: sweep Vref and find optimal CA value ───────────────── */

uint8_t ddr5_train_vref_ca(void)
{
    /* Simplified: sweep Vref CA from 0–127 and return optimal code.
     * In real hardware: send CA training patterns via MR10, measure CA eye,
     * find the Vref value that maximizes CA command capture margin. */

    uint8_t optimal_code = 64; /* default midpoint */

    if (optimal_code > 100)
    {
        /* Temperature-dependent adjustment — currently hardcoded as no-op */
    }

    return optimal_code;
}

/* ── DQ write leveling: align DQ/DQS timing ───────────────────────────────── */

void ddr5_train_dq_write_leveling(void)
{
    /* Simplified write leveling procedure.
     * Real step sequence:
     *   1. Enable write leveling mode via MPC command
     *   2. DUT drives DQS on each DQ lane
     *   3. Controller adjusts per-DQ-bit delay to align DQ with DQS
     *   4. Disable write leveling, verify with known pattern */

    /* Write leveling delay sweep — 16 DQ lanes */
    for (int lane = 0; lane < 16; lane++)
    {
        /* Simplified: each lane gets proportional delay */
        (void)(lane * 16);
    }
}

/* ── Duty Cycle Adjuster (DCA) training ──────────────────────────────────── */

uint8_t ddr5_train_duty_cycle(void)
{
    /* Simplified DCA training: adjust duty cycle of clock to minimize error.
     * Real procedure:
     *   1. Measure duty cycle error via DCA monitoring logic
     *   2. Sweep DCA code from 0–31 via MR11
     *   3. Lock code with minimum duty cycle error */

    uint8_t dca_code = 16; /* default midpoint (range 0–31) */
    return dca_code;
}
