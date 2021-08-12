////////////////////////////////////////////////////////////////////////////////
// Creator:        Gabriele Tripi - gabrieletripi02@gmail.com                 //
//                                                                            //
// Design Name:    Instruction_pkg                                            //
// Project Name:   MicroGT-01                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Package that contains all the typedefs to describe         //
//                 the RISC-V instruction set                                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


`ifndef INSTRUCTION_DONE
  `define INSTRUCTION_DONE  

    //Package containing all the typedef that form the instruction type
    package INSTRUCTION_TYPE;
      
        //Opcode
        typedef enum logic [6:0] {
            //RV32I base opcodes
            LUI     = 7'b0110111,    //Load Upper Immediate
            AUIPC   = 7'b0010111,    //Add Upper Immediate to Program Counter
            JAL     = 7'b1101111,
            JALR    = 7'b1100111,
            BRANCH  = 7'b1100011,
            LOAD    = 7'b0000011,
            STORE   = 7'b0100011,
            ALU_I   = 7'b0010011,    //ALU operations immediate
            REG_OP  = 7'b0110011,    //ALU operations register, contain RV32M extension opcode
            FENCE_O = 7'b0001111,
            ECSR    = 7'b1110011,    //Ecall ... CSR's instructions
            //RV32F extension opcodes
            FLOAD   = 7'b0000111,
            FSTORE  = 7'b0100111,
            FMADD   = 7'b1000011,    
            FMSUB   = 7'b1000111,
            FNMSUB  = 7'b1001011,
            FNMADD  = 7'b1001111,
            F_OPS   = 7'b1010011     //Generic operations on floating-point register
        } opcode_e;

        //Integer registers
        typedef enum logic [4:0] {
            X0,  X1,  X2,  X3,  X4,  X5,  X6, X7,
            X8,  X9,  X10, X11, X12, X13, X14,
            X15, X16, X17, X18, X19, X20, X21,
            X22, X23, X24, X25, X26, X27, X28,
            X29, X30, X31
        } i_register_e;

        //Floating-point registers
        typedef enum logic [4:0] {
            F0,  F1,  F2,  F3,  F4,  F5,  F6, F7,
            F8,  F9,  F10, F11, F12, F13, F14,
            F15, F16, F17, F18, F19, F20, F21,
            F22, F23, F24, F25, F26, F27, F28,
            F29, F30, F31
        } f_register_e;

        //Immediate 11:0 bit field for I type instruciton
        typedef logic [11:0] imm_I_t;

        //Immediate 11:5 bit field for S type instruction
        typedef logic [6:0] imm_high_S_t;

        //Immediate 4:0 bit field for S type instruction
        typedef logic [4:0] imm_low_S_t;

        //Immediate 12|10:5 bit field for B type instruction
        typedef struct packed {
            logic       imm12;
            logic [5:0] imm_10_5;
        } imm_high_B_t;

        //Immediate 4:1|11 bit field for B type instruction
        typedef struct packed {
            logic [3:0] imm_4_1;
            logic       imm11;
        } imm_low_B_t;

        //Immediate 31:12 bit field for U type instruction
        typedef logic [19:0] imm_U_t;

        //Immediate bit field for J type instruction
        typedef struct packed {
            logic       imm20;
            logic [9:0] imm_10_1;
            logic       imm11;
            logic [7:0] imm_19_12;
        } imm_J_t;



    /////////////////////////////////
    //                             //
    //   INTEGER BASE EXTENSION    //
    //                             //
    /////////////////////////////////


        //Branch funct3 field (RV32I)
        typedef enum logic [2:0] {
            BEQ  = 3'b000,
            BNE  = 3'b001,
            BLT  = 3'b100,
            BGE  = 3'b101,
            BLTU = 3'b110,
            BGEU = 3'b111
        } branch_funct3_e;

        //Load funct3 field (RV32I)
        typedef enum logic [2:0] {
            LB  = 3'b000,
            LH  = 3'b001,
            LW  = 3'b010,
            LBU = 3'b100,
            LHU = 3'b101
        } load_funct3_e;

        //Store funct3 field (RV32I)
        typedef enum logic [2:0] {
            SB = 3'b000,
            SH = 3'b001,
            SW = 3'b010
        } store_funct3_e;

        //ALU immediate funct3 field (RV32I)
        typedef enum logic [2:0] {
            ADDI  = 3'b000,
            SLTI  = 3'b010,     //Compares
            SLTIU = 3'b011,
            XORI  = 3'b100,
            ORI   = 3'b110,
            ANDI  = 3'b111,
            SLLI  = 3'b001,
            SRI   = 3'b101      //Shift right can be logical or arithmetical
        } alui_funct3_e;

        //ALU register funct3 field (RV32I)
        typedef enum logic [2:0] {
            SUM   = 3'b000,      //ADD and SUB
            SLL   = 3'b001,
            SLT   = 3'b010,      //Compares
            SLTU  = 3'b011,      
            XOR_  = 3'b100, 
            SR    = 3'b101,      //Shift right can be logical or arithmetical   
            OR_   = 3'b110, 
            AND_  = 3'b111
        } alur_funct3_e;

        //FENCE funct3 field (RV32I)
        typedef enum logic [2:0] {
            FENCE  = 3'b000,
            FENCEI = 3'b001
        } fence_funct3_e;

        //CSR and environment call funct3 field (RV32I)
        typedef enum logic [2:0] {
            ECA_BK = 3'b000,    //ECALL or EBREAK
            CSRRW  = 3'b001, 
            CSRRS  = 3'b010,
            CSRRC  = 3'b011, 
            CSRRWI = 3'b101, 
            CSRRSI = 3'b110, 
            CSRRCI = 3'b111
        } csr_funct3_e;

        //Integer funct7 field (RV32I)
        typedef enum logic [6:0] {
            A_F7_I = 7'b0000000,
            B_F7_I = 7'b0100000     //Used to encode other instruction (Shift left use A shift right use B)
        } int_funct7_e;


    /////////////////////////////////
    //                             //
    //  MULTIPLY DIVIDE EXTENSION  //
    //                             //
    /////////////////////////////////


        //Multiply and divide funct3 field (RV32M)
        typedef enum logic [2:0] {
            MUL    = 3'b000, 
            MULH   = 3'b001,
            MULHSU = 3'b010,
            MULHU  = 3'b011, 
            DIV    = 3'b100, 
            DIVU   = 3'b101, 
            REM    = 3'b110, 
            REMU   = 3'b111
        } muldiv_funct3_e;

        //Multiply and divide funct7 field (RV32M)
        typedef enum logic [6:0] {
            F7_M = 7'b0000001   //Same for all the RV32M instructions
        } muldiv_funct7_e;


    /////////////////////////////////
    //                             //
    //  FLOATING POINT EXTENSION   //
    //                             //
    /////////////////////////////////


        //Rounding mode field (RV32F) 
        typedef enum logic [2:0] {
            RNE = 3'b000,     //Round to Nearest, ties to Even
            RTZ = 3'b001,     //Round Towards Zero
            RDN = 3'b010,     //Round Down
            RUP = 3'b011,     //Round Up
            RMM = 3'b100,     //Round to Nearest, ties to Max Magnitude
            RDY = 3'b111     //Dynamic rounding mode (check fcsr)
        } roundmode_funct3_e;

        //Floating point funct7 field
        typedef enum logic [6:0] {
            FADD    = 7'b0000000,
            FSUB    = 7'b0000100,
            FMUL    = 7'b0001000,
            FDIV    = 7'b0001100,
            FSQRT   = 7'b0101100,
            FSGN    = 7'b0010000,   //Depend on the rounding mode
            FLIM    = 7'b0010100,   //Can be FMAX or FMIN
            FCVTW   = 7'b1100000,   //Depend on the rounding mode
            FMV_CLS = 7'b1110000,   //Move / Class
            FCMP    = 7'b1010000,   //Depend on the rounding mode (EQ, LT, LE)
            FCVTS   = 7'b1101000,   //Depend on the rounding mode
            FMVWX   = 7'b1111000
        } float_funct7_e;

        //Floating point funct2 field
        typedef enum logic [1:0] {
            S   = 2'b00,            //Single precision
            D   = 2'b01,            //Double precision (NOT IMPLEMENTED)
            RES = 2'b10,            //Reserved
            Q   = 2'b11             //Quad precision (NOT IMPLEMENTED)
        } funct2_t;


    /////////////////////////////////
    //                             //
    //    INSTRUCTION ENCODING     //
    //                             //
    /////////////////////////////////


        /////////////////////////////////
        //                             //
        //     RV32I INSTRUCTIONS      //
        //                             //
        /////////////////////////////////

        typedef union packed {          //X indicate the type of the funct3 field to differentiate them from each other
            branch_funct3_e B_f3;          //For example funct3.B indicate a funct field of branch instruction
            load_funct3_e   L_f3;   
            store_funct3_e  S_f3;
            alui_funct3_e   I_f3;
            alur_funct3_e   R_f3;
            fence_funct3_e  F_f3;
            csr_funct3_e    C_f3;
        } int_funct3_u;

        typedef struct packed {     //R type instructions
            int_funct7_e funct7;
            i_register_e rs2;
            i_register_e rs1;
            int_funct3_u funct3;
            i_register_e rd;
        } R_type_I_s;

        typedef struct packed {     //I type instructions
            imm_I_t      imm_I;
            i_register_e rs1;
            int_funct3_u funct3;
            i_register_e rd;
        } I_type_I_s;

        typedef struct packed {         //S type instructions
            imm_high_S_t imm_high_S;    //Immediate 11:5
            i_register_e rs2;
            i_register_e rs1;
            int_funct3_u funct3;
            imm_low_S_t  imm_low_S;     //Immediate 4:0
        } S_type_I_s;

        typedef struct packed {         //B type instructions
            imm_high_B_t imm_high_B;    //Immediate 12|10:5
            i_register_e rs2;
            i_register_e rs1;
            int_funct3_u funct3;
            imm_low_B_t  imm_low_B;     //Immediate 4:1|11
        } B_type_I_s;

        typedef struct packed {         //U type instructions
            imm_U_t      imm_U;
            i_register_e rd;
        } U_type_I_s;

        typedef struct packed {         //J type instructions
            imm_J_t      imm_J;
            i_register_e rd;
        } J_type_I_s;

        /////////////////////////////////
        //                             //
        //    RV32I FINAL ENCODING     //
        //                             //
        /////////////////////////////////

        typedef union packed {
            R_type_I_s R_type;
            I_type_I_s I_type;
            S_type_I_s S_type;
            B_type_I_s B_type;
            U_type_I_s U_type;
            J_type_I_s J_type;
        } RV32_I_u;

        /////////////////////////////////
        //                             //
        // RV32M INSTRUCTION ENCODING  //
        //                             //
        /////////////////////////////////

        typedef struct packed {
            muldiv_funct7_e funct7;
            i_register_e    rs2;
            i_register_e    rs1;
            muldiv_funct3_e funct3;
            i_register_e    rd;
        } RV32_M_s;

        /////////////////////////////////
        //                             //
        // RV32F INSTRUCTION ENCODING  //
        //                             //
        /////////////////////////////////

        typedef struct packed {     //R type instructions
            float_funct7_e     funct7;
            f_register_e       rs2;
            f_register_e       rs1;
            roundmode_funct3_e rm;  //Rounding mode
            f_register_e       rd;
        } R_type_F_s;

        typedef struct packed {     //R4 type instructions
            f_register_e        rs3;
            funct2_t            funct2;
            f_register_e        rs2;
            f_register_e        rs1;
            roundmode_funct3_e  rm;
            f_register_e        rd;
        } R4_type_F_s;

        typedef struct packed {     //I type instructions
            imm_I_t             imm_I;
            f_register_e        rs1;
            roundmode_funct3_e  rm;
            f_register_e        rd;
        } I_type_F_s;

        typedef struct packed {         //S type instructions
            imm_high_S_t        imm_high_S;    //Immediate 11:5
            f_register_e        rs2;
            f_register_e        rs1;
            roundmode_funct3_e  rm;
            imm_low_S_t         imm_low_S;     //Immediate 4:0
        } S_type_F_s;

        /////////////////////////////////
        //                             //
        //    RV32F FINAL ENCODING     //
        //                             //
        /////////////////////////////////

        typedef union packed {
            R_type_F_s  R_type;
            R4_type_F_s R4_type;
            I_type_F_s  I_type;
            S_type_F_s  S_type;
        } RV32_F_u;

        /////////////////////////////////
        //                             //
        // INSTRUCTION FINAL ENCODING  //
        //                             //
        /////////////////////////////////

        typedef union packed {
            RV32_I_u I;
            RV32_M_s M;
            RV32_F_u F;
        } RV32_u;

        typedef struct packed {
            RV32_u   RV32;
            opcode_e opcode;
        } instruction_t;


//EXAMPLE:
//
//  input instruction_t IW; 
//  
//  We reference the various subfield of Instruction Word like that:
//
//  IW.opcode;                          Instruction word opcode
//  IW.RV32.I.R_type.rs2 = X31;         Instruction word source register 2 is equal to X31 (1111)
//  IW.RV32.I.R_type.func3.I_f3 = ADDI  Instruction word funct3 field is equal to ADDI

    endpackage 
    
  import INSTRUCTION_TYPE::*;
  
`endif 
