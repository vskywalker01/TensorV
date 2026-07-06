# MAC unit 
This unit is used to performs an hardware multipication and accumulation in a single Processing Unit. It performs: 
- INT8 signed multiplication between two inputs A and B.
- signed addition between an accumulator with parametric size (the size depends on the size of the DNN matrix)

The first stage of the architecture performs the following operations: 
1. *Generation of the partials*. A multiplication between two signed numbers can be performed in hardware by extracting first partials from a specific generator (the most common example is the Booth Radix-4 encoder).
   For this specific applicaation, a Baugh-Wooley generator (presented in ["A 70-MHz 8-bit x 8-bit Parallel Pipelined Multiplier in
2.5-μm CMOS"](https://ieeexplore.ieee.org/document/1052564) by M. Hatamian and G. L. Cash) in order to reduce the complexity and handle signed operands.
   
2. *Partial reduction*. The reduction is performed using a carry save tree based on half adder and full adders in 5 different stages.

The second stage performs:
1. *Preprocessing*. The two rows obtained by the reduction are summed with the accumulator using again the carry-save strategy
  
2. *Final sum*. The final sum is performed using an implementation of the [Brent-Kung adder](https://ieeexplore.ieee.org/document/1675982).

The architecture can achieve performances up to 200Mhz on FPGA with latency of 2 clock cycles. 

