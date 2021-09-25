////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Non restoring divider                                      //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains a generic module that can perform a   //
//                 division. It is used for the floating point division.      //
////////////////////////////////////////////////////////////////////////////////

`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_nr_divider ( 
  //Inputs
  input  logic signed [24:0]              dividend_i, divisor_i, 

  input  logic                            clk_i, clk_en_i,               //Clock signals
  input  logic                            rst_n_i,                       //Reset active low

  //Outputs
  output logic signed [24:0]              quotient_o, remainder_o,                     
  output logic                            valid_o,
  output logic                            zero_divide_o
);

  //Number of iteration done by the sequential divider 
  localparam ITERATIONS = 24;

  //XLEN == 24 XLEN - 1 == 23

  typedef enum logic [1:0] {IDLE, DIVIDE, RESTORING, VALID} fsm_state_e;

  typedef struct packed {
      logic signed [25:0] _P;      //Partial 
      logic signed [24:0] _A;      //Dividend
  } reg_pair_s;

  logic signed [24:0] dividend, divisor;

  assign dividend = dividend_i;

  assign divisor = divisor_i;

  ///////////////
  // FSM LOGIC //
  ///////////////

  //Current and next FSM state
  fsm_state_e crt_state, nxt_state;

  logic [5:0] counter;
  
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

      //Counter, it tracks the state of the operation
      always_ff @(posedge clk_i)
        begin : COUNTER
          if (!rst_n_i | (counter == ITERATIONS))
            counter <= 0;
          else if (clk_en_i && (crt_state == DIVIDE))
            counter <= counter + 1; 
        end : COUNTER

      //Next state logic
      always_comb 
        begin
          unique case (crt_state)

            IDLE:       nxt_state = (~rst_n_dly) ? IDLE : DIVIDE;

            DIVIDE:     nxt_state = (counter == ITERATIONS) ? RESTORING : DIVIDE;  //If counter is equal to 11111

            RESTORING:  nxt_state = VALID;

            VALID:      nxt_state = IDLE;
            
          endcase
        end

  //Register pair nets (contains both dividend and the partial product)
  reg_pair_s reg_pair_in, reg_pair_out;

  //Shifted dividend
  logic signed [24:0] A_shifted;

  //Partial division
  logic signed [25:0] partial_division, partial_division_shift;

  //Divisor register nets
  logic signed [25:0] reg_b_in, reg_b_out;

  assign reg_b_in = {divisor[24], divisor};

  ////////////////////
  // Data registers //
  ////////////////////
  
      always_ff @(posedge clk_i)
        begin : REG_B 
          if (!rst_n_i)
            reg_b_out <= 26'b0;
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
                reg_pair_out <= '{dividend, 26'b0};
              else if (crt_state == DIVIDE)
                reg_pair_out <= reg_pair_in;
              else 
                reg_pair_out._P <= reg_pair_in._P;
            end
        end : REG_P_A 

  /////////////////////
  // Algorithm logic //
  /////////////////////

  //If the divider is in the first iteration just skip it
  assign {partial_division_shift, A_shifted} = (~|counter) ? reg_pair_out : (reg_pair_out << 1); 
        
  assign reg_pair_in._A = {A_shifted[24:1], ~partial_division[25]};    //If P[XLEN] == 1 => A[0] = 0 else A[0] = 1;
  assign reg_pair_in._P = partial_division;

      always_comb 
        begin : DIVISION_LOGIC
          if (crt_state == IDLE)
            begin
              partial_division = 26'b0; //Initialize to zero 
            end
          else if (crt_state == DIVIDE)
            begin
              if (reg_pair_out._P[25] == 1'b1)  //If P is negative
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
              if (reg_pair_out._P[25] == 1'b1)     //If P is negative
                partial_division = reg_pair_out._P + reg_b_out;
              else                                 //If P is positive
                partial_division = reg_pair_out._P + 0;
            end
          else //DEFAULT
            partial_division = reg_pair_out._P;
        end : DIVISION_LOGIC

  //NOR of divisor 
  assign zero_divide_o = ~|divisor_i;

  assign quotient_o = reg_pair_out._A;
  assign remainder_o = reg_pair_out._P[24:0];

  assign valid_o = (crt_state == VALID);

endmodule
