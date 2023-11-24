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
    inc %ebx
    cmpb $token_num, (%ebx)
    error jne, SN
    inc %ebx
    movl (%ebx), %ecx
    add $4, %ebx
    cmpb $token_eof, (%ebx)
    error jne, SN
    mov %ecx, %edi
    call get_line
    mov %rax, %r13
    jmp exec_line


    .globl statement_gosub
statement_gosub:
    jmp unsupported_statement


    .globl statement_if
statement_if:
    jmp unsupported_statement


    .globl statement_input
statement_input:
    cmp $end, %ebx
    error jl, ID /* can't use input as a direct */

    mov $'?', %edi
    call write_char

    call read_line
    mov %eax, %edi
    mov $exec_buffer, %esi
    call tokenize

    inc %ebx
    mov $exec_buffer, %edx /* edx=tokenized input */
0:
    movb (%ebx), %al
    cmpb $token_var, %al
    je 1f
    cmpb $token_var_intern, %al
    error jne, SN
1:
    inc %ebx
    call read_var /* eax=pointer to var */

    movb (%edx), %cl
    cmpb $token_num, %cl
    error jne, SN
    inc %edx
    movl (%edx), %ecx
    add $5, %edx /* skip the comma too */

    mov %ecx, (%eax) /* set the variable */

    inc %ebx /* skip potential comma */
    movb -1(%ebx), %al
    cmpb $',', %al
    je 0b
    cmpb $token_eof, %al
    error jne, SN
    jmp exec_next_line


    .globl statement_let
statement_let:
    inc %ebx
    movb (%ebx), %al
    cmpb $token_var, %al
    je 0f
    cmpb $token_var_intern, %al
    error jne, SN
0:
    inc %ebx
    call read_var /* eax is ptr to var */
    cmpb $'=', (%ebx)
    error jne, SN
    inc %ebx
    cmpb $token_num, (%ebx)
    error jne, SN
    movl 1(%ebx), %ecx
    movl %ecx, (%eax)
    jmp exec_next_line


    .globl statement_print
statement_print:
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
    cmpb $token_var_intern, %al
    je print_var
    cmpb $token_var, %al
    je print_var
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
print_var:
    call read_var
    mov (%eax), %edi
    call write_int
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
    call list
    jmp exec_next_line


    .globl statement_run
statement_run:
    ldaddr code_head, ax
    mov %rax, %r13
    jmp exec_line


    .globl statement_new
statement_new:
    jmp _start


    .globl statement_load
statement_load:
    jmp unsupported_statement


    .globl statement_save
statement_save:
    jmp unsupported_statement


    .globl read_var
read_var: /* %ebx=the line pointer+1, %al=the opcode, returns pointer to rvar in eax */
    cmpb $token_var_intern, %al
    je 0f
    /* var case */
    ldaddr (%ebx), ax
    add $2, %ebx
    ret
0:  /* intern case */
    lea 2(%ebx), %eax
    add $6, %ebx
1:
    mov (%ebx), %cl
    inc %ebx
    cmpb $0, %cl
    jne 1b
    ret


    /* TODO: remove this once all statements are supported, or handle with the error mechanism */
unsupported_statement:
    mov $unsupported_string, %edi
    call write_string
    jmp exec_next_line

    .data
unsupported_string: .asciz "unsupported statement\n"
