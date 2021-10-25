////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point multiplication unit                         //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This unit perform a simple floating point multiplication.  //
//                 you can select the radix 4 one if you want to lower the    //
//                 resources usage. Select the radix 16 one if you want       //
//                 performance.                                               //
//                                                                            //
// Dependencies:   MGT-01_booth_radix4.sv                                     //
//                 MGT-01_booth_radix16.sv                                    //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"  
  
module MGT_01_fp_mul_unit
( //Inputs
  input  float_t    multiplier_i, multiplicand_i,

  input  logic      clk_i, clk_en_i,               //Clock signals
  input  logic      rst_n_i,                       //Reset active low

  //Outputs
  output float_t    to_round_unit_o,   //Result 
  output logic      valid_o,
  output fu_state_e fu_state_o,
  output logic      overflow_o, 
  output logic      underflow_o, 
  output logic      invalid_op_o 
);

  typedef enum logic [2:0] {IDLE, PREPARE, MULTIPLY, NORMALIZE, VALID} fsm_state_e;

  fsm_state_e crt_state, nxt_state;
  
  // IDLE: The unit is waiting for data
  // PREPARE: Preparing the data to be computed (sign extraction, add exponent)
  // MULTIPLY: Multiply the mantissas
  // NORMALIZE: Normalize the result
  // VALID: The output is valid

  ///////////////
  // FSM LOGIC //
  ///////////////

  logic valid_mantissa; //Multiplied mantissa is valid

  logic rst_n_dly;      //Reset delayed

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
          case (crt_state)

            IDLE:       nxt_state = (~rst_n_dly) ? IDLE : PREPARE;

            PREPARE:    nxt_state = MULTIPLY; 

            //If the result of the multiplier is valid, go to next state
            MULTIPLY:   nxt_state = valid_mantissa ? NORMALIZE : MULTIPLY; 

            NORMALIZE:  nxt_state = VALID;

            VALID:      nxt_state = IDLE;

          endcase
        end


  effective_float_t multiplier_in, multiplicand_in;
  effective_float_t multiplier_out, multiplicand_out;

  float_t result, op_A_out, op_B_out;

      always_ff @(posedge clk_i)
        begin 
          if ((crt_state == PREPARE) & clk_en_i)
            begin 
              op_A_out <= multiplier_i;
              op_B_out <= multiplicand_i;
            end
        end

  //OR the exponent to detect if the number is a 0 (hidden bit is 0 too)
  assign multiplier_in = {multiplier_i.sign, multiplier_i.exponent, |multiplier_i.exponent, multiplier_i.mantissa};
  
  assign multiplicand_in = {multiplicand_i.sign, multiplicand_i.exponent, |multiplicand_i.exponent, multiplicand_i.mantissa};

      always_ff @(posedge clk_i) 
        begin : DATA_REGISTER
          if (!rst_n_i)
            begin 
              multiplier_out <= 33'b0;
              multiplicand_out <= 33'b0;
            end
          if (clk_en_i & (crt_state == IDLE))
            begin 
              multiplier_out <= multiplier_in;
              multiplicand_out <= multiplicand_in;
            end
        end : DATA_REGISTER

  //Valid bits: [47:0]
  //The multiplier is a 32 x 32 mult. so it returns a 64 bits value
  //Since we are multiplying 24 bits numbers we take the lower 48 bits
  logic [(XLEN * 2) - 1:0] result_mantissa_full;

  logic [22:0] result_mantissa;

  //Enable multiplication
  logic mult_en;

  assign mult_en = (crt_state == MULTIPLY) & clk_en_i;

  generate 

    if (PERFORMANCE)
      begin
        MGT_01_booth_radix16 mantissa_multiplier (
          .multiplier_i   ( {8'b0, multiplier_out.hidden_bit, multiplier_out.mantissa}     ),
          .multiplicand_i ( {8'b0, multiplicand_out.hidden_bit, multiplicand_out.mantissa} ),
          .clk_i          ( clk_i                                                          ),
          .clk_en_i       ( mult_en                                                        ),
          .rst_n_i        ( rst_n_i                                                        ),
          .result_o       ( result_mantissa_full                                           ),  
          .valid_o        ( valid_mantissa                                                 ),
          .fu_state_o     (             /* WON'T BE CONNECTED TO ANYTHING*/                )
        );
      end
    else 
      begin 
        MGT_01_booth_radix4 mantissa_multiplier (
          .multiplier_i   ( {8'b0, multiplier_out.hidden_bit, multiplier_out.mantissa}     ),
          .multiplicand_i ( {8'b0, multiplicand_out.hidden_bit, multiplicand_out.mantissa} ),
          .clk_i          ( clk_i                                                          ),
          .clk_en_i       ( mult_en                                                        ),
          .rst_n_i        ( rst_n_i                                                        ),
          .result_o       ( result_mantissa_full                                           ),  
          .valid_o        ( valid_mantissa                                                 ),
          .fu_state_o     (             /* WON'T BE CONNECTED TO ANYTHING*/                )
        );
      end

  endgenerate

  logic round;

  assign round = |result_mantissa_full[22:0];

  //One more bit for underflow detection
  logic signed [8:0] result_exponent;

  logic [7:0] norm_exponent;
  logic       result_sign;

  //We are adding two biased numbers so after the addition we need to subtract the bias
  assign result_exponent = (multiplier_i.exponent + multiplicand_i.exponent) - BIAS;

  //If the two sign bits are equal: result sign = 0 (positive) else result sign = 1 (negative)
  assign result_sign = multiplier_i.sign ^ multiplicand_i.sign;

  //If the MSB of the multiplied mantissa is 1 shift it by 1 else do nothing (take the [46:25] bits)
  assign result_mantissa = result_mantissa_full[47] ? result_mantissa_full[45:23] >> 1 : result_mantissa_full[45:23];

  //Modify the exponent accordingly 
  assign norm_exponent = result_mantissa_full[47] ? result.exponent + 1 : result.exponent; 

      always_ff @(posedge clk_i) 
        begin 
          if (!rst_n_i)
            result <= 33'b0;
          if (clk_en_i & (crt_state == PREPARE))
            begin
              result.exponent <= result_exponent[7:0];
              result.sign <= result_sign;
            end
          if (clk_en_i & (crt_state == NORMALIZE))
            begin 
              result.mantissa <= result_mantissa + round;
              result.exponent <= norm_exponent;
            end
        end

  ////////////////////
  //  Output logic  //
  ////////////////////

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;
  
  assign valid_o = (crt_state == VALID);

  logic underflow, overflow;

  //Detect if one of the inputs are 0
  logic zero_detect;

  //Mantissa is zero
  logic op_A_mantissa_zero, op_B_mantissa_zero, res_mantissa_zero;

  assign op_A_mantissa_zero = ~|op_A_out.mantissa;
  assign op_B_mantissa_zero = ~|op_B_out.mantissa;
  assign res_mantissa_zero  = ~|result.mantissa;
  
  //AND the two operand (except the sign) and NOR the result to detect the 0
  assign zero_detect = ~|({op_A_out.exponent, op_A_out.mantissa} & {op_B_out.exponent, op_B_out.mantissa});

  logic is_infty_A, is_infty_B;
  logic is_nan_A, is_nan_B;

  //Is signaling NaN
  logic is_sign_A, is_sign_B;

  assign is_infty_A = (&op_A_out.exponent) & op_A_mantissa_zero;
  assign is_infty_B = (&op_B_out.exponent) & op_B_mantissa_zero;

  assign is_nan_A = (&op_A_out.exponent) & !op_A_mantissa_zero;
  assign is_nan_B = (&op_B_out.exponent) & !op_B_mantissa_zero;

  assign is_sign_A = op_A_out.sign & is_nan_A;
  assign is_sign_B = op_B_out.sign & is_nan_B;

  //Exponent overflow range
  logic exp_ov_rng;

  assign exp_ov_rng = (op_A_out.exponent[7] & op_B_out.exponent[7]) & !result.exponent[7];

      always_comb
        begin : OUTPUT_LOGIC   
          //Exceed max floating point range (overflow on exponent) or one of the input is an infinity. Sign must be positive
          overflow = !zero_detect & !result.sign & ((is_infty_A | is_infty_B) | exp_ov_rng);

          //If both the operands have negative exponent and the result's exponent is zero but the mantissa is not zero
          underflow = ((!op_A_out.exponent[7] & !op_B_out.exponent[7]) & (result_exponent[8] & !res_mantissa_zero)) |
                      !zero_detect & result.sign & ((is_infty_A | is_infty_B) | exp_ov_rng);

          //If is 0 x Infinity or one of the two inputs (or both) is a signaling NaN 
          invalid_op_o = (zero_detect & (is_infty_A | is_infty_B)) | (is_sign_A | is_sign_B);

          if (!zero_detect & (is_infty_A | is_infty_B))
            begin            // +Infinity or -Infinity
              to_round_unit_o = {result.sign, {8{1'b1}}, 23'b0};
            end
          else if (zero_detect & (is_infty_A | is_infty_B))
            begin 
              to_round_unit_o = CANO_NAN;
            end
          else if (is_nan_A | is_nan_B)
            begin 
              to_round_unit_o = CANO_NAN;
            end
          else if (overflow)
            begin 
              to_round_unit_o = P_INFTY;
            end
          else if (result.sign & ((is_infty_A | is_infty_B) | exp_ov_rng) | underflow)
            begin 
              to_round_unit_o = N_INFTY;
            end
          //Default
          else 
            begin 
              to_round_unit_o = zero_detect ? {result.sign, 8'b0, 23'b0} : result;
            end
        end : OUTPUT_LOGIC

  assign overflow_o = overflow;
  assign underflow_o = underflow;
  
endmodule
