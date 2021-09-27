////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point Register File FLIP-FLOPS                    //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    The register file of MicroGT-01, it contains all the       //
//                 floating point registers. It has 6 read and 2 write ports. //            
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_f_reg_file #(
  parameter WRITE_PORTS = 2,
  parameter READ_PORTS  = 6
)
(   //Inputs
    input  logic                            clk_i,        //Clock 
    input  logic                            clk_en_i,     //Clock enable
    input  logic        [WRITE_PORTS - 1:0] we_i,         //Write enable for each write port
    input  logic                            rst_n_i,      //Reset active low

    input  f_register_e [WRITE_PORTS - 1:0] wr_faddr_i,   //Write address
    
    input  f_register_e [READ_PORTS - 1:0]  rd_faddr_i,   //Read address

    input  float_t      [WRITE_PORTS - 1:0] wr_fdata_i,   //Data in

    //Outputs
    output float_t      [READ_PORTS - 1:0]  rd_fdata_o    //Data out
); 

  //Register file 
  float_t [XLEN - 1:0] f_REG_FILE; 

  //Enable the write of each register  
  logic [WRITE_PORTS - 1:0][XLEN - 1:0] row_sel;                   


    always_comb 
      begin : ROW_DECODER
        for (int i = 0; i < WRITE_PORTS; i++)
          begin 
            for (int j = 0; j < XLEN; j++)  
              begin
                //Enable the write of the j-th register 
                row_sel[i][j] = (wr_faddr_i[i] == j) ? we_i[i] : 1'b0;
              end
          end
      end : ROW_DECODER

      always_ff @(posedge clk_i) 
        begin : REGISTER_FILE
          if (!rst_n_i)     //Reset 
            f_REG_FILE <= '{default: 0};
          else 
            begin 
              for (int i = 0; i < WRITE_PORTS; i++)
                begin 
                  for (int j = 0; j < XLEN; j++)  
                    begin
                      //If the selection row signal is asserted write the data
                      if (row_sel[i][j])  
                        f_REG_FILE[j] <= wr_fdata_i[i];   
                    end
                end
            end
        end : REGISTER_FILE

      always_comb
        begin : OUTPUT_LOGIC 
          for (int i = 0; i < READ_PORTS; i++)
            begin 
              //Output the data in the i-th read port 
              //using the i-th read address
              rd_fdata_o[i] = f_REG_FILE[rd_faddr_i[i]];
            end            
        end : OUTPUT_LOGIC

endmodule
