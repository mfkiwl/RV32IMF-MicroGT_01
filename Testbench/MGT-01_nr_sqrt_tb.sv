`timescale 1ns/1ps

module MGT_01_nr_sqrt_tb ();

  localparam T = 10;
  localparam DATA_WIDTH = 48;
  localparam OUT_WIDTH = DATA_WIDTH / 2;
  localparam ITERATIONS = (DATA_WIDTH) / 2;

  //Inputs
  logic                    clk_i;    
  logic                    clk_en_i;
  logic                    rst_n_i;

  logic [DATA_WIDTH - 1:0] radicand_i;

  //Outputs
  logic [OUT_WIDTH - 1:0]  root_o; 
  logic [OUT_WIDTH:0]      remainder_o;  
  
  logic                    valid_o;

  MGT_01_nr_sqrt uut (.*);

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
      radicand_i = {24'b011011100100010110100010, 24'b0}; //6.892 mantissa, CORRECT

      #(T * 27);

      radicand_i = {24'b100111000101010100101111, 24'b0}; //10005.29596 mantissa, CORRECT
      
      #(T * 27);

      radicand_i = {24'b100000000000000000000000, 24'b0}; //2 mantissa, CORRECT
      
      #(T * 27);

      radicand_i = {24'b100101001010001010111101, 24'b0}; //148.6357 mantissa, CORRECT

      #(T * 27);

      $stop;
    end

endmodule