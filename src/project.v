/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_ALU (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Simple 4-bit ALU mapped onto Tiny Tapeout-style IOs
    //   ui_in[3:0]  = operand A
    //   ui_in[7:4]  = operand B
    //   uio_in[2:0] = opcode
    //
    // Opcodes:
    //   3'b000 : A + B
    //   3'b001 : A - B
    //   3'b010 : A & B
    //   3'b011 : A | B
    //   3'b100 : A ^ B
    //   3'b101 : A << 1
    //   3'b110 : A >> 1
    //   3'b111 : pass-through A
    //
    // Output mapping:
    //   [3:0] = result[3:0]
    //   [4]   = carry / borrow flag
    //   [5]   = zero flag (1 when result == 0)
    //   [6]   = negative flag (MSB of result)
    //   [7]   = overflow flag for add/sub

    // Operand and opcode extraction
    wire [3:0] a  = ui_in[3:0];
    wire [3:0] b  = ui_in[7:4];
    wire [2:0] op = uio_in[2:0];

    // ALU (D side)
    logic [3:0] result_d;
    logic       carry_d;
    logic       overflow_d;
    logic       zero_d;
    logic       negative_d;

    // ALU (Q side)
    logic [3:0] result_q;
    logic       carry_q;
    logic       overflow_q;
    logic       zero_q;
    logic       negative_q;

    // Combinational ALU
    always_comb begin
        result_d   = 0;
        carry_d    = 0;
        overflow_d = 0;
        negative_d = 0;

        unique case (op)
            3'b000: begin //add case
                {carry_d, result_d} = a + b;
                overflow_d = (a[3] == b[3]) && (result_d[3] != a[3]);
                negative_d = result_d[3];
            end
            3'b001: begin
                // SUB: A - B
                {carry_d, result_d} = a + (~b + 4'b0001);
                overflow_d = (a[3] != b[3]) && (result_d[3] != a[3]);
                negative_d = result_d[3];
            end
            3'b010: begin
                // AND
                result_d = a & b;
                negative_d = 1'b0;
            end
            3'b011: begin
                // OR
                result_d = a | b;
                negative_d = 1'b0;
            end
            3'b100: begin
                // XOR
                result_d = a ^ b;
                negative_d = 1'b0;
            end
            3'b101: begin
                // SHIFT LEFT A
                {carry_d, result_d} = {a, 1'b0};
                negative_d = result_d[3];
            end
            3'b110: begin
                // SHIFT RIGHT A
                result_d = {1'b0, a[3:1]};
                carry_d  = a[0];
                negative_d = (a[3:1] == 3'b000) ? 1'b0 : a[3];
            end
            3'b111: begin
                // PASS-THROUGH A
                result_d = a;
                negative_d = a[3];
            end
            default: begin
                result_d   = 4'b0000;
                carry_d    = 1'b0;
                overflow_d = 1'b0;
                negative_d = 1'b0;
            end
        endcase

        // Flag next-state values
        zero_d = (result_d == 4'b0000);
    end

    // Sequential logic for registered outputs
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            result_q   <= 4'b0000;
            carry_q    <= 1'b0;
            overflow_q <= 1'b0;
            zero_q     <= 1'b0;
            negative_q <= 1'b0;
        end else begin
            result_q   <= result_d;
            carry_q    <= carry_d;
            overflow_q <= overflow_d;
            zero_q     <= zero_d;
            negative_q <= negative_d;
        end
    end

    // Drive outputs
    assign uo_out = {overflow_q, negative_q, zero_q, carry_q, result_q};

    // We only use the input side of the uio bus in this design.
    assign uio_out = 8'b0000_0000;
    assign uio_oe  = 8'b0000_0000; // all uio bits are inputs

endmodule

