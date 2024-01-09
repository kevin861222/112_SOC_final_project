# 112 SOC Lab - Final Project
![Static Badge](https://img.shields.io/badge/Build-40%25-green?labelColor=gray)

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
## Simulation
``` bash
cd ~/testbench
make
```

## Simulation Result