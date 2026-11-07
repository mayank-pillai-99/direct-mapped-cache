# Prototype Video Script (target 4:30, limit 5:00)

Record as a screen share (slides from `docs/figures/*.png` + terminal + code editor).
Each member speaks for about 50 seconds about their own part.

---

## 0:00 – 0:40 · Mayank Pillai — Introduction and project idea

**Show:** title slide with all 5 names, then `docs/figures/block_diagram.png`.

> "Hello, we are Asad Ali, Divyansh Bhartia, Vikrant Yadav, Mayank Pillai and Prashant Raj.
> Our project is Project 6, a **Direct-Mapped Cache Controller** in Verilog.
> A processor is much faster than main memory, so a cache keeps recently used data close to the processor.
> Our cache is 1 KB with 16-byte blocks and 32-bit addresses, so it has 64 lines.
> In a direct-mapped cache each memory block can go into exactly one line, which makes the lookup simple and fast.
> We measure hit ratio, miss ratio and AMAT on different memory-access patterns."

## 0:40 – 1:30 · Asad Ali — Address fields and tag comparator

**Show:** `rtl/address_decoder.v`, `rtl/tag_comparator.v`, table from README.

> "The 32-bit address is split into three fields. The offset is 4 bits because a block is 16 bytes.
> The index is 6 bits because we have 64 lines. The remaining 22 bits are the tag.
> For example address 0x404 has index 0 and tag 1, so it goes to the same line as address 0x000 — this is a conflict.
> The address decoder is just wiring. The tag comparator gives hit = valid AND stored tag equals address tag."

## 1:30 – 2:15 · Divyansh Bhartia — Cache storage

**Show:** `rtl/valid_ram.v`, `rtl/tag_ram.v`, `rtl/data_ram.v`.

> "The cache storage has three memories, all indexed by the 6-bit index.
> The valid RAM has 64 bits that are cleared on reset, so the cache starts empty and the first access to a line
> is always a miss. The tag RAM stores 64 tags of 22 bits. The data RAM stores 64 blocks of 128 bits.
> It can write a whole block on a refill, or one word on a write hit. Reads are combinational, so the lookup
> takes one cycle."

## 2:15 – 3:05 · Mayank Pillai — Controller FSM and integration

**Show:** `docs/figures/fsm.png`, then `rtl/cache_controller.v`.

> "The controller is a 4-state FSM. In IDLE it waits for a request. In COMPARE it checks the tag:
> a read hit returns the data immediately; a read miss goes to ALLOCATE, which fetches the 16-byte block from
> memory and writes data, tag and valid bit, then returns to COMPARE where it now hits.
> Writes go to WRITE_MEM, because we use write-through. A hit takes 2 cycles and a miss takes 14 cycles
> with a 10-cycle memory. `cache_top.v` connects all modules."

## 3:05 – 3:45 · Vikrant Yadav — Main memory and traces

**Show:** `rtl/main_memory.v`, `scripts/gen_traces.py`, `traces/demo.txt`.

> "Main memory is a 64 KB model with a configurable latency. Every word holds its own address as data,
> so it is easy to check the results. It returns a whole block on a read.
> We generate six traces: sequential for spatial locality, repeated for temporal locality, random,
> a conflict trace with two addresses 1 KB apart, a mixed read/write trace, and a short demo trace."

## 3:45 – 4:40 · Prashant Raj — Testbench, live demo, results

**Show:** terminal: `./scripts/run_all.sh`, then `results/demo_log.txt`, `docs/figures/waveform_demo.png`,
`docs/figures/hit_ratio.png`.

> "The testbench reads a trace, sends each access to the cache, and checks every read against a reference memory.
> Here is the demo log: the first read is a cold miss taking 14 cycles, the next two hit in 2 cycles, and 0x400
> evicts 0x000 so the next read of 0x000 misses again.
> The results: sequential 75 percent hits, repeated 97.5 percent, random 1 percent, and the conflict trace
> 0 percent. AMAT is 2 plus miss rate times 12, and the measured value matches the formula exactly.
> All traces pass with zero errors. Yosys synthesis uses about 316 LUTs and 138 flip-flops."

## 4:40 – 4:55 · Mayank Pillai — Closing

> "To summarise, our direct-mapped cache works correctly and shows clearly how locality and conflicts affect
> performance. Next we plan to add a 2-way set-associative version to remove the conflict misses. Thank you."
