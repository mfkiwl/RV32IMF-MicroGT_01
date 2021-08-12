/////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                  //
//                                                                             //
// Design Name:    Floating point adder                                        //
// Project Name:   MicroGT-01                                                  //
// Language:       SystemVerilog                                               //
//                                                                             //
// Description:    Floating Point adder, it perform both add and sub operation.//                                    
//                 It produces the output in 4 cycles.                         //
/////////////////////////////////////////////////////////////////////////////////
//
//NOTES FOR FUTURE:
//FP-add-sub 4 latency cycles
//FP-mul     4 latency cycles
//FP-fused   6 latency cycles
//FP-div    10 latency cycles
//FP-sqrt   12 latency cycles
//
//rst_n_i should be asserted for two cycles

//MODULE STILL NOT TESTED

`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_fp_add_sub 
( //Inputs
  input  float_t         op_A_i, op_B_i,   //Operands

  input  float_funct7_e  iw_funct7_i,

  input  logic           clk_i,
  input  logic           clk_en_i,        //Enable clock
  input  logic           rst_n_i,         //Reset active low

  //Outputs
  output float_t         result_o,
  output fu_state_e      fu_state_o,      //Functional unit state

  output logic           underflow_o,
  output logic           overflow_o,
  output logic           invalid_op_o     //IEE-754 invalid operation
);

  logic op_A_valid, op_B_valid;

  logic op_A_rdy, op_B_rdy;

  //Inputs are ready when the clock enable is active

  logic ops_valid;    //Operation is valid
  logic ops_rdy;

  logic [7:0] ops_ip; //Ip block operation to perform (ADD or SUB)

  //ADD: 000000000

  //SUB: 000000001

      always_comb 
        begin : OP_SELECT
          if (iw_funct7_i == FADD)
            begin
              ops_ip = 8'b000000000;
            end
          else if (iw_funct7_i == FSUB)
            begin
              ops_ip = 8'b000000001;
            end
          else        //If it's not an ADD or a SUB
            begin
              ops_ip = 8'b000000000; //Don't care
            end
        end : OP_SELECT

  logic result_valid, result_rdy;

  logic [2:0] exception_ip_out;

  //VIVADO IP

    fp_add_sub fp_add_sub (
    .aclk                     ( clk_i            ),                                   
    .aclken                   ( clk_en_i         ),                          
    .aresetn                  ( rst_n_i          ),                   
    .s_axis_a_tvalid          ( op_A_valid       ),               
    .s_axis_a_tready          ( op_A_rdy         ),        
    .s_axis_a_tdata           ( op_A_i           ),         
    .s_axis_b_tvalid          ( op_B_valid       ),     
    .s_axis_b_tready          ( op_B_rdy         ),         
    .s_axis_b_tdata           ( op_B_i           ),                    
    .s_axis_operation_tvalid  ( ops_valid        ), 
    .s_axis_operation_tready  ( ops_rdy          ),  
    .s_axis_operation_tdata   ( ops_ip           ),    
    .m_axis_result_tvalid     ( result_valid     ),        
    .m_axis_result_tready     ( result_rdy       ),        
    .m_axis_result_tdata      ( result_o         ),          
    .m_axis_result_tuser      ( exception_ip_out )          
  );

  assign underflow_o = exception_ip_out[0];

  assign overflow_o = exception_ip_out[1];

  assign invalid_op_o = exception_ip_out[2];


  logic [1:0] counter;

      always_ff @(posedge clk_i)
        begin : COUNTER
          if (!rst_n_i)
            counter <= 2'b0;
          else if (clk_en_i & ops_valid)
            begin
              if (counter == 4)
                counter <= 2'b0;    //This is overflow 
              else 
                counter <= counter + 1;
            end
        end : COUNTER

  assign fu_state_o = (counter == 0) ? FREE : BUSY;

endmodule 