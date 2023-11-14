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
    get_nextline ax
    cmpw $0, %ax
    je repl /* return to repl if we're at the end of the code */
    mov %rax, %r13
    /* intentional fallthrough */
exec_line:
    xor %ecx, %ecx
    movb (%r13), %cl
    ldaddr statement_table, %ecx, ax /* load extended address into eax */
    jmp *%rax /* call the statement handler */
