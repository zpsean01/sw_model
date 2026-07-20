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

#include <stdint.h>
#include <stdbool.h>
#include "ddr5_regs.h"
#include "ddr5_cmds.h"
#include "ddr5_timing.h"
#include "ddr5_training.h"

/* ── Platform abstraction ────────────────────────────────────────────────── */

extern void     ddr5_delay_cycles(uint32_t cycles);
extern void     ddr5_ca_bus_send(uint16_t cmd, uint32_t addr);
extern uint32_t ddr5_mr_read(uint8_t mr_addr);
extern void     ddr5_mr_write(uint8_t mr_addr, uint32_t data);
extern void     ddr5_set_cke(uint8_t state);
extern void     ddr5_set_reset_n(uint8_t state);
extern uint32_t ddr5_read_reg(uint32_t addr);
extern void     ddr5_write_reg(uint32_t addr, uint32_t val);

/* ── Training timeout (in cycles) ─────────────────────────────────────────── */
#define TRAIN_TIMEOUT_CYCLES    (DDR5_TZQINIT_CYCLES * 10U)
#define TRAIN_RETRY_MAX         3U

/* ── Initialization context ──────────────────────────────────────────────── */

typedef struct {
    ddr5_init_state_t   current_state;
    ddr5_speed_bin_t    speed_bin;
    uint8_t             mr_configs[256];        /* written MR values for verification */
    ddr5_training_result_t train_result;
    uint8_t             error_count;
    uint8_t             error_max;
} ddr5_init_context_t;

/* ── Forward declarations ────────────────────────────────────────────────── */

static void     _state_mr_config(ddr5_init_context_t *ctx);
static void     _state_vref_train(ddr5_init_context_t *ctx);
static void     _state_zq_calib(ddr5_init_context_t *ctx);
static void     _state_dq_train(ddr5_init_context_t *ctx);
static void     _state_ca_train(ddr5_init_context_t *ctx);
static void     _state_dca_train(ddr5_init_context_t *ctx);
static void     _state_crc_config(ddr5_init_context_t *ctx);
static bool     _state_mr_verify(ddr5_init_context_t *ctx);
static bool     _mrw_register(ddr5_init_context_t *ctx, uint8_t mr, uint32_t value);

/* ── Main initialization entry ───────────────────────────────────────────── */

ddr5_init_state_t ddr5_initialize(ddr5_speed_bin_t speed_bin)
{
    ddr5_init_context_t ctx = {
        .current_state  = DDR5_STATE_RESET,
        .speed_bin      = speed_bin,
        .error_count    = 0,
        .error_max      = 3,
    };

    /* ── Phase 1: Power-up and RESET sequence (JESD79-5C §3.3.1) ─────────── */

    ctx.current_state = DDR5_STATE_RESET;

    /* VDD/VDDQ must be stable before RESET */
    ddr5_set_reset_n(0);                    /* Assert RESET low */
    ddr5_set_cke(0);                        /* CKE low during reset */
    DDR5_WAIT_CYCLES(1000000);              /* Wait for power stabilization (~1M cycles) */

    ddr5_set_reset_n(1);                    /* De-assert RESET */
    DDR5_WAIT_CYCLES(DDR5_TXPR_CYCLES);    /* Wait tXPR before CKE */

    ddr5_set_cke(1);                        /* CKE high — DIMM exits reset */
    DDR5_WAIT_CYCLES(DDR5_TDLLK_CYCLES);    /* Wait DLL lock */

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
    uint32_t mr0_val = DDR5_MR0_BL(0) | DDR5_MR0_DLL_EN
                     | DDR5_MR0_WR_LAT(6) | DDR5_MR0_RD_LAT(8);
    _mrw_register(ctx, DDR5_MR0, mr0_val);

    /* MR1: RTT_NOM = RZQ/4 (40Ω), DQ drive = RZQ/7 (34Ω), CA drive = RZQ/7 */
    uint32_t mr1_val = DDR5_MR1_RTT_NOM(1) | DDR5_MR1_DQ_DRV_STR(1)
                     | DDR5_MR1_CA_DRV_STR(1);
    _mrw_register(ctx, DDR5_MR1, mr1_val);

    /* MR2: Vref DQ and CA training enable */
    uint32_t mr2_val = DDR5_MR2_VREF_DQ_TRAIN_EN | DDR5_MR2_VREF_CA_TRAIN_EN
                     | DDR5_MR2_VREF_DQ_RANGE(0) | DDR5_MR2_VREF_CA_RANGE(0);
    _mrw_register(ctx, DDR5_MR2, mr2_val);

    /* MR3: Enable parity and CRC on writes */
    uint32_t mr3_val = DDR5_MR3_CRC_EN_WR | DDR5_MR3_PARITY_EN;
    _mrw_register(ctx, DDR5_MR3, mr3_val);

    /* MR4: No PDA, connectivity test disabled */
    uint32_t mr4_val = 0;
    _mrw_register(ctx, DDR5_MR4, mr4_val);

    /* MR5: READ preamble = 1tCK, WRITE preamble = 1tCK, DFE enabled */
    uint32_t mr5_val = DDR5_MR5_RD_PREAMBLE(0) | DDR5_MR5_WR_PREAMBLE(0)
                     | DDR5_MR5_DFE_EN;
    _mrw_register(ctx, DDR5_MR5, mr5_val);
}

/* ── State: Vref training ────────────────────────────────────────────────── */

