/*
 * Copyright (c) 2024 Tommy Thorn
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none
`default_nettype none

// Muller's C-element
module celem(input A, input B, output Q);
   // We can implement this with a majority gate with feedback
   sky130_fd_sc_hd__maj3_1 maj(.X(Q), .A(A), .B(B), .C(Q));
endmodule

`ifdef COCOTB_SIM
module sky130_fd_sc_hd__maj3_1 (
    output X,
    input  A,
    input  B,
    input  C
);
   assign X = A & B | C & (A | B);
endmodule
`endif

module tt_um_tommythorn_ncl_lfsr (
/* verilator lint_off UNUSEDSIGNAL */
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
/* verilator lint_on UNUSEDSIGNAL */
);

   assign uo_out[7:1] = 0;
   assign uio_oe = 0;
   assign uio_out = 0;

   // Simple C-element
   celem celem_inst(.A(ui_in[0]), .B(ui_in[1]), .Q(uo_out[0]));
endmodule

`ifdef COCOTB_SIM
module mytb;
   reg  [7:0] ui_in = 0; // Dedicated inputs
   wire [7:0] uo_out;   // Dedicated outputs
   wire [7:0] uio_in;   // IOs: Input path
   wire [7:0] uio_out;  // IOs: Output path
   wire [7:0] uio_oe = 0;// IOs: Enable path (active high: 0=input; 1=output)
   wire       ena = 1;  // will go high when the design is enabled
   reg        clk = 1;  // clock
   wire       rst_n = 1;// reset_n - low to reset

   always #5 clk = !clk;

   tt_um_tommythorn_ncl_lfsr inst_ncl_lfsr
     (ui_in,    // Dedicated inputs
      uo_out,   // Dedicated outputs
      uio_in,   // IOs: Input path
      uio_out,  // IOs: Output path
      uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
      ena,      // will go high when the design is enabled
      clk,      // clk
      rst_n);   // reset_n - low to reset



   initial begin
      $monitor("%5d  A %d B %d  Q %d", $time, ui_in[0], ui_in[1], uo_out[0]);

      #10 ui_in[0] = 1;
      #10 ui_in[1] = 1;
      #10 ui_in[0] = 0;
      #10 ui_in[1] = 0;

      #100 $display("The End");
      $finish;
   end
endmodule
`endif
