/*
pbasic's interned words and tables
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

    /* TODO: figure out how to link so we can support multiple platforms */
    .set page_start, 0x400000

    /* these macros are the definitions for all the words */
    .macro statements mac
    \mac end
    \mac goto
    \mac gosub
    \mac if
    \mac input
    \mac let
    \mac print
    \mac rem
    \mac return
    \mac stop
    \mac clear
    \mac list
    \mac run
    \mac new
    \mac load
    \mac save
    .endm

    .macro words mac
    statements \mac
    \mac then
    /* these are done manually */
    /*\mac <>
    \mac <=
    \mac >=*/
    .endm

    .data

    .macro strings name
    str_\name: .asciz "\name"
    .endm

words strings
str_ne: .asciz "<>"
str_le: .asciz "<="
str_ge: .asciz ">="

    .macro wt_entry name
    .globl word_\name
    word_addr_\name:
    .2byte str_\name - page_start
    .set word_\name, (word_addr_\name - word_table)/2
    .endm

    .globl word_table
    .globl word_table_end
    .globl word_table_length
    .align 2
word_table:
    words wt_entry
word_ne_addr:   .2byte str_ne - page_start
word_le_addr:   .2byte str_le - page_start
word_ge_addr:   .2byte str_ge - page_start

word_table_end:
    .set word_table_length, (word_table_end-word_table)/2

    .globl word_ne, word_le, word_ge
    .set word_ne, (word_ne_addr - word_table)/2
    .set word_le, (word_le_addr - word_table)/2
    .set word_ge, (word_ge_addr - word_table)/2

    .macro st_entry name
    .2byte statement_\name - page_start
    .endm

    .globl statement_table
    .globl statement_table_end
    .globl statement_table_length
    .align 2
statement_table:
    statements st_entry
statement_table_end:
    .set statement_table_length, (statement_table_end-statement_table)/2


    .globl token_num
    .set token_num, word_table_length
    .globl token_str
    .set token_str, word_table_length+1
    .globl token_var
    .set token_var, word_table_length+2
    .globl token_var_intern
    .set token_var_intern, word_table_length+3
    .globl token_eof
    .set token_eof, word_table_length+4
