/*
pbasic utility macros
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


    .macro ldaddr src dst
    mov $page_start, %e\dst         /* set top of eax */
    movw word_table(,\src,2), %\dst /* load relative address part of eax */
    .endm

    .macro isnotdig reg, label
    cmpb $'0', \reg
    jl \label
    cmpb $'9', \reg
    jg \label
    .endm

    .macro breakpoint
    int $3
    .endm
