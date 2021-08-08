`timescale 1ns/1ps


module MGT_01_iregs_tb ();

  localparam T = 10;  //Clock cycle in nanoseconds

  //Signals
  //Inputs
  logic        clk_i;       //Clock 
  logic        we_i;        //Write enable 

  i_register_e r1_iaddr_i;  //Read addresses
  i_register_e r2_iaddr_i;

  i_register_e w_iaddr_i;   //Write address

  data_bus_t   wr_idata_i;  //Write port

  //Outputs
  data_bus_t   r1_idata_o;  //Read ports
  data_bus_t   r2_idata_o;
  

  //UUT intantiation
  MGT_01_i_reg_file uut (.*);

  //Test

    //Clock 
    always 
      begin
        clk_i = 1'b1;
        #(T / 2);
        clk_i = 1'b0;
        #(T / 2);
      end

    //Initial values
    initial 
      begin
        we_i = 1'b0;
        r1_iaddr_i = X0;
        r2_iaddr_i = X0;
        w_iaddr_i  = X0;
        wr_idata_i = 32'b0;
        #(T / 2);
      end

    //Stimuli
    initial
      begin
        we_i = 1'b1;  //Enable the write

        wr_idata_i = 32'd500;
        w_iaddr_i  = X0;      //Write on register X0

        #T; 

        r1_iaddr_i = X0;  //Read register X0
        r2_iaddr_i = X0;

        #T;

        wr_idata_i = 32'd1000; //Write on register X1
        w_iaddr_i  = X1;

        #T ;

        wr_idata_i = 32'd2000; //Write on register X1
        w_iaddr_i  = X1;
        
        r1_iaddr_i = X1;       //Read register X1 in the same cycle
        r2_iaddr_i = X0;

        #T; 

        we_i = 1'b0;          //Do not enable the write
        wr_idata_i = 32'd200; 
        w_iaddr_i  = X1;      //Try to write in X1

        r1_iaddr_i = X1;      //Read register X1
        r2_iaddr_i = X0;

        #T;
        $stop;
      end

endmodule

//PASSED!