`timescale 1ns/1ps

module MGT_01_fp_sqrt_unit_tb ();

  localparam T = 10;

  //Inputs
  logic      clk_i;    
  logic      clk_en_i;
  logic      rst_n_i;       //Reset active low

  float_t    radicand_i;

  //Outputs
  float_t    root_o;        //Result     
  
  logic      valid_o;
  fu_state_e fu_state_o;
  logic      invalid_op_o;
  logic      overflow_o;
  logic      underflow_o; 


  MGT_01_fp_sqrt_unit uut (.*);

    initial
      begin 
        clk_i = 1;
        rst_n_i = 0;
        clk_en_i = 0;
      end

    always #(T / 2) clk_i = !clk_i;

    initial
      begin
        rst_n_i = 0;
        clk_en_i = 0;
        
        #T;
        
        clk_en_i = 1;
        rst_n_i = 1;
        radicand_i = 32'h40DC8B44;  //6.892 => 2.625261892 or 0x4028044A
        
        #(T * 29);

        radicand_i = 32'h40000000;  //2 => 1.41421356237 or 0x3FB504F3

        #(T * 29);

        radicand_i = 32'h45225AFB;  //2597.6864 => 50.96750337224 or 0x424BDEB9

        #(T * 29);

        radicand_i = 32'h3BA3D70A;  //0.005 => 0.0707106 or 0x3D90D0B8

        #(T * 29);

        radicand_i = 32'h0014D0B8;  //1.911584 * 10^-39 => 4.3721665 * 10^-20 or 0x1F4E7840

        #(T * 29);

        radicand_i = 32'hC0000000;  //-2 => Invalid operation

        #(T * 29);

        radicand_i = P_INFTY;

        #(T * 29);

        assert ((root_o == P_INFTY) && (overflow_o == 1))
          $display("TEST: Radicand = POSITIVE INFINITY completed! \n");
        else 
          $error("TEST: Radicand = POSITIVE INFINITY failed!");

        radicand_i = N_INFTY;

        #(T * 29);

        assert ((root_o == CANO_NAN) && (invalid_op_o == 1))
          $display("TEST: Radicand = NEGATIVE INFINITY completed! \n");
        else 
          $error("TEST: Radicand = NEGATIVE INFINITY failed!");

        radicand_i = S_NAN;

        #(T * 29);

        assert ((root_o == CANO_NAN) && (invalid_op_o == 1))
          $display("TEST: Radicand = SIGNALING NAN completed! \n");
        else 
          $error("TEST: Radicand = SIGNALING NAN failed!");
        
        $stop;
      end
      
endmodule
