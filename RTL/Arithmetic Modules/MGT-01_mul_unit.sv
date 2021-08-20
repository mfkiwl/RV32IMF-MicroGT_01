////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Multiplication Unit                                        //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    This module contains the hardware necessary to perform a   //
//                 signed/unsigned multiplication. It is not pipelined to     //
//                 save area and resources. The multiplication is performed   //
//                 using the Booth radix-4 multiplication algorithm.          //
////////////////////////////////////////////////////////////////////////////////

`include "Instruction_pkg.svh"
`include "Modules_pkg.svh"

module MGT_01_mul_unit
( //Inputs
  input  logic signed [XLEN - 1:0]        multiplier_i, multiplicand_i, 

  input  logic                            clk_i, clk_en_i,               //Clock signals
  input  logic                            rst_n_i,                       //Reset active low

  input  mul_ops_e                        operation_i,
  
  //Outputs
  output logic signed [XLEN - 1:0]        result_o,                      
  output fu_state_e                       fu_state_o,                    //Functional unit state
  output logic                            sel_mux_o                      //Final execute multiplexer select
);

//START BOOTH RADIX-4 ALGORITHM 

  typedef struct packed {
      logic signed [XLEN:0]      _P;      //Partial product
      logic signed [XLEN - 1:0]  _A;      //Multiplier
      logic                      _L;      //Last bit shifted
  } reg_pair_s;

  reg_pair_s reg_pair_in, reg_pair_out;

  logic signed [XLEN:0] partial_product;

  logic signed [XLEN:0] reg_b_in, reg_b_out;   //Multiplicand register nets
  
  logic [4:0] counter;
  
  //~(|counter) is equal to counter == 0
  
      always_ff @(posedge clk_i)
        begin 
          if (!rst_n_i)
            reg_pair_out <= 0;
          else if (clk_en_i)  //If the operation has completed accept new values else keep using the old ones
            reg_pair_out <= (~(|counter)) ? '{33'b0, multiplier_i, 1'b0} : reg_pair_in;
        end

  assign reg_b_in = {multiplicand_i[XLEN - 1], multiplicand_i};

      always_ff @(posedge clk_i)
        begin
          if (!rst_n_i)
            reg_b_out <= 0;
          else if (~(|counter) & clk_en_i)    //Don't update the register until the operation is completed
            reg_b_out <= reg_b_in;
        end

      always_comb 
        begin : BOOTH_RULES
          case ({reg_pair_out._A[1:0], reg_pair_out._L})    //Booth radix-4 rules

            3'b000:           partial_product = reg_pair_out._P + 0;

            3'b001:           partial_product = reg_pair_out._P + reg_b_out;
            
            3'b010:           partial_product = reg_pair_out._P + reg_b_out;

            3'b011:           partial_product = reg_pair_out._P + (reg_b_out << 1);   //reg_b_out * 2

            3'b100:           partial_product = reg_pair_out._P - (reg_b_out << 1);   //reg_b_out * 2

            3'b101:           partial_product = reg_pair_out._P - reg_b_out;
            
            3'b110:           partial_product = reg_pair_out._P - reg_b_out; 
            
            3'b111:           partial_product = reg_pair_out._P + 0;

          endcase

          //Arithmetic shift for signed numbers. Cast $signed else the >>> operator would synthesize in a LOGICAL shift right.
          {reg_pair_in._P, reg_pair_in._A, reg_pair_in._L} = $signed({partial_product, reg_pair_out._A, reg_pair_out._L}) >>> 2;

        end : BOOTH_RULES

      always_ff @(posedge clk_i)
        begin : COUNTER
          if (!rst_n_i)
            counter <= 0;
          else if (clk_en_i)
            begin 
              if (counter == 5'd16)
                counter <= 0;
              else 
                counter <= counter + 1;
            end
        end : COUNTER

  logic signed [(XLEN * 2) - 1:0] result_mul;

  //When the functional unit is FREE the result become VALID 
  assign fu_state_o = (~(|counter)) ? FREE : BUSY;

  assign result_mul = {reg_pair_out._P[XLEN - 1:0], reg_pair_out._A};

//END BOOTH RADIX-4 ALGORITHM

    always_comb 
      begin : MULTIPLEXER
        case (operation_i)

                    //Take the lower 32 bits
          MUL_:     result_o = result_mul[XLEN - 1:0];  

                    //Take the upper 32 bits
          MULH_:    result_o = result_mul[63:XLEN];

                    //Take the unsigned upper 32 bits (unsigned X unsigned multiplication)
          MULHU_:   result_o = result_mul[(XLEN * 2) - 1] ? -result_mul[63:XLEN] : result_mul[63:XLEN];


          MULHSU_:  begin 
                      case({multiplier_i[XLEN - 1], multiplicand_i[XLEN - 1]}) 
                                   
                        //Both positive
                        2'b00:            result_o = result_mul[63:XLEN];

                        //Positive, negative
                        2'b01:            result_o = -result_mul[63:XLEN];

                        //Negative, positive
                        2'b10:            result_o = result_mul[63:XLEN];

                        //Both negative
                        2'b11:            result_o = -result_mul[63:XLEN];

                      endcase
                    end
        endcase
      end : MULTIPLEXER
  
  //When result is VALID (when counter is equal to 0) the multiplexer select the output of this functional unit.
  assign sel_mux_o = (~(|counter));

endmodule
