////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point Register File FPGA                          //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The register file of MicroGT-01, it contains all the       //
//                 floating point registers. It has 3 read and 1 write ports. //            
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_f_reg_file 
(   //Inputs
    input  logic        clk_i,       //Clock 
    input  logic        clk_en_i,
    input  logic        we_i,        //Write enable 

    input  f_register_e r1_faddr_i,  //Read addresses
    input  f_register_e r2_faddr_i,
    input  f_register_e r3_faddr_i,

    input  f_register_e w_faddr_i,   //Write address

    input  float_t      wr_fdata_i,  //Write port

    //Outputs
    output float_t      r1_fdata_o,  //Read ports
    output float_t      r2_fdata_o,
    output float_t      r3_fdata_o
);

  data_bus_t f_REG_FILE [0:XLEN - 1];   //Register file 

    always_ff @(posedge clk_i)
      begin  
          if (we_i & clk_en_i)
            f_REG_FILE[w_faddr_i] <= wr_fdata_i;  //Write on positive edge of clk
      end

  //Reads are combinatorials
  assign r1_fdata_o = f_REG_FILE[r1_faddr_i];   

  assign r2_fdata_o = f_REG_FILE[r2_faddr_i];

  assign r3_fdata_o = f_REG_FILE[r3_faddr_i];

endmodule
