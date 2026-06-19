# 1 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c" 2
/**
 * ddr5_init_controller.c — DDR5 Initialization Controller
 *
 * Implements the complete DDR5 initialization sequence per JEDEC JESD79-5C §3.3.
 * This file is the "DUT" (Device Under Test) for the sw_model analysis pipeline.
 *
 * Quality analysis targets:
 *   - State machine completeness (all states reachable?)
 *   - Register configuration correctness (MR values match protocol?)
 *   - Timing constraint adherence (delays between commands?)
 *   - Interrupt safety (training ISR vs main init flow)
 *   - Error handling coverage (what if training fails?)
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
# 16 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 17 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c" 2
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
# 18 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_cmds.h" 1
/**
 * ddr5_cmds.h — DDR5 Command Set Definitions
 *
 * Maps JEDEC JESD79-5C §4 Command Set.
 * Each command is encoded via CA[13:0] bus signals.
 * Reference: spec_model ddr5 extract → generalized_interfaces → CA_Bus operations
 */






/* ── CA Bus command encoding (CA[13:0]) ──────────────────────────────────── */

/* Activation commands */



/* Read commands */




/* Write commands */




/* Precharge commands */




/* Refresh commands */




/* Mode Register access */




/* Self-refresh / Power-down */





/* Training commands */


/* ZQ calibration */




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
# 19 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c" 2
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
# 20 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_training.h" 1
/**
 * ddr5_training.h — DDR5 Training State Machine and Routines
 *
 * Defines the DDR5 initialization state machine and training procedures.
 * Reference: spec_model ddr5 extract → behavior_constraints → state_machines
 *            + scenarios → initialization scenario paths
 */
# 16 "D:\\programming\\sw_model\\fw_samples\\src\\ddr/ddr5_training.h"
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
# 21 "D:\\programming\\sw_model\\fw_samples\\src\\ddr\\ddr5_init_controller.c" 2

/* ── Platform abstraction ────────────────────────────────────────────────── */

extern void ddr5_delay_cycles(uint32_t cycles);
extern void ddr5_ca_bus_send(uint16_t cmd, uint32_t addr);
extern uint32_t ddr5_mr_read(uint8_t mr_addr);
extern void ddr5_mr_write(uint8_t mr_addr, uint32_t data);
extern void ddr5_set_cke(uint8_t state);
extern void ddr5_set_reset_n(uint8_t state);
extern uint32_t ddr5_read_reg(uint32_t addr);
extern void ddr5_write_reg(uint32_t addr, uint32_t val);

/* ── Training timeout (in cycles) ─────────────────────────────────────────── */



/* ── Initialization context ──────────────────────────────────────────────── */

typedef struct {
    ddr5_init_state_t current_state;
    ddr5_speed_bin_t speed_bin;
    uint8_t mr_configs[256]; /* written MR values for verification */
    ddr5_training_result_t train_result;
    uint8_t error_count;
    uint8_t error_max;
} ddr5_init_context_t;

/* ── Forward declarations ────────────────────────────────────────────────── */

static void _state_mr_config(ddr5_init_context_t *ctx);
static void _state_vref_train(ddr5_init_context_t *ctx);
static void _state_zq_calib(ddr5_init_context_t *ctx);
static void _state_dq_train(ddr5_init_context_t *ctx);
static void _state_ca_train(ddr5_init_context_t *ctx);
static void _state_dca_train(ddr5_init_context_t *ctx);
static void _state_crc_config(ddr5_init_context_t *ctx);
static _Bool _state_mr_verify(ddr5_init_context_t *ctx);
static _Bool _mrw_register(ddr5_init_context_t *ctx, uint8_t mr, uint32_t value);

/* ── Main initialization entry ───────────────────────────────────────────── */

