/*
the elf header of our executable. also reused for platform specific variables
Copyright (C) 2023 Peter Elliott

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

    .section .elf
    .globl page_start
    .globl line_buffer
    .globl line_buffer_len
page_start:
elf_header:
line_buffer: /* 80 byte line buffer */
    .byte 0x7f
    .ascii "ELF"
    .byte 2, 1, 1, 0 /* EI_CLASS, EI_DATA, EI_VERSION, EI_OSABI */
    /* can fuck with */
    .byte 0 /* EI_ABIVERSION */
    .zero 7 /* EI_PAD */
    /* can't fuck with */
    .2byte 0x02 /* e_type */
    .2byte 0x3e /* e_machine */
    .4byte 1 /* e_version */
    .8byte _start /* e_entry */
    .8byte 64 /* e_phoff */
    /* can fuck with */
    .8byte 0 /* e_shoff */
    .4byte 0 /* e_flags */
    .2byte 64 /* e_ehsize */
    /* can't fuck with */
    .2byte 56 /* e_phentsize */
    .2byte 1 /* e_phnum */
    .2byte 64 /* e_shentsize */
    .2byte 0 /* e_shentnum */
    .2byte 0 /* e_shstrndx */

elf_pht:
    .4byte 1 /* p_type=PT_LOAD */
    .4byte 7 /* p_flags=RWX */
    .8byte 0 /* p_offset */
line_buffer_len:
    .8byte elf_header /* p_vaddr */
tmp1:
    .8byte elf_header /* p_paddr */
tmp2:
    .8byte 4096 /* p_filesz */
tmp3:
    .8byte 4096 /* p_memsz */
tmp4:
    .8byte 4096 /* p_align */
elf_end:
