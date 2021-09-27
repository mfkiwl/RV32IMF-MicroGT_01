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

`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_i_reg_file #(
  parameter WRITE_PORTS = 2,
  parameter READ_PORTS  = 6
)
( //Inputs
  input  logic                            clk_i,       //Clock 
  input  logic        [WRITE_PORTS - 1:0] we_i,        //Write enable 
  input  logic                            clk_en_i,    //Clock enable
  input  logic                            rst_n_i,     //Reset active low

  input  i_register_e [READ_PORTS - 1:0]  rd_iaddr_i,  //Read addresses

  input  i_register_e [WRITE_PORTS - 1:0] wr_iaddr_i,  //Write address

  input  data_bus_t   [WRITE_PORTS - 1:0] wr_idata_i,  //Write port

  //Outputs
  output data_bus_t   [READ_PORTS - 1:0]  rd_idata_o   //Read ports
);

  //Register file, the first register is not considered
  data_bus_t i_REG_FILE [XLEN - 1:1];    
    
  //Enable the write of each register   
  logic [WRITE_PORTS - 1:0][XLEN - 1:1] row_sel;


    always_comb
      begin : ROW_DECODER
        for (int i = 0; i < WRITE_PORTS; i++)
          begin 
            //J starts form 1 because of the register X0
            for (int j = 1; j < XLEN; j++)  
              begin
                //Enable the write of the j-th register 
                row_sel[i][j] = (wr_iaddr_i[i] == j) ? we_i[i] : 1'b0;
              end
          end
      end : ROW_DECODER

      always_ff @(posedge clk_i) 
        begin : REGISTER_FILE
          if (!rst_n_i)     //Reset 
            i_REG_FILE <= '{default: 0};
          else 
            begin 
              for (int i = 0; i < WRITE_PORTS; i++)
                begin 
                  //J starts form 1 because of the register X0
                  for (int j = 1; j < XLEN; j++)  
                    begin
                      //If the selection row signal is asserted write the data
                      if (row_sel[i][j])  
                        i_REG_FILE[j] <= wr_idata_i[i];   
                    end
                end
            end
        end : REGISTER_FILE

      always_comb
        begin : OUTPUT_LOGIC 
          for (int i = 0; i < READ_PORTS; i++)
            begin
              if (rd_iaddr_i[i] == X0)
                rd_idata_o[i] = 32'b0;
              else   
                //Output the data in the i-th read port 
                //using the i-th read address
                rd_idata_o[i] = i_REG_FILE[rd_iaddr_i[i]];
            end            
        end : OUTPUT_LOGIC
        
endmodule
