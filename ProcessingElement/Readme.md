# Processing Element design 
A Processing Element is composed by: 
- An activation row FIFO register, which contains activation row to maintain.
- A weight row FIFO register, which contains the weight row to maintain.
- A MAC unit, for performing periodic multiply and accumulate operations.
- Three output registers for forwarding the input data and the MAC output.

How it works: 
1. The processing element receives at every clock cycle N weights and inputs to be stored in the FIFO registers and forwarded to the next PE using the output lines. 
2. After N elements, the PE receives a MAC result from the previous PE and starts to process the Weights+Acrivations saved in the FIFO registers.
3. After N MAC cycles, the result is forwarded to the output line so that the next PE can start processing its elements.
