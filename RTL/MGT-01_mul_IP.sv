////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Multiply Unit                                              //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This unit perform an XLEN x XLEN multiplication generating //
//                 a 2XLEN result. The multiplier itself has 3 latency cycle. // 
////////////////////////////////////////////////////////////////////////////////

`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_mul_IP 
( //Inputs
  input  data_u           multiplicand_i,    //Multiplicand
  input  data_u           multiplier_i,      //Multiplier

  input  logic            clk_i,
  input  logic            clk_en_i,    //Clock enable to stall the pipeline

  input  mul_ops_e        ops_i,       //Operation to perform
  
  //Outputs
  output data_u           result_o     //32 bits result selected from 64 bit result
);

  typedef struct packed {
      logic [XLEN - 1:0] high;  //63:32
      logic [XLEN - 1:0] low;   //31:0
  } mul_res_s;

  mul_res_s   result_mul_sm, 
              result_mul_mm, 
              result_mul_um;    //Output of multipliers

  //MODULES INSTANTIATION IP VIVADO 

  sign_mult signed_multiplier (
  .CLK( clk_i                 ),  
  .A  ( multiplicand_i.s_data ),      
  .B  ( multiplier_i.s_data   ),      
  .CE ( clk_en_i              ),    
  .P  ( result_mul_sm         )      
  );

  unsign_mult unsigned_multiplier (
  .CLK( clk_i                 ),  
  .A  ( multiplicand_i.u_data ),      
  .B  ( multiplier_i.u_data   ),      
  .CE ( clk_en_i              ),    
  .P  ( result_mul_um         )     
  );

  sign_x_unsign_mult mix_multiplier (
  .CLK( clk_i                 ),  
  .A  ( multiplicand_i.s_data ),      
  .B  ( multiplier_i.u_data   ),      
  .CE ( clk_en_i              ),    
  .P  ( result_mul_mm         )
  );
  
      always_comb 
        begin : SELECT_OUTPUT
          unique case (ops_i)

            MUL_:    result_o = result_mul_sm.low;

            MULH_:   result_o = result_mul_sm.high;

            MULHSU_: result_o = result_mul_mm.high;

            MULHU_:  result_o = result_mul_um.high;

          endcase
        end : SELECT_OUTPUT
  
endmodule
