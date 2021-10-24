////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point division unit                               //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This unit perform a simple floating point division.        //
//                 Doesn't support denormals number at the moment.            //
//                                                                            //
// Dependencies:   MGT-01_nr_divider.sv                                       //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"
  
module MGT_01_fp_div_unit
( //Inputs
  input  float_t    dividend_i, divisor_i, 

  input  logic      clk_i, clk_en_i,   //Clock signals
  input  logic      rst_n_i,           //Reset active low

  //Outputs
  output float_t    to_round_unit_o,   //Result 
  output logic      valid_o,
  output fu_state_e fu_state_o,
  output logic      overflow_o, 
  output logic      underflow_o, 
  output logic      invalid_op_o,
  output logic      zero_divide_o
);

  typedef enum logic [2:0] {IDLE, PREPARE, DIVIDE, NORMALIZE, VALID} fsm_state_e;

  fsm_state_e crt_state, nxt_state;

  // IDLE: The unit is waiting for data
  // PREPARE: Preparing the data to be computed (sign extraction, add exponent)
  // DIVIDE: Divide the mantissas
  // NORMALIZE: Normalize the result
  // VALID: The output is valid

  ///////////////
  // FSM LOGIC //
  ///////////////

  logic valid_mantissa;         //Divided mantissa is valid
  logic zero_divide_mantissa;   //Divide a non zero mantissa by zero (when the divisor is 0)

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

            PREPARE:    nxt_state = DIVIDE; 

            //If the result of the divider is valid, go to next state
            DIVIDE:     nxt_state = (valid_mantissa) ? NORMALIZE : DIVIDE; 

            NORMALIZE:  nxt_state = VALID;

            VALID:      nxt_state = IDLE;

          endcase
        end


  effective_float_t dividend_in, divisor_in;
  effective_float_t dividend_out, divisor_out;

  float_t result, op_A_out, op_B_out;

      always_ff @(posedge clk_i)
        begin 
          if ((crt_state == PREPARE) & clk_en_i)
            begin 
              op_A_out <= dividend_i;
              op_B_out <= divisor_i;
            end
        end

  //OR the exponent to detect if the number is a 0 (hidden bit is 0 too)
  assign dividend_in = {dividend_i.sign, dividend_i.exponent, |dividend_i.exponent, dividend_i.mantissa};
  
  assign divisor_in = {divisor_i.sign, divisor_i.exponent, |divisor_i.exponent, divisor_i.mantissa};

  ////////////////////
  // Data registers //
  ////////////////////
  
      always_ff @(posedge clk_i) 
        begin : DATA_REGISTER
          if (!rst_n_i)
            begin 
              dividend_out <= 33'b0;
              divisor_out <= 33'b0;
            end
          if (clk_en_i & (crt_state == IDLE))
            begin 
              dividend_out <= dividend_in;
              divisor_out <= divisor_in;
            end
        end : DATA_REGISTER

  logic [24:0] result_mantissa;
  logic [23:0] norm_mantissa;

  /////////////////////
  // Algorithm logic //
  /////////////////////

  //Enable the division
  logic div_en;

  assign div_en = (crt_state == DIVIDE) & clk_en_i;

  MGT_01_nr_divider mantissa_divider (
    .dividend_i    ({1'b0, dividend_out.hidden_bit, dividend_out.mantissa}  ),
    .divisor_i     ({1'b0, divisor_out.hidden_bit, divisor_out.mantissa}    ),
    .clk_i         ( clk_i                                                  ),
    .clk_en_i      ( div_en                                                 ),
    .rst_n_i       ( rst_n_i                                                ),
    .quotient_o    ( result_mantissa                                        ),
    .remainder_o   (           /* WON'T BE CONNECTED TO ANYTHING*/          ),
    .valid_o       ( valid_mantissa                                         ),
    .zero_divide_o ( zero_divide_mantissa                                   )
  );
  
  assign valid_o = (crt_state == VALID);
  
  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;

  logic [8:0] result_exponent, norm_exponent;
  logic       result_sign;
  logic [4:0] leading_zero;

  //XOR the sign bits: if different the sign bit is 1 (-) else the sign bit is (+)
  assign result_sign = dividend_out.sign ^ divisor_out.sign;

  //Subtract the exponents since it is a division
  assign result_exponent = (dividend_out.exponent - divisor_out.exponent) + BIAS;

      always_comb
        begin : NORMALIZE_LOGIC
          casez (result_mantissa)    //Leading zero encoder

            25'b1????????????????????????:  leading_zero = 5'd0;
            25'b01???????????????????????:  leading_zero = 5'd1;
            25'b001??????????????????????:  leading_zero = 5'd2;
            25'b0001?????????????????????:  leading_zero = 5'd3;
            25'b00001????????????????????:  leading_zero = 5'd4;
            25'b000001???????????????????:  leading_zero = 5'd5;
            25'b0000001??????????????????:  leading_zero = 5'd6;
            25'b00000001?????????????????:  leading_zero = 5'd7;
            25'b000000001????????????????:  leading_zero = 5'd8;
            25'b0000000001???????????????:  leading_zero = 5'd9;
            25'b00000000001??????????????:  leading_zero = 5'd10;
            25'b000000000001?????????????:  leading_zero = 5'd11;
            25'b0000000000001????????????:  leading_zero = 5'd12;
            25'b00000000000001???????????:  leading_zero = 5'd13;
            25'b000000000000001??????????:  leading_zero = 5'd14;
            25'b0000000000000001?????????:  leading_zero = 5'd15;
            25'b00000000000000001????????:  leading_zero = 5'd16;
            25'b000000000000000001???????:  leading_zero = 5'd17;
            25'b0000000000000000001??????:  leading_zero = 5'd18;
            25'b00000000000000000001?????:  leading_zero = 5'd19;
            25'b000000000000000000001????:  leading_zero = 5'd20;
            25'b0000000000000000000001???:  leading_zero = 5'd21;
            25'b00000000000000000000001??:  leading_zero = 5'd22;
            25'b000000000000000000000001?:  leading_zero = 5'd23;
            25'b0000000000000000000000001:  leading_zero = 5'd24;
            25'b0000000000000000000000000:  leading_zero = 5'd25;

          endcase
                  
          norm_mantissa = result_mantissa << leading_zero;
          norm_exponent[7:0] = result.exponent[7:0] - leading_zero; 

        end : NORMALIZE_LOGIC


      always_ff @(posedge clk_i)
        begin 
          if (!rst_n_i)
            result <= 32'b0;
          if (clk_en_i)
            begin 
              if (crt_state == PREPARE)
                begin 
                  result.sign <= result_sign;
                  result.exponent <= result_exponent;
                end
              else if (crt_state == NORMALIZE)
                begin 
                  result.exponent <= norm_exponent[7:0];
                  result.mantissa <= norm_mantissa[23:1];
                end
            end
        end

  logic zero_divide, dividend_zero;
  logic overflow, underflow;

  assign dividend_zero = (~|dividend_out.exponent) & (~|dividend_out.mantissa); 

  assign zero_divide = zero_divide_mantissa & (~|divisor_out.exponent);
  assign zero_divide_o = zero_divide;
  
  //Input is an infinity or a generic NaN
  logic is_infty_A, is_infty_B;
  logic is_nan_A, is_nan_B;

  //Input is a signaling NaN
  logic is_sign_A, is_sign_B;

  assign is_infty_A = (&dividend_out.exponent) & (~|dividend_out.mantissa);
  assign is_infty_B = (&divisor_out.exponent) & (~|divisor_out.mantissa);

  assign is_nan_A = (&dividend_out.exponent) & (|dividend_out.mantissa);
  assign is_nan_B = (&divisor_out.exponent) & (|divisor_out.mantissa);

  assign is_sign_A = dividend_out.sign & is_nan_A;
  assign is_sign_B = divisor_out.sign & is_nan_B;

  logic invalid_op;

  //If both inputs are zeros, infinities or one is a signaling NaN 
  assign invalid_op = (((~|dividend_out.exponent) & (~|dividend_out.mantissa)) & zero_divide) | (is_infty_A & is_infty_B)
                      | (is_sign_A | is_sign_B);

      always_comb
        begin : OUTPUT_LOGIC         
          //If the dividend's exponent is positive and the divisor one's is negative (Ex: +2*10^9 / 2*10^-5 = 2*10^14)
          //and if the result's exponent is negative that means we have an overflow
          overflow = ((dividend_out.exponent[7] & (~divisor_out.exponent[7])) & (~result.exponent[7])) | is_infty_A;

          //If the divisor's exponent is positive and the dividend's exponent is negative
          //and if the exponent of the result has all bits cleared and the mantissa's bits are not we have an underflow
          underflow = result_exponent[8] & (divisor_out.exponent[7] & (~dividend_out.exponent[7]));

          invalid_op_o = invalid_op;

          if (invalid_op)
            begin 
              to_round_unit_o = CANO_NAN;
            end
          else if (is_infty_B | dividend_zero | underflow) //If (X / INF) or (0 / X)
            begin 
              // +-Zero
              to_round_unit_o = {result_sign, 31'b0};
            end
          else if (is_infty_A & | (zero_divide & !invalid_op) | overflow) //If (INF / X) or (X / 0) or result overflowed
            begin 
              // +-Infinity
              to_round_unit_o = {result_sign, 31'h7F800000};
            end
          else
            begin 
              to_round_unit_o = result;
            end
        end : OUTPUT_LOGIC
  
  assign overflow_o = overflow;
  assign underflow_o = underflow;

endmodule
