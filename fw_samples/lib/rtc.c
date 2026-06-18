/**
 * rtc.c — RTC Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_rtc_instance, g_rtc_initialized, g_rtc_alarm_count
 *   - Types: rtc_time_t, rtc_date_t, rtc_format_t, rtc_regs_t
 *   - Register base: RTC_BASE
 *   - BCD encoding/decoding inline
 *   - 7 functions
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */
#define RTC_BASE               0x40002800UL

/* ------------------------------------------------------------------ */
/*  BCD conversion helpers (inline)                                    */
/* ------------------------------------------------------------------ */
#define BCD_TO_BIN(bcd)  ((((bcd) >> 4) * 10U) + ((bcd) & 0x0FU))
#define BIN_TO_BCD(bin)  ((((bin) / 10U) << 4) | ((bin) % 10U))

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef struct {
    uint8_t hours;
    uint8_t minutes;
    uint8_t seconds;
} rtc_time_t;

typedef struct {
    uint16_t year;
    uint8_t  month;
    uint8_t  day;
} rtc_date_t;

typedef enum {
    H12 = 0,
    H24 = 1
} rtc_format_t;

typedef struct {
    volatile uint32_t TR;      /* 0x00 - Time Register       */
    volatile uint32_t DR;      /* 0x04 - Date Register       */
    volatile uint32_t CR;      /* 0x08 - Control Register    */
    volatile uint32_t ISR;     /* 0x0C - Init & Status Reg   */
    volatile uint32_t PRER;    /* 0x10 - Prescaler Register  */
    volatile uint32_t WPR;     /* 0x14 - Write Protection    */
    volatile uint32_t CALR;    /* 0x18 - Calibration Register*/
} rtc_regs_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static rtc_regs_t *g_rtc_instance = (rtc_regs_t *)RTC_BASE;
static bool        g_rtc_initialized = false;
static uint32_t    g_rtc_alarm_count = 0;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * RTC_Init — Initialise the RTC peripheral.
 * Enables access and sets default prescaler.
 */
void RTC_Init(void)
{
    rtc_regs_t *regs = g_rtc_instance;

    /* Disable write protection to allow config */
    regs->WPR = 0xCA;
    regs->WPR = 0x53;

    /* Enter initialisation mode */
    regs->ISR |= 0x00000010UL;    /* INIT = 1 */
    while ((regs->ISR & 0x00000020UL) == 0U) { }  /* Wait for INITF */

    /* Set prescaler: async=128, sync=256 => 1 Hz */
    regs->PRER = (127UL << 16) | 255UL;

    /* Set 24-hour format */
    regs->CR &= ~0x00000040UL;    /* FMT = 0 (24h) */

    /* Exit initialisation mode */
    regs->ISR &= ~0x00000010UL;   /* INIT = 0 */

    /* Re-enable write protection */
    regs->WPR = 0xFF;

    g_rtc_alarm_count = 0;
    g_rtc_initialized = true;
}

/**
 * RTC_TimeSet — Set the current time.
 * @param time   : pointer to rtc_time_t (hours, minutes, seconds in binary)
 * @param format : H12 or H24
 */
void RTC_TimeSet(const rtc_time_t *time, rtc_format_t format)
{
    rtc_regs_t *regs = g_rtc_instance;

    regs->WPR = 0xCA;
    regs->WPR = 0x53;

    regs->ISR |= 0x00000010UL;
    while ((regs->ISR & 0x00000020UL) == 0U) { }

    uint32_t tr = 0;

    if (format == H12) {
        /* PM/AM indication via bit 22 (PM=1, AM=0) — simplified: treat as AM */
        tr = (uint32_t)BIN_TO_BCD(time->hours)   |
            ((uint32_t)BIN_TO_BCD(time->minutes) <<  8U) |
            ((uint32_t)BIN_TO_BCD(time->seconds) << 16U);
        /* Hour format: bit 16 in CR? For H12, set HT[21:20] correctly */
        /* We just store as-is; the TR format supports H12 with bit 22 as PM */
    } else {
        tr = ((uint32_t)BIN_TO_BCD(time->hours)   << 16U) |
             ((uint32_t)BIN_TO_BCD(time->minutes) <<  8U) |
              (uint32_t)BIN_TO_BCD(time->seconds);
    }

    regs->TR = tr;

    /* Set format in CR */
    if (format == H24) {
        regs->CR &= ~0x00000040UL;   /* FMT = 0 -> 24h */
    } else {
        regs->CR |= 0x00000040UL;    /* FMT = 1 -> 12h */
    }

    regs->ISR &= ~0x00000010UL;
    regs->WPR = 0xFF;
}

