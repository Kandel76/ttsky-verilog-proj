`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Clock generation (100 MHz -> period 10ns)
  initial clk = 0;
  always #5 clk = ~clk;

  // expected value for operations
  function [7:0] expected_alu;
    input [3:0] a;
    input [3:0] b;
    input [2:0] op;
    reg [4:0] tmp;
    reg c;
    reg v;
    begin
      case (op)

        3'b000: begin // A + B
          tmp = a + b;
          c = tmp[4];
          // overflow: same sign operands, different from result sign
          v = (a[3] == b[3]) && (tmp[3] != a[3]);
          expected_alu = {v, tmp[3], (tmp[3:0] == 4'b0000), c, tmp[3:0]};
        end


        3'b001: begin // A - B
          tmp = a - b;
          c = tmp[4]; // borrow inverted in two's complement, carry indicates no borrow
          v = (a[3] != b[3]) && (tmp[3] != a[3]);
          expected_alu = {v, tmp[3], (tmp[3:0] == 4'b0000), c, tmp[3:0]};
        end


        3'b010: expected_alu = {1'b0,1'b0, (a & b) == 4'b0000,1'b0, a & b};
        3'b011: expected_alu = {1'b0,1'b0, (a | b) == 4'b0000,1'b0, a | b};
        3'b100: expected_alu = {1'b0,1'b0, (a ^ b) == 4'b0000,1'b0, a ^ b};
        3'b101: begin
          tmp = {a,1'b0};
          c = tmp[4];
          expected_alu = {1'b0, tmp[3], (tmp[3:0] == 4'b0000), c, tmp[3:0]};
        end


        3'b110: begin
          c = a[0];
          expected_alu = {1'b0, a[3:1] == 3'b000 ? 1'b0 : a[3], ( {1'b0,a[3:1]} == 4'b0000), c, {1'b0,a[3:1]}};
          // for right shift negative flag comes from MSB of result
        end


        3'b111: expected_alu = {1'b0, a[3], (a == 4'b0000), 1'b0, a};
        default: expected_alu = 8'h00;
      endcase
    end
  endfunction


  // Replace tt_um_example with your module name:
  tt_um_ALU user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  // test
  initial begin

    //default values
    ena = 1;
    ui_in = 8'b00;
    uio_in = 8'b00;
    rst_n = 0;
    #20;
    rst_n = 1;

    // loop through a combinations
    for (int op = 0; op < 8; op++) begin //from 0 to 7 (op code is 3 bit)
      
      for (int a = 0; a < 16; a++) begin //operand A (3 bit) loop from 0-15
        
        for (int b = 0; b < 16; b++) begin //operant B (3 bit) loop from 0-15
          
          ui_in  = {b[3:0], a[3:0]};
          
          uio_in = op;
          
          @(posedge clk); // synchronize with clock edge

          //check against the expected values
          if (uo_out !== expected_alu(a[3:0], b[3:0], op[2:0])) begin
            
            //show potential errors
            $display("ERROR: op %b A %h B %h got %h expected %h", op, a, b, uo_out, expected_alu(a[3:0], b[3:0], op[2:0]));
            //exit
            $fatal(1);
          end
        end
      end
    end

    $display("================All ALU tests PASSED================");
    $finish;
  end

endmodule
