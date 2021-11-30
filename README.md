# **MicroGT-01 RISC-V CORE**

MicroGT-01 is my first core designed in SystemVerilog. It is a 32bit OoO execution, single issue RISC-V core, 5 **main** stages deep pipeline, designed for low energy consumption.

It is possible to implement it on a Xilinx FPGA, for example a [Basys 3](https://store.digilentinc.com/basys-3-artix-7-fpga-beginner-board-recommended-for-introductory-users/).  
The core target mainly FPGA's but it can be synthetised into a chip.

MicroGT-01 **is not designed for commercial purpouse but for educational**, I belive the best method to learn how CPU's work is to design one by yourself! However if you want to 
use this softcore in your design you are free to do so.

 

## **WARNING!**
---

Since it's not a completed project, the following text is not 100% correct and it will probably be modified.


# **Documentation**

All the documents are in the Docs folder in this repository, here you can find description about architectural and microarchitectural design.

<br />

# **References**

Jhon L. Hennessy, David A. Patterson, N 2017, *Computer Architecture: A Quantitative Approach, Sixth Edition*, Morgan Kaufmann Publishers
