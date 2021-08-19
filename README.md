# **MicroGT-01 RISC-V SOFTCORE**

Github: (https://github.com/GabbedT/RV32IMF-MicroGT_01)

MicroGT_01 is the first core of the series MicroGT written in SystemVerilog, it is a 32bit OoO execution RISC-V core, 5 stage deep pipeline, designed for low energy consumption. Outside the core, there are two caches and a module for I/O and memory management.


It is possible to implement it on a Xilinx FPGA, for example a [Basys 3](https://store.digilentinc.com/basys-3-artix-7-fpga-beginner-board-recommended-for-introductory-users/). **For now** this project implement some Xilinx's IPs *to achieve higher performance and lower the resources usage* (for example for math functions block. The files that have `_IP.sv` contain IPs blocks), thus **it's not a portable design**.  

MicroGT_01 **is not designed for commercial purpouse but for educational**, I belive the best method to learn how CPU's work is to design one by yourself! However if you want to 
use this softcore in your design you are free to do so.




## **WARNING!**
---

Since it's not a completed project, the following text is not 100% correct and it will probably be modified.




## Overview
---

MicroGT-01 top level view:


  ![plot](Docs/Images/Top.png)


The bus system is not implemented yet.

The **sensors** comprehend different devices for:
  * CPU energy consumption detection
  * CPU temperature detection

They are used to monitor the CPU's status and lower the clock frequency if necessary.

**Timers** are used for various application.

As the image tells, **caches** are 4-way associative 8KB large, each block in a set is 32 bytes long and they implement the following policies:
  * Pseudo LRU: a simplyfied LRU algorithm
  * Write through
  * No-write allocate

These policies are selected to keep caches design simple thus using less resources.

The **I/O unit** implement different communication protocols as discussed later.

All these things are discussed more in depth, you can find the documents in the Docs 
folder.

### MicroGT-01 microarchitecture:

  ![plot](Docs/Images/uArch.png)


## Features

### **Core**:
---
* 32-bit RISC-V CPU softcore.
* In order issue, out of order execute and in order commit pipeline.
* Support for RISC-V extension:
  * **I**: Integer base instructions.
  * **M**: Integer multiplication and division instructions.
  * **F**: Single-Precision Floating Point instructions.
* Support for privilege levels:
  * **M**: Machine level.
  * **U**: User level.
* Variable clock frequency based on energy consumption and chip's temperature: 
  * High performance: 100MHz
  * Normal performance: 50MHz
  * Energy saving: 10MHz
* Simple branch predictor.
* Precise interrupt.

### **External**:
---
* Parameterizable modules like RAM, Caches etc.
* Two different 8KB caches (expandable): one for the instruction and one for data.
* Unified 128KB RAM (expandable).
* Different I/O device support:
  * UART
  * SPI
  * I^2C
  * VGA
  * GPIO
  * LCD



## Documentation
---

All the documents are in the Docs folder in this repository, here you can find description about architectural and microarchitectural design.
