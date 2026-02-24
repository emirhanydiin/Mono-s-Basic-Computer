# Basic Computer I — Verilog Implementation

A fully functional implementation of the **Basic Computer I** (von Neumann / Mono Architecture) described in *Computer System Architecture* by Morris Mano, written in Verilog HDL and simulated with [Icarus Verilog](https://steveicarus.github.io/iverilog/) and [cocotb](https://www.cocotb.org/).

---

## Architecture Overview

The design follows the classic **hardwired control unit** approach with a 4-bit sequence counter and a 4×16 decoder generating timing signals T₀–T₁₅. The datapath and controller are separate modules connected through a single 16-bit common bus.

```
                    ┌────────────────────────┐
                    │       BC_I (Top)        │
                    │  ┌──────────────────┐  │
          clk ─────►│  │    Controller    │  │
          FGI ─────►│  │  (Hardwired CU)  │  │
                    │  └────────┬─────────┘  │
                    │  Control  │ Signals     │
                    │  ┌────────▼─────────┐  │
                    │  │     Datapath     │  ├──► PC, AR, IR
                    │  │  16-bit Bus      │  ├──► AC, DR, E
                    │  └──────────────────┘  │
                    └────────────────────────┘
```

---

## File Structure

```
.
├── BC_I.v              # Top-level module (connects datapath + controller)
├── controller.v        # Hardwired control unit
├── datapath.v          # Datapath (module instantiations only)
├── alu.v               # 16-bit Arithmetic Logic Unit
├── reg_unit.v          # Parameterised register (LD / INR / CLR)
├── bus_mux.v           # 8-to-1 parameterised multiplexer (common bus)
├── seq_counter.v       # 4-bit sequence counter (timing signals)
├── memory_unit.v       # 4096 × 16 word-addressable memory
├── memory_content.hex  # Initial memory image (test program)
└── code.txt            # Assembly source of the test program
```

---

## Module Descriptions

### `BC_I.v` — Top-Level
Instantiates and wires together the `datapath` and `controller`. Exposes the following ports:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk`| input     | 1     | System clock |
| `FGI`| input     | 1     | Interrupt flag (input device ready) |
| `PC` | output    | 12    | Program Counter |
| `AR` | output    | 12    | Address Register |
| `IR` | output    | 16    | Instruction Register |
| `AC` | output    | 16    | Accumulator |
| `DR` | output    | 16    | Data Register |
| `E`  | output    | 1     | Extended carry bit |

---

### `datapath.v` — Datapath
A structural module containing only module instantiations (no `always` or `assign` blocks). Registers present:

| Register | Width | Controls |
|----------|-------|---------|
| AR       | 12    | LD, INR, CLR |
| PC       | 12    | LD, INR, CLR |
| DR       | 16    | LD, INR, CLR |
| AC       | 16    | LD, INR, CLR |
| E        | 1     | LD, INR, CLR |
| IR       | 16    | LD, CLR |
| TR       | 16    | LD, CLR |
| IEN      | 1     | LD, INR, CLR |
| R        | 1     | LD, CLR (Interrupt flip-flop) |

All registers are initialised to `0` via `initial` blocks (no hardware reset port on the top level).

---

### `controller.v` — Hardwired Control Unit
A combinational `always @(*)` block that decodes the timing signal `T`, the opcode field `IR[14:12]`, the indirect bit `IR[15]`, and status flags (`E`, `Z`, `N`, `IEN`, `R`, `FGI`) to drive all datapath control signals.

**Execution phases:**

1. **Fetch** (T0–T1): Load AR ← PC, read memory into IR, increment PC.  
2. **Decode** (T2): Load AR ← IR[11:0] (effective address pre-fetch).  
3. **Indirect** (T3, I=1, D≠7): AR ← M[AR].  
4. **Execute** (T3+): Instruction-specific microoperations.  
5. **Interrupt** (R=1): Save PC to M[0], jump to M[1], clear IEN & R.

The sequence counter (`seq_counter.v`) is instantiated inside the controller and can be cleared (`clr_T`) to reset T back to 0 at the end of any instruction.

---

### `alu.v` — Arithmetic Logic Unit
Parameterised (`W`, default 16 bits). Operations selected by `op[2:0]`:

| `op` | Operation | Description |
|------|-----------|-------------|
| `000`| ADD       | AC + DR → out, updates CO, OVF, E |
| `001`| AND       | AC ∧ DR → out |
| `010`| Transfer DR   | DR → out |
| `011`| Complement AC | ~AC → out |
| `100`| Shift Right   | {E, AC[W-1:1]} → out, AC[0] → E |
| `101`| Shift Left    | {AC[W-2:0], E} → out, AC[W-1] → E |
| `110`| Transfer AC   | AC → out (default/passthrough) |

Status outputs `Z` (zero) and `N` (negative) are updated for every operation; `CO` and `OVF` are meaningful only for ADD.

---

### `reg_unit.v` — Parameterised Register
Positive-edge-triggered register with synchronous reset, write enable, and increment:

| Reset | WE | INC | Operation |
|-------|----|-----|-----------|
| 0     | 0  |  0  | Retain |
| 0     | 0  |  1  | A ← A + 1 |
| 0     | 1  |  X  | A ← DATA |
| 1     | X  |  X  | A ← 0 |

---

### `bus_mux.v` — 8-to-1 Multiplexer (Common Bus)
Parameterised (`W`, default 16 bits). Selector mapping inside the datapath:

| `sel` | Source |
|-------|--------|
| 0     | `0x0000` |
| 1     | AR |
| 2     | PC |
| 3     | DR |
| 4     | AC |
| 5     | IR |
| 6     | TR |
| 7     | Memory read data |

---

### `seq_counter.v` — Sequence Counter
4-bit counter that produces timing signals T0–T15. Increments on every positive clock edge; resets to 0 when `clr_T` is asserted by the controller.

---

### `memory_unit.v` — Memory
4096 × 16 synchronous-write, combinational-read RAM. Initialised from `memory_content.hex` using `$readmemh`.

---

## Implemented Instructions

### Memory-Reference Instructions

| Opcode | Symbol | Description |
|--------|--------|-------------|
| 000    | AND    | AC ← AC ∧ M[X] |
| 001    | ADD    | AC ← AC + M[X], E ← carry |
| 010    | LDA    | AC ← M[X] |
| 011    | STA    | M[X] ← AC |
| 100    | BUN    | PC ← X |
| 101    | BSA    | M[X] ← PC, PC ← X+1 |
| 110    | ISZ    | M[X]++; skip if zero |

### Register-Reference Instructions

| Code | Symbol | Description |
|------|--------|-------------|
| 7800 | CLA    | Clear AC |
| 7400 | CLE    | Clear E |
| 7200 | CMA    | Complement AC |
| 7100 | CME    | Complement E |
| 7080 | CIR    | Circular shift right (AC, E) |
| 7040 | CIL    | Circular shift left (AC, E) |
| 7020 | INC    | Increment AC |
| 7010 | SPA    | Skip if AC positive |
| 7008 | SNA    | Skip if AC negative |
| 7004 | SZA    | Skip if AC zero |
| 7002 | SZE    | Skip if E zero |
| 7001 | HLT    | Halt |

### I/O Reference Instructions 

| Code | Symbol | Description |
|------|--------|-------------|
| F080 | ION    | Interrupt enable |
| F040 | IOF    | Interrupt disable |

> **Note:** INP, OUT, SKI, SKO are not implemented.

---

## Interrupt Handling

When `IEN = 1`, `FGI = 1`, and `R = 0`, the interrupt flip-flop R is set after T2. The interrupt cycle then executes:

```
T0: AR ← 0
T1: M[AR] ← PC,  PC ← 0
T2: PC ← PC + 1,  IEN ← 0,  R ← 0,  SC ← 0
```

The ISR vector is expected at `M[1]` (a `BUN` instruction pointing to the service routine). The return address is saved at `M[0]`.

---

## Test Program

The sample test program (`code.txt`) exercises memory-reference, register-reference, and interrupt instructions. Its machine code is pre-loaded into `memory_content.hex`.

```asm
        BUN 0x2         ; Return save address slot
        BUN 0x400       ; ISR vector
        CLE             ; Program start
        LDA 0x600
        ADD 0x601
1       ADD 0x602       ; Indirect add
1       AND 0x603       ; Indirect AND
        SPA
        CLA
        STA 0xaea
        CMA
        ADD 0xaea
        SNA
        CLA
        ION
        SZA
        BUN 15          ; Loop until interrupt
        CME
        CIL
        CIR
        HLT

ORG 0x400               ; Interrupt Service Routine
        INC
        ION
1       BUN 0x0         ; Return via indirect BUN

ORG 0x600               ; Data
        441
        445
        0xaeb
        0xaea

ORG 0xAEA               ; More data
        348
        447
```

---

## How to Simulate

### Prerequisites

## For Linux

```bash
# Icarus Verilog
sudo apt install iverilog

# cocotb
pip install cocotb
```

### Compile & Run with Icarus Verilog

```bash
iverilog -o bc_sim BC_I.v controller.v datapath.v alu.v reg_unit.v \
         bus_mux.v seq_counter.v memory_unit.v
vvp bc_sim
```

### Writing Your Own Testbench (cocotb)

No testbench is provided — you are expected to write your own using [cocotb](https://www.cocotb.org/). The top-level DUT is `BC_I`, which exposes the following ports for you to drive and monitor:

| Signal | Direction | Width | Notes |
|--------|-----------|-------|-------|
| `clk`  | input     | 1     | Drive with a clock generator |
| `FGI`  | input     | 1     | Assert to trigger an interrupt |
| `PC`   | output    | 12    | Monitor for control flow |
| `AR`   | output    | 12    | Monitor for memory addressing |
| `IR`   | output    | 16    | Monitor fetched instructions |
| `AC`   | output    | 16    | Monitor computation results |
| `DR`   | output    | 16    | Monitor data register |
| `E`    | output    | 1     | Monitor carry/extend bit |
