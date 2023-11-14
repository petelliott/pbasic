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


    /* long running registers:
    %ebx = code target
    %r10 = line buffer position
    */
    .text
    .globl repl
    .globl repl_not_ok
repl:
    mov $ok_str, %rdi
    call write_string
repl_not_ok:
    call read_line /* eax is a pointer to a line buffer that we can mess with */
    mov $exec_buffer, %ebx  /* ebx is the address we will begin writing tokenized code */
    mov %rbx, %r13 /* set execution context */
    mov %rax, %r10 /* r10 holds the line buffer long term */
    /* TODO: handle line number here */
parse_line_num:

process_tokens:
    /* handle eof */
    movb (%r10), %al
    cmpb $0, %al
    je run_command

whitespace_case:
    cmpb $' ', %al
    je 0f
    cmpb $'\n', %al
    jne 1f
0:
    inc %r10
    jmp process_tokens
1:

number_case:
    isnotdig %al, 0f
    call repl_get_num
    movb $token_num, (%ebx)
    inc %ebx
    mov %eax, (%ebx)
    add $4, %ebx
    jmp process_tokens
0:

string_case:
    cmpb $'\"', %al
    jne 2f
    movb $token_str, (%ebx) /* emit the str byte */
    inc %ebx
0:
    inc %r10
    movb (%r10), %al /* read a byte */
    cmpb $0, %al
    error je, SN
    cmpb $'\"', %al
    je 1f
    movb %al, (%ebx) /* emit the str byte */
    inc %ebx
    jmp 0b
1:
    inc %r10
    movb $0, (%ebx)
    inc %ebx
    jmp process_tokens
2:

symbol_case:
    /* handwritten ispunct */
    cmpb $'!', %al
    jl 1f
    cmpb $'/', %al
    jle 0f
    cmpb $':', %al
    jl 1f
    cmpb $'@', %al
    jle 0f
    cmpb $'[', %al
    jl 1f
    cmpb $'`', %al
    jle 0f
    cmpb $'{', %al
    jl 1f
    cmpb $'~', %al
    jle 0f
0:
    inc %r10
    movb %al, (%ebx) /* emit symbols directly */
    inc %ebx
    jmp process_tokens
1:

word_case:
    xor %ecx, %ecx
    dec %ecx /* current statement index -1 */
0:
    inc %ecx
    cmp $word_table_length, %ecx
    je 3f
    mov %r10, %rdi              /* rdi=mutable string ptr for compare */
    ldaddr word_table, %ecx, ax /* load extended address into eax */
    mov %eax, %esi              /* rsi=current word in table */
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
    movb %cl, (%ebx) /* emit encoded byte */
    inc %ebx
    mov %rdi, %r10
    jmp process_tokens
3:

var_case:
    /* TODO */
    jmp process_tokens

run_command:
    movb $token_eof, (%ebx) /* terminate line */
    test %r13, %r13
    jz repl /* no command to be run (in line mode) */
    cmpb $statement_table_length, (%r13)
    error jg, SN
    xor %eax, %eax
    set_nextline %ax
    jmp exec_line
    /* END repl (no ret because the repl doesn't return) */

repl_get_num:
    xor %eax, %eax /* eax is the number */
    xor %ecx, %ecx
    mov $10, %edi
0:
    movb (%r10), %cl /* cl is one char */
    isnotdig %cl, 1f
    sub $'0', %cl
    mul %edi
    add %ecx, %eax
    inc %r10
    jmp 0b
1:
    ret

    .data
ok_str: .asciz "\n OK\n"
