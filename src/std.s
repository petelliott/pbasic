/*
standard utility functions
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
    .globl strlen
strlen: /* strlen(string %rdi) -> len %rax */
    xor %ecx, %ecx
    dec %ecx
    xor %eax, %eax
    repne scasb
    sub %ecx, %eax
    sub $2, %eax
    ret


    .globl write_int
    .globl write_uint
    /* write a signed integer to stdout */
write_int:
    test %edi, %edi
    jns write_uint
    push %rdi
    mov $'-', %edi
    call write_char
    pop %rdi
    neg %edi
    /* intentional fallthrough */
write_uint:
    mov %edi, %esi /* esi=current number (untouched by uilog10) */
    /* BEGIN INLINE P10above */
    /* gets the power of 10 above edi (min 10) */
p10above:
    xor %eax, %eax
    inc %eax       /* eax= the power of 10 (starts at 1) */
    mov $10, %ecx
0:
    xor %edx, %edx
    mul %ecx
    cmp %eax, %edi
    jae 0b
1:
    /* END INLINE P10above */
2:
    xor %edx, %edx
    mov $10, %ecx
    div %ecx       /* divide current divisor by 10 */
    push %rax
    push %rsi
    xchg %esi, %eax
    div %esi       /* divide current number by current divisor */
    xor %edx, %edx
    div %ecx       /* mod 10 */
    mov %edx, %edi
    add $'0', %edi
    call write_char /* write the char */
    pop %rsi
    pop %rax
    cmp $1, %eax
    ja 2b
    ret

    .globl newline
newline:
    mov $'\n', %rdi
    jmp write_char /* tail call to write char */
