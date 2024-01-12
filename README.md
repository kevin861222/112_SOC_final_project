# 112 SOC Lab - Final Project
![Static Badge](https://img.shields.io/badge/Build-Success-green?labelColor=gray)

## System Architecture
```mermaid
flowchart LR
A[CPU]
B[Cache_instruction]
C[Arbiter]
D[DMA Controller]
E[BRAM Controller]
F[BRAM]
G[ASIC Controller]
G1[FIR]
G2[q-sort]
G3[matmul]
G4[FIFO_in]
G5[FIFO_out]
A -- wishbone --> B
A -- wishbone --> C
A -- wishbone --> D
B --> C
D -- AXI-Stream --> G
G -- AXI-Stream --> D

C -- AXI-Stream --> D
D -- AXI-Stream --> C
C <--> E
E <--> F
subgraph ASIC
G --> G4
G4 --> G1
G4 --> G2
G4 --> G3
G1 --> G5
G2 --> G5
G3 --> G5
G5 --> G
end
```

## System Architecture
![截圖 2024-01-10 上午1 08 22](https://github.com/pocper/112_SOC_final_project/assets/79128379/4e949ce3-229f-4ff7-af8f-372c3f7bb3ae)


## Simulation
``` bash
cd ~/testbench
make
```

## Simulation Result
- Command Line
    ``` bash
    ~\testbench (main)
    λ make
    make[1]: Entering directory '~/testbench'
    make[1]: Leaving directory ~/testbench'
    Reading main.hex
    main.hex loaded into memory
    Memory 5 bytes = 0x6f 0x00 0x00 0x0b 0x13
    VCD info: dumpfile main.vcd opened for output.       
    Times = 1/3
    Test start - FIR
    Test end   - FIR
    Test start - matmul
    Test end   - matmul
    Test start - qsort
    Test end   - qsort
    Times = 2/3
    Test start - FIR
    Test end   - FIR
    Test start - matmul
    Test end   - matmul
    Test start - qsort
    Test end   - qsort
    Times = 3/3
    Test start - FIR
    Test end   - FIR
    Test start - matmul
    Test end   - matmul
    Test start - qsort
    Test end   - qsort
    main_tb.v:84: $finish called at 2936837500 (1ps)
    ```
- Waveform
## About This Project
### Memory Map 
|  Base   |   End   |   Hardware   |                  Description                 |
|---------|---------|--------------|----------------------------------------------|
|3800_0000|3800_6FFF|BRAM_u0       |.text(instruction)<br/>.data(initialized data)|
|3800_7000|3800_7FFF|BRAM_u1       |Calculated Result                             |
|3000_8000|3000_8000|DMA_Controller|DMA_cfg                                       |
|3000_8004|3000_8004|DMA_Controller|DMA_addr                                      |
|3100_0000|3100_0000|uart_ctrl     |RX_DATA                                       |
|3100_0004|3100_0004|uart_ctrl     |TX_DATA                                       |
|3100_0008|3100_0008|uart_ctrl     |STAT_REG                                      |

### DMA Config
```
          +------+------+-------+------+---------+--------+
  DMA_cfg |      |      |       |      |         |        |
          | done | idle | start | type | channel | length |
 38008000 |      |      |       |      |         |        |
          +------+------+-------+------+---------+--------+
            [12]   [11]   [10]     [9]    [8:7]     [6:0]
 
 
          +--------------------------------+--------------+
 DMA_addr |                                |              |
          |                                | addr_DMA2RAM |
 38008004 |                                |              |
          +--------------------------------+--------------+
                                                 [12:0]
```
### UART Config
```
+------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
|RX_DATA |  RESERVERD  |                        DATA BITS                              |
|        |    31-8     |  7    |  6    |  5    |  4    |  3    |  2    |  1    |  0    |
+------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
|TX_DATA |  RESERVERD  |                        DATA BITS                              |
|        |    31-8     |  7    |  6    |  5    |  4    |  3    |  2    |  1    |  0    |
+------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
|STAT_REG|  RESERVERD  |  Frame Err  |  Overrun Err  |  Tx_full  |  Tx_empty  |  Rx_full  |  Rx_empty |
|        |    31-6     |  5          |  4            |  3        |  2         |  1        |  0        |
+------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
```

### Linker Script
``` 
.text: origin : 0x3800_0500 , length : 6500
.data: origin : 0x3800_0000 , lenght : 500
```

### Transfer Protocol

