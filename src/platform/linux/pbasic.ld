OUTPUT_FORMAT("binary")

SECTIONS
{
    . = 0x400000;
    .text : {
          KEEP(*(.elf))
          *(.text)
    }
    .data : { *(.data) }
    .bss : { *(.bss) }
    _end = .; PROVIDE (end = .);

    /DISCARD/ : {
        *(.note.gnu.property)
    }
}
