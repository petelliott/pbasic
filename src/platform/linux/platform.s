/*
platform specific functions
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
    .globl read_line
read_line:                      /* read_line() -> ptr */
    xor %eax, %eax              /* SYS_READ=0 */
    xor %edi, %edi              /* STDIN_FILENO=0 */
    mov $line_buffer, %esi      /* line_buffer */
    mov $80, %edx               /* count */
    syscall
    movb $0, (%esi,%eax)        /* nul terminate */
    mov %esi, %eax
    ret

    .globl write_string
    .globl write_string_n
write_string:                   /* write_string(string %rdi) -> number of bytes written */
    push %rdi
    call strlen
    pop %rdi
    mov %eax, %esi
    /* intentional fallthrough */
write_string_n:                 /* write_string_n(string %rdi, len %rsi) */
    mov %esi, %edx              /* count */
    mov %edi, %esi              /* string */
    xor %edi, %edi
    inc %edi                    /* STDOUT_FILENO=1 */
    mov %edi, %eax              /* SYS_WRITE=1 */
    syscall
    ret


    .globl write_char
write_char: /* write_char(ch %rdi) */
    mov %edi, %eax
    mov %esp, %edi /* using the red-zone so we can jump and skip the cleanup */
    dec %edi
    movb %al, (%edi)
    xor %esi, %esi
    inc %esi /* len=1 */
    jmp write_string_n /* tail call */
