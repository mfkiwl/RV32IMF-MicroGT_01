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
  // ADDITION: Multiply the mantissas
  // NORMALIZE: Normalize the result

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
          unique case (crt_state)

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

  assign mult_en = (crt_state == MULTIPLY);

  //Select the module to instantiate
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
          .fu_state_o     (           /* THIS WON'T BE CONNECTED TO ANYTHING*/             )
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
          .fu_state_o     (           /* THIS WON'T BE CONNECTED TO ANYTHING*/             )
        );
      end

  endgenerate
  
  logic round;

  assign round = |result_mantissa_full[22:0];

  logic [7:0] result_exponent, norm_exponent;
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
              result.exponent <= result_exponent;
              result.sign <= result_sign;
            end
          if (clk_en_i & (crt_state == NORMALIZE))
            begin 
              result.mantissa <= result_mantissa + round;
              result.exponent <= norm_exponent;
            end
        end

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;
  
  assign valid_o = (crt_state == VALID);

  //Detect if one of the inputs are 0
  logic zero_detect;
  
  //AND the two operand (except the sign) and NOR the result to detect the 0
  assign zero_detect = ~|({op_A_out.exponent, op_A_out.mantissa} & {op_B_out.exponent, op_B_out.mantissa});
  
      always_comb 
        begin 
          casez ({op_A_out, op_B_out})

            {P_INFTY, N_INFTY},
            {N_INFTY, P_INFTY},
            {N_INFTY, 32'b?  },
            {32'b?, N_INFTY  }:   begin 
                                    to_round_unit_o = N_INFTY;
                                    overflow_o = 0;
                                    underflow_o = 1;
                                    invalid_op_o = 0;
                                  end

            {P_INFTY, P_INFTY},
            {N_INFTY, N_INFTY},
            {P_INFTY, 32'b?  },
            {32'b?, P_INFTY  }:   begin 
                                    to_round_unit_o = P_INFTY;
                                    overflow_o = 1;
                                    underflow_o = 0;
                                    invalid_op_o = 0;
                                  end

            {P_INFTY, ZERO},
            {ZERO, P_INFTY},
            {N_INFTY, ZERO},
            {ZERO, N_INFTY}:      begin 
                                    to_round_unit_o = 32'hFFFFFFFF;
                                    overflow_o = 0;
                                    underflow_o = 0;
                                    invalid_op_o = 1;
                                  end

            {SIGN_NAN, 32'b?},
            {32'b?, SIGN_NAN}:    begin 
                                    to_round_unit_o = 32'hFFFFFFFF;
                                    overflow_o = 0;
                                    underflow_o = 0;
                                    invalid_op_o = 1;
                                  end

            default:              begin 
                                    //If an input is 0 put in output +-0
                                    to_round_unit_o = zero_detect ? {result.sign, 8'b0, 23'b0} : result; 

                                    //Exceed max floating point range (overflow on exponent) 
                                    overflow_o = (op_A_out.exponent[7] & op_B_out.exponent[7]) & (~result.exponent[7]);

                                    //If the result is zero while the operand are different or when exponent is zero 
                                    //but mantissa is not zero (denormalized)
                                    underflow_o = ((op_A_out != op_B_out) & (~|{result.exponent, result.mantissa})) | ((~|result.exponent) & (|result.mantissa));
                                    invalid_op_o = ((result == QUIET_NAN) | (result == SIGN_NAN));
                                  end
          endcase
        end
  
endmodule
