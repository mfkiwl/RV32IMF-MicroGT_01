`timescale 1ns/1ns 

module MGT_01_nr_div_tb ();

  localparam T = 10;

  //Inputs
  logic signed [23:0]              dividend_i, divisor_i; 

  logic                            clk_i, clk_en_i;               //Clock signals
  logic                            rst_n_i;                       //Reset active low

  //Outputs
  logic signed [23:0]              quotient_o, remainder_o;                      
  logic                            valid_o;
  logic                            zero_divide_o;

  MGT_01_nr_divider uut (.*);

  always 
    begin 
      clk_i = 0; #5;
      clk_i = 1; #5;
    end

  initial
    begin 
      clk_en_i = 0;
      rst_n_i = 0;
        
      #T;
    end

  initial
    begin 
      clk_en_i = 0;
      rst_n_i = 0;
        
      #T;

      clk_en_i = 1;
      rst_n_i = 1;
      dividend_i = 32'd100;
      divisor_i = 32'd5;      //20

      #((26 * T) + 15);

      dividend_i = 32'd10025;
      divisor_i = 32'd8;      //1253

      #((26 * T) + 10);

      dividend_i = 32'd10025;
      divisor_i = 32'd0;   

      #((26 * T) + 5);
      
      dividend_i = 32'd2;
      divisor_i = 32'd1005;   

      #(30 * T);

      $stop;
    end
endmodule