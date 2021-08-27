# ALU

The core implement a simple ALU capable of doing: 

  **Arithmetic operations**:

  * Additions
  * Subtractions
  
  **Logic operations**:

  * AND
  * OR
  * XOR
  * BIT MASK for CSR instructions
  
  **Shift operations**:

  * Logical shift left
  * Logical shift right
  * Arithmetic shift right

  **Compares**:

  * Equality
  * Majority
  
With additional logic the ALU is capable of checking if the two numbers are different, or one number is smaller than the other one.

The Vivado Synthesis Tool estimate an usage of:

| **Used:**                    | LUT  | LUTRAM |  FF  | BRAM | URAM | DSP |
| :--------------------------  | :-:  | :----: | :--: | :--: | :-:  | :-: |
| ALU                          | 323  |   0    |  0   |  0   |  0   |  0  |
