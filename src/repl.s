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
repl:
    mov $ok_str, %rdi
    call write_string
    call read_line /* eax is a pointer to a line buffer that we can mess with */
    mov %eax, %ebx
    add $20, %ebx  /* ebx is the address we will begin writing tokenized code to. intentionally overlapping with linebuffer */
    mov %rbx, %r13 /* set execution context */
    mov %rax, %r10 /* r10 holds the line buffer long term */
    /* TODO: handle line number here */
parse_line_num:

process_tokens:
    /* handle whitespace and eof */
    movb (%r10), %al
    cmpb $0, %al
    je run_command
    cmpb $' ', %al
    je whitespace_case
    cmpb $'\n', %al
    jne number_case

whitespace_case:
    inc %r10
    jmp process_tokens

number_case:
    isnotdig %al, word_case
    call repl_get_num
    movb $token_num, (%ebx)
    inc %ebx
    mov %eax, (%ebx)
    add $4, %ebx
word_case:
    xor %ecx, %ecx
    dec %ecx /* current statement index -1 */
0:
    inc %ecx
    cmp $word_table_length, %ecx
    je 3f
    mov %r10, %rdi             /* rdi=mutable string ptr for compare */
    ldaddr %ecx, ax            /* load extended address into eax */
    mov %eax, %esi             /* rsi=current word in table */
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
3:
    jmp process_tokens
    /* CASE 2: TODO */
run_command:
    breakpoint
    jmp repl
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
