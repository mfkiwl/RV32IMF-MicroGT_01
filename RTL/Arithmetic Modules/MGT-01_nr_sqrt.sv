/////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                  //
//                                                                             //
// Design Name:    Non restoring square root                                   //
// Project Name:   MicroGT-01                                                  //
// Language:       SystemVerilog                                               //
//                                                                             //
// Description:    This module contains a generic module that can perform the  //
//                 square root of an UNSIGNED N bit number. It is used for the //
//                 floating point square root module.                          //
/////////////////////////////////////////////////////////////////////////////////

// Reference: A New Non-Restoring Square Root Algorithm and Its VLSI Implementations
// Authors: Yamin Li, Wanming Chu  
// Link: https://ieeexplore.ieee.org/abstract/document/563604  

`include "Modules_pkg.svh"     
`include "Instruction_pkg.svh" 

module MGT_01_nr_sqrt #(
  parameter DATA_WIDTH = 48
)
( //Inputs
  input  logic                          clk_i,    
  input  logic                          clk_en_i,
  input  logic                          rst_n_i,     //Reset active low

  input  logic [DATA_WIDTH - 1:0]       radicand_i,

  //Outputs
  output logic [(DATA_WIDTH / 2) - 1:0] root_o,      //Result
  output logic [(DATA_WIDTH / 2):0]     remainder_o,  
  
  output logic                          valid_o
);

  //Number of iterations that this module have to perform to return a valid value
  localparam ITERATIONS = (DATA_WIDTH) / 2;

  ///////////////
  // FSM LOGIC //
  ///////////////

  typedef enum logic [1:0] {IDLE, SQRT, RESTORING, VALID} fsm_state_e;

  // IDLE: The unit is waiting for data
  // SQRT: Perform the square root
  // RESTORING: Restore the result
  // VALID: The output is valid

  fsm_state_e crt_state, nxt_state;

  logic [$clog2(ITERATIONS) - 1:0] counter;

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
          if (!rst_n_i | (crt_state == IDLE))
            counter <= ITERATIONS - 1;
          else if (clk_en_i && (crt_state == SQRT))
            counter <= counter - 1; 
        end : COUNTER

      //Next state logic
      always_comb 
        begin
          unique case (crt_state)

            IDLE:       nxt_state = (~rst_n_dly) ? IDLE : SQRT;

            SQRT:       nxt_state = (~|counter) ? RESTORING : SQRT;  //If counter is equal to 0

            RESTORING:  nxt_state = VALID;

            VALID:      nxt_state = IDLE;

            default:    nxt_state = IDLE;
            
          endcase
        end

  ////////////////////
  // Data registers //
  ////////////////////

  //Flip-Flops nets
  logic    [DATA_WIDTH - 1:0] root_in, root_out;           //Q
  logic    [DATA_WIDTH:0] remainder_in, remainder_out;     //R
  logic    [DATA_WIDTH - 1:0] radicand_in, radicand_out;   //D
  
  logic signed [DATA_WIDTH:0] remainder_rest;

  assign radicand_in = radicand_i;
   
      always_ff @(posedge clk_i)
        begin
          if (!rst_n_i)
            radicand_out <= 0;
          else if (clk_en_i & (crt_state == IDLE))
            radicand_out <= radicand_in;
        end

      always_ff @(posedge clk_i) 
        begin : DATA_REGISTER
          if (!rst_n_i)
            begin 
              //Reset logic
              root_out <= 0;
              remainder_out <= 0;
            end
          else if (clk_en_i & (crt_state == IDLE))
            begin 
              //Load the values with the initial value
              root_out <= 0;
              remainder_out <= 0;
            end
          else if (clk_en_i & (crt_state == SQRT))
            begin 
              //Each iteration update the values
              root_out <= root_in;
              remainder_out <= remainder_in;
            end
          else if (clk_en_i & (crt_state == RESTORING))
            begin 
              remainder_out <= remainder_rest;
            end
        end : DATA_REGISTER

  /////////////////////
  // Algorithm logic //
  /////////////////////

  //To store counter + counter or 2 * counter
  logic [$clog2(ITERATIONS):0] counter_2;   

  assign counter_2 = counter << 1;

  logic [DATA_WIDTH:0]  rem_new; 

      always_comb
        begin : ALGORITHM_LOGIC
          //If the remainder is negative
          if (remainder_out[DATA_WIDTH])
            begin 
              rem_new = (remainder_out << 2) | ((radicand_out >> counter_2) & 'd3);

              remainder_in = rem_new + ((root_out << 2) | 'd3);
            end
          //If the remainder is positive or zero
          else
            begin 
              rem_new = (remainder_out << 2) | ((radicand_out >> counter_2) & 'd3);

              remainder_in = rem_new - ((root_out << 2) | 'b1);
            end

          //If the remainder is negative
          if (remainder_in[DATA_WIDTH])
            root_in = (root_out << 1);
          //If the remainder is positive
          else
            root_in = (root_out << 1) | 'b1;
        end : ALGORITHM_LOGIC

  //Restoring logic

  //If the remainder is negative => RESTORE else don't change anything
  assign remainder_rest = remainder_out[DATA_WIDTH] ? (remainder_out + ((root_out << 1'b1) | 'b1)) : remainder_out; 

  ////////////////////
  //  Output logic  //
  ////////////////////

  assign valid_o = (crt_state == VALID);

  assign remainder_o = remainder_out;

  assign root_o = root_out;
  
endmodule
