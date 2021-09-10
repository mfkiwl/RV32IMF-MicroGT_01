////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Modules_pkg                                                //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Package that contains all the typedefs and parameters      //
//                 used in the modules of this project                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`ifndef PACKAGES_DONE
  `define PACKAGES_DONE

    package MGT_01_PACKAGE;
        

    //////////////////////////////////////////////
    //                                          //
    // General purpouse parameters and typedefs //
    //                                          //
    //////////////////////////////////////////////

        parameter TRUE        = 1;
        parameter FALSE       = 0;
        parameter XLEN        = 32;   //Width of an X register
        parameter ADDR_WIDTH  = 17;   //Address width
        parameter OP_WIDTH    = 7;    //Width of the opcode field
        parameter REG_WIDTH   = 5;    //Width of the register address field
        parameter CSR_WIDTH_A = 12;   //Width of the CSR address bus 
        parameter TIMER_WIDTH = 64;   //Width of timers
        parameter VALID       = 1;
        parameter INVALID     = 0;
        
        typedef enum logic {FREE, BUSY} fu_state_e;

        typedef logic signed [XLEN - 1:0] data_bus_t;   //Data bus

        typedef logic [ADDR_WIDTH - 1:0]  address_bus_t; //Address bus


    /////////////////////////////////
    //                             //
    // ALU parameters and typedefs //
    //                             //
    /////////////////////////////////
        
        //Used to elaborate different type of data in the ALU selecting the proper operations
        typedef union packed {                      
            logic        [XLEN - 1:0] u_data;      //Unsigned data
            logic signed [XLEN - 1:0] s_data;      //Signed data
        } data_u;

        //ALU can perform 16 different operations
        typedef enum logic [3:0] {  
            ALU_ADD  = 4'b0000,
            ALU_SUB  = 4'b0001,
            ALU_EQ   = 4'b0010,
            ALU_NE   = 4'b0011,
            ALU_LT   = 4'b0100,
            ALU_LTU  = 4'b0101,
            ALU_GE   = 4'b0110,
            ALU_GEU  = 4'b0111,
            ALU_SLL  = 4'b1000,
            ALU_SRL  = 4'b1001,
            ALU_SRA  = 4'b1010,
            ALU_AND  = 4'b1011,
            ALU_OR   = 4'b1100,
            ALU_XOR  = 4'b1101,
            ALU_BMSK = 4'b1110    //Bit mask for CSRRC instruction
        } alu_ops_e;


    ////////////////////////////////////
    //                                //
    // MUL/DIV parameters and typedef //
    //                                //
    ////////////////////////////////////

        //THESE ARE NOT THE REAL FUNCT3 FIELD VALUES
        
        typedef enum logic [1:0] {  //MUL unit opcodes
            MUL_    = 2'b00, 
            MULH_   = 2'b01,
            MULHSU_ = 2'b10,
            MULHU_  = 2'b11
        } mul_ops_e;

        typedef enum logic [1:0] {  //DIV unit opcodes
            DIV_    = 2'b00,
            DIVU_   = 2'b01,
            REM_    = 2'b10,
            REMU_   = 2'b11
        } div_ops_e;


    //////////////////////////////
    //                          //
    // List of privilege levels //
    //                          //
    //////////////////////////////

        parameter USER       = 2'b00;
        parameter SUPERVISOR = 2'b01;   //Not supported
        parameter HYPERVISOR = 2'b10;   //Not supported
        parameter MACHINE    = 2'b11;


    ////////////////////////////
    //                        //
    // List of CSR parameters //
    //                        //
    ////////////////////////////

        //Address bus
        typedef logic [CSR_WIDTH_A - 1:0] csr_addr_t;
        //Permission level
        parameter READ_WRITE_0 = 2'b00;
        parameter READ_WRITE_1 = 2'b01;
        parameter READ_WRITE_2 = 2'b10;
        parameter ONLY_READ    = 2'b11;

        //User level CSR's addresses
        parameter USTATUS  = 12'h000;    //Status register
        parameter UIE      = 12'h004;    //Interrupt enable
        parameter UTVEC    = 12'h005;    //Trap handler base address
        parameter USCRATCH = 12'h040;    //Scratch register
        parameter UEPC     = 12'h041;    //Exception program counter
        parameter UCAUSE   = 12'h042;    //Trap cause
        parameter UBADADDR = 12'h043;    //Bad address
        parameter UIP      = 12'h044;    //Interrupt pending
        parameter FFLAGS   = 12'h001;    //Floating point accrued exceptions
        parameter FRM      = 12'h002;    //Floating point dynamic rounding mode
        parameter FCSR     = 12'h003;    //FRM + FFLAGS
        parameter CYCLE    = 12'hC00;    //Cycle counter
        parameter TIME     = 12'hC01;    //Timer
        parameter CYCLEH   = 12'hC80;    //Cycle counter 32 bit
        parameter TIMEH    = 12'hC81;    //Timer 32 bit

        //Machine level CSR's addresses
        parameter MVENDORID = 12'hF11;   //Vendor ID
        parameter MARCHID   = 12'hF12;   //Architecture ID
        parameter MIMPID    = 12'hF13;   //Implementation ID
        parameter MSTATUS   = 12'h300;   //Status register
        parameter MISA      = 12'h301;   //ISA and extensions
        parameter MEDELEG   = 12'h302;   //Exception delegation register
        parameter MIDELEG   = 12'h303;   //Interrupt delegation register
        parameter MIE       = 12'h304;   //Interrupt enable register
        parameter MTVEC     = 12'h305;   //Trap handler base address
        parameter MSCRATCH  = 12'h340;   //Scratch register 
        parameter MEPC      = 12'h341;   //Exception program counter
        parameter MCAUSE    = 12'h342;   //Trap cause
        parameter MBADADDR  = 12'h343;   //Bad address
        parameter MIP       = 12'h344;   //Interrupt pending


    ////////////////////////////////////////////
    //                                        //
    // Floating-Point parameters and typedefs //
    //                                        //
    ////////////////////////////////////////////

        typedef enum logic [2:0] {
            RNE = 3'b000,     //Round to Nearest, ties to Even
            RTZ = 3'b001,     //Round Towards Zero
            RDN = 3'b010,     //Round Down
            RUP = 3'b011,     //Round Up
            RMM = 3'b100,     //Round to Nearest, ties to Max Magnitude
            RDY = 3'b111      //Dynamic rounding mode
        } rounding_e;

        typedef struct packed {     //IEEE-754 floating point rapresentation standard
            logic        sign;
            logic [7:0]  exponent;
            logic [22:0] mantissa;
        } float_t;

        typedef struct packed {     //Effective floating point rapresentation    
            logic        sign;
            logic [7:0]  exponent;
            logic        hidden_bit;
            logic [22:0] mantissa;
        } effective_float_t;

        typedef enum logic {FADD_, FSUB_} fsum_ops;

        parameter BIAS = 127;  

        parameter P_INFTY = 32'h7F800000;   //Positive infinity
        parameter N_INFTY = 32'hFF800000;   //Negative infinity

        parameter P_ZERO = 32'h00000000;    //Positive zero
        parameter N_ZERO = 32'h80000000;    //Negative zero
        parameter ZERO = 32'b?0000000000000000000000000000000;  //Generic zero

        parameter QUIET_NAN = 32'b111111111???????????????????????; //Not a Number
        parameter SIGN_NAN = 32'b011111111???????????????????????;  //Not a Number

    endpackage     

  import MGT_01_PACKAGE::*; //Import in the $unit

`endif
