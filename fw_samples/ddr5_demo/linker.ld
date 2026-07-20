/**
 * Linker script for ARM Cortex-M33 (ARMv8-M) — simplified TF-M layout
 *
 * Memory layout:
 *   FLASH   (rx) : 0x10000000 - 0x1007FFFF  (512 KB)
 *   RAM     (rw) : 0x30000000 - 0x3003FFFF  (256 KB)
 *   STACK           : 0x30040000 - 0x30040FFF  (4 KB)
 */

MEMORY
{
    FLASH  (rx) : ORIGIN = 0x10000000, LENGTH = 512K
    RAM    (rw) : ORIGIN = 0x30000000, LENGTH = 256K
    STACK  (rw) : ORIGIN = 0x30040000, LENGTH = 4K
}

SECTIONS
{
    /* Interrupt vector table at the start of flash */
    .vectors :
    {
        . = ALIGN(4);
        KEEP(*(.vectors))
        . = ALIGN(4);
    } > FLASH

    /* Executable code */
    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text*)
        *(.glue_7)
        *(.glue_7t)
        *(.rodata)
        *(.rodata*)
        . = ALIGN(4);
    } > FLASH

    /* Initialization data (copied from FLASH to RAM at startup) */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > RAM AT > FLASH
    _sidata = LOADADDR(.data);

    /* Zero-initialized data */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM

    /* Heap — for dynamic allocation (if any) */
    .heap :
    {
        . = ALIGN(8);
        _heap_start = .;
        . = . + 32K;
        _heap_end = .;
    } > RAM

    /* Stack at the end of RAM */
    .stack :
    {
        . = ALIGN(8);
        _stack_start = .;
        . = . + 4K;
        _stack_end = .;
    } > STACK

    /* Discard unused sections */
    /DISCARD/ :
    {
        *(.ARM.exidx*)
        *(.ARM.attributes*)
        *(.comment)
        *(.note*)
    }
}