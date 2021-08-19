`timescale 1ns/1ps

`include "Instruction_pkg.svh"
`include "Modules_pkg.svh"

module MGT_01_alu_tb ();

  localparam T = 10;  //Clock cycle in nanoseconds

  //Signals
  //Inputs
  data_u     op_A_i, op_B_i;            //Operators
  alu_ops_e  ops_i;                     //Operations

  //Outputs
   logic      comparison_o;              //Comparison flag
   data_bus_t result_o;
   logic      fu_state_o;                //Functional unit READY or BUSY


  //UUT intantiation
  MGT_01_alu uut (.*);

  //Test

    //Initial values
    initial 
      begin
        op_A_i = 32'b0;
        op_B_i = 32'b0;
        ops_i  = ALU_ADD;
        #(T / 2);
      end

    //Stimuli               Result:
    initial 
      begin
        op_A_i = 32'd100;
        op_B_i = 32'd200;   //300
        ops_i  = ALU_ADD;

        #T; 

        op_A_i = 32'd100;
        op_B_i = -32'd200;  //-100
        ops_i  = ALU_ADD;

        #T;

        op_A_i = -32'd100;
        op_B_i = -32'd200;  //-300
        ops_i  = ALU_ADD;

        #T;

        op_A_i = 32'd500;
        op_B_i = 32'd200;   //300
        ops_i  = ALU_SUB;

        #T;

        op_A_i = 32'd500;
        op_B_i = -32'd200;  //700
        ops_i  = ALU_SUB;

        #T;

        op_A_i = -32'd500;
        op_B_i = -32'd200;  //-300
        ops_i  = ALU_SUB;

        #T;

        op_A_i = 32'd3;
        op_B_i = 32'd5;   
        ops_i  = ALU_SRL;

        #T;

        op_A_i = 32'd500;
        op_B_i = 32'd200;   //300
        ops_i  = ALU_EQ;

        #T;

        op_A_i = 32'd200;
        op_B_i = 32'd200;   //300
        ops_i  = ALU_EQ;

        #T;

        op_A_i = 32'd500;
        op_B_i = 32'd200;   //300
        ops_i  = ALU_GE;

        #T;

        op_A_i = -32'd500;
        op_B_i = 32'd200;   //300
        ops_i  = ALU_GE;

        #T;
        $stop;
      end
endmodule
//PASSED!
