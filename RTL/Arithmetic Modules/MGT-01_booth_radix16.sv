////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Booth radix 16 multiplicator                               //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains a generic module that can perform a   //
//                 multiplication. It is used for the floating point          //
//                 HIGH PERFORMANCE multiplication.                           //
////////////////////////////////////////////////////////////////////////////////


`include "Modules_pkg.svh"
`include "Instruction_pkg.svh"

module MGT_01_booth_radix16
( //Inputs
  input  logic signed [XLEN - 1:0]       multiplier_i, multiplicand_i, 

  input  logic                           clk_i, clk_en_i,               //Clock signals
  input  logic                           rst_n_i,                       //Reset active low
  
  //Outputs
  output logic signed [(2 * XLEN) - 1:0] result_o,
  output logic                           valid_o                             
); 
  
  // Since the B operand is shifted at maximum of SHIFT_AMOUNT - 1 
  // the registers P and B should be that amount of bits wider to 
  // accomodate the shifted bits.
  localparam TOTAL_BITS = XLEN + 3;
  
  typedef enum logic [1:0] {IDLE, MULTIPLY, VALID} fsm_state_e;

  fsm_state_e crt_state, nxt_state;
  
  logic [2:0] counter;
  logic rst_n_dly;

      always_ff @(posedge clk_i)
        begin
          rst_n_dly <= rst_n_i;
        end

      always_ff @(posedge clk_i)
        begin : STATE_REGISTER
          if (!rst_n_i)
            crt_state <= IDLE;
          if (clk_en_i)
            crt_state <= nxt_state;
        end : STATE_REGISTER

      always_comb 
        begin
          case (crt_state)

            IDLE:     nxt_state = (~rst_n_dly) ? IDLE : MULTIPLY;

            //Stay in multiplication state for 8 cycles
            MULTIPLY: nxt_state = (&counter) ? VALID : MULTIPLY;

            VALID:    nxt_state = IDLE;

          endcase
        end

  typedef struct packed {
    logic signed [TOTAL_BITS - 1:0] _P;      //Partial product
    logic signed [XLEN - 1:0]       _A;      //Multiplier
      logic                         _L;      //Last bit shifted
  } reg_pair_s;

  reg_pair_s reg_pair_in, reg_pair_out;

  logic signed [TOTAL_BITS - 1:0] partial_product;

  logic signed [TOTAL_BITS - 1:0] reg_b_in, reg_b_out;   //Multiplicand register nets
  
      always_ff @(posedge clk_i)
        begin 
          if (!rst_n_i)
            reg_pair_out <= 0;
          else if (clk_en_i)  //If the operation has completed accept new values else keep using the old ones
            begin
              if (crt_state == IDLE)
                reg_pair_out <= '{35'b0, multiplier_i, 1'b0};
              else if (crt_state == MULTIPLY)
                reg_pair_out <= reg_pair_in;
            end
        end
  
  //Sign extend
  assign reg_b_in = $signed(multiplicand_i);

      always_ff @(posedge clk_i)
        begin
          if (!rst_n_i)
            reg_b_out <= 0;
          else if ((crt_state == IDLE) & clk_en_i)    //Don't update the register until the operation is completed
            reg_b_out <= reg_b_in;
        end

      always_comb 
        begin : BOOTH_RULES
          if (crt_state == MULTIPLY)
            begin
              case ({reg_pair_out._A[3:0], reg_pair_out._L})    //Booth radix-16 rules

                5'b00000,
                5'b11111:    partial_product = reg_pair_out._P;   //P + 0

                5'b00001,
                5'b00010:    partial_product = reg_pair_out._P + reg_b_out;   //P + B
                
                5'b00011,
                5'b00100:    partial_product = reg_pair_out._P + (reg_b_out << 1);    //P + 2B

                5'b00101,
                5'b00110:    partial_product = reg_pair_out._P + ((reg_b_out << 1) + reg_b_out);    //P + 3B 

                5'b00111,
                5'b01000:    partial_product = reg_pair_out._P + (reg_b_out << 2);    //P + 4B

                5'b01001,
                5'b01010:    partial_product = reg_pair_out._P + ((reg_b_out << 2) + reg_b_out);    //P + 5B 

                5'b01011,
                5'b01100:    partial_product = reg_pair_out._P + ((reg_b_out << 2) + (reg_b_out << 1));   //P + 6B

                5'b01101,
                5'b01110:    partial_product = reg_pair_out._P + ((reg_b_out << 2) + (reg_b_out << 1) + reg_b_out);   //P + 7B

                5'b01111:    partial_product = reg_pair_out._P + (reg_b_out << 3);    //P + 8B

                5'b10000:    partial_product = reg_pair_out._P - (reg_b_out << 3);    //P - 8B
                
                5'b10001,
                5'b10010:    partial_product = reg_pair_out._P - ((reg_b_out << 2) + (reg_b_out << 1) + reg_b_out);    //P - 7B

                5'b10011,
                5'b10100:    partial_product = reg_pair_out._P - ((reg_b_out << 2) + (reg_b_out << 1));    //P - 6B

                5'b10101,
                5'b10110:    partial_product = reg_pair_out._P - ((reg_b_out << 2) + reg_b_out);   //P - 5B

                5'b10111,
                5'b11000:    partial_product = reg_pair_out._P - (reg_b_out << 2);    //P - 4B

                5'b11001,
                5'b11010:    partial_product = reg_pair_out._P - ((reg_b_out << 1) + reg_b_out);    //P - 3B

                5'b11011,
                5'b11100:    partial_product = reg_pair_out._P - (reg_b_out << 1);    //P - 2B

                5'b11101,
                5'b11110:    partial_product = reg_pair_out._P - reg_b_out;   //P - B

              endcase

              //Floating point numbers are stored in signed magnitude form thus the multiplier operate with UNSIGNED values 
              //so we perform a LOGICAL shift right
              reg_pair_in = $signed({partial_product, reg_pair_out._A, reg_pair_out._L}) >>> 4;

            end
          else 
            begin 
              //No operation
              reg_pair_in = 0;
            end

        end : BOOTH_RULES

      always_ff @(posedge clk_i)
        begin : COUNTER
          if (!rst_n_i)
            counter <= 0;
          else if (clk_en_i & (crt_state == MULTIPLY))
            counter <= counter + 1;
        end : COUNTER

  assign result_o = {reg_pair_out._P[XLEN - 1:0], reg_pair_out._A};

  assign valid_o = (crt_state == VALID);

endmodule
