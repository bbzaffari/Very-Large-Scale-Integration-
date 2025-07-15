# FIFO_SYNC – Synchronous FIFO in VHDL

This project implements a synchronous FIFO called `FIFO_SYNC` in VHDL. It was developed for the Integrated Systems Design II course at PUCRS.

The design provides a 64-position FIFO with 8-bit words, managing data flow with write/read enable signals and status outputs like full, empty, almost full/empty, and error.

### Main specs

- Clock: 100 MHz (`clk`)
- Asynchronous reset (`rst`)
- 8-bit data bus for input (`wr_data`) and output (`rd_data`)
- Write enable (`wr_en`) and read enable (`rd_en`)
- Status outputs:
  - `sts_full`, `sts_empty`
  - `sts_high` (almost full), `sts_low` (almost empty)
  - `sts_error` (overflow/underflow detection)

### Tools used

- Simulation: ModelSim
- Synthesis & analysis: Cadence Genus

### Notes

The project focuses on designing a fully synthesizable FIFO, with attention to proper pointer management and robust error signaling. I also experimented with synthesis at different effort levels (low/high) to observe timing, area, and power differences, which was a valuable part of the learning process.

