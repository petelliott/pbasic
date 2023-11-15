/*
uninitialized space for pbasic globals
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

    /* TODO: we only have 120 bytes for bss (on linux) */
    .bss
    .globl line_buffer
    .globl exec_buffer
    .globl code_head
exec_buffer_feilds:
    .skip 4
exec_buffer:
    .skip 24
line_buffer:
    .skip 80

    .align 2
code_head:
    .skip 2
