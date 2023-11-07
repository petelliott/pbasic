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
read_line:                      /* read_line() */
    mov $0, %rax                /* SYS_READ */
    mov $0, %rdi                /* STDIN_FILENO */
    mov $line_buffer, %rsi      /* line_buffer */
    mov $80, %rdx               /* count */
    syscall
    movb $0, line_buffer(%rax)  /* nul terminate */
    mov %rax, line_buffer_len
    ret


    .globl write_string
    .globl write_string_n
write_string:                   /* write_string(string %rdi) */
    push %rdi
    call strlen
    pop %rdi
    mov %rax, %rsi
    /* intentional fallthrough */
write_string_n:                 /* write_string_n(string %rdi, len %rsi) */
    mov %rsi, %rdx              /* count */
    mov %rdi, %rsi              /* string */
    mov $1, %rdi                /* STDOUT_FILENO */
    mov $1, %rax                /* SYS_WRITE */
    syscall
    ret
