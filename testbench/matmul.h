#ifndef _MATMUL_H
#define _MATMUL_H

#define mat_SIZE 4
int mat_A[mat_SIZE*mat_SIZE] = 
{
        0, 1, 2, 3,
        0, 1, 2, 3,
        0, 1, 2, 3,
        0, 1, 2, 3,
};
int mat_B[mat_SIZE*mat_SIZE] = 
{   
     1,  2,  3,  4,
     5,  6,  7,  8,
     9, 10, 11, 12,
    13, 14, 15, 16,
};
int mat_result[mat_SIZE*mat_SIZE];
#endif