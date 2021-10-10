////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Floating point division unit                               //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This unit perform a simple floating point square root.     //
//                                                                            //
// Dependencies:   MGT-01_nr_sqrt.sv                                          //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"     
`include "Instruction_pkg.svh" 

module MGT_01_fp_sqrt_unit 
( //Inputs
  input  logic      clk_i,    
  input  logic      clk_en_i,
  input  logic      rst_n_i,       //Reset active low

  input  float_t    radicand_i,

  //Outputs
  output float_t    root_o,        //Result     
  
  output logic      valid_o,
  output fu_state_e fu_state_o,
  output logic      invalid_op_o,
  output logic      overflow_o,
  output logic      underflow_o
);

  ///////////////
  // FSM LOGIC //
  ///////////////

  typedef enum logic [1:0] {IDLE, SQRT, VALID} fsm_state_e;

  // IDLE: The unit is waiting for data 
  // SQRT: Perform the square root
  // VALID: The output is valid

  fsm_state_e crt_state, nxt_state;

  logic valid_mantissa;   //The result out of the sqrt block is valid

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

            IDLE:       nxt_state = (~rst_n_dly) ? IDLE : SQRT;

            SQRT:       nxt_state = valid_mantissa ? VALID : SQRT;  

            VALID:      nxt_state = IDLE;

            default:    nxt_state = IDLE;
            
          endcase
        end

  ////////////////////
  // Data registers //
  ////////////////////

  effective_float_t radicand_in, radicand_out;

  assign radicand_in = {radicand_i.sign, radicand_i.exponent, |radicand_i.exponent, radicand_i.mantissa};

      always_ff @(posedge clk_i) 
        begin 
          if (!rst_n_i)
            radicand_out <= 33'b0;
          else if (clk_en_i & (crt_state == IDLE))
            radicand_out <= radicand_in;
        end

  float_t root_out;
  
  logic [7:0] root_exponent;
  
  //Output of the square root block
  logic [23:0] mantissa_sqrt;
  
      always_ff @(posedge clk_i) 
        begin : OUTPUT_REGISTER
          if (!rst_n_i)
            root_out <= 32'b0;
          else if (clk_en_i & (crt_state == SQRT))
            begin 
              root_out.exponent <= root_exponent + BIAS;
              root_out.mantissa <= mantissa_sqrt;
            end
        end : OUTPUT_REGISTER

  //Root is always positive
  assign root_out.sign = 1'b0;

  /////////////////////
  // Algorithm logic //
  /////////////////////
   
  logic [7:0]  new_exp;
  
  //Input net of the sqrt block
  logic [23:0] radicand_in_sqrt;
  
      always_comb
        begin 
          //Considering the biased exponent
          //If the exponent is odd
          if (radicand_out.exponent[0])
            begin 
              //Adjust the mantissa and the exponent accordingly
              radicand_in_sqrt = {radicand_out.hidden_bit, radicand_out.mantissa} >> 1;
              new_exp = radicand_out.exponent + 1;
            end
          //If the exponent is even
          else
            begin 
              //Do not modify the exponent and mantissa
              radicand_in_sqrt = {radicand_out.hidden_bit, radicand_out.mantissa};
              new_exp = radicand_out.exponent;
            end
        end

  //Divide by 2 the exponent
  assign root_exponent = $signed(new_exp - BIAS) >> 1;

  logic sqrt_en;

  //Enable the square root block only if the current state is SQRT.
  //Otherwise it would compute the wrong values.
  assign sqrt_en = (crt_state == SQRT) & clk_en_i;

  //Square root block instantiation
  MGT_01_nr_sqrt mantissa_sqrt_block (
    .clk_i        ( clk_i                               ),    
    .clk_en_i     ( sqrt_en                             ),
    .rst_n_i      ( rst_n_i                             ),
    .radicand_i   ( {radicand_in_sqrt, 24'b0}           ),
    .root_o       ( mantissa_sqrt                       ),
    .remainder_o  ( /* WON'T BE CONNECTED TO ANYTHING*/ ),
    .valid_o      ( valid_mantissa                      )
  );

  ////////////////////
  //  Output logic  //
  ////////////////////

  logic is_negative;
  logic is_nan;
  logic is_infty;

  //Mantissa is zero
  logic mantissa_zero;

  assign mantissa_zero = ~|radicand_out.mantissa;

  assign is_negative = radicand_out.sign;

  assign is_nan = (&radicand_out.exponent) & !mantissa_zero;

  assign is_infty = (&radicand_out.exponent) & mantissa_zero;

      always_comb
        begin : OUTPUT_LOGIC

          invalid_op_o = is_negative;

          //If the result is not infinity then the square root never 
          //overflow since we are dividing the exponent by 2
          overflow_o = is_infty & (!is_negative);

          //Since we are dividing the exponent by two if we take a very
          //small number (x * 10^-70) square rooting this number will 
          //generate a bigger number
          underflow_o = 1'b0;

          if (is_infty)
            begin 
              root_o = (radicand_out.sign) ? CANO_NAN : P_INFTY;
            end
          else if (is_nan | is_negative)
            begin 
              root_o = CANO_NAN;
            end
          else 
            begin 
              root_o = root_out;
            end
        end : OUTPUT_LOGIC

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;

  assign valid_o = (crt_state == VALID);
  
endmodule
