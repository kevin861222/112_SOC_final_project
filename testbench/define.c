#include "define.h"

// FIR
int fir_taps[NUM_FIR_TAP] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
int fir_input[NUM_FIR_INPUT] = 
{
     1, 2, 3, 4, 5, 6, 7, 8, 9,10,
    11,12,13,14,15,16,17,18,19,20,
    21,22,23,24,25,26,27,28,29,30,
    31,32,33,34,35,36,37,38,39,40,
    41,42,43,44,45,46,47,48,49,50,
    51,52,53,54,55,56,57,58,59,60,
    61,62,63,64
};
int fir_output[NUM_FIR_INPUT];

// matmul
int mat_A[NUM_MAT_A] = 
{
     0, 1, 2, 3,
     0, 1, 2, 3,
     0, 1, 2, 3,
     0, 1, 2, 3,
};
// Transpose matrix
int mat_B_T[NUM_MAT_B] = 
{   
     1,  5,  9, 13,
     2,  6, 10, 14,
     3,  7, 11, 15,
     4,  8, 12, 16,
};
int mat_output[NUM_MAT_OUTPUT];

// qsort
int qsort_input[NUM_QSORT_INPUT] = {893, 40, 3233, 4267, 2669, 2541, 9073, 6023, 5681, 4622};
int qsort_output[NUM_QSORT_OUTPUT];
