import numpy as np
from scipy import signal

small_activation = np.array([
    [1,  2,  0,  -1, 3],
    [4,  0,  2,  -3, 1],
    [-2, 1,  3,  0,  4],
    [0,  -3, 1,  2, -1],
    [3,  1,  -2, 0,  2]

], dtype = np.int8)

medium_activation = np.array([
    [ 3,  7, -4, 12, -1,  9,  3,  6, -8, 15],
    [11, -2,  6, 14,  0,  7, -5,  3, 10, -1],
    [-7,  5, 13, -2,  8,  1,  6, 11, -3,  4],
    [ 2,  8, -6, 10,  4, -3,  7,  1,  6, 12],
    [15, -1,  7, -8,  2, 11,  4,  9, -5,  3],
    [-3,  6, 12,  1,  9,  4, -7,  2,  8, 14],
    [ 8, -5,  1,  7, 13,  3,  6, -2,  4, 11],
    [-9,  3,  8, 10, -4,  6,  1, 12,  5,  2],
    [ 5, 11, -2,  7,  3,  9,  4, -6,  8,  1],
    [12,  0,  6, -8,  5,  2,  8,  3, -1,  7]
], dtype=np.int8)

large_activation = np.array([
    [-24, 37, -56, 89, 12, -43, 67, -18, 45, -32, 78, -91, 103, -21, 54],
    [72, -19, 48, -35, 61, -7, 83, -14, 29, -51, 36, -76, 94, -42, 16],
    [-63, 28, -49, 87, 33, -11, 75, -16, 21, -47, 58, -88, 99, -13, 38],
    [14, -41, 52, -68, 30, -9, 81, -10, 34, -72, 43, -65, 95, -23, 57],
    [-36, 22, -44, 85, 11, -15, 70, -8, 46, -39, 69, -77, 102, -25, 31],
    [55, -12, 39, -58, 76, -3, 84, -17, 23, -53, 42, -66, 93, -20, 50],
    [-11, 40, -46, 82, 18, -5, 71, -13, 26, -38, 51, -74, 98, -27, 35],
    [64, -9, 33, -60, 54, -2, 79, -19, 37, -44, 49, -70, 92, -29, 41],
    [-28, 51, -34, 86, 15, -6, 68, -21, 25, -40, 56, -67, 97, -24, 32],
    [39, -16, 47, -55, 62, -1, 80, -20, 24, -45, 48, -69, 91, -30, 53],
    [-42, 31, -38, 81, 10, -8, 66, -15, 27, -41, 59, -63, 96, -26, 36],
    [20, -48, 50, -73, 58, -4, 78, -22, 22, -43, 52, -64, 90, -31, 44],
    [-25, 35, -41, 84, 7, -9, 74, -12, 28, -37, 55, -62, 95, -22, 40],
    [46, -10, 43, -59, 65, -2, 82, -18, 20, -42, 50, -68, 89, -28, 33],
    [-30, 44, -36, 83, 16, -7, 67, -21, 23, -39, 57, -61, 94, -23, 38]
], dtype = np.int32)


small_kernel = np.array([
    [-1,  0,  1],
    [-2,  0,  2],
    [-3,  0,  3]
], dtype=np.int8)

small_kernel_2 = np.array([
    [ 1,    0,   -1],
    [ 2,    1,    0],
    [ -1,   2,    1]
], dtype=np.int8)


medium_kernel = np.array([
    [1,  2,  0,  -1, 3],
    [4,  0,  2,  -3, 1],
    [-2, 1,  3,  0,  4],
    [0,  -3, 1,  2, -1],
    [3,  1,  -2, 0,  2]
], dtype=np.int8)

large_kernel = np.array([
    [-12, 18, -24, 7, -9, 15, -11, 6],
    [13, -17, 22, -5, 10, -8, 14, -19],
    [-20, 16, -21, 9, -4, 12, -15, 7],
    [19, -14, 23, -12, 6, -10, 18, -8],
    [-11, 15, -22, 8, -13, 9, -16, 5],
    [17, -9, 20, -7, 11, -14, 13, -6],
    [-18, 21, -25, 4, -8, 11, -12, 10],
    [14, -6, 19, -11, 7, -15, 10, -3]
], dtype=np.int32)

medium_bias = np.array([
    [-32, 16, -48, 57],
    [21, -19, 76, -35],
    [-13, 88, -42, 61],
    [45, -27, 33, -8]
], dtype = np.int32)

small_bias = np.array([
    [-1, 2,  -3],
    [-1, 2,  -3],
    [-1, 2,  -3]
], dtype=np.int8)


small_convolution_result = signal.correlate2d(small_activation, small_kernel_2, mode='valid')

print("--- test small matrices (stride = 1, shift = 0) ---") 
print("Activation matrix: ")
print(small_activation) 
print("Weight matrix: ")
print(small_kernel_2)
print("Results:")
print(small_convolution_result)
print("Processed results: ")
print(np.maximum(0, small_convolution_result+small_bias))

medium_convolution_result = signal.correlate2d(medium_activation, small_kernel, mode='valid')

print("--- test medium matrices (stride = 1, shift = 0) ---") 
print("Activation matrix: ")
print(medium_activation) 
print("Weight matrix: ")
print(small_kernel)
print("Results:")
print(medium_convolution_result)
print("Processed results: ")
print(np.maximum(0, medium_convolution_result))

large_convolution_result = signal.correlate2d(large_activation, large_kernel, mode='valid')[::2, ::2]
processed_matrix = ((large_convolution_result+medium_bias) >> 8).clip(-128, 127)

print("--- test large matrices (stride = 2, shift = 8 ---")
print(large_activation) 
print("Weight matrix: ")
print(large_kernel)
print("Results:")
print(large_convolution_result)
print("Biased results:")
print(large_convolution_result+medium_bias)
print("Processed results: ")
print(np.maximum(0, processed_matrix))


