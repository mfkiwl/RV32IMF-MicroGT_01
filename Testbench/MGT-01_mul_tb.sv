`timescale 1ns/1ps

module MGT_01_mul_tb ();
  
  localparam T = 10;
  
  //Inputs
  data_u           op_A_i;      //Multiplicand
  data_u           op_B_i;      //Multiplier

  logic            clk_i;
  logic            clk_en_i;    //Clock enable to stall the pipelin

  mul_ops_e        ops_i;       //Operation to perform
  
  //Outputs
  data_u           result_o;    //32 bits result selected from 64 bit result
  

  //UUT intantiation
  MGT_01_mul_IP uut (.*);

  //Test

    //Clock 
    always 
      begin
        clk_i = 1'b1;
        #(T / 2);
        clk_i = 1'b0;
        #(T / 2);
      end

    //Initial value
    initial 
      begin
        op_A_i = 32'd9;
        op_B_i = 32'd10;
        clk_en_i = 1'b1;
        ops_i = MUL_U;
        #(4 * T);
      end

    //Stimuli
    initial 
      begin
        op_A_i = 32'd9;
        op_B_i = -32'd10;
        ops_i = MUL_U;
        
        #(4 * T);
        
        op_A_i = 32'd45;
        op_B_i = 32'd1;
        ops_i = MUL_U;
        
        #(4 * T);
        
        op_A_i = 32'd91234;
        op_B_i = 32'd102345;
        ops_i = MULH_U;
        
        #(6 * T);

//        op_A_i = 32'd90;
//        op_B_i = 32'd10;
//        ops_i = MUL_U;

//        #T;

//        op_A_i = -32'd9;
//        op_B_i = 32'd10;
//        ops_i = MUL_U;

//        #T;

//        op_A_i = -32'd9;
//        op_B_i = -32'd10;
//        ops_i = MUL_U;

//        #T;

//        op_A_i = 32'd9;
//        op_B_i = 32'd10;
//        ops_i = MULH_U;

//        #T;

//        clk_en_i = 1'b0;

//        #(2 * T);

//        clk_en_i = 1'b1;

//        #T;

//        op_A_i = 32'd9235;
//        op_B_i = 32'd1000;
//        ops_i = MULH_U;

//        #T;

//        op_A_i = -32'd9235;
//        op_B_i = 32'd1000;
//        ops_i = MULH_U;

//        #T;

//        op_A_i = -32'd9235;
//        op_B_i = -32'd1000;
//        ops_i = MULH_U;

//        #T;

//        op_A_i = -32'd9;
//        op_B_i = 32'd10;
//        ops_i = MULHSU_U;

//        #T;

//        op_A_i = 32'd9;
//        op_B_i = -32'd10;
//        ops_i = MULHSU_U;

//        #T;

//        op_A_i = -32'd9;
//        op_B_i = -32'd10;
//        ops_i = MULHSU_U;

//        #T;

//        op_A_i = 32'd9;
//        op_B_i = -32'd10;
//        ops_i = MULHU_U;

//        #T;

//        op_A_i = -32'd9;
//        op_B_i = -32'd10;
//        ops_i = MULHU_U;

//        #T;

//        op_A_i = 32'd9;
//        op_B_i = 32'd10;
//        ops_i = MULHU_U;

//        #T;
        $stop;
      end

endmodule
//PASSED!