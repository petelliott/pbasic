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
// statement_end is just repl in repl.s
    .globl statement_end


    .globl statement_gosub
statement_gosub:
    pushw %bx
    // intentional fallthrough
    .globl statement_goto
statement_goto:
    inc %ebx
    cmpb $token_num, (%ebx)
    error jne, SN
internal_goto:
    inc %ebx
    movl (%ebx), %ecx
    add $4, %ebx
    call expect_eof
    mov %ecx, %edi
    call get_line
    jmp exec_line_rax


    .globl statement_if
statement_if:
    inc %ebx
    call do_expression
    test %eax, %eax
    jz exec_next_line /* do nothing if false */
    movb (%ebx), %al
    inc %ebx
    cmpb $word_goto, %al
    je internal_goto
    cmpb $word_then, %al
    error jne, SN
    movb (%ebx), %al
    cmpb $token_num, %al
    je internal_goto
    jmp exec_midline


    .globl statement_input
statement_input:
    cmp $end, %ebx
    error jl, ID /* can't use input as a direct */

    movb $'?', %dil
    call write_char

    call read_line
    mov %eax, %edi
    mov $exec_buffer, %esi
    call tokenize

    mov $exec_buffer, %edx /* edx=tokenized input */
0:
    inc %ebx
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

    movb (%ebx), %al
    cmpb $',', %al
    je 0b
    call expect_eof
    jmp nextline_target_0


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
    push %rax
    call do_expression
    pop %rcx
    mov %eax, (%ecx)
    call expect_eof
    jmp nextline_target_0
nextline_target_0:
    jmp exec_next_line


    .globl statement_print
statement_print:
    inc %ebx
0:
    movb (%ebx), %al
    cmpb $token_str, %al
    je print_str
    cmpb $',', %al
    je print_comma
    cmpb $';', %al
    je print_semicolon
    cmpb $token_eof, %al
    je 1f
print_expr:
    call do_expression
    mov %eax, %edi
    call write_int
    jmp 0b
print_num:
    inc %ebx
    movl (%ebx), %edi
    call write_int
    add $4, %ebx
    jmp 0b
print_str:
    inc %ebx
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
    inc %ebx
    /* special case for trailing newline */
    movb (%ebx), %al
    cmpb $token_eof, %al
    je 2f
    jmp 0b
1:
    call newline
2:
    jmp nextline_target_0


    .globl statement_rem
statement_rem:
    jmp nextline_target_0


    .globl statement_return
statement_return:
    mov $page_start, %r13
    popw %r13w
    jmp nextline_target_0


    .data
saved_r13:
    .4byte 0
    .text


    .globl statement_stop
statement_stop:
    movl %r13d, saved_r13
    jmp repl


    .globl statement_cont
statement_cont:
    xor %eax, %eax
    xchg %eax, saved_r13
    test %eax, %eax
    error jz, CN
    mov %eax, %r13d
    jmp nextline_target_1


    .globl statement_list
statement_list:
    call list
    jmp nextline_target_1


    .globl statement_run
statement_run:
    ldaddr code_head, ax
    jmp exec_line_rax


    .globl statement_new
statement_new:
    jmp _start


    .globl statement_load
statement_load:
    cmp $end, %ebx
    error jge, ID /* must use load as a direct */
    call setup_open
    xor %esi, %esi /* open for reading */
    call open
    movb $1, suppress_repl_output
    call repl
    movb $0, suppress_repl_output
    xor %edi, %edi /* close for reading */
    call close
    jmp repl


    .globl statement_save
statement_save:
    call setup_open
    mov $1, %esi /* open for writing */
    call open
    call list
    mov $1, %edi /* close for writing */
    call close
nextline_target_1:
    jmp exec_next_line

setup_open:
    inc %ebx
    movb (%ebx), %al
    cmpb $token_str, %al
    error jne, SN
    inc %ebx
    mov %ebx, %edi
    ret

expect_eof: /* takes current token in al, error if al=eof */
    cmpb $token_eof, (%ebx)
    error jne, SN
    ret
