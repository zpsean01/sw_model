/**
 * ddr5_training.h — DDR5 Training State Machine and Routines
 *
 * Defines the DDR5 initialization state machine and training procedures.
 * Reference: spec_model ddr5 extract → behavior_constraints → state_machines
 *            + scenarios → initialization scenario paths
 */

#ifndef DDR5_TRAINING_H
#define DDR5_TRAINING_H

#include <stdint.h>
#include "ddr5_regs.h"
#include "ddr5_timing.h"

/* ── DDR5 initialization state machine ──────────────────────────────────── */

typedef enum {
    DDR5_STATE_RESET            = 0,   /* RESET asserted, VDD/VDDQ stable */
    DDR5_STATE_CKE_HIGH         = 1,   /* CKE raised after RESET de-assert */
    DDR5_STATE_MR_CONFIG        = 2,   /* Configuring MR0–MR5 via MRW */
    DDR5_STATE_VREF_TRAIN       = 3,   /* Vref DQ and CA training (MR6-MR7) */
    DDR5_STATE_ZQ_CALIB         = 4,   /* ZQ calibration long */
    DDR5_STATE_DQ_TRAIN         = 5,   /* DQ training pattern A/B (MR8-MR9) */
    DDR5_STATE_CA_TRAIN         = 6,   /* CA training pattern (MR10) */
    DDR5_STATE_DCA_TRAIN        = 7,   /* Duty cycle adjust (MR11) */
    DDR5_STATE_CRC_CONFIG       = 8,   /* CRC configuration (MR21-MR22) */
    DDR5_STATE_MR_VERIFY        = 9,   /* MRR verification of all config MRs */
    DDR5_STATE_READY            = 10,  /* Normal operation */
    DDR5_STATE_ERROR            = 15,  /* Fatal initialization error */
} ddr5_init_state_t;

/* State transition table (JESD79-5C §3.3 — Initialization Procedure) */
static const char* ddr5_state_names[] = {
    [DDR5_STATE_RESET]      = "RESET",
    [DDR5_STATE_CKE_HIGH]   = "CKE_HIGH",
    [DDR5_STATE_MR_CONFIG]  = "MR_CONFIG",
    [DDR5_STATE_VREF_TRAIN] = "VREF_TRAIN",
    [DDR5_STATE_ZQ_CALIB]   = "ZQ_CALIB",
    [DDR5_STATE_DQ_TRAIN]   = "DQ_TRAIN",
    [DDR5_STATE_CA_TRAIN]   = "CA_TRAIN",
    [DDR5_STATE_DCA_TRAIN]  = "DCA_TRAIN",
    [DDR5_STATE_CRC_CONFIG] = "CRC_CONFIG",
    [DDR5_STATE_MR_VERIFY]  = "MR_VERIFY",
    [DDR5_STATE_READY]      = "READY",
    [DDR5_STATE_ERROR]      = "ERROR",
};

/* ── Vref training result structure ──────────────────────────────────────── */

typedef struct {
    uint8_t  vref_dq_code;     /* MR6 value — Vref DQ training result */
    uint8_t  vref_ca_code;     /* MR7 value — Vref CA training result */
    uint8_t  duty_cycle_val;   /* MR11 value — duty cycle adjust value */
    uint32_t dq_pattern_a;     /* MR8 value — DQ training pattern A */
    uint32_t dq_pattern_b;     /* MR9 value — DQ training pattern B */
    uint32_t ca_pattern;       /* MR10 value — CA training pattern */
    uint8_t  training_pass;    /* 1 = all training passed, 0 = failed */
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

#endif /* DDR5_TRAINING_H */