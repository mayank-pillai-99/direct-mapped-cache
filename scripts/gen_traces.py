"""Generate memory-access traces for the direct-mapped cache.

Each line of a trace file is one access:
    R <address>            read  (address in hex)
    W <address> <data>     write (address and data in hex)

All addresses are word aligned and inside the 64 KB main memory.
Run:  python3 scripts/gen_traces.py
"""
import os
import random

CACHE_BYTES = 1024          # 1 KB cache
BLOCK_BYTES = 16            # 16-byte blocks
MEM_BYTES = 64 * 1024       # 64 KB main memory model

OUT = os.path.join(os.path.dirname(__file__), "..", "traces")
random.seed(42)             # same traces every time


def write_trace(name, accesses):
    path = os.path.join(OUT, name + ".txt")
    with open(path, "w") as f:
        for acc in accesses:
            if acc[0] == "R":
                f.write(f"R {acc[1]:08x}\n")
            else:
                f.write(f"W {acc[1]:08x} {acc[2]:08x}\n")
    print(f"{name:12s} {len(accesses):5d} accesses -> {path}")


# 1. Sequential: walk through 4 KB word by word (spatial locality).
#    One miss per 16-byte block, then 3 hits -> expected hit ratio 75 %.
sequential = [("R", a) for a in range(0, 4096, 4)]

# 2. Repeated (loop): read a 512-byte array 10 times (temporal locality).
#    Only the first pass misses (32 blocks) -> expected 1 - 32/1280 = 97.5 %.
repeated = [("R", a) for _ in range(10) for a in range(0x2000, 0x2000 + 512, 4)]

# 3. Random: 1000 random words anywhere in 64 KB (little locality).
#    Cache holds 1/64 of memory -> expected hit ratio of only a few %.
rand = [("R", random.randrange(0, MEM_BYTES, 4)) for _ in range(1000)]

# 4. Conflict: two addresses 1 KB apart map to the same line (same index,
#    different tag). Alternating between them -> every access misses.
conflict = []
for _ in range(100):
    conflict.append(("R", 0x0040))
    conflict.append(("R", 0x0040 + CACHE_BYTES))

# 5. Mixed read/write: checks write-through and that reads see new data.
mixed = []
for i in range(200):
    addr = random.randrange(0, 2048, 4)          # small region -> many hits
    if random.random() < 0.3:
        mixed.append(("W", addr, random.getrandbits(32)))
    else:
        mixed.append(("R", addr))

# 6. Demo: a short trace that is easy to explain in the video.
demo = [
    ("R", 0x0000),   # miss (cold)          index 0
    ("R", 0x0004),   # hit  (same block)    index 0
    ("R", 0x000C),   # hit  (same block)    index 0
    ("R", 0x0010),   # miss (next block)    index 1
    ("R", 0x0400),   # miss (conflict: index 0, new tag) -> replaces 0x0000
    ("R", 0x0000),   # miss (was evicted)
    ("W", 0x0004, 0xDEADBEEF),  # write hit -> cache + memory updated
    ("R", 0x0004),   # hit, returns DEADBEEF
]

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    write_trace("sequential", sequential)
    write_trace("repeated", repeated)
    write_trace("random", rand)
    write_trace("conflict", conflict)
    write_trace("mixed", mixed)
    write_trace("demo", demo)
