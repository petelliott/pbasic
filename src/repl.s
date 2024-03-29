/*
pbasic's repl
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
    .globl repl
    .globl repl_not_ok
    .globl statement_end
statement_end:
repl:
    .set input, %r12
    .set output, %r14

    cmpb $0, suppress_repl_output
    jne 0f
    mov $ok_str, %edi
    call write_string
0:
repl_not_ok:
    call read_line /* eax is a pointer to a line buffer that we can mess with */
    movb (%eax), %cl
    cmpb $0, %cl
    jne 0f
    ret /* return on eof */
0:
    mov %rax, input /* input line pointer */
    mov $exec_buffer, output /* output code pointer */
    mov output, %r13 /* set execution context */

parse_line_num:
    movb (input), %al
    isnotdig %al, process_tokens
    xor %r13, %r13 /* zero the exec context to signal that we are adding a line */
    mov %r15, output /* set output code pointer to heap end */
    mov input, %rdi
    call atoi /* eax = line number, edi preserved string pointer */
    mov %rdi, input
    movw %ax, (output)
    add $4, output /* allocate space for line number and nextptr */
    mov output, %rdi
    mov %eax, %esi
    call insert_line

process_tokens:
    mov input, %rdi
    mov output, %rsi
    call tokenize
    .set input, %edi
    .set output, %esi
    .set outputq, %rsi

run_command:
    movb $token_eof, (output) /* terminate line */
    inc output
    test %r13, %r13
    jz 0f /* no command to be run (in line mode) */
    set_nextline $0, %r13
    jmp exec_line
0:
    mov outputq, %r15 /* skip the heap we've allocated */
    jmp repl_not_ok
    /* END repl (no ret because the repl doesn't return) */


    .globl tokenize
tokenize: /* edi: input string, %esi: output token string */
    .set input, %r12
    .set output, %r14

    push input
    push output
    mov %rdi, input
    mov %rsi, output
token_loop:
    /* handle eof */
    movb (input), %al
    cmpb $0, %al
    jne 0f
tokenize_return:
    mov input, %rdi
    mov output, %rsi
    pop output
    pop input
    ret
0:

whitespace_case:
    cmpb $' ', %al
    je 0f
    cmpb $'\n', %al
    jne 1f
0:
    inc input
    jmp token_loop
1:

number_case:
    isnotdig %al, 0f
    mov input, %rdi
    call atoi /* eax = line number */
    mov %rdi, input
    movb $token_num, (output)
    inc output
    mov %eax, (output)
    add $4, output
    jmp token_loop
0:

string_case:
    cmpb $'\"', %al
    jne 2f
    movb $token_str, (output) /* emit the str byte */
    inc output
0:
    inc input
    movb (input), %al /* read a byte */
    cmpb $0, %al
    error je, SN
    cmpb $'\"', %al
    je 1f
    movb %al, (output) /* emit the str byte */
    inc output
    jmp 0b
1:
    inc input
    movb $0, (output)
    inc output
    jmp token_loop
2:

word_case:
    xor %ecx, %ecx
    dec %ecx /* current statement index -1 */
0:
    inc %ecx
    cmp $word_table_length, %ecx
    je 3f
    mov input, %rdi              /* rdi=mutable string ptr for compare */
    ldaddr_tbl word_table, %ecx, si /* load extended address into esi */
    /* string compare */
1:
    xor %eax, %eax
    movb (%esi), %al
    cmpb $0, %al
    je 2f
    cmpb %al, (%edi)
    jne 0b
    inc %esi
    inc %edi
    jmp 1b
2:
    movb %cl, (output) /* emit encoded byte */
    inc output
    mov %rdi, input
    cmpb $word_rem, %cl
    jne token_loop
    /* special case tokenizing for rem */
    movb $token_str, (output)
    inc output
4:
    movb (input), %al
    inc input
    movb %al, (output)
    inc output
    cmpb $0, %al
    jne 4b
    jmp tokenize_return
    /* end rem special case */
3:

symbol_case:
    movb (input), %al
    /* whitespace is already handled */
    mov $1f, %edi
    mov $0f, %esi
    jmp jmp_alphanum
0:
    inc input
    movb %al, (output) /* emit symbols directly */
    inc output
    jmp token_loop
1:

var_case:
    mov $var_head, %ecx /* ecx holds pointer to the next var */
    /* check if var is already interned */
check_intern_loop:
    ldaddr (%ecx), dx
    test %dx, %dx
    jz create_variable /* intern variable */
    mov %edx, %ecx
    add $6, %edx /* edx is the pointer to the interned var string */
    mov input, %r8 /* r8 is the pointer to the new var string */
varname_strcmp:
    movb (%edx), %ah
    movb (%r8), %al
    inc %r8
    inc %edx
    cmpb %al, %ah
    je varname_strcmp
    cmpb $0, %ah
    jne check_intern_loop
    mov $check_intern_loop, %edi /* target if al is alphanum */
    mov $var_defined, %esi /* target otherwise */
    jmp jmp_alphanum

create_variable: /* variable hasn't already been defined, create it */
    test %r13, %r13
    jnz command_mode_create_variable /* no command to be run (in line mode) */
    movb $token_var_intern, (output)
    inc output
    mov output, %rdi
    call push_var_entry
    mov %rdi, output
    jmp token_loop

command_mode_create_variable: /* variable hasn't been defined, but we are in command mode, so allocate a variable slot on the heap */
    mov %r15, %rdi
    call push_var_entry
    mov %rdi, %r15
    mov input, %r8
    inc %r8 /* setup a fake %r8 */
    /* fall through to variable defined case */
var_defined: /* variable has already been defined */
    dec %r8
    mov %r8, input /* set linebuffer to new value */
    movb $token_var, (output)
    add $2, %cx /* move pointer to variable */
    movw %cx, 1(output)
    add $3, output
    jmp token_loop


push_var_entry:  /* edi=destination to write entry, inherits ecx, input, output */
    mov %di, (%ecx)
    mov %edi, %ecx
    xor %eax, %eax
    movw %ax, (%edi) /* add next link */
    movl %eax, 2(%edi) /* add variable content */
    add $6, %edi
    mov %rdi, %r9
0:
    movb (input), %al
    mov $1f, %edi
    mov $2f, %esi
    jmp jmp_alphanum
1:
    movb %al, (%r9)
    inc input
    inc %r9
    jmp 0b
2:
    mov %r9, %rdi
    movb $0, (%edi) /* nul terminate the var string */
    inc %edi
    ret



jmp_alphanum: /* edi=jump target true alphanum, esi=jump target false */
    cmpb $'0', %al
    jl 1f
    cmpb $'9', %al
    jle 0f
    or $0x20, %al /* remove clear lowercase bit */
    cmpb $'a', %al
    jl 1f
    cmpb $'z', %al
    jle 0f
1:
    jmp *%rsi
0:
    jmp *%rdi

    .data
ok_str: .asciz "\n OK\n"
