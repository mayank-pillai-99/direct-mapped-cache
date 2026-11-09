#!/bin/bash
# Run every read-only trace with different main-memory latencies to see how
# the miss penalty changes AMAT. Output: results/latency_sweep.csv
set -e
cd "$(dirname "$0")/.."
python3 scripts/gen_traces.py > /dev/null
OUT=results/latency_sweep.csv
echo "trace,mem_latency,accesses,reads,writes,read_hits,read_misses,write_hits,hit_rate,miss_rate,hit_time,miss_penalty,amat_formula,amat_measured,total_cycles,errors" > $OUT
for L in 5 10 20 50 100; do
    iverilog -g2012 -I rtl -P tb_cache.MEM_LATENCY=$L -o results/sweep.vvp rtl/*.v tb/tb_cache.v
    for t in sequential repeated random conflict; do
        vvp -n results/sweep.vvp +trace=traces/$t.txt +name=$t +csv=$OUT > /dev/null
    done
done
rm -f results/sweep.vvp
column -s, -t $OUT | cut -c1-200
