////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point multiplication unit                         //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This unit perform a simple floating point multiplication.  //
//                                                                            //
// Dependencies:   MGT-01_booth_r4.sv                                         //
////////////////////////////////////////////////////////////////////////////////

// NOT TESTED!

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_fp_mul_unit
( //Inputs
  input  float_t    multiplier_i, multiplicand_i,

  input  logic      clk_i, clk_en_i,               //Clock signals
  input  logic      rst_n_i,                       //Reset active low

  output float_t    result_o,
  output logic      valid_o,
  output fu_state_e fu_state_o 
);

  typedef enum logic [1:0] {IDLE, PREPARE, MULTIPLY, NORMALIZE} fsm_state_e;

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

            NORMALIZE:  nxt_state = IDLE;

          endcase
        end


  effective_float_t op_A_in, op_B_in;
  effective_float_t multiplier_out, multiplicand_out;

  float_t result;

  //OR the exponent to detect if the number is a 0 (hidden bit is 0 too)
  assign op_A_in = {multiplier_i.sign, multiplier_i.exponent, |multiplier_i.exponent, multiplier_i.mantissa};
  
  assign op_B_in = {multiplicand_i.sign, multiplicand_i.exponent, |multiplicand_i.exponent, multiplicand_i.mantissa};

      always_ff @(posedge clk_i) 
        begin : DATA_REGISTER
          if (!rst_n_i)
            begin 
              multiplier_out <= 33'b0;
              multiplicand_out <= 33'b0;
            end
          if (clk_en_i & (crt_state == IDLE))
            begin 
              multiplier_out <= op_A_in;
              multiplicand_out <= op_B_in;
            end
        end : DATA_REGISTER

  //Valid bits: [47:0]
  //The multiplier is a 32 x 32 mult. so it returns a 64 bits value
  //Since we are multiplying 24 bits numbers we take the lower 48 bits
  logic [(XLEN * 2) - 1:0] result_mantissa_full;

  logic [22:0] result_mantissa;

    MGT_01_booth_radix4 mantissa_multiplier (
      .multiplier_i   ( {8'b0, multiplier_out.hidden_bit, multiplier_out.mantissa}     ),
      .multiplicand_i ( {8'b0, multiplicand_out.hidden_bit, multiplicand_out.mantissa} ),
      .clk_i          ( clk_i                                                          ),
      .clk_en_i       ( clk_en_i                                                       ),
      .rst_n_i        ( rst_n_i                                                        ),
      .result_o       ( result_mantissa                                                ),  
      .valid_o        ( valid_mantissa                                                 )
    );

  logic [7:0] result_exponent, norm_exponent;
  logic       result_sign;

  //We are adding two biased numbers so after the addition we need to subtract the bias
  assign result_exponent = (multiplier_i.exponent + multiplicand_i.exponent) - BIAS;

  //If the two sign bits are equal: result sign = 0 (positive) else result sign = 1 (negative)
  assign result_sign = multiplier_i.sign ^ multiplicand_i.sign;

  //If the MSB of the multiplied mantissa is 1 shift it by 1 else do nothing (take the [22:0] bits)
  assign result_mantissa = result_mantissa_full[(XLEN * 2) - 1] ? result_mantissa_full >> 1 : result_mantissa_full;

  //Modify the exponent accordingly 
  assign norm_exponent = result_mantissa_full[(XLEN * 2) - 1] ? result.exponent + 1 : result.exponent; 

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
              result.mantissa <= result_mantissa;
              result.exponent <= norm_exponent;
            end
        end

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;
  
  assign valid_o = (crt_state == IDLE) & clk_en_i;
  
  assign result_o = result;
  
endmodule
