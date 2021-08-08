# REGISTER FILE

This core has 2 register file 32 bit wide and 32 word deep since it implement the basic I extension and F for floating point instructions.

## Integer register file

There are 31 writable register, the register ``x0`` is hardwired to 0 value in the integer register file. 

The module has:

  * 1 write address and 1 write port.
  * 2 read addresses and 2 read ports.
  * Clock.
  * Write enable signal.

The write enable signal is equal to zero when the write address is the register ``x0`` to
save power.

## Floating point register file

There are 32 writable register unlike the integer register file.

This time the module has:

  * 1 write address and 1 write port.
  * 3 read addresses and 3 read ports.
  * Clock.
  * Write enable signal.

## Synthesis
 
| **Used:**                    | LUT | LUTRAM |  FF  | BRAM | URAM | DSP |
| :--------------------------  | :-: | :----: | :--: | :--: | :-:  | :-: |
| Floating point register file | 78  |   78   |  0   |  0   |  0   |  0  |
| Integer register file        | 113 |   48   |  0   |  0   |  0   |  0  |