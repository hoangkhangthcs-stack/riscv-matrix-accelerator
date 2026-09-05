# Phase 1 — Handoff Context

**Purpose:** lets a new chat in this project continue Phase 1 without
repeating prior reasoning. Read this, `docs/phase1-roadmap.md`, and
`docs/phase1-design-decisions.md` before doing anything else.

---

## Current completion status

Modules 1–5 (ALU, Register File, Immediate Generator, Instruction Decoder,
PC register) are **complete**: implemented, reviewed, and verified.

Modules 1–6 (ALU, Register File, Immediate Generator, Instruction Decoder,
PC register, and all five datapath registers — `IR`/`A`/`B`/`ALUOut`/`MDR`)
are **complete**: implemented, reviewed, and verified.

Modules 7–11 (memory interface, Control FSM, illegal-instruction/halt logic,
CPU integration, program bring-up) — **not started**.

## Completed modules (files)

- `rtl/rv32i_pkg.sv` — shared package: `alu_op_e`, `imm_type_e` (includes
  `IMM_NA`), `instr_type_e`.
- `rtl/alu.sv` + `tb/alu_tb.sv`
- `rtl/register_file.sv` + `tb/register_file_tb.sv`
- `rtl/immediate_generator.sv` + `tb/immediate_generator_tb.sv`
- `rtl/decoder.sv` + `tb/decoder_tb_passB.sv` (table-driven, 47 vectors)
- `rtl/pc_reg.sv` + `tb/pc_reg_tb.sv`
- `rtl/ir_reg.sv` + `tb/ir_reg_tb.sv`
- `rtl/a_reg.sv` + `tb/a_reg_tb.sv`
- `rtl/b_reg.sv` — developer-confirmed complete, structurally identical to
  `a_reg.sv`; **not independently reviewed in chat**.
  - `rtl/ALUout.sv` + `sim/alu_out_reg_tb.sv`
- `rtl/mdr_reg.sv` + `sim/mdr_reg_tb.sv`

## Remaining in Phase 1 (in order)
1. Memory interface (Section 7).
2. Control FSM (Section 8) — this is where several open dependencies below
   get resolved/verified for the first time.
3. Illegal-instruction/unmapped-access halt logic (Section 9).
4. CPU integration (Section 10).
5. RV32I program bring-up vs. golden-reference simulator (Section 11).

## Design decisions already made (do not re-derive)

Full detail in `docs/phase1-design-decisions.md`. Summary:

- **D1 — Register file reset:** no reset for `x1`–`x31`. Justified by
  software-behavior assumption (matches real RISC-V semantics) *and*
  keeps the regfile a legal distributed-RAM (LUTRAM) synthesis candidate,
  since a simultaneous multi-register reset isn't compatible with a
  single-write-port RAM primitive. `x0` needs no reset logic — reads are
  hardwired to 0, writes are unconditionally blocked.
- **D2 — Decoder/FSM boundary:** decoder is a pure combinational function
  of `IR` alone (answers "what"); FSM answers "when" and must never
  duplicate decode logic or take FSM state as a decoder input.
- **D3 — `IR`/`A`/`B` reset:** no reset for any of the three. Different
  justification category than D1 — this rests on a hardware-structural
  FSM-sequencing guarantee (write always precedes first read), not a
  software-behavior assumption. **This guarantee is not yet verified**
  since the FSM doesn't exist — it's a requirement the FSM must satisfy,
  flagged for confirmation once Section 8 begins.
