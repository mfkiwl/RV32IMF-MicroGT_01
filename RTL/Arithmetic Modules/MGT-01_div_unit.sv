////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Multiplication Unit                                        //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains the hardware necessary to perform a   //
//                 signed/unsigned division. It is not pipelined to           //
//                 save area and resources. The division is performed using   //
//                 the non restoring radix-2 division algorithm.              //
////////////////////////////////////////////////////////////////////////////////

//NOT TESTED, THIS IS JUST A TEST MODULE

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

//FSM state enumeration (move in module when finish this design)
typedef enum logic [1:0] {IDLE, DIVIDE, RESTORING} fsm_state_e;

module MGT_01_div_unit 
( //Inputs
  input  logic signed [XLEN - 1:0]        dividend_i, divisor_i, 

  input  logic                            clk_i, clk_en_i,               //Clock signals
  input  logic                            rst_n_i,                       //Reset active low

  input  div_ops_e                        operation_i,

  //Outputs
  output logic signed [XLEN - 1:0]        result_o,                      
  output fu_state_e                       fu_state_o,                    //Functional unit state
  output logic                            zero_divide,

  //TEST: THIS WILL BE DELETED ONCE THIS MODULE WILL BE VERIFIED
  output fsm_state_e                      state_o,
  output logic [XLEN - 1:0]               quotient_o, remainder_o
);

  typedef struct packed {
      logic signed [XLEN:0]      _P;      //Partial 
      logic signed [XLEN - 1:0]  _A;      //Dividend
  } reg_pair_s;

  //Operands conversion in unsigned numbers

  logic signed [XLEN - 1:0] dividend, divisor;

  assign dividend = dividend_i[XLEN - 1] ? -dividend_i : dividend_i;

  assign divisor = divisor_i[XLEN - 1] ? -divisor_i : divisor_i;

  //Current and next FSM state
  fsm_state_e crt_state, nxt_state;

  logic [4:0] counter;

      //State register
      always_ff @(posedge clk_i)
        begin : STATE_REG
          if (!rst_n_i)
            crt_state <= IDLE;
          else if (~(|counter) & clk_en_i)  //The counter needs to be 0 to advance to the next state 
            crt_state <= nxt_state;
        end : STATE_REG

      //Counter, it tracks the state of the operation
      always_ff @(posedge clk_i)
        begin : COUNTER
          if (!rst_n_i)
            counter <= 0;
          else if (clk_en_i && (crt_state == DIVIDE))
            counter <= counter + 1;
        end : COUNTER

      //Next state logic
      always_comb 
        begin
          unique case (crt_state)

            IDLE:       nxt_state = DIVIDE;

            DIVIDE:   if (~|counter)
                        nxt_state = RESTORING;
                      else 
                        nxt_state = DIVIDE;

            RESTORING:  nxt_state = IDLE;

            default:    nxt_state = IDLE;
            
          endcase
        end

  //Register pair nets (contains both dividend and the partial product)
  reg_pair_s reg_pair_in, reg_pair_out;

  //Shifted dividend
  logic signed [XLEN - 1:0] A_shifted;

  //Partial division
  logic signed [XLEN:0] partial_division, partial_division_shift;

  //Divisor register nets
  logic signed [XLEN:0] reg_b_in, reg_b_out;

  assign reg_b_in = {divisor_i[XLEN - 1], divisor_i};

      //Data registers

      always_ff @(posedge clk_i)
        begin : REG_B 
          if (!rst_n_i)
            reg_b_out <= 0;
          else if ((crt_state == IDLE) && clk_en_i)    //Don't update the register until the operation is completed
            reg_b_out <= reg_b_in;
        end : REG_B 

      always_ff @(posedge clk_i)
        begin : REG_P_A
          if (!rst_n_i)
            reg_pair_out <= 0;
          else if (clk_en_i)
            begin
              if (crt_state == IDLE)
                reg_pair_out <= '{33'b0, dividend_i};
              else 
                reg_pair_out <= reg_pair_in;
            end
        end : REG_P_A 

  //Algorithm logic

  assign {partial_division_shift, A_shifted} = {reg_pair_out._P, reg_pair_out._A} << 1; //Shift left one
        
  assign reg_pair_in._A = {A_shifted[XLEN - 1:1], ~partial_division[XLEN]};    //If P[XLEN] == 1 => A[0] = 0 else A[0] = 1;
  assign reg_pair_in._P = partial_division;

      always_comb 
        begin : DIVISION_LOGIC
          if (crt_state == IDLE)
            begin
              partial_division = 0; //Initialize to zero 
            end
          else if (crt_state == DIVIDE)
            begin
              if (reg_pair_out._P[XLEN] == 1'b1)  //If P is negative
                begin                  
                  partial_division = partial_division_shift + reg_b_out;  //Add divisor to P
                end
              else  //If P is positive
                begin
                  partial_division = partial_division_shift - reg_b_out;  //Subtract divisor to P
                end
            end
          else if (crt_state == RESTORING)
            begin
              if (partial_division[XLEN] == 1'b1)     //If P is negative
                partial_division = reg_pair_out._P + reg_b_out;
              else                                    //If P is positive
                partial_division = reg_pair_out._P + 0;
            end
          else //DEFAULT
            partial_division = 0;

        end : DIVISION_LOGIC

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;

  //NOR of divisor 
  assign zero_divide = ~|divisor_i;

  //Result of the divison
  logic signed [XLEN - 1:0] quotient, remainder;

  assign quotient = reg_pair_out._A;
  assign remainder = reg_pair_out._P[XLEN - 1:0];

      always_comb 
        begin : RESULT_SELECTION
          unique case (operation_i)

            DIV_:   begin
                      case ({dividend_i[XLEN - 1], divisor_i[XLEN - 1]})

                        //If it is (positive X positive) or (negative x negative) don't change sign
                        2'b00, 2'b11:   result_o = quotient;
                                           
                        //If it is (negative X positive) or (positive x negative) change sign
                        2'b01, 2'b10:   result_o = -quotient;   
                                          
                      endcase
                    end

            DIVU_:  result_o = quotient;  //Do nothing since the operands are already unsigned

            REM_:   begin
                      case ({dividend_i[XLEN - 1], divisor_i[XLEN - 1]})

                        //If it is (positive X positive) or (negative x negative) don't change sign
                        2'b00, 2'b11:   result_o = remainder;
                                           
                        //If it is (negative X positive) or (positive x negative) change sign
                        2'b01, 2'b10:   result_o = -remainder;   
                                          
                      endcase
                    end

            REMU_:  result_o = remainder;  //Do nothing since the operands are already unsigned
            
          endcase
        end : RESULT_SELECTION
  
  //TEST: THIS WILL BE DELETED ONCE THIS MODULE WILL BE VERIFIED
  assign state_o = crt_state;
  assign quotient_o = quotient;
  assign remainder_o = remainder;

endmodule 
