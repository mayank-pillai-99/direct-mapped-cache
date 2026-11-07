# Team Git Guide

The evaluators check the **commit history** to see that every member contributed. So each member must
commit **their own files from their own GitHub account**. Do not let one person push everything.

## 1. One-time setup (Mayank — repository owner)

1. Create an empty GitHub repository, e.g. `direct-mapped-cache` (no README).
2. Settings → Collaborators → add Asad, Divyansh, Vikrant and Prashant.
3. Push only the skeleton first:

```bash
cd mca_project
git init
git add README.md .gitignore docs/Project_list_MCA.pdf rtl/cache_params.vh
git commit -m "Project skeleton: README, parameters, project brief"
git branch -M main
git remote add origin https://github.com/<user>/direct-mapped-cache.git
git push -u origin main
```

## 2. Every member

Set your own name and email once (the email must be the one on your GitHub account):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Clone, add your files, commit, push:

```bash
git clone https://github.com/<user>/direct-mapped-cache.git
cd direct-mapped-cache
# copy your files in, then:
git add <your files>
git commit -m "Add <module>: <one line about what it does>"
git pull --rebase
git push
```

## 3. Suggested order and files

| # | Member | Files | Commit message example |
|---|--------|-------|------------------------|
| 1 | Asad Ali | `rtl/address_decoder.v`, `rtl/tag_comparator.v` | Add address decoder and tag comparator |
| 2 | Divyansh Bhartia | `rtl/valid_ram.v`, `rtl/tag_ram.v`, `rtl/data_ram.v` | Add valid, tag and data RAMs |
| 3 | Vikrant Yadav | `rtl/main_memory.v`, `scripts/gen_traces.py`, `traces/` | Add main memory model and trace generator |
| 4 | Mayank Pillai | `rtl/cache_controller.v`, `rtl/cache_top.v` | Add controller FSM and top-level integration |
| 5 | Prashant Raj | `tb/tb_cache.v`, `scripts/run_all.sh`, `scripts/latency_sweep.sh`, `results/` | Add self-checking testbench and results |
| 6 | Prashant Raj | `synth/` | Add Yosys synthesis script and report |
| 7 | Asad + Divyansh | `report/main.tex` (Abstract, Literature Review) | Report: abstract and literature review |
| 8 | Mayank + Vikrant | `report/main.tex` (Proposed Solution), `report/figures/`, `scripts/make_plots.py`, `scripts/vcd_to_tikz.py`, `docs/figures/` | Report: proposed solution and figures |
| 9 | Prashant | `report/main.tex` (Results), `report/main.pdf` | Report: results and discussion |
| 10 | Mayank | `README.md` (video link), `docs/video_script.md` | Add demo video link |

Spread the commits over several days rather than all in one hour, and make small follow-up commits
(comments, fixes, extra traces) — this looks like (and is) real teamwork.

## 4. Phase II ideas (each member can own one)

* Block-size / cache-size sweep (change `cache_params.vh`, rerun traces) — Asad / Divyansh
* Write-back policy with dirty bits — Mayank
* 2-way set-associative cache with LRU and comparison on the same traces — Mayank / Vikrant
* Traces from a real program (e.g. matrix multiply, row vs column order) — Vikrant
* Timing (Fmax) in Vivado on an Artix-7 — Prashant
