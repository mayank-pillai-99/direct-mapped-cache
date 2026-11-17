"""Generate memory-access traces for the direct-mapped cache.

Each line of a trace file is one access:
    R <address>            read  (address in hex)
    W <address> <data>     write (address and data in hex)

All addresses are word aligned and inside the 64 KB main memory.

Run:
    python3 scripts/gen_traces.py                      # all traces, seed 42
    python3 scripts/gen_traces.py --only demo mixed    # just these traces
    python3 scripts/gen_traces.py --seed 7 --out /tmp/traces
"""
import argparse
import os
import random

CACHE_BYTES = 1024          # 1 KB cache
BLOCK_BYTES = 16            # 16-byte blocks
MEM_BYTES = 64 * 1024       # 64 KB main memory model

DEFAULT_OUT = os.path.join(os.path.dirname(__file__), "..", "traces")
DEFAULT_SEED = 42           # same traces every time
TRACE_NAMES = ["sequential", "repeated", "random", "conflict", "mixed", "demo"]


def make_traces(seed=DEFAULT_SEED):
    """Build every trace and return them as {name: [access, ...]}.

    All traces are always built in the same order, so the random ones are
    identical whether you generate one trace or all of them.
    """
    rng = random.Random(seed)

    # 1. Sequential: walk through 4 KB word by word (spatial locality).
    #    One miss per 16-byte block, then 3 hits -> expected hit ratio 75 %.
    sequential = [("R", a) for a in range(0, 4096, 4)]

    # 2. Repeated (loop): read a 512-byte array 10 times (temporal locality).
    #    Only the first pass misses (32 blocks) -> expected 1 - 32/1280 = 97.5 %.
    repeated = [("R", a) for _ in range(10) for a in range(0x2000, 0x2000 + 512, 4)]

    # 3. Random: 1000 random words anywhere in 64 KB (little locality).
    #    Cache holds 1/64 of memory -> expected hit ratio of only a few %.
    rand = [("R", rng.randrange(0, MEM_BYTES, 4)) for _ in range(1000)]

    # 4. Conflict: two addresses 1 KB apart map to the same line (same index,
    #    different tag). Alternating between them -> every access misses.
    conflict = []
    for _ in range(100):
        conflict.append(("R", 0x0040))
        conflict.append(("R", 0x0040 + CACHE_BYTES))

    # 5. Mixed read/write: checks write-through and that reads see new data.
    mixed = []
    for _ in range(200):
        addr = rng.randrange(0, 2048, 4)          # small region -> many hits
        if rng.random() < 0.3:
            mixed.append(("W", addr, rng.getrandbits(32)))
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

    return {
        "sequential": sequential,
        "repeated": repeated,
        "random": rand,
        "conflict": conflict,
        "mixed": mixed,
        "demo": demo,
    }


def write_trace(out_dir, name, accesses):
    path = os.path.join(out_dir, name + ".txt")
    with open(path, "w") as f:
        for acc in accesses:
            if acc[0] == "R":
                f.write(f"R {acc[1]:08x}\n")
            else:
                f.write(f"W {acc[1]:08x} {acc[2]:08x}\n")
    print(f"{name:12s} {len(accesses):5d} accesses -> {path}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate memory-access traces for the direct-mapped cache.")
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED,
                        help=f"random seed for the random/mixed traces (default {DEFAULT_SEED})")
    parser.add_argument("--out", default=DEFAULT_OUT,
                        help="output folder (default: traces/)")
    parser.add_argument("--only", nargs="+", choices=TRACE_NAMES, metavar="TRACE",
                        help="generate only these traces: " + ", ".join(TRACE_NAMES))
    args = parser.parse_args()

    traces = make_traces(args.seed)
    os.makedirs(args.out, exist_ok=True)
    for name in args.only or TRACE_NAMES:
        write_trace(args.out, name, traces[name])


if __name__ == "__main__":
    main()
