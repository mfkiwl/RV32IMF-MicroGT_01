/////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                  //
//                                                                             //
// Design Name:    Floating point magnitude unit                               //
// Project Name:   MicroGT-01                                                  //
// Language:       SystemVerilog                                               //
//                                                                             //
// Description:    This unit perform a simple floating point magnitude check   //
//                 between the two inputs. It return the greater or the lesser //
//                 number.                                                     //
/////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_fp_mag_unit 
( //Inputs
  input  float_t  operand_A_i, operand_B_i,

  input  fcmp_ops operation_i,

  input  logic    clk_i, clk_en_i,           //Clock signals
  input  logic    rst_n_i,                   //Reset active low

  //Outputs
  output float_t  to_round_unit_o,           //Result
  output logic    invalid_op_o,
  output logic    overflow_o, 
  output logic    underflow_o
);

  //Result of the comparison
  float_t cmp_result;
  float_t to_round_unit;
  
  ////////////////////
  // Data registers //
  ////////////////////

  //Stages nets
  float_t  cmp_result_ff;
  float_t  operand_A_ff;
  float_t  operand_B_ff;
  fcmp_ops operation_ff;

      always_ff @(posedge clk_i) 
        begin 
          if (!rst_n_i)
            begin 
              operand_A_ff  <= 0;
              operand_B_ff  <= 0;
              cmp_result_ff <= 0;
            end
          else if (clk_en_i)
            begin 
              operand_A_ff  <= operand_A_i;
              operand_B_ff  <= operand_B_i;
              cmp_result_ff <= cmp_result;
              operation_ff  <= operation_i;
            end
        end

  /////////////////////
  // Algorithm logic //
  /////////////////////

      always_comb
        begin : COMPARE_BLOCK 
          if (operation_i == FMIN_)
            begin 
              //If A is negative and B is positive
              if (operand_A_i.sign & (!operand_B_i.sign))
                cmp_result = operand_A_i;
              //If A is positive and B is negative
              else if ((!operand_A_i.sign) & operand_B_i.sign)
                cmp_result = operand_B_i;
              //If both are negative or positive
              else 
                begin 
                  //If the A's exponent is negative and B's one is positive
                  if ((~operand_A_i.exponent[7]) & operand_B_i.exponent[7])
                    cmp_result = operand_A_i;
                  //If the B's exponent is negative and A's one is positive
                  else if (operand_A_i.exponent[7] & (~operand_B_i.exponent[7]))
                    cmp_result = operand_B_i;
                  //If both exponents are negative or positive
                  else 
                    begin
                      //Compare the two mantissas 
                      if (operand_A_i.mantissa > operand_B_i.mantissa)
                        cmp_result = operand_B_i;
                      else 
                        cmp_result = operand_A_i;
                    end
                end
            end
          //Operation is FMAX
          else 
            begin 
              //If A is negative and B is positive
              if (operand_A_i.sign & (!operand_B_i.sign))
                cmp_result = operand_B_i;
              //If A is positive and B is negative
              else if ((!operand_A_i.sign) & operand_B_i.sign)
                cmp_result = operand_A_i;
              //If both are negative or positive
              else 
                begin 
                  //If the A's exponent is negative and B's one is positive
                  if ((~operand_A_i.exponent[7]) & operand_B_i.exponent[7])
                    cmp_result = operand_B_i;
                  //If the B's exponent is negative and A's one is positive
                  else if (operand_A_i.exponent[7] & (~operand_B_i.exponent[7]))
                    cmp_result = operand_A_i;
                  //If both exponents are negative or positive
                  else 
                    begin
                      //Compare the two mantissas 
                      if (operand_A_i.mantissa > operand_B_i.mantissa)
                        cmp_result = operand_A_i;
                      else 
                        cmp_result = operand_B_i;
                    end
                end
            end

        end : COMPARE_BLOCK

  ////////////////////
  //  Output logic  //
  ////////////////////

  //NAN logic check
  logic is_nan_A, is_nan_B;

  //If operands are signaling NaNs
  logic is_sign_A, is_sign_B;

  logic [31:0] not_a_nan;

  //Select the operand 
  assign not_a_nan = is_nan_A ? operand_B_ff : operand_A_ff;

  //Check 
  assign is_nan_A = (&operand_A_ff.exponent) & (|operand_A_ff.mantissa);
  assign is_nan_B = (&operand_B_ff.exponent) & (|operand_B_ff.mantissa);

  assign is_sign_A = operand_A_ff.sign & is_nan_A;
  assign is_sign_B = operand_B_ff.sign & is_nan_B;

  //Infinity logic check
  logic is_infty_A, is_infty_B;

  assign is_infty_A = (&operand_A_ff.exponent) & (~|operand_A_ff.mantissa);
  assign is_infty_B = (&operand_B_ff.exponent) & (~|operand_B_ff.mantissa);
  
      always_comb
        begin : OUTPUT_LOGIC
          
          //If result is a signaling NaN
          invalid_op_o = to_round_unit.sign & (&to_round_unit.exponent) & (|to_round_unit.mantissa);
          
          //If it's positive infinity
          overflow_o = to_round_unit.sign & (&to_round_unit.exponent) & (~|to_round_unit.mantissa);
          
          //If it's negative infinity or denormalized
          underflow_o = ((~|to_round_unit.exponent) & (|to_round_unit.mantissa)) 
                        | (to_round_unit.sign & (&to_round_unit.exponent) & (~|to_round_unit.mantissa));

          //If only one is a NaN 
          if (is_nan_A ^ is_nan_B)
            begin
              to_round_unit = not_a_nan;
            end
          //If both are NaNs
          else if (is_nan_A & is_nan_B)
            begin 
              to_round_unit = CANO_NAN;
            end
          //If they are both infinities
          else if (is_infty_A & is_infty_B)
            begin 
              //If operation is FMAX and both are negative => out = N_INFINITY
              to_round_unit = ((operation_ff == FMAX_) & (operand_A_ff.sign & operand_B_ff.sign)) ? N_INFTY : P_INFTY; 
            end
          else if (is_infty_A ^ is_infty_B)
            begin 
              if (is_infty_A & (!is_infty_B))
                begin 
                  //If A is a positive infinity and operation is FMAX or if If A is a negative infinity and operation is FMIN
                  to_round_unit = ((operation_ff == FMAX_) ~^ (!operand_A_ff.sign)) ? operand_A_ff : operand_B_ff;
                end
              else
                begin 
                  //If B is a positive infinity and operation is FMAX or if If B is a negative infinity and operation is FMIN
                  to_round_unit = ((operation_ff == FMAX_) ~^ (!operand_B_ff.sign)) ? operand_B_ff : operand_A_ff;
                end 
            end
          //Default
          else 
            begin 
              to_round_unit = cmp_result_ff;
            end     
        end : OUTPUT_LOGIC
  
  assign to_round_unit_o = to_round_unit;
                           
endmodule
