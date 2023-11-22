# pbasic

pbasic is a modern 4k basic for x86_64. that means it runs entirely within a
single page, the minimum amount of physical memory alocatable to a process. all
memory touched by pbasic resides in this single page including:
- the elf executable headers
- pbasic code
- pbasic data
- runtime basic data
- the stack

## pbasic internals

### memory layout

pbasic on linux links the following sections:
- `.bss`
- `.elf`
- `.text`
- `.data`

`.bss` and `.elf` are 120 bytes, and overlap. following is `.text` and then `.data`

the stack pointer is set to the end of the page on startup.

### data structures

#### compressed pointers

most pointers stored in memory by pbasic are 16 bit. this is accomplished by
using the higher 16 bits of the current page.

the macro `ldaddr src, dst` can do this automatically.

#### lines

lines are a linked list of the form:

| linenum | next line pointer | line data |
|---------|-------------------|-----------|
| 16 bit unsigned line number | 16 bit compressed pointer to the next line | line bytecode |

#### bytecode

lines are translated to the following bytecode to save space and simplify execution.

| op | format |
|----|--------|
| word byte | a single byte representing a basic word (`goto`, `print`, etc.) |
| char byte | a symbol character like `=`, `,`, `;` etc. |
| token_num | `token_num` followed by a 4 byte number |
| token_str | `token_str` followed by a null-terminated ascii string |
| token_var | `token_var` followed by a 2 byte pointer to a 4 byte variable |
| token_var_intern | `token_var_intern` followed by a 2 byte pointer to the next var, then a 4 byte variable and a null-terminated string of the variable name |
| token_eof | the end of a line |


### registers

pbasic uses the 64-bit systemV calling convention for all functions, and also
uses some registers to hold global values.

pbasic mostly uses 32-bit registers when possible to save a byte in instruction
encodings.

| register | special purpose   | saved by |
|----------|-------------------|----------|
| RAX      |                   | caller   |
| RBX      | reserved for statements | callee   |
| RCX      | arg3              | caller   |
| RDX      | arg2              | caller   |
| RBP      | base pointer      | callee   |
| RSI      | arg1              | caller   |
| RDI      | arg0              | caller   |
| RSP      | stack pointer     | callee   |
| R8       | arg4              | caller   |
| R9       | arg5              | caller   |
| R10      |                   | caller   |
| R11      |                   | caller   |
| R12      |                   | callee   |
| R13      | execution context | callee   |
| R14      |                   | callee   |
| R15      | end of heap       | callee   |
