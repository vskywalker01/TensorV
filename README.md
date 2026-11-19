# TensorV
This project contains an architecture proposal for a small *Convolutional neural network accelerator* that should enable *Intermitted computing*. 

In particular, the architecture contains a low power *INT8* 2D convolution hardware accelerator which applies automatically *biasing*, *requantization* and *ReLU* function:
 
- An **8x8 Processing element matrix** provides a parallel acceleration for computing a convolution between a 15x15 *activation* and an 8x8 *weight* matrices.
  Each *Processing element* contains a *scratchpad*, which is used avoid data retransmission and reduce power consumptions.
- A **Memory controller** enables communication between an *AXI bus* and the *convolutional core*.
- An **Out-of-Ourder scheduler** coodinates memory transfers data computations in order to keep the convolutional core as busy as possible.
- The custom **internal buffers**, used among the entire architecture, are able to create checkpoints in a transparent way and store data into persistent memories to enable *Intermitted computing* applications.



