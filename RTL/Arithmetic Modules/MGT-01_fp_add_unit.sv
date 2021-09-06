////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point add/sub unit                                //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains the hardware necessary to perform a   //
//                 addition / subtraction on floating point data. It produces //
//                 a valid result in 4 clock cycles.                          //
////////////////////////////////////////////////////////////////////////////////

`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_fp_add_unit
( //Inputs
  input  float_t          op_A_i, op_B_i,     //Operands

  input  logic            rst_n_i,            //Reset active low
  input  logic            clk_i, clk_en_i,    //Clock signals

  input  fsum_ops         operation_i,
  input  rounding_e       round_i, 

  //Outputs
  output float_t          to_round_unit_o,    
  output fu_state_e       fu_state_o,         //Functional unit state
  output rounding_e       round_o, 
  output valid_e          valid_o,

  output logic            underflow_o,
  output logic            overflow_o,
  output logic            invalid_op_o 
);

  typedef enum logic [1:0] {IDLE, PREPARE, ADDITION, NORMALIZE} fsm_state_e;

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

            NORMALIZE:  nxt_state = IDLE;

          endcase
        end

  typedef struct packed {     
      logic        sign;
      logic [7:0]  exponent;
      logic        hidden_bit;
      logic [22:0] mantissa;
  } effective_float_t;

  effective_float_t op_A, op_B;

  logic hidden_a, hidden_b;

  //Compute the hidden bit ORing all the bits of the exponent
  assign hidden_a = |op_A_i.exponent; 
  assign hidden_b = |op_B_i.exponent;   

  //Initialize the data with effective mantissa 
  assign op_A = '{op_A_i.sign, op_A_i.exponent, hidden_a, op_A_i.mantissa};

  //The sign bit of the second operand is inverted if the operation is a subtraction
  assign op_B = (operation_i == FADD_) ? '{op_B_i.sign, op_B_i.exponent, hidden_b, op_B_i.mantissa} :
                                         '{~op_B_i.sign, op_B_i.exponent, hidden_b, op_B_i.mantissa};

  //Register input/output
  effective_float_t op_A_in, op_A_out, op_B_in, op_B_out;
  logic [23:0] shifted_mantissa, shifted_mantissa_out;
  logic [7:0]  exponent_diff;     //Obtained by subtracting the two exponents
    
      always_comb 
        begin
          unique case (crt_state)

            IDLE:       begin
                          op_A_in = op_A;
                          op_B_in = op_B;
                        end

            PREPARE:    begin             //The two numbers have the same exponent
                          op_A_in = (exponent_diff[7]) ? {op_A_out.sign, op_B_out.exponent, shifted_mantissa} : op_A_out;
                          op_B_in = (exponent_diff[7]) ? op_B_out : {op_B_out.sign, op_A_out.exponent, shifted_mantissa};
                        end

            ADDITION:   begin             //Dont'care, we won't use these values anymore
                          op_A_in = op_A;
                          op_B_in = op_B;
                        end

            NORMALIZE:  begin             //Dont'care, we won't use these values anymore
                          op_A_in = op_A;
                          op_B_in = op_B;
                        end

          endcase
        end

      //Data register

      always_ff @(posedge clk_i)
        begin : REG_A
          if (!rst_n_i)
            op_A_out <= 33'b0;      //Reset, in float +0
          if (clk_en_i) 
            op_A_out <= op_A_in;   
        end : REG_A

      always_ff @(posedge clk_i)
        begin : REG_B
          if (!rst_n_i)
            op_B_out <= 33'b0;      //Reset, in float +0 
          if (clk_en_i)
            op_B_out <= op_B_in;               
        end : REG_B
   
    
  float_t result;

  logic [7:0]  exponent_diff_abs; //Absolute value

  logic [7:0]  result_exponent;   //Exponent used for the final result
  logic [7:0]  norm_exponent;     //Normalized exponent

  logic [24:0] result_mantissa;   //result_mantissa[24] is the carry bit
  logic [24:0] result_mantissa_out;   
  logic [23:0] result_mantissa_abs;
  logic [23:0] norm_mantissa;     //Normalized mantissa
    
  logic        result_sign;       //Sign used for the result

  logic [23:0] mantissa_diff;     //Used to find the result's sign bit 

  logic [4:0]  leading_zero;        //Number of consecutive 0s 
  
    
      always_ff @(posedge clk_i)
        begin : RESULT_REG
          if (!rst_n_dly)
            result <= 32'b0;    //Reset, in float +0 
          if (clk_en_i)
            begin 
              if (crt_state == PREPARE)         //The result's sign and exponent is calculated
                begin                           //in the PREPARE stage
                  result.sign <= result_sign;
                  result.exponent <= result_exponent;
                end
              else if (crt_state == NORMALIZE)  //Normalized exponent and mantissa are calculated
                begin                           //in NORMALIZE stage
                  result.exponent <= norm_exponent;
                  result.mantissa <= norm_mantissa[22:0];
                end
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

  assign mantissa_diff = op_A.mantissa - op_B.mantissa;   
  assign exponent_diff = op_A_out.exponent - op_B_out.exponent;

      always_comb 
        begin
          if (crt_state == IDLE)
            begin
              //Values used to not interfere a latch
              norm_mantissa = 0;
              norm_exponent = 0;
              result_exponent = 0;
              shifted_mantissa = 0;
              result_sign = 0;
              result_mantissa = 0;
            end
          else if (crt_state == PREPARE)
            begin
              //Values used to not interfere a latch  
              norm_mantissa = 0;
              norm_exponent = 0;
              result_mantissa = 0;
                         
              if (exponent_diff[7] == 1)
                begin  
                  exponent_diff_abs = -exponent_diff;   //If the difference is negative it means B > A
                  result_exponent = op_B_out.exponent;  //Use the B exponent for the result

                  shifted_mantissa = {op_A_out.hidden_bit, op_A_out.mantissa} >> exponent_diff_abs;    //Shift by the difference
                  result_sign = op_B_out.sign;
                end 
              else
                begin
                  exponent_diff_abs = exponent_diff;    //If the difference is positive it means A > B or A = B
                  result_exponent = op_A_out.exponent;  //Use the A exponent for the result

                  shifted_mantissa = {op_B_out.hidden_bit, op_B_out.mantissa} >> exponent_diff_abs;    //Shift by the difference
                                    
                  //If the difference is equal to zero select the sign based on the mantissa_diff sign bit
                  result_sign = (|exponent_diff_abs) ? op_A_out.sign : ((mantissa_diff[23]) ? op_B_out.sign : op_A_out.sign);
                end
            end
          else if (crt_state == ADDITION)
            begin
              //Values used to not interfere a latch
              norm_mantissa = 0;
              norm_exponent = 0;
              result_exponent = 0;
              shifted_mantissa = 0;
              result_sign = 0;
              
              unique case ({op_A_out.sign, op_B_out.sign})   

                  2'b00:   result_mantissa = {op_A_out.hidden_bit, op_A_out.mantissa} + {op_B_out.hidden_bit, op_B_out.mantissa}; 

                  2'b01:   result_mantissa = {op_A_out.hidden_bit, op_A_out.mantissa} - {op_B_out.hidden_bit, op_B_out.mantissa}; 

                  2'b10:   result_mantissa = -{op_A_out.hidden_bit, op_A_out.mantissa} + {op_B_out.hidden_bit, op_B_out.mantissa};
                  
                  2'b11:   result_mantissa = {op_A_out.hidden_bit, op_A_out.mantissa} + {op_B_out.hidden_bit, op_B_out.mantissa};

              endcase
            end
          else 
            begin
              //Values used to not interfere a latch
              result_exponent = 0;
              shifted_mantissa = 0;
              result_sign = 0;
              result_mantissa = result_mantissa_out;

              if (op_A.sign ~^ op_B.sign)     //XNOR: basically if the sign bit of the operands are the same (is an addition)
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

                  unique casez (result_mantissa_abs)    //Leading zero encoder

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
            end 
        end

  //////////////////
  // Output logic //
  //////////////////

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;

  assign round_o = round_i;
 
  assign valid_o = ((crt_state == IDLE) & rst_n_dly) ? VALID : INVALID;
  
      always_comb     //Output selection 
        begin 
          unique casez ({{op_A.sign, op_A.exponent, op_A.mantissa}, {op_B.sign, op_B.exponent, op_B.mantissa}})

            {P_INFTY, 32'b?}:     begin
                                    to_round_unit_o = P_INFTY;
                                    overflow_o  = 1'b1;
                                    underflow_o = 1'b0;
                                    invalid_op_o = 1'b0;
                                  end

            {32'b?, P_INFTY}:     begin
                                    to_round_unit_o = P_INFTY;
                                    overflow_o  = 1'b1;
                                    underflow_o = 1'b0;
                                    invalid_op_o = 1'b0;
                                  end

            {N_INFTY, 32'b?}:     begin
                                    to_round_unit_o = N_INFTY;
                                    overflow_o  = 1'b0;
                                    underflow_o = 1'b1;
                                    invalid_op_o = 1'b0;
                                  end

            {32'b?, N_INFTY}:     begin
                                    to_round_unit_o = N_INFTY;
                                    overflow_o  = 1'b0;
                                    underflow_o = 1'b1;
                                    invalid_op_o = 1'b0;
                                  end

            {P_INFTY, N_INFTY}:   begin
                                    to_round_unit_o = N_INFTY;
                                    overflow_o  = 1'b0;
                                    underflow_o = 1'b0;
                                    invalid_op_o = 1'b1;
                                  end

            {N_INFTY, P_INFTY}:   begin
                                    to_round_unit_o = N_INFTY;
                                    overflow_o  = 1'b0;
                                    underflow_o = 1'b0;
                                    invalid_op_o = 1'b1;
                                  end

            default:              begin
                                    to_round_unit_o = result;
                                    overflow_o  = (result == P_INFTY) ? 1'b1 : 1'b0;
                                    underflow_o = (result == N_INFTY) ? 1'b1 : 1'b0;
                                    invalid_op_o = (result == NAN) ? 1'b1 : 1'b0;
                                  end

          endcase
        end

endmodule 
