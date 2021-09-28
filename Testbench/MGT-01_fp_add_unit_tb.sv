`timescale 1ns/1ps

module MGT_01_fp_add_unit_tb ();

  localparam T = 10;
  localparam NUMBER_TEST = 50;

  //Inputs
  float_t          op_A_i, op_B_i;     //Operands

  logic            rst_n_i;            //Reset active low
  logic            clk_i, clk_en_i;    //Clock signals

  fsum_ops         operation_i;
  rounding_e       round_i; 

  //Outputs
  float_t          to_round_unit_o;    
  fu_state_e       fu_state_o;         //Functional unit state
  rounding_e       round_o; 
  logic            valid_o;

  logic            underflow_o;
  logic            overflow_o;
  logic            invalid_op_o; 

  MGT_01_fp_add_unit uut (.*);

  //Expected values
  shortreal scoreboard [NUMBER_TEST];

  //Output values
  float_t scoreboard_out [NUMBER_TEST];

  shortreal float_A, float_B;
  shortreal float_result;

  int i = 0;

  logic [31:0] mantissa_masked;
  logic [31:0] exponent_masked;
  logic [31:0] sign_masked;
  
  logic clk4;
  logic [1:0] count;
  
      initial
        begin
          #10;
          rst_n_i = 1'b0;
          clk_en_i = 1'b0;
        end
          
      always 
        begin
         clk_i = 0; #5;
         clk_i = 1; #5;
        end  
        
      always @(posedge clk_i)
        begin
          if (!rst_n_i)
            count <= 0;
          else 
            count <= count + 1;
        end       
        
  assign clk4 = &count;
        
  assign float_result = (operation_i == FADD_) ? (float_A + float_B) : (float_A - float_B);
  
  int j = 0;
  
      always @(posedge clk_i)
        begin           
          float_A = $random();
          float_B = $random();  
          
          rst_n_i = 1'b1;
          clk_en_i = 1'b1;
          op_A_i = $shortrealtobits(float_A);   //Assign the randomized values to the input converting them
          op_B_i = $shortrealtobits(float_B);   //in 32 bits vector
          operation_i = (i % 2) ? FADD_ : FSUB_;
          round_i = RTZ;

          scoreboard_out[j] = to_round_unit_o;  //Initialize the scoreboard
          j++;
          
          #(T * 4);
        end
        
  
      always @(posedge clk4)
        begin 
            if (i == NUMBER_TEST)
              $stop;
          scoreboard[i] = float_result;   //Initialize the scoreboard 
          
          mantissa_masked = $shortrealtobits(scoreboard[i]) & {9'b0, 23'b1};
          exponent_masked = $shortrealtobits(scoreboard[i]) & {1'b0, 8'b1, 23'b0};
          sign_masked = $shortrealtobits(scoreboard[i]) & {1'b1, 31'b0};

          assert (sign_masked[31] == scoreboard_out[i].sign)  
              $display("Sign of test [%d] is correct!\n", i);   
            else $error("Sign test [%d] failed at time %t!\n", i, $time);

          assert (exponent_masked[30:23] == scoreboard_out[i].exponent)  
              $display("Exponent of test [%d] is correct!\n", i);   
            else $error("Exponent test [%d] failed at time %t!\n", i, $time);

          assert (mantissa_masked[22:0] == scoreboard_out[i].mantissa)  
              $display("Mantissa of test [%d] is correct!\n", i);   
            else $error("Mantissa test [%d] failed at time %t!\n", i, $time);

          $monitor("Comparison:\n");
          $display("EXPECTED: %h\n", $shortrealtobits(scoreboard[i]));
          $display("OUTPUT:   %h\n", scoreboard_out[i]);   
          
          i++;                            
        end
endmodule