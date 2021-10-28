////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Fused Multiply Add                                         //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Perform a multiplication followed by an addition. It can   //
//                 compute 4 variation:                                       //
//                 (A * B) + C                                                //
//                -(A * B) + C                                                //
//                 (A * B) - C                                                //
//                -(A * B) - C                                                //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_fp_fused_muladd 
( //Inputs
  input  logic        clk_i, clk_en_i, //Clock signals
  input  logic        rst_n_i,         //Reset active low

  input  fmuladd_ops  operation_i,

  input  float_t      rs1_i, rs2_i, rs3_i,   //Operands

  output float_t      to_round_unit_o,

  output fu_state_e   fu_state_o,
  output logic        valid_o,
  output logic        invalid_op_o,
  output logic        overflow_o,
  output logic        underflow_o
);

  ///////////////
  // FSM LOGIC //
  ///////////////

  typedef enum logic [1:0] {IDLE, FMUL, FADD, VALID} fsm_state_e;

  // IDLE: the unit is ready to accept new values
  // FMUL: the unit perform a multiplication between the first two operands
  // FADD: the unit perform an addition between the result of the multiplication and the third operand
  // VALID: the result is valid, ready to be rounded in the round unit

  fsm_state_e crt_state, nxt_state;

  //Valid signals coming out from the computational blocks
  logic fmul_valid, fadd_valid;

  logic rst_n_dly;  //Reset delayed

      // We delay the reset signals by 1 cycle because the FSM should
      // stay 2 cycles in the IDLE stage when resetted

      always_ff @(posedge clk_i)
        begin
          rst_n_dly <= rst_n_i;
        end

      //State register
      always_ff @(posedge clk_i)
        begin : STATE_REG
          if (!rst_n_i)
            crt_state <= IDLE;
          else if (clk_en_i)   
            crt_state <= nxt_state;
        end : STATE_REG

      //Next state logic
      always_comb 
        begin
          unique case (crt_state)

            IDLE:       nxt_state = (~rst_n_dly) ? IDLE : FMUL;

            FMUL:       nxt_state = fmul_valid ? FADD : FMUL;  

            FADD:       nxt_state = fadd_valid ? VALID : FADD;

            VALID:      nxt_state = IDLE;

            default:    nxt_state = IDLE;
            
          endcase
        end

  ////////////////////
  // Data registers //
  ////////////////////

  float_t rs1_out, rs2_out, rs3_out;

  float_t result_fadd, result_fmul, to_round_unit;

  logic rs3_sign;

  //New sign of rs3 based on the operation
  assign rs3_sign = (operation_i == FMSUB_ | operation_i == FNMADD_) ? !rs3_i.sign : rs3_i.sign;

      always_ff @(posedge clk_i) 
        begin : DATA_REGISTER
          if (!rst_n_i)
            begin 
              rs1_out <= 0;
              rs2_out <= 0;
              rs3_out <= 0;
            end
          else if (clk_en_i & (crt_state == IDLE))
            begin 
              rs1_out <= rs1_i;
              rs2_out <= rs2_i;
              rs3_out <= {rs3_sign, rs3_i.exponent, rs3_i.mantissa};
            end
        end : DATA_REGISTER

      always_ff @(posedge clk_i) 
        begin : OUTPUT_REGISTER
          if (!rst_n_i)
            begin 
              to_round_unit <= 0;
            end
          else if (clk_en_i & (crt_state == VALID))
            begin 
              to_round_unit <= result_fadd;
            end
        end : OUTPUT_REGISTER

  /////////////////////
  // Algorithm logic //
  /////////////////////

  //Enable signals
  logic fmul_en, fadd_en;

  assign fmul_en = crt_state == FMUL;
  assign fadd_en = crt_state == FADD;

  logic overflow_fmul, underflow_fmul, invalid_op_fmul;
  logic overflow_fadd, underflow_fadd, invalid_op_fadd;


  //Floating point multiply block 
  MGT_01_fp_mul_unit  multiplication_block (
    .multiplier_i    ( rs1_out                             ),
    .multiplicand_i  ( rs2_out                             ),
    .clk_i           ( clk_i                               ),
    .clk_en_i        ( fmul_en                             ),
    .rst_n_i         ( rst_n_i                             ),
    .to_round_unit_o ( result_fmul                         ),
    .valid_o         ( fmul_valid                          ),
    .fu_state_o      ( /* WON'T BE CONNECTED TO ANYTHING*/ ),
    .overflow_o      ( overflow_fmul                       ),
    .underflow_o     ( underflow_fmul                      ),
    .invalid_op_o    ( invalid_op_fmul                     )
  );

  //Rs1 * Rs2
  float_t rs12_in, rs12_out;

  assign rs12_in.sign = (operation_i == FNMSUB_ | operation_i == FNMADD_) ? !result_fmul.sign : result_fmul.sign;
  assign rs12_in.exponent = result_fmul.exponent;
  assign rs12_in.mantissa = result_fmul.mantissa;

      always_ff @(posedge clk_i) 
        begin 
          if (!rst_n_i)
            begin 
              rs12_out <= 0;
            end           
          else if (clk_en_i)
            begin 
              rs12_out <= rs12_in;
            end
        end

  //Floating point adder block
  MGT_01_fp_add_unit adder_block (
    .op_A_i          ( rs12_out                            ),
    .op_B_i          ( rs3_out                             ),
    .clk_i           ( clk_i                               ),
    .clk_en_i        ( fadd_en                             ),
    .rst_n_i         ( rst_n_i                             ),
    .operation_i     ( FADD_                               ),
    .to_round_unit_o ( result_fadd                         ),
    .valid_o         ( fadd_valid                          ),
    .fu_state_o      ( /* WON'T BE CONNECTED TO ANYTHING*/ ),
    .overflow_o      ( overflow_fadd                       ),
    .underflow_o     ( underflow_fadd                      ),
    .invalid_op_o    ( invalid_op_fadd                     )
  );

  //Detect if one block launched an exception
  logic overflow, underflow, invalid_op;

  assign overflow = overflow_fadd | overflow_fmul;
  assign underflow = underflow_fadd | underflow_fmul;
  assign invalid_op = invalid_op_fadd | invalid_op_fmul;

  //////////////////
  // Output logic //
  //////////////////

      always_comb
        begin 
          if (overflow)
            begin 
              to_round_unit_o = P_INFTY;
            end 
          else if (underflow)
            begin 
              to_round_unit_o = N_INFTY;
            end
          else if (invalid_op)
            begin 
              to_round_unit_o = CANO_NAN;
            end
          else 
            begin 
              to_round_unit_o = to_round_unit;
            end
        end

  assign overflow_o = overflow;
  assign underflow_o = underflow;
  assign invalid_op_o = invalid_op;

  assign valid_o = (crt_state == VALID);
  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;
  
endmodule
