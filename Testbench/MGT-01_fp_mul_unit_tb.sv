`timescale 1ns/1ps

module MGT_01_fp_mul_unit_tb ();

  localparam T = 10;

  //Inputs
  float_t    multiplier_i, multiplicand_i;

  logic      clk_i, clk_en_i;               //Clock signals
  logic      rst_n_i;                       //Reset active low

  //Outputs
  float_t    to_round_unit_o;
  logic      valid_o;
  fu_state_e fu_state_o;
  logic      overflow_o; 
  logic      underflow_o;
  logic      invalid_op_o;

  MGT_01_fp_mul_unit uut (.*);

  //Test

    //Clock 
    always 
      begin
        clk_i = 1'b1;
        #(T / 2);
        clk_i = 1'b0;
        #(T / 2);
      end

    initial
      begin 
      
        clk_en_i = 0;
        rst_n_i = 0;
        
        #T;

        clk_en_i = 1;
        rst_n_i = 1;
        multiplicand_i = 32'h40200000;  //2.5
        multiplier_i = 32'h40200000;

        #(13 * T);

        multiplicand_i = 32'h466fbe89;  //15343.634
        multiplier_i = 32'h40200000;    //2.5

        #(13 * T);

        multiplicand_i = 32'hc0200000;  //-2.5
        multiplier_i = 32'h40200000;    //2.5

        #(13 * T);

        multiplicand_i = 32'hc0200000;  //-2.5
        multiplier_i = 32'h00000000;    //0

        #(13 * T);
        
        multiplicand_i = 32'h4049999a;  //3.15
        multiplier_i = 32'h3ba3d70a;    //0.005     Result: 0.01575 or 
        
        #(13 * T);
        
        multiplicand_i = 32'h3c800005;  //3.15
        multiplier_i = 32'h42800002;    //0.005     Result: 0.01575 or 
        
        #(13 * T);
        
        multiplicand_i = 32'h40600000;  //3.5
        multiplier_i = 32'h40aa3d71;    //5.32     Result: 18.62 
        
        #(13 * T);

        $finish;

      end

endmodule