`timescale 1ns/1ps

`include "Instruction_pkg.svh"
`include "Modules_pkg.svh"

module MGT_01_multiply_unit_tb ();
  
  localparam T = 10;

  //Inputs
  logic signed [XLEN - 1:0]        multiplier_i, multiplicand_i; 

  logic                            clk_i, clk_en_i;               //Clock signals
  logic                            rst_n_i;                       //Reset active low

  mul_ops_e                        operation_i;
  
  //Outputs
  logic signed [XLEN - 1:0]        result_o;                      
  fu_state_e                       fu_state_o;                    //Functional unit state
    

  MGT_01_multiply_unit uut (.*);
  
  //TB signal
  logic signed [(XLEN * 2) - 1:0]  result_64;
  
  //Test
  
    assign result_64 = multiplier_i * multiplicand_i;

    //Clock 
    always 
      begin
        clk_i = 1'b1;
        #(T / 2);
        clk_i = 1'b0;
        #(T / 2);
      end

    always @(posedge clk_i) 
      begin
        rst_n_i = 1'b0;
        clk_en_i = 1'b1;
        operation_i = MUL_;
        multiplier_i = 32'd0;
        multiplicand_i = 32'd0; 
        
        #(2 * T);
        
        rst_n_i = 1'b1;
        clk_en_i = 1'b1;
        operation_i = MUL_;
        multiplier_i = 32'd10;
        multiplicand_i = 32'd20;      

        #(17 * T);
        
        multiplier_i = 32'd100;
        multiplicand_i = -32'd200;      
        operation_i = MUL_;
            
        #(17 * T);
        
        multiplier_i = 32'd150;
        multiplicand_i = 32'd1000;      
        operation_i = MUL_;
      
        #(17 * T);
               
        multiplier_i = -32'd10;
        multiplicand_i = -32'd20;       
        operation_i = MULH_;
        
        #(17 * T);
               
        multiplier_i = 32'hFFFFFFFF;
        multiplicand_i = 32'h80000000;  
        operation_i = MULHU_;

        #(17 * T);
        

        $stop;
      end

endmodule