- **`ALUOut` reset (agreed, not yet logged as a decision entry since the
  module isn't implemented — becomes D4 once it is):** no reset, same
  category of argument as D3, but the write-precedes-read guarantee is
  **per-instruction-type** rather than one fixed state (R/I-type ALU ops,
  branches, loads/stores, and JAL/JALR each write `ALUOut` at a different
  point in their respective execution paths). Verifying this holds is a
  multi-path obligation on the FSM, not a single check.
- **`SYSTEM` (opcode `1110011`) and `FENCE` (opcode `0001111`) are both
  treated as illegal instructions** — proposed and accepted, no memory-
  ordering use case given this design's single-master, no-arbitration bus.
  - **D4 — `ALUOut` reset:** no reset; multi-path write-before-read guarantee
  (weaker/harder-to-verify claim than D3), unresolved until FSM exists.
- **D5 — `MDR` reset:** no reset; simplest case — single `LOAD`-only path.
- **O2 — sub-word load extraction placement (raw-vs-extracted before `MDR`)
  is an open, f_max-relevant question for Section 7** — not yet decided.

## Open items (unresolved, flagged for later)

- **O1 — Branch/jump target alignment** (full detail in decision log):
  Phase 0 §3 documents misaligned load/store as a software constraint but
  never addresses branch/jump-target alignment (`PC[1]`). To be decided
  at Execute/Branch/Jump implementation: third software constraint, or
  halt-on-illegal-state given the larger blast radius (corrupts `PC`
  itself, not just one data access)?
- **FSM-ordering guarantees** (D3 and the `ALUOut` note above): must be
  confirmed once the Control FSM is designed, not assumed.

## Verification status

- All modules through the decoder have self-checking SystemVerilog
  testbenches, verified via Icarus Verilog in this chat's sandbox
  wherever Icarus's feature support allowed it.
- The decoder's full 47-vector table-driven testbench was verified in
  **Vivado and ModelSim** directly by the developer (Icarus could not run
  it — see tool-limitation list below).
- **Icarus Verilog limitations hit during this phase** (confirm each is a
  non-issue in Vivado/XSim/ModelSim before relying on Icarus results
  again for future modules):
  - No support for named task/function arguments (`.arg(value)` works for
    module ports, not task calls).
  - Ternary expressions between two enum literals require an explicit
    cast to the enum type (`alu_op_e'(cond ? A : B)`) or Icarus rejects
    the assignment.
  - `unique case` is parsed but its runtime uniqueness check is not
    enforced — no warning on a genuine violation.
  - The `inside` operator is unsupported ("sorry: not supported yet").
  - Unpacked structs are unsupported.
  - Array-literal aggregate assignment to a declared array is unsupported.
  - Minor: constant part-selects inside `always_comb` produce a harmless
    "all bits will be included" sensitivity-list warning.

## Coding conventions in use

- `logic` typed explicitly on every port, always.
- `always_comb` + `unique case` with an explicit `default` branch for
  latch safety, *unless* the case is already exhaustive over the signal's
  full bit-width (e.g. a 3-bit `funct3` case with all 8 values covered) —
  in which case no default is added.
- Sequential registers: `always_ff @(posedge clk)`, no explicit
  self-assignment `else` branch for "hold" (relying on natural flip-flop
  hold behavior — this was an explicit lesson learned, not an oversight).
- Enum members referenced either via `import pkg::*;` or fully-qualified
  `pkg::MEMBER` — both used across different files; no strict project-wide
  rule yet, but the decoder uses `import`.
- Reset style: synchronous, active-low (`rst_n`), where a register needs
  reset at all — decided for `pc_reg` specifically (Xilinx 7-series
  timing/routing rationale). Several registers (`IR`, `A`, `B`, planned
  `ALUOut`) deliberately have **no** reset at all — see D3.
- Self-checking testbenches: `PASS`/`FAIL` `$display` per vector plus a
  final summary count; table-driven style (struct-of-vectors + loop) used
  for the decoder given its large vector count.

## Immediate next task

Begin Section 7 (memory interface, I-mem + D-mem shared access abstraction).
Resolve O2 (sub-word extraction timing/placement) as part of that design.

## Do NOT reconsider unless a new issue appears

- Register file reset policy (D1).
- Decoder/FSM responsibility boundary (D2).
- `IR`/`A`/`B` no-reset policy (D3).
-(D4)
-(D5)
- `ALUOut` no-reset policy (agreed, pending formal logging as D4).
- `SYSTEM`/`FENCE` = illegal.
- Sync (not async) reset as the project's default reset style.
- The decoder's Pass A / Pass B classification and illegal-detection
  tables — already exhaustively verified against independent ISA-based
  references and two real toolchains.
- `B`'s completion — accept the developer's statement that it matches
  `a_reg.sv`; do not ask for it to be re-posted unless a bug surfaces
  elsewhere that traces back to it.
