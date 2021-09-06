////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Integer Register File FPGA                                 //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The register file of MicroGT-01, it contains all the       //
//                 integer registers. It has 2 read and 1 write ports.        //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_i_reg_file 
( //Inputs
  input  logic        clk_i,       //Clock 
  input  logic        we_i,        //Write enable 
  input  logic        clk_en_i,

  input  i_register_e r1_iaddr_i,  //Read addresses
  input  i_register_e r2_iaddr_i,

  input  i_register_e w_iaddr_i,   //Write address

  input  data_bus_t   wr_idata_i,  //Write port

  //Outputs
  output data_bus_t   r1_idata_o,  //Read ports
  output data_bus_t   r2_idata_o
);

  data_bus_t i_REG_FILE [0:XLEN - 1];   //Register file 
    
  logic we;
    
    assign we = (w_iaddr_i == X0) ? 1'b0 : we_i;  //If write address is register x0 don't write 

    always_ff @(posedge clk_i)
      begin  
        if (we & clk_en_i)
          i_REG_FILE[w_iaddr_i] <= wr_idata_i;  //Write on positive edge of clk
      end

  //Reads are combinatorials
  assign r1_idata_o = (r1_iaddr_i == X0) ? 32'b0 : i_REG_FILE[r1_iaddr_i];   //Register x0 is hardwired to 0

  assign r2_idata_o = (r2_iaddr_i == X0) ? 32'b0 : i_REG_FILE[r2_iaddr_i];

endmodule
