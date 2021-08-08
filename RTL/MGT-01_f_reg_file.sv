////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Integer Register File                                      //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The register file of MicroGT-01, it contains all the       //
//                 floating point registers. It has 3 read and 1 write ports. //
////////////////////////////////////////////////////////////////////////////////

`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_f_reg_file 
(   //Inputs
    input  logic        clk_i,       //Clock 
    input  logic        we_i,        //Write enable

    input  f_register_e r1_faddr_i,  //Read addresses
    input  f_register_e r2_faddr_i,
    input  f_register_e r3_faddr_i,

    input  f_register_e w_faddr_i,   //Write address

    input  float_t      wr_fdata_i,

    //Outputs
    output float_t      r1_fdata_o,  //Read ports
    output float_t      r2_fdata_o,
    output float_t      r3_fdata_o
);

    float_t f_REG_FILE [0:XLEN - 1];   //Register file

    //We write on the negative edge of the clock because by doing so we can read
    //the updated value of the register on the second half of the clock cycle

    always_ff @(posedge clk_i)
      begin  
        if (we_i)
          f_REG_FILE[w_faddr_i] <= wr_fdata_i;  //Write on negative edge of clk
      end

    //Reads are combinatorials
    assign r1_fdata_o = f_REG_FILE[r1_faddr_i];   //Register x0 is hardwired to 0

    assign r2_fdata_o = f_REG_FILE[r2_faddr_i];

    assign r3_fdata_o = f_REG_FILE[r3_faddr_i];

endmodule