/*
execution functions for pbasic
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
    .globl exec_next_line
    .globl exec_line
exec_next_line:
    get_nextline %r13, ax
    mov %rax, %r13
exec_line:
    mov %r13, %rax
    test %ax, %ax
    je repl /* return to repl if we're at the end of the code */
    xor %ecx, %ecx
    movb (%r13), %cl
    ldaddr_tbl statement_table, %ecx, ax /* load extended address into eax */
    mov %r13, %rbx /* provide a mutable r13 in ebx */
    jmp *%rax /* call the statement handler */


    /* TODO: write a better macro to get line number */

    .globl get_line
get_line: /* %rdi: target line num, throws US */
    mov %edi, %edx
    mov %edi, %esi
    mov $code_head, %edi
    call line_slot
    ldaddr (%edi), ax
    test %ax, %ax
    error je, US
    xor %ecx, %ecx
    movw -4(%eax), %cx /* cx = line number of next line */
    cmp %edx, %ecx
    error jne, US
    ret

    .globl insert_line
insert_line: /* %rdi: line ptr, %rsi, target line */
    mov %edi, %edx
    mov $code_head, %edi
    call line_slot
    ldaddr (%edi), cx
    test %cx, %cx
    je 0f
    cmpw -4(%ecx), %si
    jne 0f
    /* overwrite, since lines are equal */
    movw -2(%ecx), %cx
0:
    /* insert the line */
    movw %dx, (%edi)
    movw %cx, -2(%edx)
    ret

line_slot: /* rdi: double pointer to code head, rsi: target line num, returns the slot in edi */
    cmpw $0, (%edi)
    je 0f
    ldaddr (%edi), cx
    xor %eax, %eax
    movw -4(%ecx), %ax /* ax = line number of next line */
    cmp %eax, %esi
    jle 0f
    sub $2, %ecx
    mov %ecx, %edi
    jmp line_slot
0:
    ret
