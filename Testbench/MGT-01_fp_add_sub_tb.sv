`timescale 1ns/1ps

module MGT_01_fp_add_sub_tb ();

  localparam T = 10;

  //Inputs
  float_t         op_A_i, op_B_i;   //Operands

  float_funct7_e  iw_funct7_i;

  logic           clk_i;
  logic           clk_en_i;         //Enable clock
  logic           rst_n_i;          //Reset active low

  //Outputs
  float_t         result_o;
  fu_state_e      fu_state_o;       //Functional unit state

  logic           underflow_o;
  logic           overflow_o;
  logic           invalid_op_o;     //IEE-754 invalid operation

  
  //UUT intantiation
  MGT_01_fp_add_sub_IP uut (.*);


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
        op_A_i = 0;
        op_B_i = 0;
        iw_funct7_i = FADD;
        clk_en_i = 1'b0;
        rst_n_i = 1'b0;

        #(2 * T);
      end

    //Stimuli
    initial 
      begin
        clk_en_i = 1'b1;
        rst_n_i = 1'b1;
        op_A_i = 32'h41200000;   //10.0
        op_B_i = 32'h40000000;   //2.0
        iw_funct7_i = FADD;      //12.0

        #(5 * T);

        op_A_i = 32'h40600000;   //3.5
        op_B_i = 32'h3fc00000;   //1.5
        iw_funct7_i = FADD;      //5.0

        #(5 * T);

        op_A_i = 32'h40600000;   //3.5
        op_B_i = 32'h3fc00000;   //1.5
        iw_funct7_i = FSUB;      //2.0

        #(5 * T);

        op_A_i = 32'h7fffffff;   //NaN
        op_B_i = 32'h3fc00000;   //1.5
        iw_funct7_i = FSUB;      //2.0

        #(10 * T);

        $stop;

      end

endmodule