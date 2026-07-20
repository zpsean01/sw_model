/**
 * board.c — Board Initialisation
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>
#include <stdbool.h>

/* ---------------------------------------------------------------------------
 * Register definitions
 * --------------------------------------------------------------------------- */
#define RCC_AHBENR (*(volatile uint32_t *)0x40023814UL)

/* GPIO register map base (example: GPIOA) */
#define GPIOA_BASE    0x40020000UL
#define GPIO_MODER    (*(volatile uint32_t *)(GPIOA_BASE + 0x00UL))
#define GPIO_ODR      (*(volatile uint32_t *)(GPIOA_BASE + 0x14UL))
#define GPIO_BSRR     (*(volatile uint32_t *)(GPIOA_BASE + 0x18UL))

/* Enable bit for GPIOA in AHBENR */
#define RCC_AHBENR_GPIOA_EN (1u << 0)

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */
typedef enum
{
    BOARD_REV_A = 0,
    BOARD_REV_B = 1,
    BOARD_REV_C = 2
} board_id_t;

typedef struct
{
    board_id_t rev;
    uint8_t    serial[16];
    uint32_t   hw_version;
} board_info_t;

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static board_info_t g_board_info;
static bool         g_led_initialized = false;
static uint16_t     g_led_pin        = 5u;  /* GPIOA pin 5 */

/* ---------------------------------------------------------------------------
 * External interface declarations (provided by lower-level drivers)
 * --------------------------------------------------------------------------- */
extern int32_t GPIO_Init(uint32_t port, uint32_t pin, uint32_t mode);
extern int32_t UART_Init(uint32_t instance, uint32_t baud);
extern int32_t SPI_Init(uint32_t instance, uint32_t speed);


/* ---------------------------------------------------------------------------
 * BOARD_Init — initialise board-level hardware
 * --------------------------------------------------------------------------- */
void BOARD_Init(void)
{
    /* Enable GPIOA clock */
    RCC_AHBENR |= RCC_AHBENR_GPIOA_EN;

    /* Initialise board info defaults */
    g_board_info.rev        = BOARD_REV_A;
    g_board_info.hw_version = 0x01000000u;

    for (uint32_t i = 0u; i < sizeof(g_board_info.serial); i++)
    {
        g_board_info.serial[i] = 0u;
    }

    /* Call peripheral init routines */
    (void)GPIO_Init(0u, g_led_pin, 1u);  /* output */
    (void)UART_Init(0u, 115200u);
    (void)SPI_Init(0u, 1000000u);
    /* I2C not implemented on this board variant */
}

/* ---------------------------------------------------------------------------
 * BOARD_GetInfo — fill user-supplied board_info_t
 * --------------------------------------------------------------------------- */
void BOARD_GetInfo(board_info_t *info)
{
    if (info != (board_info_t *)0)
    {
        *info = g_board_info;
    }
}

/* ---------------------------------------------------------------------------
 * BOARD_GetSerialNumber — copy serial number into buffer
 * --------------------------------------------------------------------------- */
void BOARD_GetSerialNumber(uint8_t *buf, uint32_t len)
{
    uint32_t copy_len = (len < sizeof(g_board_info.serial))
                            ? len
                            : sizeof(g_board_info.serial);

    for (uint32_t i = 0u; i < copy_len; i++)
    {
        buf[i] = g_board_info.serial[i];
    }
}

/* ---------------------------------------------------------------------------
 * BOARD_LEDInit — configure LED pin
 * --------------------------------------------------------------------------- */
void BOARD_LEDInit(uint16_t pin)
{
    g_led_pin         = pin;
    g_led_initialized = true;

    /* Enable GPIOA clock */
    RCC_AHBENR |= RCC_AHBENR_GPIOA_EN;

    /* Configure as general-purpose output (mode = 0x01) */
    GPIO_MODER = (GPIO_MODER & ~(0x03u << (pin * 2u))) | (0x01u << (pin * 2u));
}

/* ---------------------------------------------------------------------------
 * BOARD_LEDSet — turn LED on (state != 0) or off (state == 0)
 * --------------------------------------------------------------------------- */
void BOARD_LEDSet(uint8_t state)
{
    if (!g_led_initialized)
    {
        return;
    }

    if (state != 0u)
    {
        GPIO_BSRR = (1u << g_led_pin);            /* set bit */
    }
    else
    {
        GPIO_BSRR = (1u << (g_led_pin + 16u));    /* reset bit */
    }
}

/* ---------------------------------------------------------------------------
 * BOARD_Reset — trigger system reset
 * --------------------------------------------------------------------------- */
void BOARD_Reset(void)
{
    extern void SystemReset(void);
    SystemReset();
}

/* ---------------------------------------------------------------------------
 * BOARD_DelayMs — simple blocking delay
 * --------------------------------------------------------------------------- */
void BOARD_DelayMs(uint32_t ms)
{
    extern void SystemDelayMs(uint32_t);
    SystemDelayMs(ms);
}