/*
 * Copyright (c) 2024 Tommy Thorn
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none
`default_nettype none

`ifdef COCOTB_SIM

// Muller's C-element also TH22
module tt22(input A, input B, output reg Q);
   always @(*) if (A == B) Q <= #1 A;
endmodule

// Like tt22 but NULL while init is asserted
module tt22n(input A, input B, input init, output reg Q);
   always @(*) if (init) Q <= #1 0; else if (A == B) Q <= #1 A;
endmodule

// Like tt22 but DATA while init is asserted
module tt22d(input A, input B, input init, output reg Q);
   always @(*) if (init) Q <= #1 1; else if (A == B) Q <= #1 A;
endmodule

`else

module tt22(input A, input B, output Q);
   // We can implement this with a majority gate with feedback
   sky130_fd_sc_hd__maj3_1 maj(.X(Q), .A(A), .B(B), .C(Q));
endmodule

module tt22n(input A, input B, input init, output Q);
   wire Q1;
   // We can implement this with a majority gate with feedback
   sky130_fd_sc_hd__maj3_1 maj(.X(Q1), .A(A), .B(B), .C(Q));
   assign Q = init ? 0 : Q1; // == !init & Q1"
endmodule

// Like tt22 but DATA while init is asserted
module tt22d(input A, input B, input init, output Q);
   wire Q1;
   // We can implement this with a majority gate with feedback
   sky130_fd_sc_hd__maj3_1 maj(.X(Q1), .A(A), .B(B), .C(Q));
   assign Q = init ? 1 : Q1; // == init | Q1
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

   assign uio_oe = 0;
   assign uio_out = 0;

   // Simple C-element
   tt22 tt22_inst(.A(ui_in[0]), .B(ui_in[1]), .Q(uo_out[0]));

   // Simple NCL ring:
   //
   //     A -> B -> C -> D
   //     ^-------------/
   //

   wire               init = ui_in[2];
   wire               g0_out;
   wire               g1_out;
   wire               g2_out;
   wire               g3_out;
   wire               g0_complete;
   wire               g1_complete;
   wire               g2_complete;
   wire               g3_complete;
   assign             g0_complete = g0_out;
   assign             g1_complete = g1_out;
   assign             g2_complete = g2_out;
   assign             g3_complete = g3_out;

   assign uo_out[7:1] = {g3_out,g2_out,g1_out,g0_out};


   tt22n g0(.A(g3_out), .B(!g1_complete), .Q(g0_out), .init(init));
   tt22d g1(.A(g0_out), .B(!g2_complete), .Q(g1_out), .init(init));
   tt22n g2(.A(g1_out), .B(!g3_complete), .Q(g2_out), .init(init));
   tt22n g3(.A(g2_out), .B(!g0_complete), .Q(g3_out), .init(init));
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
      $monitor("%5d  One TT22 A %d B %d  Q %d",
               $time, ui_in[0], ui_in[1], uo_out[0]);

      ui_in[2] = 1;

      #10 ui_in[0] = 1;
      #10 ui_in[1] = 1;
      #10 ui_in[0] = 0;
      #10 ui_in[1] = 0;

      #30
      $monitor("%5d  Ring (init %d) %d%d%d%d",
               $time, ui_in[2], uo_out[1], uo_out[2], uo_out[3], uo_out[4]);
      #10
        ui_in[2] = 0;

      #100 $display("The End");
      $finish;
   end
endmodule
`endif
