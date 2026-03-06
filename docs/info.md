<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project is a 4-bit ALU using Verilog. The ALU performs arithmetic and logical operations on two 4-bit inputs (A and B) using a 3-bit input opcode. The following are the I/Os for the project.

### Inputs:
- `ui_in[3:0]`: Operand A (4-bit)
- `ui_in[7:4]`: Operand B (4-bit)
- `uio_in[2:0]`: Opcode (3-bit)

### Operations (based on opcode):
- `000`: A + B (Addition)
- `001`: A - B (Subtraction)
- `010`: A & B (Bitwise AND)
- `011`: A | B (Bitwise OR)
- `100`: A ^ B (Bitwise XOR)
- `101`: A << 1 (Left shift A by 1)
- `110`: A >> 1 (Right shift A by 1)
- `111`: Pass-through A

### Outputs:
- `uo_out[3:0]`: Result (4-bit)
- `uo_out[4]`: Carry/Borrow flag
- `uo_out[5]`: Zero flag (1 if result == 0)
- `uo_out[6]`: Negative flag (MSB of result)
- `uo_out[7]`: Overflow flag (for add/sub operations)

This design is synchronous, using the provided clock and reset signals.

## How to test

The project includes a testbench for verification.

1. Make sure you have the required dependencies installed (see `test/requirements.txt`).
2. Navigate to the `test/` directory.
3. Run the RTL simulation with the makefile
4. To view waveforms, use GTKWave
5. For gate-level simulation after hardening, copy the netlist and run: make -B GATES=yes

The testbench verifies all operations and flag conditions.

## External hardware

No external hardware is required for this design.
