# Phase 1 — Design Decision Log

**Status:** Living document, updated as Phase 1 progresses.
**Purpose:** Phase 0 (`docs/phase0-architecture-specification.md`) is the fixed
source-of-truth baseline and is not edited to record these entries. This log
captures decisions made *during* implementation that Phase 0 left genuinely
open — gaps, not revisions. Where a later phase reveals an actual conflict
with a Phase 0 decision, that goes back into the Phase 0 document itself with
justification, per its own closing note — not here.

Each entry: **Issue → Options considered → Decision → Rationale → Consequences.**

---

## D1 — Register File Reset Policy (`x1`–`x31`)

**Issue:** Phase 0 §5 specifies the PC reset value (`0x00000000`) but is
silent on whether general-purpose registers `x1`–`x31` need a defined value
at reset. §2 only guarantees `x0` reads as zero and ignores writes.

**Options considered:**
1. No reset for `x1`–`x31` — registers hold arbitrary/unknown content until
   the first instruction writes them.
2. Synchronous reset clearing all 32 registers to `0` on `rst_n` assertion.

**Decision:** No reset for `x1`–`x31`.

**Rationale:**
- Matches real RISC-V hardware semantics: the ISA only architecturally
  guarantees `x0 == 0`; general registers are undefined until software
  initializes them. This is the more "architecturally honest" choice, not
  just the simpler one.
- The register file's read ports are combinational (async) by design — a
  direct consequence of Phase 0 §4's `A`/`B` datapath registers already
  providing the cycle-to-cycle latching this multi-cycle CPU needs, which
  would make a registered read port redundant double-buffering.
- Combinational-read, no-reset storage remains a legal candidate for
  distributed RAM (LUTRAM) synthesis. A full synchronous reset that clears
  all registers *simultaneously* cannot be implemented by a single-write-port
  RAM primitive (it can only update one address per cycle) — synthesis tools
  would be forced to fall back to flip-flop-based storage with a shared reset
  net to honor that requirement. No reset avoids forcing that choice
  incidentally; the primitive used is left to synthesis/tool defaults instead
  (to be confirmed against the Phase 11 post-synthesis utilization report,
  not assumed here).
- `x0` needs no reset logic regardless of this decision: reads are
  unconditionally hardwired to `0` and writes to `x0` are unconditionally
  blocked, independent of what (if anything) is stored at index 0. `regs[0]`
  is provably dead storage under the current interface.

**Consequences:**
- Simulation: `x1`–`x31` are `X` (unknown) until explicitly written. Unit
  testbenches must write a register before ever reading it (already followed
  in `tb/register_file_tb.sv`).
- Future golden-reference comparison (§11, CPU integration phase): the RTL
  CPU's architectural state must only be compared against the software
  simulator for registers the test program has actually written by that
  point — never-written registers cannot be assumed equal to whatever the
  simulator itself initializes its register array to.

---

## D2 — Instruction Decoder / Control FSM Responsibility Boundary

**Issue:** Phase 0 describes the multi-cycle FSM-controlled datapath (§4) but
does not explicitly draw a line between "interpreting an instruction" and
"sequencing control signals across cycles" as separate module
responsibilities — both are implied but not assigned.

**Decision:**
- **Instruction Decoder:** a pure combinational function of `IR` alone.
  Produces extracted fields (`rd`, `rs1`, `rs2`, `funct3`), the `alu_op_e`
  selection (reusing the mapping established for `rtl/alu.sv`), the
  `imm_type_e` selection (reusing the mapping established for
  `rtl/immediate_generator.sv`), and (once implemented) an
  illegal-instruction flag. Never depends on, or is aware of, the current FSM
  state.
- **Control FSM:** decides, per cycle, *when* to act on what the decoder has
  already determined — asserting `reg_we`, selecting `ALUOut` vs. `MDR` for
  writeback, selecting the PC source, etc. Consumes the decoder's outputs
  plus its own state; never re-derives instruction meaning itself.

**Rationale:**
- Keeps the decoder fully testable in isolation, in the same category as the
  ALU and immediate generator (pure combinational, unit-verifiable with no
  dependency on any other module existing yet).
- If an FSM state signal is ever found necessary as a decoder *input*, that's
  a signal this boundary is being violated, not a hint to add a port —
  worth treating as a design smell if it comes up later.

**Consequences:**
- The Control FSM (roadmap module 8) must not duplicate decode logic; it
  strictly consumes decoder outputs.
- The decoder (roadmap module 5) can be implemented and unit-tested before
  the FSM exists at all.

---

## D3 — `IR`, `A`, `B` Register Reset Policy

**Issue:** Do the `IR` instruction register and the `A`/`B` operand-latch
registers need a defined reset value, given none of them hold architecturally
meaningful data until first written?

**Decision:** No reset for any of the three.

**Rationale:**
- This is a **different category of justification than D1**, not just the
  same conclusion reapplied. D1 (register file `x1`–`x31`) rests on a
  *software-behavior* assumption: no-reset is safe only insofar as correct
  programs write a register before reading it — a property of the code
  running on the CPU, not something the hardware itself guarantees.
