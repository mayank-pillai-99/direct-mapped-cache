# Interview / Viva Preparation

Short answers every member should be able to give.

**1. Why do we need a cache?**  
The CPU is much faster than DRAM. A small fast memory near the CPU holds recently used data, so most
accesses finish in a few cycles instead of waiting for DRAM.

**2. What is temporal and spatial locality?**  
Temporal: data used now will be used again soon (loop variables). Spatial: data near it will be used soon
(next array element). Our *repeated* trace shows temporal (97.5 % hits), *sequential* shows spatial (75 %).

**3. How do you get the tag, index and offset widths?**  
Offset = log2(block size) = log2(16) = 4. Lines = 1024/16 = 64, index = log2(64) = 6.
Tag = 32 − 6 − 4 = 22.

**4. What is a direct-mapped cache?**  
Each memory block can go into only one line: line = (address / 16) mod 64. Lookup needs only one tag compare.

**5. When is it a hit?**  
When the valid bit of the line is 1 **and** the stored tag equals the address tag.

**6. Why do we need a valid bit?**  
After reset the tag RAM holds garbage. Without the valid bit, garbage could match a tag and give a false hit.

**7. What are the three kinds of misses? Show each one in your results.**  
Compulsory (first access — the first pass of *repeated*), capacity (working set too big — *random*),
conflict (two blocks share a line — *conflict* trace, 0 % hits).

**8. Why is the sequential hit ratio exactly 75 %?**  
A block has 4 words. The first word misses and loads the block, the other 3 hit → 3/4.

**9. What is AMAT? What are your numbers?**  
AMAT = hit time + miss rate × miss penalty = 2 + miss rate × 12 cycles (memory latency 10).
Sequential: 2 + 0.25 × 12 = 5 cycles.

**10. Why is the miss penalty 12 and not 10?**  
10 cycles of memory latency + 1 cycle to write the block into the cache + 1 cycle for the second COMPARE.

**11. Explain the FSM.**  
IDLE → COMPARE on a request. Read hit → IDLE. Read miss → ALLOCATE → (block arrives) → COMPARE → IDLE.
Write → WRITE_MEM → IDLE.

**12. What write policy do you use and why?**  
Write-through, no-write-allocate. Memory is always up to date, so no dirty bits and no write-back state —
simpler to design and verify. Drawback: every store goes to memory.

**13. How do you know the cache is correct?**  
The testbench keeps a reference copy of memory and compares every read. All traces: 0 errors.

**14. How would you fix the conflict misses?**  
Use a 2-way set-associative cache (two blocks per set, LRU replacement) or add a small victim cache.

**15. What did synthesis give?**  
About 316 LUTs, 138 flip-flops and 136 RAM64M (LUT RAM) on Xilinx 7-series. RAMs became distributed RAM
because they are read asynchronously; with a synchronous read they could use block RAM.

**16. What happens if the block size is bigger?**  
More spatial locality per miss (sequential hit ratio 1 − 4/block_bytes), but fewer lines for the same cache
size → more conflict misses, and a longer miss penalty.
