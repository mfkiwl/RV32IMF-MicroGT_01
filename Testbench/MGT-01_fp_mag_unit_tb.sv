`timescale 1ns/1ps

module MGT_01_mag_unit_tb ();

  localparam T = 10;

  //Inputs
  float_t  operand_A_i, operand_B_i;

  fcmp_ops operation_i;

  logic    clk_i, clk_en_i;           //Clock signals
  logic    rst_n_i;                   //Reset active low

  //Outputs
  float_t  to_round_unit_o;           //Result
  logic    invalid_op_o;
  logic    overflow_o; 
  logic    underflow_o;

  int counter = 0;

  MGT_01_fp_mag_unit uut (.*);

      initial
        begin 
          clk_i = 1;
          rst_n_i = 0;
          clk_en_i = 0;
        end

      always #(T / 2) clk_i = !clk_i;

      initial
        begin
          rst_n_i = 0;
          clk_en_i = 0;
          
          #T;

          rst_n_i = 1;
          clk_en_i = 1;
          operation_i = FMAX_;

          operand_A_i = 32'h40F224DD;   //7.567
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert (to_round_unit_o == operand_A_i)
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);

          counter++;

          operand_A_i = 32'h3F99999A;   //1.2
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert (to_round_unit_o == operand_B_i)
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);

          counter++;

          operand_A_i = Q_NAN;          //QNAN
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert ((to_round_unit_o == operand_B_i) && (invalid_op_o == 0))
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);
          
          counter++;

          operand_A_i = S_NAN;          //SNAN
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert (to_round_unit_o == operand_B_i)
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);

          counter++;

          operation_i = FMIN_;

          operand_A_i = 32'h40F224DD;   //7.567
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert (to_round_unit_o == operand_B_i)
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);

          counter++;

          operand_A_i = 32'h3F99999A;   //1.2
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert (to_round_unit_o == operand_A_i)
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);
          
          counter++;

          operand_A_i = Q_NAN;          //QNAN
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert ((to_round_unit_o == operand_B_i) && (invalid_op_o == 0))
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);
          
          counter++;

          operand_A_i = S_NAN;          //SNAN
          operand_B_i = 32'h40BD70A4;   //5.92

          #(2 * T);

          assert ((to_round_unit_o == operand_B_i) && (invalid_op_o == 1))
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);

          counter++;

          operand_A_i = S_NAN;   //SNAN
          operand_B_i = S_NAN;   //5.92

          #(2 * T);

          assert ((to_round_unit_o == CANO_NAN) && (invalid_op_o == 1))
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);

          counter++;

          operand_A_i = 32'h40BD70A4;   //5.92
          operand_B_i = N_INFTY;        

          #(2 * T);

          assert ((to_round_unit_o == N_INFTY) && (overflow_o == 0))
            $display("Assertion %d completed!", counter);
          else 
            $error("Assertion %d failed!", counter);

          $stop;
        end 

endmodule