- `IR`/`A`/`B` rest on a stronger, purely *hardware-structural* guarantee
  instead: the Control FSM's fixed state sequencing means the write
  unconditionally precedes the first read, regardless of what program is
  running.
  - `IR` is written during Fetch — the FSM's reset-entry state — and is
    first read by the decoder only at Decode, one state later.
  - `A`/`B` are written during Decode, sourced from the register file's
    combinational `rs1_data`/`rs2_data` outputs (see D1), and are first read
    by the ALU only in a later state (e.g. Execute).

**Consequences / open dependency on the future FSM:**
- This conclusion is only valid if the Control FSM's reset state is Fetch
  (or otherwise guarantees `ir_write` fires before any Decode-stage
  consumption, and `a_write`/`b_write` fire before their first downstream
  read). **This has not yet been verified**, since the Control FSM (roadmap
  Section 8) does not exist yet. Flagged here as a requirement the FSM
  design must satisfy, not an assumption already confirmed.
- Simulation: `IR`/`A`/`B` hold `X` between reset deassertion and their
  first respective write. No testbench should read them before that write
  (already followed in `tb/ir_reg_tb.sv` and `tb/a_reg_tb.sv`).

---
## D4 — `ALUOut` Register Reset Policy

**Issue:** Same category of question as D3 — does `ALUOut` need a defined
reset value, given it holds no architecturally meaningful data until first
written?

**Decision:** No reset.

**Rationale:**
- Same hardware-structural, write-before-read justification as D3 — but a
  **weaker, multi-path claim** rather than D3's single-state guarantee.
  `ALUOut` is written along a different path depending on instruction type:
  R/I-type ALU result, branch target (Decode) vs. branch condition
  (branch-specific state), load/store effective address, and JAL/JALR
  `PC+4`. Each path must independently guarantee its write precedes
  `ALUOut`'s first read for that instruction.
- This is intentionally logged as a harder-to-verify claim than D3, not an
  equally strong one — flagged here so it isn't accidentally treated as
  "already proven" later.

**Consequences:**
- `rtl/ALUout.sv` implemented; `sim/alu_out_reg_tb.sv` (directed
  write/hold/second-write) passes.
- Full multi-path write-before-read verification remains **unresolved**
  until the Control FSM (Section 8) exists — same open caveat as D3.

---

## D5 — `MDR` Register Reset Policy

**Issue:** Same category of question again — does `MDR` need a reset?

**Decision:** No reset.

**Rationale:**
- Same hardware-structural category as D3/D4, but the **simplest case** of
  the three: `MDR` is written and read along exactly one path — the `LOAD`
  instruction type only (written in `MEM_READ`, read in `MEM_WB`). No other
  instruction type touches it, so there is only one path to verify, not
  several.

**Consequences:**
- `rtl/mdr_reg.sv` implemented; `sim/mdr_reg_tb.sv` (directed
  write/hold/second-write) passes.
- Single-path write-before-read verification remains **unresolved** until
  the Control FSM exists.

## Open Items (flagged, not yet resolved)

### O1 — Branch/Jump Target Alignment

Phase 0 §3 defines **misaligned load/store** as an explicit, documented
software constraint (hardware behavior unverified, not a hardware concern).
It does **not** address the alignment of a *branch or jump target* written
into `PC`.

Given RV32I (without the C extension) requires 4-byte instruction alignment
(`PC[1:0] == 00`), and given the immediate generator's forced-zero bit 0
(see the "why the trailing `1'b0`" discussion) only guarantees `PC[0] == 0`
after a branch/jump-target addition — never `PC[1]` — a target with a
2-byte-granular offset can produce a misaligned fetch address that nothing
in the current design catches.

This is architecturally distinct from load/store misalignment: it corrupts
`PC` itself, which then drives every subsequent instruction fetch, not just
one data access.

**To be decided at Execute/Branch/Jump implementation (roadmap module 10):**
does this become a third documented software constraint alongside load/store
misalignment, or does its larger blast radius warrant the same
halt-on-illegal-state treatment §3 already defines for illegal opcodes and
unmapped addresses?

**Status:** Open.

### O2 — Sub-word Load Extraction: Timing/Placement

Phase 0 §5 assigns byte/halfword extraction and sign/zero-extension to "the
CPU," without specifying which cycle or which side of `MDR` it happens on.

Two options were identified during `MDR`'s design:
1. Extract/sign-extend combinationally in `MEM_READ`, before `MDR` latches
   the value (adopted for the conceptual walkthrough, not yet built).
2. Latch the **raw** 32-bit word into `MDR` in `MEM_READ`; extract
   downstream, combinationally, in `MEM_WB`.

Option 1 puts memory-access delay + extraction-mux delay + sign-extend delay
all in `MEM_READ`'s critical path. Option 2 spreads that delay into a
separate cycle instead. Given Phase 0 §9 tracks f<sub>max</sub> as a project
metric, this should be decided with the trade-off named, not assumed.

**Status:** Open — to be resolved when Section 7 (memory interface) is
designed. Does not affect `mdr_reg.sv`'s interface either way (see D5).