ddr5_init_state_t ddr5_initialize(ddr5_speed_bin_t speed_bin)
{
    ddr5_init_context_t ctx = {
        .current_state = DDR5_STATE_RESET,
        .speed_bin = speed_bin,
        .error_count = 0,
        .error_max = 3,
    };

    /* ── Phase 1: Power-up and RESET sequence (JESD79-5C §3.3.1) ─────────── */

    ctx.current_state = DDR5_STATE_RESET;

    /* VDD/VDDQ must be stable before RESET */
    ddr5_set_reset_n(0); /* Assert RESET low */
    ddr5_set_cke(0); /* CKE low during reset */
    ddr5_delay_cycles((uint32_t)(1000000)); /* Wait for power stabilization (~1M cycles) */

    ddr5_set_reset_n(1); /* De-assert RESET */
    ddr5_delay_cycles((uint32_t)(512U)); /* Wait tXPR before CKE */

    ddr5_set_cke(1); /* CKE high — DIMM exits reset */
    ddr5_delay_cycles((uint32_t)(1024U)); /* Wait DLL lock */

    ctx.current_state = DDR5_STATE_CKE_HIGH;

    /* ── Phase 2: Mode Register configuration (JESD79-5C §3.3.3) ──────────── */

    ctx.current_state = DDR5_STATE_MR_CONFIG;
    _state_mr_config(&ctx);

    /* ── Phase 3: Vref training (MR6-MR7) ────────────────────────────────── */

    ctx.current_state = DDR5_STATE_VREF_TRAIN;
    _state_vref_train(&ctx);

    /* ── Phase 4: ZQ calibration (JESD79-5C §3.3.5) ───────────────────────── */

    ctx.current_state = DDR5_STATE_ZQ_CALIB;
    _state_zq_calib(&ctx);

    /* ── Phase 5: DQ training ─────────────────────────────────────────────── */

    ctx.current_state = DDR5_STATE_DQ_TRAIN;
    _state_dq_train(&ctx);

    /* ── Phase 6: CA training ─────────────────────────────────────────────── */

    ctx.current_state = DDR5_STATE_CA_TRAIN;
    _state_ca_train(&ctx);

    /* ── Phase 7: Duty cycle adjust training ──────────────────────────────── */

    ctx.current_state = DDR5_STATE_DCA_TRAIN;
    _state_dca_train(&ctx);

    /* ── Phase 8: CRC configuration (MR21-MR22) ───────────────────────────── */

    ctx.current_state = DDR5_STATE_CRC_CONFIG;
    _state_crc_config(&ctx);

    /* ── Phase 9: MR verification via MRR ─────────────────────────────────── */

    ctx.current_state = DDR5_STATE_MR_VERIFY;
    if (!_state_mr_verify(&ctx)) {
        ctx.current_state = DDR5_STATE_ERROR;
        return DDR5_STATE_ERROR;
    }

    ctx.current_state = DDR5_STATE_READY;
    return DDR5_STATE_READY;
}

/* ── State: MR configuration ─────────────────────────────────────────────── */

static void _state_mr_config(ddr5_init_context_t *ctx)
{
    /* MR0: Burst Length = BL16, DLL enable, Write Latency, Read Latency */
    uint32_t mr0_val = (((uint8_t)(0) & 0x07U) << 0) | (1U << 3)
                     | (((uint8_t)(6) & 0x0FU) << 4) | (((uint8_t)(8) & 0x0FU) << 8);
    _mrw_register(ctx, 0x00U, mr0_val);

    /* MR1: RTT_NOM = RZQ/4 (40Ω), DQ drive = RZQ/7 (34Ω), CA drive = RZQ/7 */
    uint32_t mr1_val = (((uint8_t)(1) & 0x07U) << 0) | (((uint8_t)(1) & 0x03U) << 3)
                     | (((uint8_t)(1) & 0x03U) << 6);
    _mrw_register(ctx, 0x01U, mr1_val);

    /* MR2: Vref DQ and CA training enable */
    uint32_t mr2_val = (1U << 0) | (1U << 1)
                     | (((uint8_t)(0) & 0x03U) << 2) | (((uint8_t)(0) & 0x03U) << 4);
    _mrw_register(ctx, 0x02U, mr2_val);

    /* MR3: Enable parity and CRC on writes */
    uint32_t mr3_val = (1U << 0) | (1U << 2);
    _mrw_register(ctx, 0x03U, mr3_val);

    /* MR4: No PDA, connectivity test disabled */
    uint32_t mr4_val = 0;
    _mrw_register(ctx, 0x04U, mr4_val);

    /* MR5: READ preamble = 1tCK, WRITE preamble = 1tCK, DFE enabled */
    uint32_t mr5_val = (((uint8_t)(0) & 0x03U) << 0) | (((uint8_t)(0) & 0x01U) << 2)
                     | (1U << 3);
    _mrw_register(ctx, 0x05U, mr5_val);
}

/* ── State: Vref training ────────────────────────────────────────────────── */

static void _state_vref_train(ddr5_init_context_t *ctx)
{
    uint8_t vref_dq = ddr5_train_vref_dq();
    uint8_t vref_ca = ddr5_train_vref_ca();

    /* Write training results to MR6 (Vref DQ) and MR7 (Vref CA) */
    uint32_t mr6_val = ((uint8_t)(vref_dq) & 0x7FU);
    uint32_t mr7_val = ((uint8_t)(vref_ca) & 0x7FU);

    _mrw_register(ctx, 0x06U, mr6_val);
    _mrw_register(ctx, 0x07U, mr7_val);

    ctx->train_result.vref_dq_code = vref_dq;
    ctx->train_result.vref_ca_code = vref_ca;
}

/* ── State: ZQ calibration ────────────────────────────────────────────────── */

