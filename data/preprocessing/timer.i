# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\timer.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\timer.c" 2
/**
 * timer.c — Timer/PWM Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_tim_instances[2], g_timer_state[2], g_timer_initialized
 *   - Types: timer_id_t, timer_mode_t, timer_oc_mode_t, timer_regs_t
 *   - Register base: TIM0_BASE / TIM1_BASE
 *   - 8 functions
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
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\timer.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\timer.c" 2

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */



/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    TIM0 = 0,
    TIM1 = 1
} timer_id_t;

typedef enum {
    UP = 0,
    DOWN = 1,
    CENTER = 2
} timer_mode_t;

typedef enum {
    OC_FROZEN = 0,
    OC_TOGGLE = 1,
    OC_PWM1 = 2,
    OC_PWM2 = 3
} timer_oc_mode_t;

typedef struct {
    volatile uint32_t CR1; /* 0x00 */
    volatile uint32_t CR2; /* 0x04 */
    volatile uint32_t DIER; /* 0x08 */
    volatile uint32_t SR; /* 0x0C */
    volatile uint32_t CCMR1; /* 0x10 */
    volatile uint32_t CCER; /* 0x14 */
    volatile uint32_t CNT; /* 0x18 */
    volatile uint32_t PSC; /* 0x1C */
    volatile uint32_t ARR; /* 0x20 */
    volatile uint32_t CCR[4]; /* 0x24 - 0x30 */
} timer_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static timer_regs_t *g_tim_instances[2] = {
    (timer_regs_t *)0x40010000UL,
    (timer_regs_t *)0x40010400UL
};

typedef struct {
    uint32_t counter_value;
    uint32_t compare_values[4];
} timer_state_t;

static timer_state_t g_timer_state[2];
static _Bool g_timer_initialized = 0;

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
            cr1_val |= 0x00000010UL; /* DIR = 1 */
            break;
        case CENTER:
            cr1_val |= 0x00000060UL; /* CMS = 0b11 */
            break;
        default: /* UP */
            break;
    }
    regs->CR1 = cr1_val;

    regs->PSC = prescaler;
    regs->ARR = period;
    regs->CNT = 0;
    regs->SR = 0;

    /* Clear compare states */
    for (int i = 0; i < 4; ++i) {
        g_timer_state[id].compare_values[i] = 0;
    }
    g_timer_state[id].counter_value = 0;
    g_timer_initialized = 1;
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
        regs->CCMR1 &= ~(0x07UL << shift); /* clear OCxM bits */
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
    regs->CR1 |= 0x00000001UL; /* CEN = 1 */
}

/**
 * TIM_Stop — Disable (stop) the timer counter.
 */
void TIM_Stop(timer_id_t id)
{
    timer_regs_t *regs = g_tim_instances[id];
    regs->CR1 &= ~0x00000001UL; /* CEN = 0 */
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
void TIM_IRQConfig(timer_id_t id, uint32_t irq_mask, _Bool enable)
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
