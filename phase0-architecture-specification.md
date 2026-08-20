# Phase 0 — Architecture Specification

**Status:** Complete
**Scope:** This document specifies the v1 architecture of the RISC-V Matrix Accelerator
system across all layers, before any RTL is written. It is the contract every later
phase implements against. Deviations from this document in later phases should be
recorded and justified, not made silently.

---

## 1. Project Scope

- Every RTL module is written from a blank file. No reference/open-source cores are
  copied or extended.
- v1 is **integer/fixed-point only** — no floating point.
- v1 is **bare-metal**: no interrupts, exceptions, privileged modes, or CSR subsystem.
- **Per-phase completion bar:** correct behavior in simulation, verified by a
  self-checking testbench.
- **Project-level completion bar:** simulation correctness *and* FPGA implementation
  *and* resource/performance evaluation *and* a CPU-only vs. accelerated comparison.
  Simulation correctness alone does not constitute project completion.
- Timeline target: ~4.5 months, first of a planned series of portfolio projects.

## 2. RISC-V ISA Subset

- **RV32I only.** No M, A, C, or Zicsr extensions in v1.
  - **M (multiply/divide)** excluded: occasional scalar multiplication (loop bounds,
    stride/address calculation) is handled by software multiply routines; the CPU is a
    controller, not a compute engine.
  - **C (compressed instructions)** excluded: avoids variable-length instruction
    fetch/alignment complexity for a first implementation; code density is not a
    project constraint.
  - **A (atomics)** excluded: system is single-core, no shared-memory synchronization
    need.
  - **Zicsr** excluded: no CSR subsystem exists in a bare-metal, trap-free design.
- **ECALL/EBREAK:** treated as illegal/unsupported instructions (see §3).
- **Register file:** 32 × 32-bit, 2 read ports / 1 write port. `x0` writes are ignored;
  `x0` reads always return zero. Implementation to be chosen with FPGA timing/resource
  usage in mind.

## 3. Undefined-Behavior Policy

For full determinism and testability, every reachable "invalid" state has an explicit,
defined hardware response:

- **Illegal/unsupported opcode (including ECALL/EBREAK):** the core halts/freezes
  deterministically, with a status signal the testbench can observe.
- **Misaligned load/store address:** documented as a **software constraint**. Hardware
  behavior is not verified for misaligned accesses; software must guarantee alignment.
- **Access to an unmapped bus address:** halts/errors, using the same deterministic
  halt mechanism as an illegal instruction — one consistent debug pattern system-wide.

## 4. CPU Microarchitecture

**Multi-cycle, FSM-controlled** datapath and control (chosen over single-cycle for
better f<sub>max</sub>/demonstration of microarchitectural design, and over a 5-stage
pipeline to keep hazard-related verification scope bounded given project timeline and
verification experience — pipelining is documented future work / a possible later
research comparison, not a v1 dependency).

**Registers:** `PC`, `IR` (instruction register — holds fetched instruction across
cycles), `MDR` (memory data register — holds loaded data before writeback), `A`/`B`
(latched `rs1`/`rs2` values), `ALUOut` (latched ALU result for later-cycle use),
plus the register file (§2).

**Functional units:** one shared ALU (reused across address calculation, arithmetic,
and branch/jump target and condition computation — no dedicated PC+4 adder in v1),
an immediate generator, and a single shared memory interface.

**Muxes:**
- ALU input A: `PC` / `A`
- ALU input B: `B` / immediate / constant (4, for PC+4)
- PC source: ALU result (all new-PC values — increment, branch target, jump target —
  are produced by the single shared ALU at different times)
- Writeback: `ALUOut` / `MDR`

**Branch handling:** the branch target address is computed early (during Decode) into
`ALUOut` via the ALU; the ALU is reused later, in the branch-specific state, purely to
evaluate the condition (equality check). This lets a single ALU serve both roles across
different cycles of the same instruction.

**JAL/JALR:** `PC+4` is computed early into `ALUOut` (before it is overwritten by the
jump-target calculation), so the existing `ALUOut` writeback path handles the
link-register write with no additional mux input required.

**Cycle count:** variable per instruction type (R/I-type finish sooner; loads/stores
take additional memory-access cycles).

## 5. Memory & Bus Architecture

- **Organization:** two physical memory blocks (instruction, data) — chosen for
  FPGA BRAM implementation/timing — accessed through one shared architectural
  interface, one access per cycle (Von-Neumann-style addressing over Harvard-style
  physical storage).
- **Access model:** unified, address-decoded 32-bit address space (not FSM-state-routed)
  — chosen to make MMIO/accelerator integration straightforward.
- **Address widths/sizes:** 32-bit addresses; 16 KB instruction memory, 16 KB data
  memory (sized for a small bare-metal control program plus matrix-driver software).
- **Sub-word access:** memory returns a full 32-bit word on reads; the CPU extracts
  and sign/zero-extends the requested byte/halfword. Stores use byte-enable signals.
- **Bus model:** single master (CPU only), no arbitration, no pipelining — justified
  because nothing else in v1 initiates transactions (accelerator is CPU-loaded, not a
  second bus master; see §6).