static void _state_vref_train(ddr5_init_context_t *ctx)
{
    uint8_t vref_dq = ddr5_train_vref_dq();
    uint8_t vref_ca = ddr5_train_vref_ca();

    /* Write training results to MR6 (Vref DQ) and MR7 (Vref CA) */
    uint32_t mr6_val = DDR5_MR6_VREF_DQ_VAL(vref_dq);
    uint32_t mr7_val = DDR5_MR7_VREF_CA_VAL(vref_ca);

    _mrw_register(ctx, DDR5_MR6, mr6_val);
    _mrw_register(ctx, DDR5_MR7, mr7_val);

    ctx->train_result.vref_dq_code = vref_dq;
    ctx->train_result.vref_ca_code = vref_ca;
}

/* ── State: ZQ calibration ────────────────────────────────────────────────── */

static void _state_zq_calib(ddr5_init_context_t *ctx)
{
    /* Issue ZQ Calibration Long command */
    DDR5_WAIT_CYCLES(DDR5_TRCD_CYCLES);    /* Wait tRCD before write */
    ddr5_ca_bus_send(CA_CMD_ZQ_CL, 0);     /* ZQ_CL command on CA bus */

    /* Wait for ZQ calibration to complete (tZQinit) */
    DDR5_WAIT_CYCLES(DDR5_TZQINIT_CYCLES);

    /* Check ZQ calibration status */
    uint32_t status = ddr5_read_reg(DDR_CTRL_ZQ_CTRL);
    if (!(status & ZQ_CALIB_DONE)) {
        ctx->error_count++;
        /* ZQ failure — attempt recovery via short calibration */
        ddr5_ca_bus_send(CA_CMD_ZQ_CS, 0);
        DDR5_WAIT_CYCLES(DDR5_TZQOPER_CYCLES);
    }
}

/* ── State: DQ training ──────────────────────────────────────────────────── */

static void _state_dq_train(ddr5_init_context_t *ctx)
{
    /* Configure DQ training patterns */
    uint32_t mr8_val = DDR5_MR8_DQ_PAT_A(0xA5A5U);
    uint32_t mr9_val = DDR5_MR9_DQ_PAT_B(0x5A5AU);

    _mrw_register(ctx, DDR5_MR8, mr8_val);
    _mrw_register(ctx, DDR5_MR9, mr9_val);

    ctx->train_result.dq_pattern_a = mr8_val;
    ctx->train_result.dq_pattern_b = mr9_val;

    DDR5_WAIT_CYCLES(DDR5_TMRD_CYCLES);
    ddr5_train_dq_write_leveling();
}

/* ── State: CA training ───────────────────────────────────────────────────── */

static void _state_ca_train(ddr5_init_context_t *ctx)
{
    uint32_t mr10_val = DDR5_MR10_CA_PAT(0x3CC3U);
    _mrw_register(ctx, DDR5_MR10, mr10_val);
    ctx->train_result.ca_pattern = mr10_val;
    DDR5_WAIT_CYCLES(DDR5_TMRD_CYCLES);
}

/* ── State: Duty cycle adjust training ────────────────────────────────────── */

static void _state_dca_train(ddr5_init_context_t *ctx)
{
    uint8_t dca_val = ddr5_train_duty_cycle();
    uint32_t mr11_val = DDR5_MR11_DCA_EN | DDR5_MR11_DCA_VAL(dca_val);
    _mrw_register(ctx, DDR5_MR11, mr11_val);
    ctx->train_result.duty_cycle_val = dca_val;
    DDR5_WAIT_CYCLES(DDR5_TMRD_CYCLES);
}

/* ── State: CRC configuration ─────────────────────────────────────────────── */

static void _state_crc_config(ddr5_init_context_t *ctx)
{
    /* MR21: Write CRC = CRC-8, MR22: Read CRC = CRC-8 */
    uint32_t mr21_val = DDR5_MR21_WCRC(1);   /* CRC-8 on writes */
    uint32_t mr22_val = DDR5_MR22_RCRC(1);   /* CRC-8 on reads */
    _mrw_register(ctx, DDR5_MR21, mr21_val);
    _mrw_register(ctx, DDR5_MR22, mr22_val);
}

/* ── State: MR verification via MRR ───────────────────────────────────────── */

static bool _state_mr_verify(ddr5_init_context_t *ctx)
{
    /* Verify all configured MRs from 0–22 by reading back via MRR */
    for (uint8_t mr = DDR5_MR0; mr <= DDR5_MR22; mr++) {
        /* Send MRR command */
        DDR5_WAIT_CYCLES(DDR5_TMRD_CYCLES);

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
                return false;           /* Too many errors — abort */
            }

            /* Retry MRW + MRR for this register */
            /* [BUG: retry re-writes to DDR_CTRL_MR_OP but does not wait tMRD again] */
            ddr5_write_reg(DDR_CTRL_MR_ADDR, mr);
            ddr5_write_reg(DDR_CTRL_MR_DATA, ctx->mr_configs[mr]);
            ddr5_write_reg(DDR_CTRL_MR_CMD, MR_CMD_MRW);
        }
    }
    return true;
}

/* ── Helper: MRW write with timing barrier ────────────────────────────────── */

static bool _mrw_register(ddr5_init_context_t *ctx, uint8_t mr, uint32_t value)
{
    /* Write MR data to controller registers */
    ddr5_write_reg(DDR_CTRL_MR_ADDR, mr);
    ddr5_write_reg(DDR_CTRL_MR_DATA, value);
    ddr5_write_reg(DDR_CTRL_MR_CMD, MR_CMD_MRW);   /* Trigger MRW */

    /* Wait tMRD before next MRW/MRR (JESD79-5C §5.2.17) */
    DDR5_WAIT_CYCLES(DDR5_TMRD_CYCLES);

    ctx->mr_configs[mr] = value;
    return true;
}