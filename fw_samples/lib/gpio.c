/**
 * gpio.c — GPIO Driver for ARM Cortex-M33
 *
 * Requirements:
 *   - Global variables: g_gpio_ports[2], g_gpio_initialized
 *   - Types: gpio_port_t, gpio_pin_t, gpio_mode_t, gpio_pull_t, gpio_regs_t
 *   - Register access via GPIOA_BASE / GPIOB_BASE (volatile pointer)
 *   - 7 public functions + 1 ISR placeholder
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  Peripheral memory-map definitions                                  */
/* ------------------------------------------------------------------ */
#define GPIOA_BASE             0x40020000UL
#define GPIOB_BASE             0x40020400UL

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    PORTA = 0,
    PORTB = 1
} gpio_port_t;

typedef uint16_t gpio_pin_t;

typedef enum {
    INPUT   = 0,
    OUTPUT  = 1,
    AF      = 2,
    ANALOG  = 3
} gpio_mode_t;

typedef enum {
    NOPULL   = 0,
    PULLUP   = 1,
    PULLDOWN = 2
} gpio_pull_t;

typedef struct {
    volatile uint32_t MODER;      /* 0x00 */
    volatile uint32_t OTYPER;     /* 0x04 */
    volatile uint32_t OSPEEDR;    /* 0x08 */
    volatile uint32_t PUPDR;      /* 0x0C */
    volatile uint32_t IDR;        /* 0x10 */
    volatile uint32_t ODR;        /* 0x14 */
    volatile uint32_t BSRR;       /* 0x18 */
    volatile uint32_t AFR[2];     /* 0x1C - 0x20 */
} gpio_regs_t;                    /* total size = 0x28 */

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static gpio_regs_t *g_gpio_ports[2] = {
    (gpio_regs_t *)GPIOA_BASE,
    (gpio_regs_t *)GPIOB_BASE
};
static bool g_gpio_initialized = false;

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * GPIO_Init — Configure a GPIO pin mode and pull setting.
 * @param port  : port index (PORTA or PORTB)
 * @param pin   : pin bitmask (bit0=pin0 … bit15=pin15)
 * @param mode  : INPUT, OUTPUT, AF, ANALOG
 * @param pull  : NOPULL, PULLUP, PULLDOWN
 */
void GPIO_Init(gpio_port_t port, gpio_pin_t pin, gpio_mode_t mode, gpio_pull_t pull)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    uint32_t pos = 0;
    uint32_t bit = pin;

    /* Find the lowest set bit position (pin number 0-15) */
    while ((bit & 1U) == 0U) {
        bit >>= 1U;
        ++pos;
    }

    uint32_t shift = pos * 2U;

    /* MODER: 2 bits per pin */
    regs->MODER &= ~(3UL << shift);
    regs->MODER |= ((uint32_t)mode << shift);

    /* PUPDR: 2 bits per pin */
    regs->PUPDR &= ~(3UL << shift);
    regs->PUPDR |= ((uint32_t)pull << shift);
}

/**
 * GPIO_WritePin — Set or clear a single output pin.
 */
void GPIO_WritePin(gpio_port_t port, gpio_pin_t pin, bool state)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    if (state) {
        regs->BSRR = (uint32_t)pin;          /* set */
    } else {
        regs->BSRR = ((uint32_t)pin << 16U); /* reset */
    }
}

/**
 * GPIO_ReadPin — Read the input level of a pin.
 * @return true if pin is high, false otherwise.
 */
bool GPIO_ReadPin(gpio_port_t port, gpio_pin_t pin)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    return (regs->IDR & (uint32_t)pin) != 0U;
}

/**
 * GPIO_TogglePin — Toggle an output pin.
 */
void GPIO_TogglePin(gpio_port_t port, gpio_pin_t pin)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    regs->ODR ^= (uint32_t)pin;
}

/**
 * GPIO_WritePort — Write an entire 16-bit word to the output data register.
 */
void GPIO_WritePort(gpio_port_t port, uint16_t value)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    regs->ODR = (uint32_t)value;
}

/**
 * GPIO_ReadPort — Read the full 16-bit input data register.
 */
uint16_t GPIO_ReadPort(gpio_port_t port)
{
    gpio_regs_t *regs = g_gpio_ports[port];
    return (uint16_t)(regs->IDR & 0xFFFFUL);
}

/**
 * GPIO_SetAF — Configure alternate-function for a pin.
 * @param af: alternate-function number (0..15).
 */
void GPIO_SetAF(gpio_port_t port, gpio_pin_t pin, uint8_t af)
{
    gpio_regs_t *regs = g_gpio_ports[port];

    uint32_t pos = 0;
    uint32_t bit = pin;
    while ((bit & 1U) == 0U) {
        bit >>= 1U;
        ++pos;
    }

    uint32_t idx   = (pos < 8U) ? 0U : 1U;
    uint32_t shift = (pos % 8U) * 4U;

    regs->AFR[idx] &= ~(0xFUL << shift);
    regs->AFR[idx] |= ((uint32_t)(af & 0x0FU) << shift);
}

/* ------------------------------------------------------------------ */
/*  Interrupt handler (placeholder)                                    */
/* ------------------------------------------------------------------ */
void GPIOA_IRQHandler(void)
{
    /* Placeholder — application-defined behaviour should be added here */
}