- **Transaction timing:** polling-based. The CPU writes a control register to start the
  accelerator, which then runs independently; the CPU polls a status register rather
  than the bus stalling for a long-running operation.

### Memory Map

| Region | Range | Size |
|---|---|---|
| Instruction memory | `0x0000_0000`–`0x0000_3FFF` | 16 KB |
| *(reserved/unused)* | `0x0000_4000`–`0x0000_FFFF` | — |
| Data memory | `0x0001_0000`–`0x0001_3FFF` | 16 KB |
| *(reserved/unused)* | `0x0001_4000`–`0x7FFF_FFFF` | — |
| Accelerator MMIO | `0x8000_0000`–`0x8000_0FFF` | 4 KB |
| *(reserved/unused)* | `0x8000_1000`–`0xFFFF_FFFF` | — |

Reset PC = `0x00000000`, which correctly falls inside instruction memory with no
special-casing required.

## 6. Accelerator Interface & Data Loading

- **Loading mechanism:** CPU-loaded local scratchpad (chosen over element-wise MMIO
  push/pull for realistic data-reuse measurement, and over accelerator-as-bus-master/
  DMA to avoid a second bus master and the arbitration/verification cost that implies).
  The CPU remains the system's only bus master.
- Loading still costs `O(N²)` CPU store instructions per matrix (`~2N²` for A and B) —
  a known, intentional v1 limitation, explicitly measured rather than hidden (see §9).
- Once loaded, the PE array reuses scratchpad-resident data without further system
  memory or MMIO traffic during compute.
- **Addressing style:** directly memory-mapped array (not an auto-increment write
  pointer) — chosen for deterministic, order-independent software access and easier
  hardware debug/verification.
- DMA-based streaming is documented as a v2/stretch extension, not a v1 requirement.

### Accelerator MMIO Register Map (within `0x8000_0000`–`0x8000_0FFF`)

| Register/Region | Offset | Size | Notes |
|---|---|---|---|
| `START` | `0x000`–`0x003` | 4 B | Write triggers start; **ignored while BUSY=1** |
| `STATUS` | `0x004`–`0x007` | 4 B | bit0 = `DONE` (sticky, cleared only when a new `START` is accepted); bit1 = `BUSY` |
| Reserved | `0x008`–`0x00F` | 8 B | Former `SIZE` register — removed for v1 since dimensions are compile-time fixed; reserved for future runtime-configurable sizing |
| Matrix A | `0x010`–`0x10F` | 256 B | Signed 8-bit, byte-granular writes |
| Matrix B | `0x110`–`0x20F` | 256 B | Signed 8-bit, byte-granular writes |
| Matrix C | `0x210`–`0x60F` | 1024 B | Signed 32-bit, word-aligned reads |
| Reserved | `0x610`–`0xFFF` | — | Future extensions |

**START/STATUS semantics:** writing `START` while `BUSY=1` is a no-op (current
computation continues unchanged). On an accepted `START`: `BUSY←1, DONE←0`. On
computation completion: `BUSY←0, DONE←1`. Reading `STATUS` never clears `DONE` —
it remains asserted until the next accepted `START`.

## 7. Matrix Representation & Dimensions

- **Dimensions:** compile-time parameterized, `MAX_N = 16` for the primary v1 build.
  Smaller configurations (4×4, 8×8) are evaluated by re-synthesis, not runtime
  reconfiguration — runtime-configurable dimensions are documented future work.
- **Data representation:** signed integers throughout. A/B elements: **8-bit**.
  MAC product: **16-bit**. Accumulator/output (C): **32-bit** — sized with real margin
  over the worst-case sum (~19 bits needed for K=16), and conveniently means C reads
  back as a plain word load with no sub-word extraction, unlike A/B.
- **Footprint check (MAX_N=16):** A = 256 B, B = 256 B, C = 1024 B → 1536 B total,
  fits within the 4 KB MMIO reservation with headroom for control registers.

## 8. MAC / PE / Accelerator Compute Core

- **MAC interface:** signed 8-bit `A`, `B` inputs; signed 32-bit accumulator output;
  `clear` (resets accumulator, asserted at the start of a new output element/tile) and
  `enable`/accumulate (`ACC <= ACC + A×B`) controls. `clear` is distinct from a global
  system `reset` — it fires once per output element, not once per system lifetime.
- **PE role:** **output-stationary** — each PE accumulates one output element `C[i][j]`
  locally over K cycles per tile.
- **Array size:** **4×4 = 16 physical PEs**, reused across multiple output tiles rather
  than a fully parallel 16×16 = 256-PE array. Chosen for FPGA area/routing/verification
  cost, and confirmed necessary on the target device (§10: 220 DSP slices < 256).
- **Topology:** **broadcast** from the on-chip scratchpad (each array row shares one
  A operand, each array column shares one B operand) rather than a systolic
  nearest-neighbor network — justified because A/B are already fully on-chip before
  compute starts (§6), so systolic wiring's main advantage (avoiding long-distance
  broadcast for *streaming* data) doesn't apply the same way here. Systolic topology
  is documented as a future extension / potential research comparison.

