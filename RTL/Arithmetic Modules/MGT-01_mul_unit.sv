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

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_div_unit 
( //Inputs
  input  logic signed [XLEN - 1:0]        dividend_i, divisor_i, 

  input  logic                            clk_i, clk_en_i,               //Clock signals
  input  logic                            rst_n_i,                       //Reset active low

  input  div_ops_e                        operation_i,

  //Outputs
  output logic signed [XLEN - 1:0]        result_o,                      
  output fu_state_e                       fu_state_o,                    //Functional unit state
  output logic                            zero_divide
);

  typedef enum logic [1:0] {IDLE, DIVIDE, RESTORING} fsm_state_e;

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
  
  logic rst_n;  //Reset delayed
  
      // We delay the reset signals by 1 cycle because the FSM should
      // stay 2 cycles in the IDLE stage when resetted

      always_ff @(posedge clk_i)
        begin
          rst_n <= rst_n_i;
        end

      //State register
      always_ff @(posedge clk_i)
        begin : STATE_REG
          if (!rst_n_i)
            crt_state <= IDLE;
          else if (clk_en_i)   
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

            IDLE:       nxt_state = (~rst_n) ? IDLE : DIVIDE;

            DIVIDE:     nxt_state = (&counter) ? RESTORING : DIVIDE;  //If counter is equal to 11111

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

  assign reg_b_in = {divisor[XLEN - 1], divisor};

      //Data registers

      always_ff @(posedge clk_i)
        begin : REG_B 
          if (!rst_n_i)
            reg_b_out <= 32'b0;
          else if ((crt_state == IDLE) && clk_en_i)    //Don't update the register until the operation is completed
            reg_b_out <= reg_b_in;
        end : REG_B 

      always_ff @(posedge clk_i)
        begin : REG_P_A
          if (!rst_n_i)
            reg_pair_out <= 0;
          if (clk_en_i)
            begin
              if (crt_state == IDLE)
                reg_pair_out <= '{33'b0, dividend};
              else if (crt_state == DIVIDE)
                reg_pair_out <= reg_pair_in;
              else 
                reg_pair_out._P <= reg_pair_in._P;
            end
        end : REG_P_A 

  //Algorithm logic

  assign {partial_division_shift, A_shifted} = reg_pair_out << 1; //Shift left one
        
  assign reg_pair_in._A = {A_shifted[XLEN - 1:1], ~reg_pair_out._P[XLEN]};    //If P[XLEN] == 1 => A[0] = 0 else A[0] = 1;
  assign reg_pair_in._P = partial_division;

      always_comb 
        begin : DIVISION_LOGIC
          if (crt_state == IDLE)
            begin
              partial_division = 32'b0; //Initialize to zero 
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
              if (reg_pair_out._P[XLEN] == 1'b1)     //If P is negative
                partial_division = reg_pair_out._P + reg_b_out;
              else                                    //If P is positive
                partial_division = reg_pair_out._P + 32'b0;
            end
          else //DEFAULT
            partial_division = 32'b0;

        end : DIVISION_LOGIC

  assign fu_state_o = (crt_state == IDLE) ? FREE : BUSY;

  //NOR of divisor 
  assign zero_divide = ~|divisor_i;

  //Result of the divison
  logic signed [XLEN - 1:0] quotient, remainder;

  assign quotient = A_shifted;
  assign remainder = reg_pair_out._P[XLEN - 1:0];
  
  //Operation register
  
  logic signed [XLEN - 1:0] dividend_ff, divisor_ff;
  
      always_ff @(posedge clk_i)
        begin
          if (clk_en_i && (crt_state == IDLE))
            begin 
              dividend_ff <= dividend_i;
              divisor_ff <= divisor_i;
            end
        end

      always_comb 
        begin : RESULT_SELECTION
          unique case (operation_i)

            //Perform a XOR between the two sign bit, if they are different invert the result otherwise keep the result

            DIV_:   result_o = (dividend_ff[XLEN - 1] ^ divisor_ff[XLEN - 1]) ? -quotient : quotient;

            DIVU_:  result_o = quotient;  //Do nothing since the operands are already unsigned

            //Perform a XOR between the two sign bit, if they are different invert the result otherwise keep the result

            REM_:   result_o = (dividend_ff[XLEN - 1] ^ divisor_ff[XLEN - 1]) ? -remainder : remainder;

            REMU_:  result_o = remainder;  //Do nothing since the operands are already unsigned
            
          endcase
        end : RESULT_SELECTION

endmodule 
