/*
shunting yard algorithm implementation
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

    .macro to_case value, prec, id, name
    cmpb \value, %al
    je case_\name
    .endm

    .macro case value, prec, id, name
    case_\name:
    movb $\prec, %ah
    movb $\id, %al
    jmp process_op
    .endm

    .macro execs value, prec, id, name
    cmpb $\id, %cl
    je exec_\name
    .endm

    .macro operations mac
    \mac $'*',     1, 0, times
    \mac $'/',     1, 1, div
    \mac $'+',     2, 2, plus
    \mac $'-',     2, 3, minus
    \mac $word_ne, 3, 4, notequals
    \mac $word_le, 3, 5, lessequals
    \mac $word_ge, 3, 6, greaterequals
    \mac $'=',     3, 7, equals
    \mac $'<',     3, 8, lessthan
    \mac $'>',     3, 9, greaterthan
    .endm

    .set eof, (4 << 8) | 10

    .text
    .globl do_expression
do_expression: /* ebx is mutable pointer to the tokenized line, returns value in rax */
    push %rbp
    mov %esp, %ebp
    mov $op_stack, %r8
    xor %r9, %r9
loop:
    inc %r9
    movb (%ebx), %al
    inc %ebx
    cmpb $token_num, %al
    je push_num
    cmpb $token_var_intern, %al
    je push_var
    cmpb $token_var, %al
    je push_var
get_op:
    operations to_case
    cmpb $1, %r9b
    je error
    mov $eof, %ax
    dec %ebx
    jmp 0f
    operations case
    /* the next token is not an operator, pop all from stack */
0:
process_op:
    cmp $op_stack, %r8
    je push_op
    movw (%r8), %cx
    cmpb %ah, %ch
    jge push_op
    add $2, %r8
    pop %rsi
    pop %rdi
    /* execute while we have lower precidence */
    operations execs
    breakpoint /* unreachable code */
exec_times:
    imul %esi, %edi
    jmp push_result
exec_div:
    xor %edx, %edx
    xchg %edi, %eax
    idiv %esi
    xchg %edi, %eax
    jmp push_result
exec_plus:
    add %esi, %edi
    jmp push_result
exec_minus:
    sub %esi, %edi
    jmp push_result
exec_lessequals:
    cmp %esi, %edi
    jle result_true
    jmp result_false
exec_greaterequals:
    cmp %esi, %edi
    jge result_true
    jmp result_false
exec_equals:
    cmp %esi, %edi
    je result_true
    jmp result_false
exec_lessthan:
    cmp %esi, %edi
    jl result_true
    jmp result_false
exec_greaterthan:
    cmp %esi, %edi
    jg result_true
    jmp result_false
exec_notequals:
    cmp %esi, %edi
    jne result_true
    jmp result_false
result_true:
    xor %edi, %edi
    dec %edi
    jmp push_result
result_false:
    xor %edi, %edi
push_result:
    push %rdi
    jmp process_op
push_op:
    cmpw $eof, %ax
    je end
    /* push new operator */
    sub $2, %r8
    movw %ax, (%r8)
    jmp loop
push_num:
    movl (%ebx), %eax
    push %rax
    add $4, %ebx
    jmp loop
push_var:
    call read_var
    mov (%eax), %eax
    push %rax
    jmp loop

error:
    mov %ebp, %esp
    pop %rbp
    error jmp, SN
end:
    pop %rax
    mov %ebp, %esp
    pop %rbp
    ret


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