### Tiling & Addressing

- 16 logical output tiles (`tile_I`, `tile_J` ∈ [0,3]), sequenced **row-major**:
  T00 → T01 → ... → T33.
- Per tile, per cycle `k` ∈ [0,15]: `PE(i,j)` consumes `A[4·tile_I+i][k]` and
  `B[k][4·tile_J+j]`.
- **A storage:** banked into 4 independent memories by `(row mod 4)` — bank `i` holds
  rows `i, i+4, i+8, i+12`. Enables 4 simultaneous single-cycle reads (one per array
  row) every cycle, which a single-port memory could not provide.
- **B storage:** banked into 4 independent memories by `(col mod 4)`, symmetric to A.
- **C storage:** single write port. A completed tile's 16 results drain sequentially,
  ~16 cycles/tile — a real, reported overhead, not hidden in the compute estimate.
- **Ideal cycle estimate:** 16 tiles × (16 MAC cycles + 16 writeback cycles) ≈
  **512 cycles**, plus minor per-tile setup/address-generation overhead. (Overlapping
  a tile's writeback with the next tile's compute is a documented future optimization.)

## 9. Performance Metrics

| Metric | Measurement approach |
|---|---|
| Latency | `T_load + T_compute + T_readback`, measured separately |
| Throughput | `2N³ / total_time` |
| Parallelism / utilization | PE count (16) vs. theoretical full-parallel (N²) |
| Resource utilization | Vivado post-synthesis LUT/FF/BRAM/DSP report vs. device budget |
| Memory bandwidth | Bytes moved during load ÷ `T_load` |
| Data reuse | Operand reads by PE array ÷ operand loads |
| Area | Vivado synthesis report (absolute LUT/FF/BRAM/DSP counts) |
| Max f<sub>max</sub> | Vivado post-implementation timing report |
| Speedup | `T_software_baseline / T_accelerated` (requires a real software matmul running on the CPU itself, distinct from the golden-reference simulator used for correctness checking) |
| Power/energy | Vivado power report, ideally driven by simulation switching activity |

## 10. FPGA Target

- **Board:** Digilent Arty Z7-20 — Xilinx Zynq-7000 **XC7Z020-1CLG400C**.
- **Usage:** **PL-only.** The dual-core ARM Cortex-A9 processing system (PS) is
  intentionally unused; the RISC-V CPU and accelerator are implemented entirely in
  programmable logic (PL), and the board is treated as a plain FPGA. This avoids
  needing Vivado IP Integrator or AXI PS↔PL bridging.
- **Device resources:** 53,200 LUTs · 106,400 flip-flops · 630 KB Block RAM ·
  220 DSP slices.
- **Toolchain:** Vivado (synthesis, implementation, bitstream).
- **Confirmed constraint:** a fully parallel 16×16 = 256-PE array would require more
  DSP-mapped multipliers (256) than the device provides (220) — validating the 16-PE
  reused-array decision as a device-specific necessity, not just a simplification, and
  providing a concrete data point for the array-scaling research question (§11).

## 11. Verification Strategy

- **Language/methodology:** SystemVerilog self-checking testbenches, Vivado/XSim-
  compatible — chosen over cocotb/Python for alignment with standard RTL/Digital IC
  industry verification practice.
- **CPU golden reference:** a custom software RV32I instruction-level simulator,
  predicting architectural state after executing a test program. Reusable across any
  future test program; a standalone artifact in its own right.
- **Accelerator golden reference:** NumPy/Python matrix multiplication (exact,
  uncontroversial oracle).
- **SVA:** added per-module for protocol-level invariants as each module is built
  (e.g., `STATUS` must never show `BUSY=1` and `DONE=1` simultaneously; MMIO address
  regions must never overlap in the decoder).
- **Verification levels:** unit (MAC, register file, single PE) → subsystem (PE array,
  CPU datapath) → integration (CPU executing full test programs) → system
  (CPU+accelerator via MMIO) → hardware bring-up.
- **Hardware bring-up (default for v1):** since the PS is unused and there is no host
  loader, test programs are pre-loaded into instruction/data memory via a
  memory-initialization file at synthesis time. Live UART/JTAG-based loading is
  documented future work, not required for v1.
- **Practice:** the full regression suite is re-run before every commit.

## 12. Research Questions (priority order)

1. **Resource/f<sub>max</sub> scaling:** how do resource utilization and achievable
   f<sub>max</sub> scale with matrix dimension N (4×4 → 8×8 → 16×16) under the fixed
   16-PE reused-array design?
2. **Bottleneck crossover:** at what matrix size does compute latency (`T_compute`)
   overtake data-movement overhead (`T_load` + `T_readback`)?
3. **Scratchpad payoff:** how much does the CPU-loaded scratchpad design (§6) improve
   measured data reuse and reduce memory traffic compared to the rejected naive
   element-wise MMIO push/pull alternative?

---

*This document reflects the v1 baseline agreed in Phase 0. Later phases may revise
individual decisions — any revision should be documented here with its justification,
not made silently.*
