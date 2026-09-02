# RISC-V Matrix Accelerator

A from-scratch RISC-V CPU that evolves into a RISC-V + hardware matrix-multiplication
accelerator SoC, built as a combined RTL/Digital IC portfolio project and a Eureka 2026
research submission.

Every RTL module in this project is written from a blank file — no reference cores are
used or extended. The goal is to be able to independently reason about, defend, and
measure every architectural decision in the system, from the CPU's control unit to the
accelerator's PE array.

## Target system (v1)

- **CPU:** custom multi-cycle RV32I core (no M/A/C/Zicsr extensions), bare-metal,
  no interrupts/exceptions
- **Accelerator:** 16×16 (max) integer matrix multiplier, 4×4 reused output-stationary
  PE array, CPU-loaded on-chip scratchpad
- **Interconnect:** single-master, address-decoded memory-mapped bus with polling-based
  MMIO for accelerator control
- **Target hardware:** Digilent Arty Z7-20 (Zynq-7000 XC7Z020), used **PL-only** —
  the ARM Cortex-A9 processing system is intentionally unused

See [`docs/phase0-architecture-specification.md`](docs/phase0-architecture-specification.md)
for the full, justified specification, and [`docs/glossary.md`](docs/glossary.md) for
terminology used throughout the project.

## Roadmap

| Phase | Description | Status |
|---|---|---|
| 0 | Architecture specification | ✅ Complete |
| 1 | RISC-V CPU (RTL + verification) | 🚧 In Progress |
| 2 | Memory subsystem | ⬜ Planned |
| 3 | Simple SoC bus | ⬜ Planned |
| 4 | Memory-mapped I/O | ⬜ Planned |
| 5 | Accelerator interface | ⬜ Planned |
| 6 | MAC unit | ⬜ Planned |
| 7 | Processing Element (PE) | ⬜ Planned |
| 8 | PE array | ⬜ Planned |
| 9 | Matrix multiplication accelerator | ⬜ Planned |
| 10 | RISC-V + accelerator integration | ⬜ Planned |
| 11 | FPGA implementation | ⬜ Planned |
| 12 | Performance / resource evaluation | ⬜ Planned |
| 13 | Research-oriented optimization & comparison | ⬜ Planned |

See [`docs/phase1-roadmap.md`](docs/phase1-roadmap.md) for detailed Phase 1
module-level progress.

## Repository structure

```
docs/     Architecture specifications, glossary, per-phase documentation
rtl/      Synthesizable RTL source (SystemVerilog)
tb/       Self-checking SystemVerilog testbenches, SVA
sim/      Simulation scripts / waveform configs
sw/       Golden reference models (RV32I instruction-level simulator, matmul reference),
          RISC-V test programs
fpga/     Constraints (XDC), memory-init files, bitstream build scripts
scripts/  Build / regression automation
```

## Verification approach

SystemVerilog self-checking testbenches, Vivado/XSim-compatible. CPU correctness is
checked against a custom software RV32I instruction-level simulator (`sw/`); accelerator
correctness is checked against a NumPy matrix-multiply reference. SVA is added per-module
for protocol-level invariants. Full details in the architecture spec.

## Research questions (priority order)V

1. How do resource utilization and achievable f<sub>max</sub> scale with matrix
   dimension N (4×4 → 8×8 → 16×16)?
2. At what matrix size does compute latency overtake data-movement overhead
   (T_load + T_readback vs. T_compute)?
3. How much does the CPU-loaded scratchpad design improve data reuse and reduce
   memory traffic compared to a naive element-wise MMIO push/pull design?

## License

MIT — see [`LICENSE`](LICENSE).
