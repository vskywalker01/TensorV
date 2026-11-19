# Processing Element design 
The Processing Element is the base component used by the convolutional core. It is used to process a 1D convolution between a Weight (maximum 8x8b) and an Activation (15x8b). 
Its internal structure contains a scratchpad register, for containing the inputs and the results computed for each shift, a multiplier and an adder, used for computing the actual convolutions. 

The architecture is divided in three pipeline stages: 
1. The first stage contains the scratchpad registers and the control unit. It receives the commands from the control lines and coordinates the execution for the next two stages.
2. The second stage contains the multiplier, used for computing the product between a weight and an activation
3. The third stage contains an adder and an accumulator register.





How it works: 
1. The processing element receives at every clock cycle N weights and inputs to be stored in the FIFO registers and forwarded to the next PE using the output lines. 
2. After N elements, the PE receives a MAC result from the previous PE and starts to process the Weights+Acrivations saved in the FIFO registers.
3. After N MAC cycles, the result is forwarded to the output line so that the next PE can start processing its elements.
<p align=center> 
<img width="460" height="270" alt="PE" src="https://github.com/user-attachments/assets/95948c7d-e315-4633-989e-ba2d66fc9881" />
</p>
