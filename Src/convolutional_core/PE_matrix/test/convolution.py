import numpy as np
from scipy import signal

large_activation = np.array([
    [ 3,  7, -4, 12, -1,  9,  3,  6, -8, 15,  2,  5, -3,  8,  1],
    [11, -2,  6, 14,  0,  7, -5,  3, 10, -1,  8, 12,  4,  9, -6],
    [-7,  5, 13, -2,  8,  1,  6, 11, -3,  4,  9,  2, -10,  7,  5],
    [ 2,  8, -6, 10,  4, -3,  7,  1,  6, 12,  0,  5,  9, -4,  3],
    [15, -1,  7, -8,  2, 11,  4,  9, -5,  3,  8, 13,  1,  6,  2],
    [-3,  6, 12,  1,  9,  4, -7,  2,  8, 14,  5,  0, -6,  3, 10],
    [ 8, -5,  1,  7, 13,  3,  6, -2,  4, 11,  9,  5, -1,  7,  8],
    [-9,  3,  8, 10, -4,  6,  1, 12,  5,  2,  7,  4,  9, -3,  1],
    [ 5, 11, -2,  7,  3,  9,  4, -6,  8,  1, 13,  6,  2,  5, 10],
    [12,  0,  6, -8,  5,  2,  8,  3, -1,  7,  4, 11,  9,  1,  6],
    [-6,  9,  1,  7, 14,  3,  5,  2, 10,  4, -3,  8,  1,  6,  7],
    [ 3, -4,  8, 11,  6, 12,  1,  7, -5,  9,  2,  4,  3,  8,  5],
    [10,  5, -7,  2,  8,  4,  9,  6,  1, 13, -1,  7,  5,  3,  2],
    [-1,  7,  4, 12,  3,  6,  8, -2,  5,  9, 10,  1,  6,  4,  7],
    [ 6,  2,  9,  5,  1,  8, 11, -3,  4,  7, -6,  3,  8,  2, 10]
], dtype=np.int8)

large_activation_kernel = np.array([
    [-1,  0,  1],
    [-2,  0,  2],
    [-3,  0,  3]
], dtype=np.int8)

def find_optimal_shift(matrice_r1, matrice_r2, target_range=256, padding='valid'):
    """Ritorna lo shift ottimum e i valori di max/min post-convoluzione"""
    
    # Genera le due matrici se non sono fornite
    if not all(hasattr(mat, '__name__') or hasattr(mat, 'size')) for mat in [matrice_r1, matrice_r2]:
        matrice_r1 = generate_mtrix(8, 8, range_val=100)
        matrice_r2 = generate_mtrix(15, 15, range_val=100)
    
    # Ottiene il padding='same' per mantenere la stessa dimensione all'uscita
    h, w = matrice_r2.shape
    
    # Esegue convoluzione come correlazione nel piano delle frequenze
    conv_result = correlate2d(
        matrice_r1, 
        np.flip(matrice_r2, axis=(0, 1)), 
        mode=padding,
        origin='lower' if padding == 'same' else None
    )
    
    # Calcolo dello range dinamico del risultato
    max_val = float(np.max(conv_result))
    min_val = float(np.min(conv_result))
    dynamic_range = max_val - min_val
    
    print(f"Dynamic Range risultati convoluzione: [{min_val:.2f}, {max_val:.2f}]")
    
    # Formula per calcolare lo shift ottimale per int8 [−128, 127] (range=256)
    target_range = 256
    
    # Calcolo del numero di bit necessari a rappresentare il range dinamiche
    log_dynamic_range = np.log2(dynamic_range / target_range + 1e-9)
    bit_shift = int(np.ceil(log_dynamic_range))
    
    print(f"Shift necessario: {bit_shift} bit")
    shift_val = 1 << bit_shift
    
    # Calcolo i valori clamped dopo lo shift e dopo la quantizzazione
    max_clamped = int(np.max(shift_val * conv_result) - target_range//2)
    min_clamped = int(np.min(shift_val * conv_result) + target_range//2)
    
    return bit_shift, shift_val, {
        'max_orig': max_val, 
        'min_orig': min_val, 
        'max_clamped': max_clamped, 
        'min_clamped': min_clamped,
        'dynamic_range': dynamic_range
    }



large_activation_result = signal.correlate2d(large_activation, large_activation_kernel, mode='valid')

print(large_activation_result)
print(np.maximum(0, large_activation_result))
