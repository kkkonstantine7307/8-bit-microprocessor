# Design Evolution & Optimization Comparison

This document details how the **Optimized** 8-bit microprocessor evolved from the **Original** straight-line design and the **Modified** loop-capable design.

---

## 1. Summary Comparison Matrix

| Metric / Capability | Original | Modified | Optimized |
|---|---|---|---|
| **Supported Opcodes** | 4 (`LOAD`, `ADD`, `OUT`, `HALT`) | 6 (`+ STORE`, `+ JMP`) | 6 (`+ STORE`, `+ JMP`) |
| **Memory Writes (`STORE`)** | No (read-only RAM) | Yes | Yes |
| **Looping (`JMP`)** | No (straight-line only) | Yes | Yes |
| **Workload** | Count `1, 2, 3`, then `HALT` | Fibonacci (`1..34` in `1520 ns`) | Full 8-bit Fibonacci (`0..233` in `960 ns`) |
| **`cpu.v` Lines (non-blank / total)** | 37 / 45 | 41 / 47 | **19 / 19** |
| **`program.mem` Lines** | 10 (8 code + 2 data) | 12 (9 code + 3 data) | **9 (7 code + 2 data)** |
| **`testbench.v` Lines (non-blank / total)** | 28 / 35 | 29 / 35 | **12 / 12** |
| **Total Lines Across All 3 Files** | 90 | 94 | **40 (−57.4% vs Modified)** |
| **Instructions per Output** | 2 (unrolled, non-looping) | 9 | **3.5 average (7 per 2 outputs)** |
| **Latency per Output (`100 MHz`)** | `40 ns` (fixed steps) | `180 ns` | **`70 ns` (2.57× faster loop)** |
| **RAM Variables Used** | 2 constants | 3 (`a`, `b`, `temp`) | **2 (`X`, `Y`)** |
| **Captures Repeated Outputs (`1, 1`)?** | N/A | No (`$monitor` skips second `1`) | **Yes (edge-triggered `$display`)** |

---

## 2. Stage 1 → Stage 2 (`Original` → `Modified`)

- **ISA Expansion:** Added `STORE` (`4'h5: ram[ir[3:0]] <= acc`) and `JMP` (`4'h6: pc <= {4'h0, ir[3:0]}`), enabling mutable variables in RAM and backward branches for loops.
- **Program Shift:** Replaced the hard-coded 3-output increment sequence with a 9-instruction Fibonacci loop (`LOAD b`, `OUT`, `ADD a`, `STORE temp`, `LOAD b`, `STORE a`, `LOAD temp`, `STORE b`, `JMP 0`).
- **Simulation Window:** Extended runtime from `200 ns` to `1500 ns` after reset.

---

## 3. Stage 2 → Stage 3 (`Modified` → `Optimized`)

### A. `cpu.v` (47 → 19 lines, Cycle-Exact Equivalent Hardware)
1. **Declaration Compaction:** Combined single-bit input ports and 8-bit registers (`pc, acc, ir, ram [0:255]`) onto single lines.
2. **Concatenated Asynchronous Reset:** Replaced four separate non-blocking assignments with `{pc, acc, out_port, state} <= 0;`.
3. **1-Bit State Toggle:** Replaced `case (state)` and per-branch state transitions with `state <= ~state;` and `if (!state) ... else case (ir[7:4])`.
4. **Implicit Zero-Extension:** Simplified `pc <= {4'h0, ir[3:0]}` to `pc <= ir[3:0]`.
5. **Equivalence Proof:** Simulating both the `Original` and `Modified` programs and testbenches on `Optimized/cpu.v` produces identical console timestamps and values.

### B. `program.mem` (12 → 9 lines, 2.57× Higher Throughput)
- Eliminated all `LOAD` instructions and the third `temp` memory slot by keeping the latest Fibonacci term live in `acc` and alternating additions/stores between `Y` (`ram[8]`) and `X` (`ram[7]`):
  `OUT → ADD Y → STORE Y → OUT → ADD X → STORE X → JMP 0`.
- Emits **two** terms every 7 instructions (`140 ns`) instead of **one** term every 9 instructions (`180 ns`), while starting cleanly at $F_0 = 0$.

### C. `testbench.v` (35 → 12 lines, Complete Decimal Trace)
- Consolidated three `initial` blocks into one and initialized `clk = 0, reset = 1` inline.
- Replaced `$monitor` (which only fires on value transitions and therefore dropped the second `1`) with a synchronous `$display` triggered whenever `OUT` executes (`uut.state && uut.ir[7:4] == 3`).
- Set `#940 $finish` (`960 ns` total) so simulation terminates cleanly after `233`, right before 8-bit unsigned overflow (`377 mod 256 = 121`).
