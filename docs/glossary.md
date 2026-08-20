# Glossary

Terminology used across this project's documentation, introduced at first use.
This file grows as later phases introduce new concepts.

## General / RTL

- **RTL (Register-Transfer Level):** describing hardware as registers plus the
  combinational logic that transforms data between them each clock cycle.
- **Microarchitecture:** the specific way an ISA is implemented in hardware
  (pipeline stages, datapath, control logic) — many microarchitectures can
  implement the same ISA.
- **CPI (Cycles Per Instruction):** average clock cycles needed to complete one
  instruction.
- **Critical path:** the longest combinational delay between two clocked elements;
  sets maximum clock frequency (f<sub>max</sub> = 1 / critical-path delay).
- **FSM (Finite State Machine):** a control circuit that steps through a fixed
  sequence of states over multiple cycles.

## ISA

- **ISA (Instruction Set Architecture):** the software/hardware contract — the
  instructions, registers, and memory model a CPU exposes.
- **RV32I:** the mandatory 32-bit integer base RISC-V instruction set.
- **M / A / C / Zicsr extensions:** optional RISC-V extensions for hardware
  multiply/divide, atomics, compressed instructions, and CSR access respectively.

## Pipelining (background, not used in v1's multi-cycle design)

- **Hazard:** a correctness risk from overlapping instruction execution —
  structural (resource conflict), data (dependency on an unfinished result), or
  control (branch outcome not yet known).
- **Forwarding (bypassing):** routing a just-computed result directly to where
  it's needed, skipping the wait for writeback.
- **Stall (bubble) / Flush:** pausing pipeline stages to let a hazard resolve, or
  discarding wrongly-fetched instructions after a branch resolves.

## Memory & Bus

- **SoC (System-on-Chip):** a design integrating CPU, memory, bus, and
  peripherals/accelerators into one system.
- **MMIO (Memory-Mapped I/O):** giving hardware peripherals addresses in the
  CPU's memory map, so the CPU talks to them via ordinary load/store instructions.
- **Bus:** a shared set of wires (address, data, control) connecting the CPU to
  memory and peripherals, with defined transaction rules.
- **Master (initiator) / Slave (target):** the device that starts a bus
  transaction, vs. the device that responds to one.
- **Harvard vs. Von Neumann:** separate instruction/data memories and address
  spaces (Harvard) vs. one unified memory and address space for both (Von Neumann).
- **Byte-enable:** control signals indicating which bytes of a word a write
  should actually update.
- **Address decoding:** combinational logic that determines which device should
  respond to a given address.

## Accelerator

- **MAC (Multiply-Accumulate):** the operation `acc += a*b` — the fundamental
  primitive of matrix multiplication and most accelerators.
- **PE (Processing Element):** a small hardware unit, often built around a MAC,
  replicated many times to form a parallel compute array.
- **Systolic array:** a grid of PEs wired only to nearest neighbors, with data
  flowing between them in a pipelined rhythm (Kung & Leiserson, 1978) — avoids any
  single signal needing to reach every PE at once.
- **Broadcast array:** PEs read shared operand values directly off common buses;
  simpler than systolic, but fan-out/routing becomes a bottleneck as the array grows.
- **Weight-stationary / Output-stationary:** dataflow taxonomy describing what
  stays fixed inside a PE across cycles. Weight-stationary: one operand held fixed,
  others stream through. Output-stationary: one output element accumulated locally
  over time while operands stream in.
- **Scratchpad:** a small memory physically inside an accelerator, holding a
  working copy of data currently being computed on, separate from main system memory.
- **DMA (Direct Memory Access):** a mechanism where a peripheral reads/writes
  system memory directly, acting as a bus master itself.

## FPGA

- **LUT (Look-Up Table):** the basic FPGA logic cell, implementing small
  arbitrary combinational functions.
- **FF (Flip-Flop):** the basic sequential storage element.
- **BRAM (Block RAM):** dedicated on-chip memory macros, distinct from LUT-based
  distributed memory; a limited, countable device resource.
- **DSP slice:** a dedicated hardware multiply-accumulate block; also a limited,
  countable device resource.
- **Timing closure:** meeting a target clock frequency after place-and-route.
- **Resource utilization:** the percentage of a device's LUTs/FFs/BRAM/DSPs a
  design consumes.
- **PS / PL (Zynq-specific):** Processing System (hard, fixed-silicon ARM cores)
  vs. Programmable Logic (reconfigurable FPGA fabric) — the two halves of a Zynq SoC.

## Verification

- **DUT (Design Under Test):** the RTL module being verified.
- **Testbench:** the (non-synthesizable) code that drives inputs into a DUT and
  checks its outputs.
- **Self-checking testbench:** one that automatically compares DUT output against
  an expected value and reports pass/fail.
- **Golden reference model:** an independent implementation of "the correct
  answer," used to generate expected values for a self-checking testbench. Built
  differently from the DUT so it can't share the DUT's bugs.
- **SVA (SystemVerilog Assertions):** properties checked directly against RTL
  behavior over time, catching invariant violations that end-to-end output
  checking alone might miss.
- **Regression suite:** the full set of self-checking tests, re-run as a whole
  whenever RTL changes.

## Performance

- **Throughput:** useful work done per unit time (e.g., operations/second).
- **Speedup:** `T_software_only / T_accelerated`.
- **Area-efficiency:** performance normalized by hardware cost (e.g., throughput
  per DSP slice), enabling fair comparison across configurations of different size.
