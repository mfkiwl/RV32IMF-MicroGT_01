////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point Register File FLIP-FLOP                     //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The register file of MicroGT-01, it contains all the       //
//                 floating point registers. It has 3 read and 1 write ports. //            
////////////////////////////////////////////////////////////////////////////////

`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_f_reg_file_FF
(   //Inputs
    input  logic        clk_i,       //Clock 
    input  logic        clk_en_i,
    input  logic        rst_n_i,
    input  logic        we_i,        //Write enable
    input  logic        sel_all_i,   //Select every register
    input  logic        inout_i,     //Write or read the entire register file

    input  f_register_e r1_faddr_i,  //Read addresses
    input  f_register_e r2_faddr_i,
    input  f_register_e r3_faddr_i,

    input  f_register_e w_faddr_i,   //Write address

    input  float_t      wr_fdata_i,

    //Outputs
    output float_t      r1_fdata_o,  //Read ports
    output float_t      r2_fdata_o,
    output float_t      r3_fdata_o,

    // Output/input port for the entire register file
    // used to store or load the entire register 
    // file in case of interrupt
    output float_t [XLEN - 1:0] freg_file_out,
    input  float_t [XLEN - 1:0] freg_file_in
);

  float_t f_REG_FILE [0:XLEN - 1];   //Register file

      always_ff @(posedge clk_i)
        begin 
          if (!rst_n_i)   //Reset active low 
            begin 
              //Reset the entire register file
              for (int i = 0; i < XLEN; i++)
                f_REG_FILE[i] <= 32'b0;       
            end 
          if (clk_en_i)
            begin
              if (sel_all_i & inout_i)    
                begin
                  //Load the entire register file
                  for (int i = 0; i < XLEN; i++)
                    f_REG_FILE[i] <= freg_file_in[i];  
                end
              if (we_i)   
                f_REG_FILE[w_faddr_i] <= wr_fdata_i;    //Register write
            end
        end

      always_comb 
        begin  
          //Store the entire register file
          for (int i = 0; i < XLEN; i++)      
            freg_file_out[i] = f_REG_FILE[i];    
        end

  //Reads are combinatorials
  assign r1_fdata_o = f_REG_FILE[r1_faddr_i];   

  assign r2_fdata_o = f_REG_FILE[r2_faddr_i];

  assign r3_fdata_o = f_REG_FILE[r3_faddr_i];

endmodule