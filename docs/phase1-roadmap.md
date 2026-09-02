# Phase 1 — RISC-V CPU Implementation Roadmap

**Status:** Living document, updated as modules are completed.
**Note on origin:** this module/dependency breakdown was first established
conversationally at the start of Phase 1 (derived from the actual datapath
dependency structure in `docs/phase0-architecture-specification.md` §4,
rather than the generic suggested ordering in the original Phase 1 kickoff
prompt). It had not previously been persisted as a file — this document
formalizes it so progress has somewhere durable to live.

Legend: ✅ Complete and verified · 🚧 Partially complete · ⬜ Not started

| # | Module | Depends on | Status |
|---|---|---|---|
| 1 | ALU | nothing | ✅ Complete — implemented, self-checking testbench passing |
| 2 | Register File | nothing | ✅ Complete — implemented, self-checking testbench passing |
| 3 | Immediate Generator | nothing | ✅ Complete — implemented, self-checking testbench passing |
| 4 | Instruction Decoder | ALU's op encoding | ✅ Complete — Pass A (classification) + Pass B (illegal-instruction detection); 47-vector table-driven testbench, verified in Vivado and ModelSim |
| 5 | PC register | ALU (next-value source) | ✅ Complete — implemented, directed testbench passing |
| 6 | `IR` / `MDR` / `A` / `B` / `ALUOut` datapath registers | ALU, decoder | 🚧 Partially complete — see breakdown below |
| 7 | Memory interface (I-mem + D-mem, shared access abstraction) | none of the above, but used by fetch/load/store | ⬜ Not started |
| 8 | Control FSM | everything above | ⬜ Not started |
| 9 | Illegal-instruction / unmapped-access halt logic | decoder, FSM, memory interface | ⬜ Not started |
| 10 | Full CPU integration (structural top-level) | all of the above | ⬜ Not started |
| 11 | RV32I program bring-up against the golden reference simulator | integration | ⬜ Not started |

## Section 6 breakdown — datapath registers

| Register | Status | Notes |
|---|---|---|
| `IR` | ✅ Complete | Implemented, directed testbench passing. No reset (see decision log D3). |
| `A` | ✅ Complete | Implemented, directed testbench passing (including a sensitivity-list bug caught and fixed — missing `posedge`). No reset (D3). |
| `B` | ✅ Complete (per developer confirmation) | Structurally identical to `A`; not independently reviewed in this chat, per developer's explicit choice to skip re-review. |
| `ALUOut` | ⬜ Not started | Reset policy reasoned through and agreed (no reset — per-instruction-type write guarantee; see `docs/phase1-handoff.md`), but `alu_out_reg.sv` has not been implemented or reviewed. |
| `MDR` | ⬜ Not started | Not yet discussed in detail. |

**Immediate next task:** implement, review, and verify `alu_out_reg.sv`, then `mdr_reg.sv`, to close out Section 6.
