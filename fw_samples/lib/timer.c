/**
 * timer.c — Timer/PWM Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_tim_instances[2], g_timer_state[2], g_timer_initialized
 *   - Types: timer_id_t, timer_mode_t, timer_oc_mode_t, timer_regs_t
 *   - Register base: TIM0_BASE / TIM1_BASE
 *   - 8 functions
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */
#define TIM0_BASE              0x40010000UL
#define TIM1_BASE              0x40010400UL

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    TIM0 = 0,
    TIM1 = 1
} timer_id_t;

typedef enum {
    UP     = 0,
    DOWN   = 1,
    CENTER = 2
} timer_mode_t;

typedef enum {
    OC_FROZEN  = 0,
    OC_TOGGLE  = 1,
    OC_PWM1    = 2,
    OC_PWM2    = 3
} timer_oc_mode_t;

typedef struct {
    volatile uint32_t CR1;       /* 0x00 */
    volatile uint32_t CR2;       /* 0x04 */
    volatile uint32_t DIER;      /* 0x08 */
    volatile uint32_t SR;        /* 0x0C */
    volatile uint32_t CCMR1;     /* 0x10 */
    volatile uint32_t CCER;      /* 0x14 */
    volatile uint32_t CNT;       /* 0x18 */
    volatile uint32_t PSC;       /* 0x1C */
    volatile uint32_t ARR;       /* 0x20 */
    volatile uint32_t CCR[4];    /* 0x24 - 0x30 */
} timer_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static timer_regs_t *g_tim_instances[2] = {
    (timer_regs_t *)TIM0_BASE,
    (timer_regs_t *)TIM1_BASE
};

typedef struct {
    uint32_t counter_value;
    uint32_t compare_values[4];
} timer_state_t;

static timer_state_t g_timer_state[2];
static bool          g_timer_initialized = false;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * TIM_Init — Configure timer mode and prescaler.
 * @param id    : TIM0 or TIM1
 * @param mode  : UP, DOWN, CENTER
 * @param prescaler : prescaler divider (PSC register value)
 * @param period    : auto-reload value (ARR)
 */
void TIM_Init(timer_id_t id, timer_mode_t mode, uint32_t prescaler, uint32_t period)
{
    timer_regs_t *regs = g_tim_instances[id];

    /* Disable timer while configuring */
    regs->CR1 = 0;

    /* Set direction / centre-aligned mode */
    uint32_t cr1_val = 0;
    switch (mode) {
        case DOWN:
            cr1_val |= 0x00000010UL;   /* DIR = 1 */
            break;
        case CENTER:
            cr1_val |= 0x00000060UL;   /* CMS = 0b11 */
            break;
        default: /* UP */
            break;
    }
    regs->CR1 = cr1_val;

    regs->PSC = prescaler;
    regs->ARR = period;
    regs->CNT = 0;
    regs->SR  = 0;

    /* Clear compare states */
    for (int i = 0; i < 4; ++i) {
        g_timer_state[id].compare_values[i] = 0;
    }
    g_timer_state[id].counter_value = 0;
    g_timer_initialized = true;
}

/**
 * TIM_PWMConfig — Configure a PWM output on a given channel.
 * @param id       : TIM0 or TIM1
 * @param channel  : 0..3 (CCR index)
 * @param oc_mode  : OC_PWM1 or OC_PWM2
 * @param pulse    : compare value (duty cycle)
 */
void TIM_PWMConfig(timer_id_t id, uint32_t channel, timer_oc_mode_t oc_mode, uint32_t pulse)
{
    timer_regs_t *regs = g_tim_instances[id];

    if (channel > 3) return;

    /* CCMR1 handles ch0-1 (bits 0-7 for ch0, 8-15 for ch1) */
    /* CCMR2 handles ch2-3 — not defined in struct, use CCMR1 for both for simplicity */
    /* Real implementation would need CCMR2; we reuse CCMR1 for ch2-3 */
    if (channel < 2) {
        uint32_t shift = channel * 8U;
        regs->CCMR1 &= ~(0x07UL << shift);   /* clear OCxM bits */
        regs->CCMR1 |= ((uint32_t)(oc_mode & 0x07U) << shift);
    } else {
        /* For channels 2, 3 we treat CCMR1 upper half as CCMR2 proxy */
        uint32_t shift = ((channel - 2U) * 8U) + 16U;
        regs->CCMR1 &= ~(0x07UL << shift);
        regs->CCMR1 |= ((uint32_t)(oc_mode & 0x07U) << shift);
    }

    /* Enable output (CCxE bit) */
    regs->CCER |= (1UL << (channel * 4U));

    /* Set compare value */
    regs->CCR[channel] = pulse;
    g_timer_state[id].compare_values[channel] = pulse;
}

/**
 * TIM_Start — Enable (start) the timer counter.
 */
void TIM_Start(timer_id_t id)
{
    timer_regs_t *regs = g_tim_instances[id];
    regs->CR1 |= 0x00000001UL;   /* CEN = 1 */
}

/**
 * TIM_Stop — Disable (stop) the timer counter.
 */
void TIM_Stop(timer_id_t id)
{
    timer_regs_t *regs = g_tim_instances[id];
    regs->CR1 &= ~0x00000001UL;  /* CEN = 0 */
}

/**
 * TIM_CounterGet — Read current counter value.
 */
uint32_t TIM_CounterGet(timer_id_t id)
{
    timer_regs_t *regs = g_tim_instances[id];
    uint32_t val = regs->CNT;
    g_timer_state[id].counter_value = val;
    return val;
}

/**
 * TIM_IRQConfig — Enable/disable timer interrupts.
 * @param id        : TIM0 or TIM1
 * @param irq_mask  : bitmask of DIER bits (UIE=bit0, CC1IE=bit1, etc.)
 * @param enable    : true to enable, false to disable
 */
void TIM_IRQConfig(timer_id_t id, uint32_t irq_mask, bool enable)
{
    timer_regs_t *regs = g_tim_instances[id];
    if (enable) {
        regs->DIER |= irq_mask;
    } else {
        regs->DIER &= ~irq_mask;
    }
}

/* ------------------------------------------------------------------ */
/*  Interrupt handlers                                                 */
/* ------------------------------------------------------------------ */
void TIM0_IRQHandler(void)
{
    timer_regs_t *regs = g_tim_instances[TIM0];
    uint32_t flags = regs->SR;

    /* Clear update event flag */
    if ((flags & 0x01UL) != 0U) {
        regs->SR &= ~0x01UL;
    }
    /* Clear capture/compare flags */
    if ((flags & 0x1EUL) != 0U) {
        regs->SR &= ~0x1EUL;
    }
}

void TIM1_IRQHandler(void)
{
    timer_regs_t *regs = g_tim_instances[TIM1];
    uint32_t flags = regs->SR;

    if ((flags & 0x01UL) != 0U) {
        regs->SR &= ~0x01UL;
    }
    if ((flags & 0x1EUL) != 0U) {
        regs->SR &= ~0x1EUL;
    }
}