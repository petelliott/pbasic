OUTPUT_FORMAT("binary")

SECTIONS
{
    . = 0x400000;
    .bss : { *(.bss) }
    . = 0x400000;
    .text : {
          KEEP(*(.elf))
          *(.text)
    }
    .data : { *(.data) }
    _end = .; PROVIDE (end = .);

    /DISCARD/ : {
        *(.note.gnu.property)
    }
}
