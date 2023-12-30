/*
pbasic error handling routines
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

    .include "macros.s"

    .text
    .globl error_handler
error_handler: /* error_handler(errorcode: %edi) */
    mov $(page_start + 4096), %esp /* reset the stack */
    movb $0, suppress_repl_output
    xor %eax, %eax
    movl %eax, read_fd
    inc %eax
    movl %eax, write_fd

    push %rdi
    call newline
    mov $' ', %dil
    call write_char
    mov %esp, %edi
    call write_string
    pop %rdi
    mov $error_str, %edi
    call write_string
    cmp $end, %r13
    jl 0f
    /* we are in a line, so print the line number */
    mov $in_str, %edi
    call write_string
    xor %edi, %edi
    get_linenumber %r13, %di
    call write_uint
0:
    call newline
    jmp repl_not_ok /* resume the repl */


    .data
error_str:  .asciz " ERROR"
in_str:     .asciz " IN "

    .macro error_code name,c1,c2
    .globl \name
    .set \name, \c1 | (\c2 << 8)
    .endm

    error_code OM, 'O, 'M
    error_code SN, 'S, 'N
    error_code US, 'U, 'S
    error_code ID, 'I, 'D
