////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Booth radix 4 multiplicator                                //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains a generic module that can perform a   //
//                 multiplication. It is used for the floating point multiply.//
////////////////////////////////////////////////////////////////////////////////


`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_booth_radix4
( //Inputs
  input  logic signed [XLEN - 1:0]       multiplier_i, multiplicand_i, 

  input  logic                           clk_i, clk_en_i,               //Clock signals
  input  logic                           rst_n_i,                       //Reset active low
  
  //Outputs
  output logic signed [(2 * XLEN) - 1:0] result_o,
  output logic                           valid_o                             
); 

  typedef enum logic [1:0] {IDLE, MULTIPLY, VALID} fsm_state_e;

  fsm_state_e crt_state, nxt_state;

  logic rst_n_dly;

      always_ff @(posedge clk_i)
        begin
          rst_n_dly <= rst_n_i;
        end

      always_ff @(posedge clk_i)
        begin
          if (!rst_n_i)
            crt_state <= IDLE;
          if (clk_en_i)
            crt_state <= nxt_state;
        end

      always_comb 
        begin
          unique case (crt_state)

            IDLE:     nxt_state = (~rst_n_dly) ? IDLE : MULTIPLY;

            //Stay in multiplication state for 16 cycles
            MULTIPLY: nxt_state = (&counter) ? VALID : MULTIPLY;

            VALID:    nxt_state = IDLE;

          endcase
        end

  typedef struct packed {
      logic signed [XLEN:0]      _P;      //Partial product
      logic signed [XLEN - 1:0]  _A;      //Multiplier
      logic                      _L;      //Last bit shifted
  } reg_pair_s;

  reg_pair_s reg_pair_in, reg_pair_out;

  logic signed [XLEN:0] partial_product;

  logic signed [XLEN:0] reg_b_in, reg_b_out;   //Multiplicand register nets

  logic [3:0] counter;
  
      always_ff @(posedge clk_i)
        begin 
          if (!rst_n_i)
            reg_pair_out <= 0;
          else if (clk_en_i)  //If the operation has completed accept new values else keep using the old ones
            begin
              if (crt_state == IDLE)
                reg_pair_out <= '{33'b0, multiplier_i, 1'b0};
              else if (crt_state == MULTIPLY)
                reg_pair_out <= reg_pair_in;
            end
        end

  assign reg_b_in = {multiplicand_i[XLEN - 1], multiplicand_i};

      always_ff @(posedge clk_i)
        begin
          if (!rst_n_i)
            reg_b_out <= 0;
          else if ((crt_state == IDLE) & clk_en_i)    //Don't update the register until the operation is completed
            reg_b_out <= reg_b_in;
        end

      always_comb 
        begin : BOOTH_RULES
          unique case ({reg_pair_out._A[1:0], reg_pair_out._L})    //Booth radix-4 rules

            3'b000:           partial_product = reg_pair_out._P + 0;

            3'b001:           partial_product = reg_pair_out._P + reg_b_out;
            
            3'b010:           partial_product = reg_pair_out._P + reg_b_out;

            3'b011:           partial_product = reg_pair_out._P + (reg_b_out << 1);   //reg_b_out * 2

            3'b100:           partial_product = reg_pair_out._P - (reg_b_out << 1);   //reg_b_out * 2

            3'b101:           partial_product = reg_pair_out._P - reg_b_out;
            
            3'b110:           partial_product = reg_pair_out._P - reg_b_out; 
            
            3'b111:           partial_product = reg_pair_out._P + 0;

          endcase

          //Floating point numbers are stored in signed magnitude form thus the multiplier operate with UNSIGNED values 
          //so we perform a LOGICAL shift right
          reg_pair_in = {partial_product, reg_pair_out._A, reg_pair_out._L} >> 2;

        end : BOOTH_RULES

      always_ff @(posedge clk_i)
        begin : COUNTER
          if (!rst_n_i)
            counter <= 0;
          else if (clk_en_i)
            counter <= counter + 1;
        end : COUNTER

  assign result_o = {reg_pair_out._P[XLEN - 1:0], reg_pair_out._A};

  assign valid_o = (crt_state == VALID);

endmodule
