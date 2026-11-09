#!/bin/bash
# Compile the cache and run every trace. Results go to results/.
# Usage:  ./scripts/run_all.sh            (memory latency 10 cycles)
#         LATENCY=20 ./scripts/run_all.sh
set -e
cd "$(dirname "$0")/.."
LATENCY=${LATENCY:-10}

python3 scripts/gen_traces.py
mkdir -p results
echo "trace,mem_latency,accesses,reads,writes,read_hits,read_misses,write_hits,hit_rate,miss_rate,hit_time,miss_penalty,amat_formula,amat_measured,total_cycles,errors" > results/summary.csv

iverilog -g2012 -I rtl -P tb_cache.MEM_LATENCY=$LATENCY -o results/sim.vvp rtl/*.v tb/tb_cache.v

for t in demo sequential repeated random conflict mixed; do
    vvp -n results/sim.vvp +trace=traces/$t.txt +name=$t | grep -v "VCD info"
done

echo
echo "Summary written to results/summary.csv"
column -s, -t results/summary.csv
