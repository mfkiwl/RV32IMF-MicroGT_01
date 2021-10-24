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


  MGT_01_fp_div_unit uut (.*);

  initial
      begin 
        clk_i = 1;
        rst_n_i = 0;
        clk_en_i = 0;
      end
      
    //Clock 
    always #(T / 2) clk_i = !clk_i;

  initial
    begin 
      
      clk_en_i = 0;
      rst_n_i = 0;
        
      #T;

      clk_en_i = 1;
      rst_n_i = 1;
      dividend_i = 32'h4119999A;  //9.6
      divisor_i = 32'h40FCCCCD;   //7.9

      #(32 * T);

      assert (to_round_unit_o == 32'h3F9B8B57) //1.215189873
        $display("TEST 1: PASSED"); 
      else
        $display("TEST 1: FAILED");

      dividend_i = 32'h4119999A;  //9.6
      divisor_i = 32'h40FCCCCD;   //7.9

      #(8 * T);

      clk_en_i = 0;

      #(5 * T);

      clk_en_i = 1;

      #(24 * T);

      assert (to_round_unit_o == 32'h3F9B8B57) //1.215189873
        $display("TEST 2: PASSED"); 
      else
        $display("TEST 2: FAILED");

      dividend_i = 32'h4119999A;  //9.6
      divisor_i = 32'h0;

      #(32 * T);

      assert (to_round_unit_o == P_INFTY) 
        $display("TEST 3: PASSED"); 
      else
        $display("TEST 3: FAILED");

      dividend_i = 32'h4119999A;  //9.6
      divisor_i = S_NAN;

      #(32 * T);

      assert (to_round_unit_o == Q_NAN) 
        $display("TEST 4: PASSED"); 
      else
        $display("TEST 4: FAILED");

      dividend_i = 32'h3A6BEDFA;  //0.0009
      divisor_i = 32'h3C75C28F;   //0.015

      #(32 * T);

      assert (to_round_unit_o == 32'h3D75C28F) //0.06
        $display("TEST 5: PASSED"); 
      else
        $display("TEST 5: FAILED");

      dividend_i = 32'h3DCCCCCD;  //0.1
      divisor_i = 32'h2B8CBCCC;   //10^-12

      #(32 * T);

      assert (to_round_unit_o == 32'h51BA43B7) //10^11
        $display("TEST 6: PASSED"); 
      else
        $display("TEST 6: FAILED AT TIME %t", $time);

      dividend_i = 32'h3DCCCCCD;  //0.1
      divisor_i = 32'h7E967699;   //10^38

      #(32 * T);

      assert (underflow_o) //10^-39 (denorm)
        $display("TEST 7: PASSED"); 
      else
        $display("TEST 7: FAILED AT TIME %t", $time);

      dividend_i = 32'h42C80000;  //100
      divisor_i = 32'h03AA2425;   //10^-36

      #(32 * T);

      assert (to_round_unit_o[31:4] == 32'h7E96769) //10^38 
        $display("TEST 8: PASSED"); 
      else
        $display("TEST 8: FAILED AT TIME %t", $time);

      dividend_i = 32'h42C80000;  //100
      divisor_i = N_INFTY;   

      #(32 * T);

      assert (to_round_unit_o == N_ZERO) 
        $display("TEST 9: PASSED"); 
      else
        $display("TEST 9: FAILED AT TIME %t", $time);

      dividend_i = 32'h42C80000;  //100
      divisor_i = P_INFTY;   

      #(32 * T);

      assert (to_round_unit_o == P_ZERO) 
        $display("TEST 10: PASSED"); 
      else
        $display("TEST 10: FAILED AT TIME %t", $time);

      dividend_i = P_ZERO;  //100
      divisor_i = P_ZERO;   

      #(32 * T);

      assert (to_round_unit_o == CANO_NAN) 
        $display("TEST 11: PASSED"); 
      else
        $display("TEST 11: FAILED AT TIME %t", $time);

      dividend_i = 32'h42C80000;  //100
      divisor_i = 32'h02081CEA;   //10^-37

      #(32 * T);

      assert (to_round_unit_o == P_INFTY && overflow_o == 1) //10^39 
        $display("TEST 12: PASSED"); 
      else
        $display("TEST 12: FAILED AT TIME %t", $time);

      dividend_i = 32'h48220399;  //165902.3864
      divisor_i = 32'h40B5EAB3;   //5.6849

      #(32 * T);

      assert (to_round_unit_o[31:4] == 32'h46E3FDF) //29182.99115
        $display("TEST 13: PASSED"); 
      else
        $display("TEST 13: FAILED AT TIME %t", $time);

      dividend_i = 32'h1e3ce508; // 10^-20 
      divisor_i = 32'h4e6e6b28;  // 10^9

      #(32 * T);

      assert (to_round_unit_o[31:4] == 32'h0f4ad2f) 
        $display("TEST 14: PASSED"); 
      else
        $display("TEST 14: FAILED AT TIME %t", $time);

      dividend_i = 32'h0da24260; // 10^-30 
      divisor_i = 32'h4e6e6b28;  // 10^9

      #(32 * T);

      assert (underflow_o) 
        $display("TEST 14: PASSED"); 
      else
        $display("TEST 14: FAILED AT TIME %t", $time);
        
      $stop;
    end

endmodule
