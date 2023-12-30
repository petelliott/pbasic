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
    .data
    .align 2
    .globl read_fd
    .globl write_fd
read_fd:    .4byte 0
write_fd:   .4byte 1


    .text
    .globl read_line
read_line:                      /* read_line() -> ptr */
    xor %eax, %eax              /* SYS_READ=0 */
    movl read_fd, %edi          /* fd */
    mov $line_buffer, %esi      /* line_buffer */
    cmp $0, %edi                /* check if on stdin */
    jne 0f

    mov $80, %edx               /* count */
    syscall
    movb $0, (%esi,%eax)        /* nul terminate */
    mov %esi, %eax
    ret
0:  /* read byte by byte from a non-stdin file */
    /* TODO: maybe buffer these */
    xor %edx, %edx
    inc %edx
1:
    xor %eax, %eax
    syscall
    test %eax, %eax
    jz 2f
    movb (%esi), %al
    inc %esi
    cmpb $'\n', %al
    jne 1b
2:
    movb $0, (%esi)
    mov $line_buffer, %eax
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
    movl write_fd, %edi         /* fd */
    xor %eax, %eax
    inc %eax                    /* SYS_WRITE=1 */
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


    .globl open
open: /* open(%rdi: filename, %rsi 0read 1write) */
    mov %rsi, %r10
    test %esi, %esi
    je 0f
    mov $(1 | 64 | 512), %esi /* O_WRONLY | O_CREAT | O_TRUNC */
    jmp 1f
0:
    mov $(0 | 64), %esi /* O_RDONLY | O_CREAT */
1:
    mov $0x1a4, %edx /* 0644 permissions */
    mov $2, %eax
    syscall
    movl %eax, read_fd(,%r10,4)
    ret


    .globl close
close: /* close rdi=0read 1write */
    mov %edi, %eax
    lea read_fd(,%edi,4), %edi
    mov %eax, (%edi)
    mov $3, %eax
    syscall
    ret