static void _state_zq_calib(ddr5_init_context_t *ctx)
{
    /* Issue ZQ Calibration Long command */
    ddr5_delay_cycles((uint32_t)(40U)); /* Wait tRCD before write */
    ddr5_ca_bus_send(0x0024U, 0); /* ZQ_CL command on CA bus */

    /* Wait for ZQ calibration to complete (tZQinit) */
    ddr5_delay_cycles((uint32_t)(1024U));

    /* Check ZQ calibration status */
    uint32_t status = ddr5_read_reg((0x40000000UL + 0x0030U));
    if (!(status & (1U << 4))) {
        ctx->error_count++;
        /* ZQ failure — attempt recovery via short calibration */
        ddr5_ca_bus_send(0x0025U, 0);
        ddr5_delay_cycles((uint32_t)(512U));
    }
}

/* ── State: DQ training ──────────────────────────────────────────────────── */

static void _state_dq_train(ddr5_init_context_t *ctx)
{
    /* Configure DQ training patterns */
    uint32_t mr8_val = ((0xA5A5U) & 0xFFFFU);
    uint32_t mr9_val = ((0x5A5AU) & 0xFFFFU);

    _mrw_register(ctx, 0x08U, mr8_val);
    _mrw_register(ctx, 0x09U, mr9_val);

    ctx->train_result.dq_pattern_a = mr8_val;
    ctx->train_result.dq_pattern_b = mr9_val;

    ddr5_delay_cycles((uint32_t)(8U));
    ddr5_train_dq_write_leveling();
}

/* ── State: CA training ───────────────────────────────────────────────────── */

static void _state_ca_train(ddr5_init_context_t *ctx)
{
    uint32_t mr10_val = ((0x3CC3U) & 0xFFFFU);
    _mrw_register(ctx, 0x0AU, mr10_val);
    ctx->train_result.ca_pattern = mr10_val;
    ddr5_delay_cycles((uint32_t)(8U));
}

/* ── State: Duty cycle adjust training ────────────────────────────────────── */

static void _state_dca_train(ddr5_init_context_t *ctx)
{
    uint8_t dca_val = ddr5_train_duty_cycle();
    uint32_t mr11_val = (1U << 0) | (((uint8_t)(dca_val) & 0x1FU) << 1);
    _mrw_register(ctx, 0x0BU, mr11_val);
    ctx->train_result.duty_cycle_val = dca_val;
    ddr5_delay_cycles((uint32_t)(8U));
}

/* ── State: CRC configuration ─────────────────────────────────────────────── */

static void _state_crc_config(ddr5_init_context_t *ctx)
{
    /* MR21: Write CRC = CRC-8, MR22: Read CRC = CRC-8 */
    uint32_t mr21_val = (((uint8_t)(1) & 0x03U) << 0); /* CRC-8 on writes */
    uint32_t mr22_val = (((uint8_t)(1) & 0x03U) << 0); /* CRC-8 on reads */
    _mrw_register(ctx, 0x15U, mr21_val);
    _mrw_register(ctx, 0x16U, mr22_val);
}

/* ── State: MR verification via MRR ───────────────────────────────────────── */

static _Bool _state_mr_verify(ddr5_init_context_t *ctx)
{
    /* Verify all configured MRs from 0–22 by reading back via MRR */
    for (uint8_t mr = 0x00U; mr <= 0x16U; mr++) {
        /* Send MRR command */
        ddr5_delay_cycles((uint32_t)(8U));

        /* Read back MR value via MRR */
        uint32_t readback = ddr5_mr_read(mr);

        /* Verify against the value we wrote */
        if (readback != ctx->mr_configs[mr]) {
            /* MR mismatch — log error but continue verification */
            ctx->error_count++;
            /* MR verification failure may indicate:
             *   - Incorrect MRW command sequence
             *   - DIMM did not latch the configuration
             *   - Timing violation before MRR (tMRD too short)
             */

            /* Only retry if within error budget */
            if (ctx->error_count >= ctx->error_max) {
                return 0; /* Too many errors — abort */
            }

            /* Retry MRW + MRR for this register */
            /* [BUG: retry re-writes to DDR_CTRL_MR_OP but does not wait tMRD again] */
            ddr5_write_reg((0x40000000UL + 0x0004U), mr);
            ddr5_write_reg((0x40000000UL + 0x0008U), ctx->mr_configs[mr]);
            ddr5_write_reg((0x40000000UL + 0x000CU), (0x00U));
        }
    }
    return 1;
}

/* ── Helper: MRW write with timing barrier ────────────────────────────────── */

static _Bool _mrw_register(ddr5_init_context_t *ctx, uint8_t mr, uint32_t value)
{
    /* Write MR data to controller registers */
    ddr5_write_reg((0x40000000UL + 0x0004U), mr);
    ddr5_write_reg((0x40000000UL + 0x0008U), value);
    ddr5_write_reg((0x40000000UL + 0x000CU), (0x00U)); /* Trigger MRW */

    /* Wait tMRD before next MRW/MRR (JESD79-5C §5.2.17) */
    ddr5_delay_cycles((uint32_t)(8U));

    ctx->mr_configs[mr] = value;
    return 1;
}
