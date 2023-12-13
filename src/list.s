/*
pbasic list function
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
    .globl list
list: /* no args */
    ldaddr code_head, ax
    mov %rax, %r10
list_line:
    cmpw $0, %ax
    jne 0f
    ret
0:
    xor %edi, %edi
    get_linenumber %r10, %di
    call write_uint
    call space

    mov %r10, %rbx
token_loop:
    xor %eax, %eax
    movb (%ebx), %al
    inc %ebx
    cmpb $word_table_length, %al
    jl word_case
    cmpb $token_num, %al
    je num_case
    cmpb $token_str, %al
    je str_case
    cmpb $token_var, %al
    je var_case
    cmpb $token_var_intern, %al
    je var_intern_case
    cmpb $token_eof, %al
    je eof_case
    /* intentional fallthrough */
letter_case:
    mov %eax, %edi
    call write_char
    jmp token_loop
word_case:
    ldaddr_tbl word_table, %eax, di
    call write_string
    call space
    jmp token_loop
num_case:
    movl (%ebx), %edi
    add $4, %ebx
    call write_int
    jmp token_loop
str_case:
    mov $'\"', %dil
    call write_char
    mov %ebx, %edi
    call write_string
    add %eax, %ebx
    inc %ebx        /* skip the string */

    mov $'\"', %dil
    call write_char
    jmp token_loop
var_case:
var_intern_case:
    call read_var
    mov %eax, %edi
    add $4, %edi
    call write_string
    jmp token_loop

eof_case:
    call newline
next:
    get_nextline %r10, ax
    mov %rax, %r10
    jmp list_line
