////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Integer Register File FLIP-FLOP                            //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The register file of MicroGT-01, it contains all the       //
//                 integer registers. It has 2 read and 1 write ports.        //
////////////////////////////////////////////////////////////////////////////////

//NOT TESTED YET

module MGT_01_i_reg_file_FF
( //Inputs
  input  logic        clk_i,       //Clock 
  input  logic        we_i,        //Write enable 
  input  logic        clk_en_i,
  input  logic        rst_n_i,
  input  logic        sel_all_i,   //Select every register
  input  logic        inout_i,     //Write or read the entire register file

  input  i_register_e r1_iaddr_i,  //Read addresses
  input  i_register_e r2_iaddr_i,

  input  i_register_e w_iaddr_i,   //Write address

  input  data_bus_t   wr_idata_i,  //Write port

  //Outputs
  output data_bus_t   r1_idata_o,  //Read ports
  output data_bus_t   r2_idata_o,

  // Output/input port for the entire register file
  // used to store or load the entire register 
  // file in case of interrupt
  output data_bus_t [XLEN - 1:0] ireg_file_out,
  input  data_bus_t [XLEN - 1:0] ireg_file_in
);

  data_bus_t i_REG_FILE [0:XLEN - 1];   //Register file

  logic we;

  //Do not write anything if the address is the register X0
  assign we = (w_iaddr_i == X0) ? 1'b0 : 1'b1;

      always_ff @(posedge clk_i) 
        begin 
          if (!rst_n_i)   //Reset active low
            begin 
              //Reset the entire register file
              for (int i = 1; i < XLEN; i++)
                i_REG_FILE[i] <= 32'b0;       
            end
          if (sel_all_i & inout_i & clk_en_i)    
            begin
              //Load the entire register file
              for (int i = 1; i < XLEN; i++)
                i_REG_FILE[i] <= reg_file_in[i];  
            end
          if (we & clk_en_i)
            i_REG_FILE[w_faddr_i] <= wr_fdata_i;  //Register write
        end

      always_comb 
        begin
          //Store the entire register file  
          for (int i = 1; i < XLEN; i++)            
            ireg_file_out[i] = i_REG_FILE[i];    
        end
  
  //Reads are combinatorials
  assign r1_idata_o = (r1_iaddr_i == X0) ? 32'b0 : i_REG_FILE[r1_iaddr_i];   //Register x0 is hardwired to 0

  assign r2_idata_o = (r2_iaddr_i == X0) ? 32'b0 : i_REG_FILE[r2_iaddr_i];

endmodule