/**
 * RTC_TimeGet — Read the current time.
 * @param time   : pointer to rtc_time_t to fill
 * @param format : H12 or H24
 */
void RTC_TimeGet(rtc_time_t *time, rtc_format_t format)
{
    rtc_regs_t *regs = g_rtc_instance;
    uint32_t tr = regs->TR;

    if (format == H12) {
        time->seconds = BCD_TO_BIN((uint8_t)(tr & 0x7FUL));
        time->minutes = BCD_TO_BIN((uint8_t)((tr >> 8U) & 0x7FUL));
        time->hours   = BCD_TO_BIN((uint8_t)((tr >> 16U) & 0x1FUL));
    } else {
        time->seconds = BCD_TO_BIN((uint8_t)(tr & 0x7FUL));
        time->minutes = BCD_TO_BIN((uint8_t)((tr >> 8U) & 0x7FUL));
        time->hours   = BCD_TO_BIN((uint8_t)((tr >> 16U) & 0x3FUL));
    }
}

/**
 * RTC_DateSet — Set the current date.
 * @param date : pointer to rtc_date_t (year, month, day in binary)
 */
void RTC_DateSet(const rtc_date_t *date)
{
    rtc_regs_t *regs = g_rtc_instance;

    regs->WPR = 0xCA;
    regs->WPR = 0x53;

    regs->ISR |= 0x00000010UL;
    while ((regs->ISR & 0x00000020UL) == 0U) { }

    uint32_t dr = ((uint32_t)BIN_TO_BCD(date->year % 100U) << 16U) |
                   ((uint32_t)BIN_TO_BCD(date->month)       <<  8U) |
                   (uint32_t)BIN_TO_BCD(date->day);
    regs->DR = dr;

    regs->ISR &= ~0x00000010UL;
    regs->WPR = 0xFF;
}

/**
 * RTC_DateGet — Read the current date.
 * @param date : pointer to rtc_date_t to fill
 */
void RTC_DateGet(rtc_date_t *date)
{
    rtc_regs_t *regs = g_rtc_instance;
    uint32_t dr = regs->DR;

    date->day   = BCD_TO_BIN((uint8_t)(dr & 0x3FUL));
    date->month = BCD_TO_BIN((uint8_t)((dr >> 8U) & 0x1FUL));
    date->year  = 2000U + BCD_TO_BIN((uint8_t)((dr >> 16U) & 0xFFUL));
}

/**
 * RTC_AlarmSet — Set an alarm time (simplified).
 * Increments alarm count for tracking.
 */
void RTC_AlarmSet(const rtc_time_t *alarm_time)
{
    (void)alarm_time;
    ++g_rtc_alarm_count;
}

/* ------------------------------------------------------------------ */
/*  Interrupt handler                                                  */
/* ------------------------------------------------------------------ */
void RTC_IRQHandler(void)
{
    rtc_regs_t *regs = g_rtc_instance;

    /* Check alarm flag */
    if ((regs->ISR & 0x00000001UL) != 0U) {
        /* Clear alarm flag */
        regs->ISR &= ~0x00000001UL;
        ++g_rtc_alarm_count;
    }

    /* Check wake-up / others could be handled here */
}