`timescale 1ns/1ps

module MGT_01_nr_sqrt_tb ();

  localparam T = 10;
  localparam DATA_WIDTH = 24;
  localparam OUT_WIDTH = DATA_WIDTH / 2;

  //Inputs
  logic                    clk_i;    
  logic                    clk_en_i;
  logic                    rst_n_i;

  logic [DATA_WIDTH - 1:0] radicand_i;

  //Outputs
  logic [OUT_WIDTH - 1:0]  root_o; 
  logic [OUT_WIDTH - 1:0]  remainder_o;  
  
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
      radicand_i = 'd4;

      #(T * 15);

      radicand_i = 'd16;

      #(T * 15);

      radicand_i = 'd35;

      #(T * 15);

      radicand_i = -'d16;

      #(T * 20);

      $stop;
    end

endmodule