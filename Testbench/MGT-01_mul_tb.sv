`timescale 1ns/1ps

`include "Instruction_pkg.svh"
`include "Modules_pkg.svh"

module MGT_01_mul_tb ();
  
  localparam T = 10;
  
  //Inputs
  data_u           multiplicand_i;      //Multiplicand
  data_u           multiplier_i;        //Multiplier

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
        multiplicand_i = 32'd1;
        multiplier_i = 32'd1;
        clk_en_i = 1'b1;
        ops_i = MUL_;
        #(4 * T);
      end

    //Stimuli
    initial 
      begin
        //Test the pipeline introducing new input every cycle
        multiplicand_i = 32'd9;
        multiplier_i = 32'd10;
        ops_i = MUL_;
        
        #T;
        
        multiplicand_i = -32'd12;
        multiplier_i = 32'd10;
        ops_i = MUL_;
        
        #T;
        
        multiplicand_i = -32'd100;
        multiplier_i = 32'd10;
        ops_i = MUL_;
        
        #T; 
        
        multiplicand_i = 32'd9;
        multiplier_i = 32'd10;
        ops_i = MUL_;
        
        //Every 4 cycles
        multiplicand_i = 32'd1000;
        multiplier_i = 32'd0;
        ops_i = MUL_;
        
        #(4 * T);
        
        multiplicand_i = 32'd10000;
        multiplier_i = 32'd2;
        ops_i = MUL_;
        
        #(5 * T)
        $stop;
      end

endmodule
//PASSED!
