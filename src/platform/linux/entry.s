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
    mov $'h', %edi
    call write_char
    mov $'e', %edi
    call write_char
    mov $'l', %edi
    call write_char
    mov $'l', %edi
    call write_char
    mov $'o', %edi
    call write_char
    mov $'\n', %edi
    call write_char
loop0:
    call read_line
    mov $line_buffer, %edi
    call write_string
    jmp loop0
    xor %edi, %edi
    mov $60, %eax
    syscall
