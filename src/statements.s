/*
handlers for pbasic statements
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
    .globl statement_end
statement_end:
    jmp repl


    .globl statement_goto
statement_goto:
    jmp unsupported_statement


    .globl statement_gosub
statement_gosub:
    jmp unsupported_statement


    .globl statement_if
statement_if:
    jmp unsupported_statement


    .globl statement_input
statement_input:
    jmp unsupported_statement


    .globl statement_let
statement_let:
    jmp unsupported_statement


    .globl statement_print
statement_print:
    mov %edi, %ebx
    inc %ebx
0:
    movb (%ebx), %al
    inc %ebx
    cmpb $token_num, %al
    je print_num
    cmpb $token_str, %al
    je print_str
    cmpb $',', %al
    je print_comma
    cmpb $';', %al
    je print_semicolon
    cmpb $token_eof, %al
    je 1f
    error jmp, SN

print_num:
    movl (%ebx), %edi
    call write_int
    add $4, %ebx
    jmp 0b
print_str:
    mov %ebx, %edi
    call write_string
    mov %ebx, %edi
    call strlen
    add %eax, %ebx
    inc %ebx
    jmp 0b
print_comma:
    mov $'\t', %edi
    call write_char
    /* intentional fallthrough */
print_semicolon:
    /* special case for trailing newline */
    movb (%ebx), %al
    cmpb $token_eof, %al
    je 2f
    jmp 0b
1:
    call newline
2:
    jmp exec_next_line

    .globl statement_rem
statement_rem:
    jmp unsupported_statement


    .globl statement_return
statement_return:
    jmp unsupported_statement


    .globl statement_stop
statement_stop:
    jmp unsupported_statement


    .globl statement_clear
statement_clear:
    jmp unsupported_statement


    .globl statement_list
statement_list:
    jmp unsupported_statement


    .globl statement_run
statement_run:
    jmp unsupported_statement


    .globl statement_new
statement_new:
    jmp _start


    .globl statement_load
statement_load:
    jmp unsupported_statement


    .globl statement_save
statement_save:
    jmp unsupported_statement


    /* TODO: remove this once all statements are supported, or handle with the error mechanism */
unsupported_statement:
    mov $unsupported_string, %edi
    call write_string
    jmp exec_next_line

    .data
unsupported_string: .asciz "unsupported statement\n"
