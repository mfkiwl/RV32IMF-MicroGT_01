////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    ALU                                                        //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This is a multiplier implementing the radix-4 booth        //
//                 algorithm for multiplication. We are multipling two N      //                                       
//                 numbers and getting a 2 * N result. It is not pipelined    //
//                 and it has N / 4 latency cycle.                            //
////////////////////////////////////////////////////////////////////////////////

//  WARNING!
//  WARNING!
//  WARNING!
//  WARNING!
//
//  THIS MODULE IS NOT TESTED YET!!!!



import MGT_01_PACKAGE::*;
import INSTRUCTION_TYPE::*;

module radix_4_booth_multiplier #(
  parameter DATA_WIDTH = 32
) 
( //Inputs
  input  logic [DATA_WIDTH - 1:0]     op_A_i, op_B_i,  //Operands
  input  logic                        clk_i, rst_n_i,  //Clock and reset 
  input  mul_ops_e                    ops_i,           //Operation to perform
  input  opcode_e                     iw_opcode,
  input  muldiv_funct3_e              iw_funct3,
  input  muldiv_funct7_e              iw_funct7,

  output logic [2 * DATA_WIDTH - 1:0] result_o,
  output fu_state_e                   fu_state_o                        
);
  
  logic [DATA_WIDTH - 1:0]     _P, P_in;          //Partial product
  logic [DATA_WIDTH - 1 :0]    _A, _B;            //Working data
  logic [DATA_WIDTH - 1 :0]    op_A_ff, op_B_ff;  //Flip flop out
  logic [DATA_WIDTH - 1 :0]    A_in, B_in;        //Flip flop in
  logic                        _L, L_in;          //Shifted out bit  
  logic [1:0]                  counter;
  logic                        is_signed;         //If signed multiplication or unsigned
  logic                        is_mul;
  logic [2 * DATA_WIDTH:0]     result_mul;
  logic                        clk_en_res;        //Enable the output

      always_comb 
        begin : TYPE_OP
          unique case (ops_i)
            MUL_U:      is_signed = TRUE;
            MULH_U:     is_signed = TRUE;
            MULHSU_U:   is_signed = TRUE;

            MULHU_U:    is_signed = FALSE;
          endcase

          unique case (iw_funct3)
            MUL_U:      is_mul = 1;
            MULH_U:     is_mul = 1;
            MULHU_U:    is_mul = 1;
            MULHSU_U:   is_mul = 1;

            default:    is_mul = 0;
          endcase
        end : TYPE_OP

  assign _B = op_B_ff;
  assign _A = op_A_ff;

  assign fu_state_o = (counter == 0) ? FREE : BUSY;

      always_ff @(posedge clk_i)
        begin : COUNTER
          if (iw_opcode == REG_OP && is_mul == 1 && iw_funct7 == F7_M)
            counter <= counter + 1;
        end : COUNTER

      always_ff @(posedge clk_i)
        begin
          if (!rst_n_i)
            begin
              _P = 0;
              op_A_ff = 0;
              op_B_ff = 0;
              _L = 0;
            end
          else if (counter == 0)  //Finished multiplication
            begin
              _P = 0;
              op_A_ff = op_A_i;
              op_B_ff = op_B_i;
              _L = 0;
            end
          else      //Not finished 
            begin
              _P = P_in;
              op_A_ff = A_in;
              op_B_ff = B_in;
              _L = L_in;
            end
         end

      always_comb
        begin : BOOTH_ALGORITHM
          for (int i = 0; i < (DATA_WIDTH / 8); i++)
            begin
              unique case ({_A[1:0], _L})   //Analyze the 3 low order bits 
                3'b000:   _P = _P + 0;
                3'b111:   _P = _P + 0;

                3'b001:   _P = _P + _B;
                3'b010:   _P = _P + _B;

                3'b011:   _P = _P + (_B << 1);  //P + (B * 2)

                3'b100:   _P = _P - (_B << 1);

                3'b101:   _P = _P - _B;
                3'b110:   _P = _P - _B;
              endcase

              {_P, _A, _L} = {_P, _A, _L} >>> 2;
            end

          P_in = _P;
          L_in = _L;
          A_in = _A;
          B_in = _B;

        end : BOOTH_ALGORITHM

  assign result_mul = {_P, _A};

  assign clk_en_res = counter == 0;

      always_ff @(posedge clk_i)
        begin
          if (clk_en_res)
            result_o <= result_mul;
        end
endmodule