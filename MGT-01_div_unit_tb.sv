`timescale 1ns/1ps

module MGT_01_div_unit_tb ();

  localparam T = 10;
  parameter XLEN = 32;
  //Outputs
  logic signed [XLEN - 1:0]        dividend_i, divisor_i; 

  logic                            clk_i, clk_en_i;               //Clock signals
  logic                            rst_n_i;                       //Reset active low

  div_ops_e                        operation_i;

  //Outputs
  logic signed [XLEN - 1:0]        result_o;                      
  fu_state_e                       fu_state_o;                    //Functional unit state
  logic                            zero_divide;
  

  MGT_01_div_unit uut (.*);

  int signed quotient_exp, remainder_exp;

  assign quotient_exp  = int'(dividend_i) / int'(divisor_i);
  assign remainder_exp = int'(dividend_i) % int'(divisor_i);

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
            rst_n_i = 1'b0; 
            clk_en_i = 1'b0;
            operation_i = DIV_;
            dividend_i = 32'd0;
            divisor_i = 32'd0;
            #(T);
            
            rst_n_i = 1'b1;
            clk_en_i = 1'b1;
            operation_i = DIV_;
            dividend_i = -32'd4;
            divisor_i = 32'd2;

            #(34 * T);

            rst_n_i = 1'b1;
            clk_en_i = 1'b1;
            operation_i = DIV_;
            dividend_i = 32'd20;
            divisor_i = 32'd2;

            #(34 * T);
            
            operation_i = DIV_;
            dividend_i = -32'd20;
            divisor_i = 32'd2;
            
            #(34 * T);
            
            operation_i = DIV_;
            dividend_i = -32'd20;
            divisor_i = -32'd2;
            
            #(34 * T);
            
            operation_i = DIV_;
            dividend_i = -32'd20;
            divisor_i = -32'd0;
            
            #(34 * T);
            
            operation_i = REM_;
            dividend_i = -32'd100;
            divisor_i = -32'd43;    //14
            
            #(34 * T);
            
            operation_i = REM_;
            dividend_i = -32'd100;
            divisor_i = -32'd43;    //2
            
            #(35 * T);

            $stop;

          end

endmodule