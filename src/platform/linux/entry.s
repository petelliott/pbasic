/*
the linux entry point of pbasic
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

    .text
    .globl _start

_start:
    mov $(page_start + 4096), %esp
    mov %esp, %edi
    sub $end, %edi
    call write_int
    mov $bytes_free, %rdi
    call write_string
    /* setup execution model */
    mov $end, %r15 /* setup r15, the end of our heap */
    movw $0, code_head /* set pointer to first statement to 0 */
    movw $0, var_head /* set pointer to first var to 0 */
    movb $0, suppress_repl_output
    xor %eax, %eax
    movl %eax, read_fd
    inc %eax
    movl %eax, write_fd
    mov $var_head, %r14 /* set pointer to tail slot of list */
    call repl /* start the repl */
    xor %edi, %edi /* zero return code */
    mov $60, %eax
    syscall

    .data
bytes_free:   .asciz " bytes free\n"
