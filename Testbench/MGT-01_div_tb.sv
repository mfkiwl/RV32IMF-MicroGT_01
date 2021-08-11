`timescale 1ns/1ps

module MGT_01_div_tb ();
  
  localparam T = 10;

  //Inputs
  data_u    dividend_i;   //Dividend
  data_u    divisor_i;    //Divisor

  logic     clk_i;
  logic     clk_en_i;
  logic     rst_n_i;      //Reset active low

  logic      is_division_i;  //Is a division instruction
  div_ops_e  ops_i;        //Select bits and signed or unsigned operation

  //Outputs
  data_u      result_o;
  logic       div_by_zero_o;        //Exception bit
  fu_state_e  fu_state_o;



  //UUT intantiation
  MGT_01_div_IP uut (.*);

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
        rst_n_i = 1'b0;
        ops_i = DIV_;
        clk_en_i = 1'b1;
        dividend_i = 1;
        divisor_i = 1;
        is_division_i = 0;
        
      end

    //Stimuli
    initial 
      begin
        rst_n_i = 1'b0;
        
        
        #T;
        
        rst_n_i = 1'b1;
        
        #T;
        
        is_division_i = 1;
        dividend_i = 32'd100;
        divisor_i = 32'd5;      
        ops_i = DIV_;

        #(37 * T);  

        dividend_i = 32'd900;
        divisor_i = 32'd5;      
        ops_i = REM_;

        #(37 * T);  

        dividend_i = -32'd80;
        divisor_i = 32'd5;      
        ops_i = DIV_;

        #(37 * T);

        dividend_i = -32'd402;
        divisor_i = 32'd5;      
        ops_i = REM_;
        
        #(37 * T);
        
        dividend_i = -32'd80;
        divisor_i = 32'd0;
        ops_i = DIV_;
        
        #(50 * T);
        
        dividend_i = -32'd33;
        divisor_i = 32'd8;
        ops_i = DIVU_;
        
        #(37 * T);
        
        dividend_i = -32'd0;
        divisor_i = 32'd8;
        ops_i = DIVU_;
        
        #(37 * T);
        
        
      $stop;    
      end

endmodule
//PASSED!