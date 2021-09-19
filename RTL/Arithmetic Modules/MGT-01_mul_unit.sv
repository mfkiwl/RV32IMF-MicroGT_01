////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Multiplication Unit                                        //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains the hardware necessary to perform a   //
//                 signed/unsigned multiplication. It is not pipelined to     //
//                 save area and resources. The multiplication is performed   //
//                 using the Booth multiplication algorithm, you can select   //
//                 the radix 4 one if you want to lower the resources usage.  //
//                 Select the radix 16 one if you want performance.           //
//                                                                            //
// Dependencies:   MGT-01_booth_radix4.sv                                     //
//                 MGT-01_booth_radix16.sv                                    //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_mul_unit
( //Inputs
  input  logic signed [XLEN - 1:0] multiplier_i, multiplicand_i, 

  input  logic                     clk_i, clk_en_i,               //Clock signals
  input  logic                     rst_n_i,                       //Reset active low

  input  mul_ops_e                 operation_i,
  
  //Outputs
  output logic signed [XLEN - 1:0] result_o,                      
  output fu_state_e                fu_state_o,                    //Functional unit state
  output logic                     valid_o
);

  logic signed [(XLEN * 2) - 1:0] result_mul;

  //Select the module to instantiate
  generate
  
    if (PERFORMANCE)
      begin 
        MGT_01_booth_radix16 mantissa_multiplier (
        .multiplier_i   ( multiplier_i     ),
        .multiplicand_i ( multiplicand_i   ),
        .clk_i          ( clk_i            ),
        .clk_en_i       ( clk_en_i         ),
        .rst_n_i        ( rst_n_i          ),
        .result_o       ( result_mul       ),  
        .valid_o        ( valid_o          ),
        .fu_state_o     ( fu_state_o       )
        );
      end
    else 
      begin 
        MGT_01_booth_radix4 mantissa_multiplier (
        .multiplier_i   ( multiplier_i     ),
        .multiplicand_i ( multiplicand_i   ),
        .clk_i          ( clk_i            ),
        .clk_en_i       ( clk_en_i         ),
        .rst_n_i        ( rst_n_i          ),
        .result_o       ( result_mul       ),  
        .valid_o        ( valid_o          ),
        .fu_state_o     ( fu_state_o       )
        );
      end
      
  endgenerate
  

    always_comb 
      begin : OUTPUT_LOGIC
        case (operation_i)

                    //Take the lower 32 bits
          MUL_:     result_o = result_mul[XLEN - 1:0];  

                    //Take the upper 32 bits
          MULH_:    result_o = result_mul[63:XLEN];

                    //Take the unsigned upper 32 bits (unsigned X unsigned multiplication)
          MULHU_:   result_o = result_mul[(XLEN * 2) - 1] ? -result_mul[63:XLEN] : result_mul[63:XLEN];


          MULHSU_:  begin 
                      case({multiplier_i[XLEN - 1], multiplicand_i[XLEN - 1]}) 
                                   
                        //Both positive
                        2'b00:            result_o = result_mul[63:XLEN];

                        //Positive, negative
                        2'b01:            result_o = -result_mul[63:XLEN];

                        //Negative, positive
                        2'b10:            result_o = result_mul[63:XLEN];

                        //Both negative
                        2'b11:            result_o = -result_mul[63:XLEN];

                      endcase
                    end
        endcase
      end : OUTPUT_LOGIC

endmodule
