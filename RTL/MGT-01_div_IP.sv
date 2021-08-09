////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Divide Unit                                                //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Divide unit, it perform XLEN / XLEN signed/unsigned        // 
//                 division with remainder. It has 36 latency cycle and it    //
//                 detect the division by zero (the only arithmetic exception)//  
//                 in RISC-V                                                  //
////////////////////////////////////////////////////////////////////////////////

`include "Primitives/Modules_pkg.svh"
`include "Primitives/Instruction_pkg.svh"

module MGT_01_div_IP
( //Inputs
  input  data_u    dividend_i,   //Dividend
  input  data_u    divisor_i,    //Divisor

  input  logic     clk_i,
  input  logic     clk_en_i,
  input  logic     rst_n_i,      //Reset active low

  input  div_ops_e ops_i,        //Select bits and signed or unsigned operation

  //Outputs
  output data_u    result_o,
  output logic     div_by_zero   //Exception bit
);

  typedef struct packed {
      logic [XLEN - 1:0] quotient;
      logic [XLEN - 1:0] remainder;
  } div_out_s;

  logic dividend_valid;  
  logic divisor_valid;
  logic out_valid;
  logic div_by_zero_sd; //Out of signed divider
  logic div_by_zero_ud; //Out of unsigned divider

  assign dividend_valid = 1'b1;   //Always valid

  assign divisor_valid = 1'b1;    //Always valid 

  div_out_s s_div_out;  //Output of divider
  div_out_s u_div_out;

  sign_div signed_divider (
    .aclk                   ( clk_i              ),                                    
    .aclken                 ( clk_en_i           ),                              
    .aresetn                ( rst_n_i            ),                               
    .s_axis_divisor_tvalid  ( divisor_valid      ), //Don't care    
    .s_axis_divisor_tdata   ( divisor_i.s_data   ),    
    .s_axis_dividend_tvalid ( dividend_valid     ), //Don't care
    .s_axis_dividend_tdata  ( dividend_i.s_data  ),    
    .m_axis_dout_tvalid     ( out_valid          ), //Don't care         
    .m_axis_dout_tuser      ( div_by_zero_sd     ),            
    .m_axis_dout_tdata      ( s_div_out          )             
  );

  // Since the unsigned divider has 34 cycle of latency and the signed one has 36 we need
  // to create 2 additional cycles of latency using 2 flip flops to simplify the control logic.
  // l1 and l2 stands for latency.

  data_u dividend_l1, dividend_l2;
  data_u divisor_l1, divisor_l2;
  logic  rst_n_l1, rst_n_l2;
  
      always_ff @(posedge clk_i)
        begin : LATENCY_1
          if (clk_en_i)
            dividend_l1 <= dividend_i;
            divisor_l1  <= divisor_i;
            rst_n_l1    <= rst_n_i;
        end : LATENCY_1

      always_ff @(posedge clk_i)
        begin : LATENCY_2
          if (clk_en_i)
            dividend_l2 <= dividend_l1;
            divisor_l2  <= divisor_l1;
            rst_n_l2    <= rst_n_l1;
        end : LATENCY_2

  unsigned_div unsigned_divider (
    .aclk                   ( clk_i              ),                                    
    .aclken                 ( clk_en_i           ),                              
    .aresetn                ( rst_n_l2           ),                               
    .s_axis_divisor_tvalid  ( divisor_valid      ), //Don't care    
    .s_axis_divisor_tdata   ( divisor_l2.u_data  ),    
    .s_axis_dividend_tvalid ( dividend_valid     ), //Don't care
    .s_axis_dividend_tdata  ( dividend_l2.u_data ),    
    .m_axis_dout_tvalid     ( out_valid          ), //Don't care         
    .m_axis_dout_tuser      ( div_by_zero_ud     ),            
    .m_axis_dout_tdata      ( u_div_out          )             
  );

  //Select output logic
    
    always_comb 
      begin
        unique case (ops_i)

          DIV_: begin  
                  result_o = s_div_out.quotient;
                  div_by_zero = div_by_zero_sd;
                end

          DIVU_: begin
                   result_o = u_div_out.quotient;
                   div_by_zero = div_by_zero_ud;
                 end

          REM_:  begin
                   result_o = s_div_out.remainder;
                   div_by_zero = div_by_zero_sd;
                 end

          REMU_:  begin
                    result_o = u_div_out.quotient;
                    div_by_zero = div_by_zero_ud;
                  end
                  
        endcase
      end

endmodule
