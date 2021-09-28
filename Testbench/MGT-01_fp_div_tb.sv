`timescale 1ns/1ns 

module MGT_01_fp_div_unit_tb ();

  localparam T = 10;

  //Inputs
  float_t    dividend_i, divisor_i; 

  logic      clk_i, clk_en_i;               //Clock signals
  logic      rst_n_i;                       //Reset active low

  //Outputs
  float_t    to_round_unit_o;   //Result 
  logic      valid_o;
  fu_state_e fu_state_o;
  logic      overflow_o; 
  logic      underflow_o; 
  logic      invalid_op_o;
  logic      zero_divide_o;
 
  fsm_state_e fsm;
  logic [24:0] mantissa, remainder;

  MGT_01_fp_div_unit uut (.*);

  always 
    begin 
      clk_i = 0; #5;
      clk_i = 1; #5;
    end

  initial
    begin 
      #(2 * T);
      
      clk_en_i = 0;
      rst_n_i = 0;
        
      #T;

      clk_en_i = 1;
      rst_n_i = 1;
      dividend_i = 32'h4119999A;  //9.6
      divisor_i = 32'h40FCCCCD;   //7.9

      #(32 * T);

      assert (to_round_unit_o == 32'h3F9B8B57) //1.215189873
        else $error("Assertion failed!");

      dividend_i = 32'h4119999A;  //9.6
      divisor_i = 32'h40FCCCCD;   //7.9

      #(8 * T);

      clk_en_i = 0;

      #(5 * T);

      clk_en_i = 1;

      #(24 * T);

      assert (to_round_unit_o == 32'h3F9B8B57) //1.215189873
        else $error("Assertion failed!");

      dividend_i = 32'h4119999A;  //9.6
      divisor_i = 32'h0;

      #(32 * T);

      assert (to_round_unit_o == P_INFTY) 
        else $error("Assertion failed!");

      dividend_i = 32'h4119999A;  //9.6
      divisor_i = S_NAN;

      #(32 * T);

      assert (to_round_unit_o == Q_NAN) 
        else $error("Assertion failed!");

      dividend_i = 32'h3A6BEDFA;  //0.0009
      divisor_i = 32'h3C75C28F;   //0.015

      #(32 * T);

      assert (to_round_unit_o == 32'h3D75C28F) //0.06
        else $error("Assertion failed!");

      dividend_i = 32'h3DCCCCCD;  //0.1
      divisor_i = 32'h2B8CBCCC;   //10^-12

      #(32 * T);

      assert (to_round_unit_o == 32'h51BA43B7) //10^11
        else $error("Assertion failed!");

      dividend_i = 32'h3DCCCCCD;  //0.1
      divisor_i = 32'h7E967699;   //10^38

      #(32 * T);

      assert (to_round_unit_o == 32'h000AE398) //10^-39 (denorm)
        else $error("Assertion failed!");

      dividend_i = 32'h42C80000;  //100
      divisor_i = 32'h03AA2425;   //10^-37

      #(32 * T);

      assert (to_round_unit_o == P_INFTY) //10^39 (denorm)
        else $error("Assertion failed!");

      dividend_i = 32'h42C80000;  //100
      divisor_i = N_INFTY;   

      #(32 * T);

      assert (to_round_unit_o == N_ZERO) //10^39 (denorm)
        else $error("Assertion failed!");

      dividend_i = 32'h42C80000;  //100
      divisor_i = P_INFTY;   

      #(32 * T);

      assert (to_round_unit_o == P_ZERO) //10^39 (denorm)
        else $error("Assertion failed!");

      dividend_i = P_ZERO;  //100
      divisor_i = P_ZERO;   

      #(32 * T);

      assert (to_round_unit_o == Q_NAN) //10^39 (denorm)
        else $error("Assertion failed!");

      dividend_i = 32'h42C80000;  //100
      divisor_i = 32'h02081CEA;   //10^-37

      #(32 * T);

      assert (to_round_unit_o == P_INFTY) //10^39 (denorm)
        else $error("Assertion failed!");

      dividend_i = 32'h48220399;  //165902.3864
      divisor_i = 32'h40B5EAB3;   //5.6849

      #(32 * T);

      assert (to_round_unit_o == 32'h46E3FDFB) //29182.99115
        else $error("Assertion failed!");
        
      $stop;
    end

endmodule