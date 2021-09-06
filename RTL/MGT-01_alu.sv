////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    ALU                                                        //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Arithmetic Logic Unit of the core, it perform arithmetic   //
//                 and logic operation, compares and build 32 bit immediate.  //
//                 The ALU doesn't update flags on every operation but only   //
//                 on compares.                                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_alu 
( //Inputs
  input  data_u     op_A_i, op_B_i,            //Operators
  input  alu_ops_e  ops_i,                     //Operations

  //Outputs
  output logic      comparison_o,              //Comparison flag
  output data_bus_t result_o
);

  logic is_equal, is_greater_eq;  //Result comparison
  logic type_data;                //Signed (1) or unsigned (0)

  //COMPARE LOGIC
  assign is_equal = (op_A_i == op_B_i);

  assign type_data = ops_i[0];  //Signed or unsigned

  //                                          Unsigned compares                 Signed compares
  assign is_greater_eq = type_data ? (op_A_i.u_data >= op_B_i.u_data) : (op_A_i.s_data >= op_B_i.s_data);

    always_comb 
      begin : OPERATIONS

        unique case (ops_i)   //Arithmetic and logic operations

          ALU_ADD:     result_o = op_A_i + op_B_i;

          ALU_SUB:     result_o = op_A_i - op_B_i;

          ALU_SLL:     result_o = op_A_i << op_B_i;

          ALU_SRL:     result_o = op_A_i >> op_B_i;

          ALU_SRA:     result_o = op_A_i >>> op_B_i;

          ALU_AND:    result_o = op_A_i & op_B_i;

          ALU_OR:     result_o = op_A_i | op_B_i;

          ALU_XOR:     result_o = op_A_i ^ op_B_i; 

          ALU_BMSK:    result_o = ~op_A_i & op_B_i;   //Bit mask for CSRRC instruction 

          default:     result_o = 0;

        endcase
      end : OPERATIONS

    always_comb 
      begin : COMPARES
        
        unique case (ops_i)

          ALU_EQ:      comparison_o = is_equal;

          ALU_NE:      comparison_o = ~is_equal;

          ALU_LT:      comparison_o = ~is_greater_eq;

          ALU_LTU:     comparison_o = ~is_greater_eq;

          ALU_GE:      comparison_o = is_greater_eq;

          ALU_GEU:     comparison_o = is_greater_eq;

          default:     comparison_o = 0;

        endcase

      end : COMPARES 
endmodule
