# pbasic

TODO

## pbasic internals

### registers

pbasic uses the 64-bit systemV calling convention for all functions, and also
uses some registers to hold global values.

pbasic mostly uses 32-bit registers when possible to save a byte in instruction
encodings.

| register | special purpose   | saved by |
|----------|-------------------|----------|
| RAX      |                   | caller   |
| RBX      |                   | callee   |
| RCX      | arg3              | caller   |
| RDX      | arg2              | caller   |
| RBP      | base pointer      | callee   |
| RSI      | arg1              | caller   |
| RDI      | arg0              | caller   |
| RSP      | stack pointer     | callee   |
| R8       | arg4              | caller   |
| R9       | arg5              | caller   |
| R10      | static chain pointer | caller   |
| R11      |                   | caller   |
| R12      |                   | callee   |
| R13      | execution context | callee   |
| R14      | basic code head   | callee   |
| R15      | end of heap       | callee   |
