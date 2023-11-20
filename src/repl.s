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
    %r13 = execution context
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

parse_line_num:
    movb (%r10), %al
    isnotdig %al, process_tokens
    xor %r13, %r13 /* zero the exec context to signal that we are adding a line */
    mov %r15, %rbx
    call repl_get_num /* eax = line number */
    movw %ax, (%ebx)
    add $4, %ebx /* allocate space for line number and nextptr */
    mov %ebx, %edi
    mov %eax, %esi
    call insert_line

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
    jmp 1f
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
    ldaddr_tbl word_table, %ecx, ax /* load extended address into eax */
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
    mov $var_head, %ecx /* ecx holds pointer to the next var */
    /* check if var is already interned */
0:
    ldaddr (%ecx), dx
    test %dx, %dx
    jz 3f /* intern variable */
    mov %edx, %ecx
    add $6, %edx /* edx is the pointer to the interned var string */
    mov %r10, %r8 /* r8 is the pointer to the new var string */
1:
    movb (%edx), %ah
    movb (%r8), %al
    inc %r8
    inc %edx
    cmpb %al, %ah
    je 1b
    cmpb $0, %ah
    jne 0b
    mov $0b, %edi /* target if al is alphanum */
    mov $2f, %esi /* target otherwise */
    jmp jmp_alphanum
7: /* variable hasn't been defined, but we are in command mode, so allocate a variable slot on the heap */
    lea (%r15), %eax
    movw %ax, (%ecx)
    mov %eax, %ecx /* increment our linked list after insert */
    xor %eax, %eax
    movw %ax, (%r15) /* add next link */
    movl %eax, 2(%r15) /* add variable content */
    add $6, %r15
    /* BEGIN JANK */
4:
    movb (%r10), %al
    mov $5f, %edi
    mov $6f, %esi
    jmp jmp_alphanum
5:
    movb %al, (%r15)
    inc %r10
    inc %r15
    jmp 4b
6:
    movb $0, (%r15) /* nul terminate the var string */
    inc %r15
    /* END JANK */
    mov %r10, %r8
    inc %r8 /* setup a fake %r8 */
    /* fall through to variable defined case */
2: /* variable has already been defined */
    dec %r8
    mov %r8, %r10 /* set linebuffer to new value */
    movb $token_var, (%ebx)
    add $2, %cx /* move pointer to variable */
    movw %cx, 1(%ebx)
    add $3, %ebx
    jmp process_tokens
3: /* variable hasn't already been defined, create it */
    test %r13, %r13
    jnz 7b /* no command to be run (in line mode) */
    movb $token_var_intern, (%ebx)
    lea 1(%ebx), %eax
    movw %ax, (%ecx)
    xor %eax, %eax
    movw %ax, 1(%ebx) /* add next link */
    movl %eax, 3(%ebx) /* add variable content */
    add $7, %ebx
4:
    movb (%r10), %al
    mov $5f, %edi
    mov $6f, %esi
    jmp jmp_alphanum
5:
    movb %al, (%ebx)
    inc %r10
    inc %ebx
    jmp 4b
6:
    movb $0, (%ebx) /* nul terminate the var string */
    inc %ebx
    jmp process_tokens

run_command:
    movb $token_eof, (%ebx) /* terminate line */
    inc %ebx
    test %r13, %r13
    jz enter_line /* no command to be run (in line mode) */
    cmpb $statement_table_length, (%r13)
    error jg, SN
    xor %eax, %eax
    set_nextline %ax
    jmp exec_line

enter_line:
    mov %rbx, %r15 /* skip the heap we've allocated */
    jmp repl_not_ok
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

jmp_alphanum: /* edi=jump target true alphanum, esi=jump target false */
    cmpb $'0', %al
    jl 1f
    cmpb $'1', %al
    jle 0f
    cmpb $'A', %al
    jl 1f
    cmpb $'Z', %al
    jle 0f
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
