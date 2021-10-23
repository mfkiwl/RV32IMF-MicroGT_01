////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point add/sub unit                                //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains the hardware necessary to perform a   //
//                 addition / subtraction on floating point data.             //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_fp_add_unit
( //Inputs
  input  float_t          op_A_i, op_B_i,     //Operands

  input  logic            rst_n_i,            //Reset active low
  input  logic            clk_i, clk_en_i,    //Clock signals

  input  fsum_ops         operation_i, 

  //Outputs
  output float_t          to_round_unit_o,    
  output fu_state_e       fu_state_o,         //Functional unit state 
  output logic            valid_o,

  output logic            underflow_o,
  output logic            overflow_o,
  output logic            invalid_op_o
);

  typedef enum logic [2:0] {IDLE, PREPARE, ADDITION, NORMALIZE, VALID} fsm_state_e;

  fsm_state_e crt_state, nxt_state;

  // IDLE: The unit is waiting for data
  // PREPARE: Preparing the data to be computed (Shift mantissa, sign extraction and exponent subtraction)
  // ADDITION: Add the mantissas
  // NORMALIZE: Normalize the result

  ///////////////
  // FSM LOGIC //
  ///////////////

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

            IDLE:       nxt_state = (~rst_n_dly) ? IDLE : PREPARE;

            PREPARE:    nxt_state = ADDITION;

            ADDITION:   nxt_state = NORMALIZE; 

            NORMALIZE:  nxt_state = VALID;

            VALID:      nxt_state = IDLE;

            default:    nxt_state = IDLE;

          endcase
        end

  effective_float_t op_A, op_A_o, op_B, op_B_o;

  logic hidden_a, hidden_b;

  //Compute the hidden bit ORing all the bits of the exponent
  assign hidden_a = |op_A_i.exponent; 
  assign hidden_b = |op_B_i.exponent;   

  //Initialize the data with effective mantissa 
  assign op_A = {op_A_i.sign, op_A_i.exponent, hidden_a, op_A_i.mantissa};

  //The sign bit of the second operand is inverted if the operation is a subtraction
  assign op_B = (operation_i == FADD_) ? {op_B_i.sign, op_B_i.exponent, hidden_b, op_B_i.mantissa} :
                                         {!op_B_i.sign, op_B_i.exponent, hidden_b, op_B_i.mantissa};

  typedef struct packed {
      logic hidden_bit;
      logic [22:0] mantissa;
  } hb_mantissa_t;

  //Register input/output values 
  hb_mantissa_t op_A_in, op_A_out, op_B_in, op_B_out;
  logic [7:0]  exponent_diff;     //Obtained by subtracting the two exponents

  ////////////////////  
  // Data registers //
  ////////////////////

      //Store operand A's value used for computation
      always_ff @(posedge clk_i) 
        begin : INIT_REG_A
        if (!rst_n_i)
            op_A_o <= 33'b0;      //Reset, in float +0
          if (clk_en_i & crt_state == IDLE)
            op_A_o <= op_A;
        end : INIT_REG_A

      always_ff @(posedge clk_i)
        begin : REG_A
          if (!rst_n_i)
            op_A_out <= 33'b0;      //Reset, in float +0 
          else if (clk_en_i & crt_state == PREPARE) 
            op_A_out <= op_A_in; 
        end : REG_A

      //Store operand B's initial value
      always_ff @(posedge clk_i) 
        begin : INIT_REG_B
          if (!rst_n_i)
            op_B_o <= 33'b0;      //Reset, in float +0
          if (clk_en_i & crt_state == IDLE)
            op_B_o <= op_B;
        end : INIT_REG_B

      //Store operand B's value used for computation
      always_ff @(posedge clk_i)
        begin : REG_B
          if (!rst_n_i)
            op_B_out <= 33'b0;      //Reset, in float +0 
          else if (clk_en_i & crt_state == PREPARE) 
            op_B_out <= op_B_in;                     
        end : REG_B 
    
  float_t result;

  logic [7:0]  exponent_diff_abs;   //Absolute value

  logic [7:0]  result_exponent;     //Exponent used for the final result
  logic [7:0]  norm_exponent;       //Normalized exponent

  logic [24:0] result_mantissa;     //[24] is the carry bit
  logic [24:0] result_mantissa_out;   
  logic [23:0] result_mantissa_abs;
  logic [23:0] norm_mantissa;       //Normalized mantissa
    
  logic        result_sign;         //Sign used for the result

  logic [23:0] mantissa_diff;       //Used to find the result's sign bit 

  logic [4:0]  leading_zero;        //Number of consecutive 0s 
  logic        result_is_zero;
    
      always_ff @(posedge clk_i)
        begin : RESULT_REG
          if (!rst_n_dly)
            result <= 32'b0;  //Reset, in float +0 
          if (clk_en_i & crt_state == PREPARE)  //The result's sign and exponent is calculated
            begin                               //in the PREPARE stage
              result.sign <= result_sign;
              result.exponent <= result_exponent;
            end
          else if (clk_en_i & crt_state == NORMALIZE)  //Normalized exponent and mantissa are calculated
            begin                                      //in NORMALIZE stage
              result.exponent <= result_is_zero ? 8'b0 : norm_exponent;
              result.mantissa <= norm_mantissa[22:0];
            end         
        end : RESULT_REG
        
      always_ff @(posedge clk_i)
        begin
          if (clk_en_i & (crt_state == ADDITION))
            result_mantissa_out <= result_mantissa;
        end

  /////////////////////  
  // Algorithm logic //
  /////////////////////

  //If two numbers are equals
  logic equals;

  assign mantissa_diff = op_A_o.mantissa - op_B_o.mantissa;   
  assign exponent_diff = op_A_o.exponent - op_B_o.exponent;

  //If mantissa diff and exponent diff are zero
  assign equals = (~|mantissa_diff) & (~|exponent_diff);  

  //If A and B absolute values are equals but have different sign
  assign result_is_zero = equals & (op_A_o.sign ^ op_B_o.sign);

      always_comb
        begin : PREPARE_LOGIC                        
          if (exponent_diff[7])
            begin  
              exponent_diff_abs = -exponent_diff;   //If the difference is negative it means B > A
              result_exponent = op_B_o.exponent;    //Use the B exponent for the result
                  
              op_B_in = {op_B_o.hidden_bit, op_B_o.mantissa};
              op_A_in = {op_A_o.hidden_bit, op_A_o.mantissa} >> exponent_diff_abs;    //Shift by the difference
                  
              result_sign = op_B_o.sign;
            end 
          else
            begin
              exponent_diff_abs = exponent_diff;    //If the difference is positive it means A > B or A = B
              result_exponent = op_A_o.exponent;    //Use the A exponent for the result
                  
              op_A_in = {op_A_o.hidden_bit, op_A_o.mantissa};
              op_B_in = {op_B_o.hidden_bit, op_B_o.mantissa} >> exponent_diff_abs;    //Shift by the difference
                                    
              //If the difference is equal to zero select the sign based on the mantissa_diff sign bit
              result_sign = (|exponent_diff_abs) ? op_A_o.sign : ((mantissa_diff[23]) ? op_B_o.sign : op_A_o.sign);
            end
        end : PREPARE_LOGIC

      always_comb
        begin : ADDITION_LOGIC
          case ({op_A_o.sign, op_B_o.sign})   

            2'b00:   result_mantissa =  op_A_out + op_B_out; 

            2'b01:   result_mantissa =  op_A_out - op_B_out; 

            2'b10:   result_mantissa = -op_A_out + op_B_out;
                  
            2'b11:   result_mantissa =  op_A_out + op_B_out;

          endcase
        end : ADDITION_LOGIC

      always_comb
        begin : NORMALIZE_LOGIC
          if (op_A_o.sign ~^ op_B_o.sign)       //XNOR: basically if the sign bit of the operands are the same (is an addition)
            begin
              if (result_mantissa_out[24])  //There is a carry bit
                begin
                  norm_mantissa = result_mantissa_out >> 1;
                  norm_exponent = result.exponent + 1;
                end
              else                          //There is NOT a carry bit
                begin
                  norm_mantissa = result_mantissa_out;
                  norm_exponent = result.exponent;
                end
            end
          else    //If the operation is a subtraction
            begin
              //Compute the absolute value
              if (result_mantissa_out[24])
                result_mantissa_abs = -result_mantissa_out[23:0];
              else 
                result_mantissa_abs = result_mantissa_out[23:0];

              casez (result_mantissa_abs)    //Leading zero encoder

                24'b1???????????????????????:  leading_zero = 5'd0;
                24'b01??????????????????????:  leading_zero = 5'd1;
                24'b001?????????????????????:  leading_zero = 5'd2;
                24'b0001????????????????????:  leading_zero = 5'd3;
                24'b00001???????????????????:  leading_zero = 5'd4;
                24'b000001??????????????????:  leading_zero = 5'd5;
                24'b0000001?????????????????:  leading_zero = 5'd6;
                24'b00000001????????????????:  leading_zero = 5'd7;
                24'b000000001???????????????:  leading_zero = 5'd8;
                24'b0000000001??????????????:  leading_zero = 5'd9;
                24'b00000000001?????????????:  leading_zero = 5'd10;
                24'b000000000001????????????:  leading_zero = 5'd11;
                24'b0000000000001???????????:  leading_zero = 5'd12;
                24'b00000000000001??????????:  leading_zero = 5'd13;
                24'b000000000000001?????????:  leading_zero = 5'd14;
                24'b0000000000000001????????:  leading_zero = 5'd15;
                24'b00000000000000001???????:  leading_zero = 5'd16;
                24'b000000000000000001??????:  leading_zero = 5'd17;
                24'b0000000000000000001?????:  leading_zero = 5'd18;
                24'b00000000000000000001????:  leading_zero = 5'd19;
                24'b000000000000000000001???:  leading_zero = 5'd20;
                24'b0000000000000000000001??:  leading_zero = 5'd21;
                24'b00000000000000000000001?:  leading_zero = 5'd22;
                24'b000000000000000000000001:  leading_zero = 5'd23;
                24'b000000000000000000000000:  leading_zero = 5'd24;

              endcase
                  
              norm_mantissa = result_mantissa_abs << leading_zero;
              norm_exponent = result.exponent - leading_zero;
            end
        end : NORMALIZE_LOGIC

  //////////////////
  // Output logic //
  //////////////////

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;
 
  assign valid_o = (crt_state == VALID) & clk_en_i;

  //Mantissa is zero
  logic op_A_mantissa_zero, op_B_mantissa_zero;

  assign op_A_mantissa_zero = ~|op_A_o.mantissa;
  assign op_B_mantissa_zero = ~|op_B_o.mantissa; 

  logic is_Pinfty_A, is_Pinfty_B, is_Ninfty_A, is_Ninfty_B;
  logic is_nan_A, is_nan_B;

  //Is signaling NaN
  logic is_sign_A, is_sign_B;

  assign is_Pinfty_A = !op_A_o.sign & (&op_A_o.exponent) & op_A_mantissa_zero;
  assign is_Pinfty_B = !op_B_o.sign & (&op_B_o.exponent) & op_B_mantissa_zero;

  assign is_Ninfty_A = op_A_o.sign & (&op_A_o.exponent) & op_A_mantissa_zero;
  assign is_Ninfty_B = op_B_o.sign & (&op_B_o.exponent) & op_B_mantissa_zero;

  assign is_nan_A = (&op_A_o.exponent) & !op_A_mantissa_zero;
  assign is_nan_B = (&op_B_o.exponent) & !op_B_mantissa_zero;

  assign is_sign_A = op_A_o.sign & is_nan_A;
  assign is_sign_B = op_B_o.sign & is_nan_B;

  logic overflow;

  //Exponent overflow range
  logic exp_ov_rng;

  //If the exponent is 0xFF
  assign exp_ov_rng = &result.exponent;
      
      always_comb
        begin : OUTPUT_LOGIC
          //Exceed max floating point range (overflow on exponent) or one of two the inputs is +Infinity 
          overflow = exp_ov_rng | (is_Pinfty_A | is_Pinfty_B);

          //If one of the two inputs is -Infinity or denormals
          underflow_o = (is_Ninfty_A | is_Ninfty_B) | (~|op_A_o.exponent & |op_A_o.mantissa) | (~|op_B_o.exponent & |op_B_o.mantissa);

          //If it's +Infinity -Infinity or -Infinity +Infinity or one of the two inputs is a signaling NaN
          invalid_op_o = (is_Pinfty_A & is_Ninfty_B) | (is_Ninfty_A & is_Pinfty_B) | (is_sign_A | is_sign_B);

          if ((is_Ninfty_A | is_Ninfty_B) & (!is_Pinfty_A & !is_Pinfty_B))
            begin 
              to_round_unit_o = N_INFTY;
            end
          else if ((is_Pinfty_A & is_Ninfty_B) | (is_Ninfty_A & is_Pinfty_B))
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
          //Default
          else 
            begin 
              to_round_unit_o = result;
            end
        end : OUTPUT_LOGIC

  assign overflow_o = overflow;

endmodule 
