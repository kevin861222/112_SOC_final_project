# 0 "define.c"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "define.c"
# 1 "define.h" 1
# 15 "define.h"
typedef enum
{
    fir_taps_base,
    fir_taps_end = (fir_taps_base + 11 - 1),
    fir_input_base,
    fir_input_end = (fir_input_base + 64 - 1),
    mat_A_base,
    mat_A_end = (mat_A_base + (4*4) - 1),
    mat_B_base,
    mat_B_end = (mat_B_base + (4*4) - 1),
    qsort_input_base,
    qsort_input_end = (qsort_input_base + 10 - 1)
} MM_BRAM_u0;


typedef enum
{
    fir_output_base,
    fir_output_end = (fir_output_base + 64 - 1),
    mat_output_base,
    mat_output_end = (mat_output_base + (4*4) - 1),
    qsort_output_base,
    qsort_output_end = (qsort_output_base + 10 - 1)
} MM_BRAM_u1;
# 2 "define.c" 2


int fir_taps[11] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
int fir_input[64] =
{
     1, 2, 3, 4, 5, 6, 7, 8, 9,10,
    11,12,13,14,15,16,17,18,19,20,
    21,22,23,24,25,26,27,28,29,30,
    31,32,33,34,35,36,37,38,39,40,
    41,42,43,44,45,46,47,48,49,50,
    51,52,53,54,55,56,57,58,59,60,
    61,62,63,64
};
int fir_output[64];


int mat_A[(4*4)] =
{
        0, 1, 2, 3,
        0, 1, 2, 3,
        0, 1, 2, 3,
        0, 1, 2, 3,
};

int mat_B_T[(4*4)] =
{
     1, 5, 9, 13,
     2, 6, 10, 14,
     3, 7, 11, 15,
     4, 8, 12, 16,
};
int mat_output[(4*4)];


int qsort_input[10] = {893, 40, 3233, 4267, 2669, 2541, 9073, 6023, 5681, 4622};
int qsort_output[10];
